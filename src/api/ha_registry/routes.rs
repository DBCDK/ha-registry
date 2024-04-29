// SPDX-FileCopyrightText: 2024 Christina Sørensen
// SPDX-FileContributor: Christina Sørensen
//
// SPDX-License-Identifier: AGPL-3.0-only

use axum::Router;

use super::v1::routes::get_routes as get_v1_routes;

pub fn get_routes() -> Router {
    Router::new().nest("/v1", get_v1_routes())
}
