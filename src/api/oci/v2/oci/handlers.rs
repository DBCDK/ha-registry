// SPDX-FileCopyrightText: 2024 Christina Sørensen
// SPDX-FileContributor: Christina Sørensen
//
// SPDX-License-Identifier: EUPL-1.2

use axum::http::StatusCode;

/// Handler for the OCI /v2/ endpoint end-1
///
/// TODO: Implement auth/401
///
/// NOTE: This is technically a lie, this endpoint should only respond if we
/// implement the entire spec but... we don't care B)
pub async fn version_check() -> StatusCode {
    StatusCode::OK
}

/// Handler for unimplemented API endpoints
///
/// See also: https://datatracker.ietf.org/doc/html/rfc7231#section-6.6.2
pub async fn unimplemented() -> StatusCode {
    StatusCode::NOT_IMPLEMENTED
}
