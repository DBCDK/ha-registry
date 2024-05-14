// SPDX-FileCopyrightText: 2024 Christina Sørensen
// SPDX-FileContributor: Christina Sørensen
//
// SPDX-License-Identifier: AGPL-3.0-only

use axum::http::StatusCode;

/// Handler for the OCI /v2/ endpoint end-1
///
/// TODO: implement auth/401
pub async fn version_check() -> StatusCode {
    StatusCode::OK
}
