// SPDX-FileCopyrightText: 2024 Christina Sørensen
// SPDX-FileContributor: Christina Sørensen
//
// SPDX-License-Identifier: AGPL-3.0-only

use super::ha_registry::routes::get_routes as get_ha_routes;
use super::oci::routes::get_routes as get_oci_routes;
use axum::Router;

pub fn get_routes() -> Router {
    Router::new()
        .nest("/ha", get_ha_routes())
        .nest("/", get_oci_routes())
}
