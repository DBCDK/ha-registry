// SPDX-FileCopyrightText: 2024 Christina Sørensen
// SPDX-FileContributor: Christina Sørensen
//
// SPDX-License-Identifier: EUPL-1.2

use axum::{routing::get, Router};

use super::status::handlers::status;

pub fn get_routes() -> Router {
    Router::new().route("/status", get(status))
}
