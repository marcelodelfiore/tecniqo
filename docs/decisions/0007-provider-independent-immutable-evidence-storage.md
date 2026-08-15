# ADR 0007: Provider-independent immutable evidence storage

- Status: Accepted
- Date: 2026-08-15

## Context

Field evidence is part of the engineering record. Its business meaning, provenance,
authorization, and integrity must survive replacement of the object-storage product.
Garage is the first backend, but Técniqo must also support another S3-compatible service
without domain-code changes.

Active Storage's checksum protects storage mechanics. It is not Técniqo's audit
fingerprint, and default permanent signed-id routes are not an adequate authorization
boundary for private tenant evidence.

## Decision

- `Evidence` is the domain record; Active Storage owns blob storage.
- Garage implements the provider-neutral `evidence_s3` service through the S3 API.
- Evidence belongs to one Execution initially. Phase 5 will decide how technical records
  reference it without changing original ownership.
- The received original stream is SHA-256 hashed and rewound before Active Storage stores
  the same bytes. Evidence snapshots filename, detected content type, size, authenticated
  uploader, acceptance time, optional capture time, and digest.
- Accepted originals are append-only: metadata is read-only, replacement raises, no
  update/destroy routes exist, and record deletion is blocked.
- Derivatives must always be separate objects. Thermographic vendor originals must never
  be normalized away because rendered previews may lose radiometric data.
- Storage is private. Default Active Storage routes are disabled. An explicit Evidence
  endpoint authorizes the domain record with Pundit and streams the original.
- Uploads are server-mediated. Direct upload, processing, malware scanning, authenticity
  certificates, signing, and trusted timestamps are deferred.

## Consequences

A provider change requires object copy, digest verification, configuration, credentials,
and infrastructure cutover—not Evidence/controller/policy/view changes. Active Storage
mirroring may assist migration but is not backup. A Garage volume on the application VPS
is primary storage and requires backup in another failure domain before production use.

Integrity means bytes still match SHA-256. Authenticity additionally concerns actor,
execution, capture/device/session context, custody, and potentially signatures. A future
Evidence Authenticity Record can build on this foundation; SHA-256 alone does not prove
authenticity.
