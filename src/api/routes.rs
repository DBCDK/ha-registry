// SPDX-FileCopyrightText: 2024 Christina Sørensen
// SPDX-FileContributor: Christina Sørensen
//
// SPDX-License-Identifier: AGPL-3.0-only

use super::ha_registry::v1::routes::get_routes as get_ha_routes;
use axum::Router;

pub fn get_routes() -> Router {
    Router::new().nest("/ha", get_ha_routes())
}
