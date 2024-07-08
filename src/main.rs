// SPDX-FileCopyrightText: 2023-2024 Christina Sørensen
// SPDX-FileContributor: Christina Sørensen
//
// SPDX-License-Identifier: EUPL-1.2

#![deny(clippy::unwrap_used)]

use std::{error::Error, ops::Deref, sync::Arc};

use axum::{
    extract::Extension,
    http::StatusCode,
    response::{IntoResponse, Redirect},
    routing::get,
    Router,
};
use tokio::{net::TcpListener, sync::RwLock};

extern crate log;
extern crate pretty_env_logger;

mod api;
mod cli;
mod data;
mod storage;

use api::routes::get_routes as get_api_routes;

#[allow(unused)]
use log::{debug, error, info, trace, warn};

use crate::{
    data::{status::ServerStatus, Config},
    storage::s3::S3Backend,
};

async fn handler_404() -> impl IntoResponse {
    (StatusCode::NOT_FOUND, "404 - not found")
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    pretty_env_logger::init();

    let matches = crate::cli::build_cli().get_matches();

    let config;

    if let Some(path) = matches.get_one::<String>("init") {
        Config::gen_example_config(path)?;
        return Ok(());
    }

    if let Some(config_file) = matches.get_one::<String>("config") {
        config = Arc::new(RwLock::new(Config::load(config_file)));
    } else {
        config = Arc::new(RwLock::new(Config::load(data::CONFIG)));
    }

    trace!("{config:#?}");

    let s3backend = S3Backend::new(
        config
            .clone()
            .read()
            .await
            .deref()
            .s3
            .as_ref()
            .expect("failed to load s3 backed from config"),
    )
    .await?;

    trace!("{s3backend:#?}");

    s3backend.init_blob_store().await;

    let s3backend = Arc::new(s3backend);

    // FIXME: We currently don't mutate the server status state, but we will in
    // the future, and we want the type checker to notice this being a problem,
    // so we keep this around.
    #[allow(unused_mut)]
    let mut status = ServerStatus::new();

    trace!("{:#?}", status);

    let app = Router::new()
        .route(
            "/",
            get(|| async { Redirect::to("https://github.com/cafkafk/ha-registry") }),
        )
        .merge(get_api_routes())
        .fallback(handler_404)
        .layer(Extension(s3backend))
        .layer(Extension(status))
        .layer(Extension(config.clone()));

    let listener = TcpListener::bind(&config.clone().read().await.bind_addr())
        .await
        .expect("failed to bind");

    info!(
        "Listening on http://{:#?}",
        &config.clone().read().await.bind_addr()
    );

    // Notify systemd that we're done getting ready to serve users
    #[cfg(target_os = "linux")]
    match sd_notify::notify(true, &[sd_notify::NotifyState::Ready]) {
        Ok(_) => (),
        Err(e) => panic!("Failed to notify systemd we're ready: {e}"),
    };

    axum::serve(listener, app)
        .await
        .expect("failed to serve app");

    Ok(())
}
