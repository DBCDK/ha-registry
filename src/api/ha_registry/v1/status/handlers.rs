// SPDX-FileCopyrightText: 2024 Christina Sørensen
// SPDX-FileContributor: Christina Sørensen
//
// SPDX-License-Identifier: AGPL-3.0-only

use std::sync::Arc;

use crate::data::status::Status;
use axum::{http::StatusCode, Extension, Json};

/// Handler for returning the server status.
pub async fn status(Extension(status): Extension<Arc<Status>>) -> Result<Json<Status>, StatusCode> {
    match Arc::into_inner(status) {
        Some(status) => Ok(Json(status)),
        None => Err(StatusCode::INTERNAL_SERVER_ERROR),
    }
}
// pub async fn status() -> StatusCode {
//     StatusCode::OK
// }
