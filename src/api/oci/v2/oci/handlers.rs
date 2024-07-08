// SPDX-FileCopyrightText: 2024 Christina Sørensen
// SPDX-FileContributor: Christina Sørensen
//
// SPDX-License-Identifier: EUPL-1.2

use std::sync::Arc;

use axum::{
    extract::{Path, Query},
    http::StatusCode,
    response::{IntoResponse, Response},
    Extension,
};
use serde::Deserialize;

use crate::storage::s3::S3Backend;

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

#[derive(Debug, Deserialize)]
pub struct UploadQueryParams {
    #[allow(dead_code)]
    digest: Option<String>,
    #[allow(dead_code)]
    location: Option<String>,
}

/// Handler for OCI /v2/ endpoint end-4a
///
/// Monolitically pushes a blob to the registry,
/// TODO: end-4b, end-11.
pub async fn init_push(
    Path(name): Path<String>,
    query: Option<Query<UploadQueryParams>>,
) -> impl IntoResponse {
    // TODO: implement end-4b.
    if let Some(..) = query {
        log::debug!("Single post (end-4b) not implemented yet.");
        let response = Response::builder()
            .status(StatusCode::NOT_IMPLEMENTED)
            .body(axum::body::Body::empty())
            .unwrap();
        return response;
    }

    let id = uuid::Uuid::new_v4();
    // TODO: ownership/access control: {name} is the namespace.
    let location = format!("/v2/{name}/uploads/{id}");
    log::trace!("Post then PUT (end-4a), location: {location}");
    let response = Response::builder()
        .status(StatusCode::ACCEPTED)
        .header("location", location)
        .body(axum::body::Body::empty())
        .unwrap();
    response
}

/// Handler for OCI /v2/ endpoint end-6
///
/// Monolitically pushes a blob to the registry,
/// TODO: implement chunking.
pub async fn push_blob(
    Extension(s3_client): Extension<Arc<S3Backend>>,
    Path((name, reference)): Path<(String, String)>,
    Query(digest): Query<String>,
    headers: axum::http::HeaderMap,
    body: axum::body::Bytes,
) -> impl IntoResponse {
    if headers.contains_key("Content-Length") || headers.contains_key("Content-Range") {
        log::debug!("Chunking not implemented (end-6b) for push_blob.");
        let response = Response::builder()
            .status(StatusCode::NOT_IMPLEMENTED)
            .body(axum::body::Body::empty())
            .unwrap();
        return response;
    }

    s3_client.push_blob(digest, body).await.unwrap();

    // TODO: ownership/access control, {name} is the namespace.
    let blob_location = format!("/v2/{name}/blobs/{reference}");
    log::trace!("Post then PUT (end-6a), blob_location: {blob_location}");
    let response = Response::builder()
        .status(StatusCode::CREATED)
        .header("location", blob_location)
        .body(axum::body::Body::empty())
        .unwrap();
    response
}
