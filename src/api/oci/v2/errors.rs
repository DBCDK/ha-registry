// SPDX-FileCopyrightText: 2024 Christina Sørensen
// SPDX-FileContributor: Christina Sørensen
//
// SPDX-License-Identifier: AGPL-3.0-only

/// Implements the OCI v2 distribution API Error Codes
///
/// The `code` field MUST be a unique identifier, containing only uppercase alphabetic characters and underscores.
/// The `message` field is OPTIONAL, and if present, it SHOULD be a human readable string or MAY be empty.
/// The `detail` field is OPTIONAL and MAY contain arbitrary JSON data providing information the client can use to resolve the issue.
///
/// The `code` field MUST be one of the following:
///
/// | ID      | Code                    | Description                                                |
/// |-------- | ------------------------|------------------------------------------------------------|
/// | code-1  | `BLOB_UNKNOWN`          | blob unknown to registry                                   |
/// | code-2  | `BLOB_UPLOAD_INVALID`   | blob upload invalid                                        |
/// | code-3  | `BLOB_UPLOAD_UNKNOWN`   | blob upload unknown to registry                            |
/// | code-4  | `DIGEST_INVALID`        | provided digest did not match uploaded content             |
/// | code-5  | `MANIFEST_BLOB_UNKNOWN` | manifest references a manifest or blob unknown to registry |
/// | code-6  | `MANIFEST_INVALID`      | manifest invalid                                           |
/// | code-7  | `MANIFEST_UNKNOWN`      | manifest unknown to registry                               |
/// | code-8  | `NAME_INVALID`          | invalid repository name                                    |
/// | code-9  | `NAME_UNKNOWN`          | repository name not known to registry                      |
/// | code-10 | `SIZE_INVALID`          | provided length did not match content length               |
/// | code-11 | `UNAUTHORIZED`          | authentication required                                    |
/// | code-12 | `DENIED`                | requested access to the resource is denied                 |
/// | code-13 | `UNSUPPORTED`           | the operation is unsupported                               |
/// | code-14 | `TOOMANYREQUESTS`       | too many requests                                          |
///
/// ## See also
/// - https://github.com/opencontainers/distribution-spec/blob/main/spec.md#error-codes
#[derive(debug)]
pub enum OciErrors {
    /// code-1: blob unknown to registry
    BlobUnknown,
    /// code-2: blob upload invalid
    BlobUploadInvalid,
    /// code-3: blob upload unknown to registry
    BlobUploadUnknown,
    /// code-4: provided digest did not match uploaded content
    DigestInvalid,
    /// code-5: manifest references a manifest or blob unknown to registry
    ManifestBlobUnknown,
    /// code-6: manifest invalid
    ManifestInvalid,
    /// code-7: manifest unknown to registry
    ManifestUnknown,
    /// code-8: invalid repository name
    NameInvalid,
    /// code-9: repository name not known to registry
    NameUnknown,
    /// code-10: provided length did not match content length
    SizeInvalid,
    /// code-11: authentication required
    Unauthorized,
    /// code-12: requested access to the resource is denied
    Denied,
    /// code-13: the operation is unsupported
    Unsupported,
    /// code-14: too many requests
    TooManyRequests,
}
