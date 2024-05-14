// SPDX-FileCopyrightText: 2024 Christina Sørensen
// SPDX-FileContributor: Christina Sørensen
//
// SPDX-License-Identifier: AGPL-3.0-only

use axum::{routing::get, Router};

use super::status::handlers::status;

pub fn get_routes() -> Router {
    Router::new().route("/status", get(status))
}
