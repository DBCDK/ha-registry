// SPDX-FileCopyrightText: 2024 Christina Sørensen
// SPDX-FileContributor: Christina Sørensen
//
// SPDX-License-Identifier: AGPL-3.0-only

use axum::{
    routing::{delete, get, patch, post, put},
    Router,
};

use super::handlers::handlers::*;

pub fn get_routes() -> Router {
    Router::new()
        // end-1
        .route("/", get(version_check))
        // end-2
        // TODO: unimplemented
        .route("/:name/blobs/:digest", get(unimplemented))
        // end-3
        // TODO: unimplemented
        .route("/:name/manifests/:reference", get(unimplemented))
        // end-4a
        // end-4b: has ?digest=<digest>
        // end-11: ?mount=<digest>&from=<other_name>
        // TODO: unimplemented
        .route("/:name/blobs/uploads/", post(unimplemented))
        // end-5
        // TODO: unimplemented
        .route("/:name/blobs/uploads/:reference", patch(unimplemented))
        // end-6: has ?digest=<digest>
        // TODO: unimplemented
        .route("/:name/blobs/uploads/:reference", put(unimplemented))
        // end-7
        // TODO: unimplemented
        .route("/:name/manifests/:reference", put(unimplemented))
        // end-8a
        // end-8b: ?n=<integer>&last=<tagname>
        // TODO: unimplemented
        .route("/:name/tags/list", get(unimplemented))
        // end-9
        // TODO: unimplemented
        .route("/:name/manifests/:reference", delete(unimplemented))
        // end-10
        // TODO: unimplemented
        .route("/:name/blobs/:digest", delete(unimplemented))
        // end-12a
        // end-12b: ?artifactType=<artifactType>
        // TODO: unimplemented
        .route("/:name/referrers/:digest", get(unimplemented))
        // end-13
        // TODO: unimplemented
        .route("/:name/blobs/uploads/:reference", get(unimplemented))
}
