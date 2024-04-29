// SPDX-FileCopyrightText: 2024 Christina Sørensen
// SPDX-FileContributor: Christina Sørensen
//
// SPDX-License-Identifier: EUPL-1.2

use std::{ops::Deref, sync::Arc};

use crate::data::status::ServerStatus;
use axum::{
    response::{IntoResponse, Response},
    Extension, Json,
};

/// Handler for returning the server status.
pub async fn status(
    Extension(status): Extension<Arc<tokio::sync::RwLock<ServerStatus>>>,
) -> Response {
    Json(status.clone().read().await.deref()).into_response()
}
