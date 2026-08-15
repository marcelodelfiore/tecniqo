# Evidence storage operations

## Contract

```text
Evidence -> Active Storage -> private S3-compatible service -> Garage
```

Application code knows Active Storage, never Garage APIs or keys. Object keys are opaque.
The database owns tenant and maintenance relationships. Original filenames are untrusted
display metadata, never storage keys.

## Supported originals

| Evidence type | Typical accepted formats | Limit | Preserve original | Processing now |
| --- | --- | ---: | --- | --- |
| Photo | JPEG, PNG, WebP, HEIC/HEIF | 25 MB | Yes | No |
| Thermogram | vendor binary, JPEG, PNG, WebP | 100 MB | Yes, mandatory | No |
| Audio | M4A/AAC, WebM, WAV | 100 MB | Yes | No |
| Video | MP4, MOV, WebM | 500 MB | Yes | No |
| Document | PDF | 25 MB | Yes | No |
| Technical file | approved text/CSV or vendor binary | 100 MB | Yes | No |
| Other | restricted image, PDF, text, or CSV | 25 MB | Yes | No |

Active Storage/Marcel identifies content rather than trusting only the browser MIME.
Octet-stream is limited to thermograms and technical files; Phase 5 should narrow vendor
extensions when actual formats are confirmed. Executables and archives are rejected.
Future previews, normalized media, OCR, and transcription are separate derivatives.

## Local Garage

Copy `.env.example` to `.env`, replace every placeholder, and use a random 64-character
hex `GARAGE_RPC_SECRET`. Then run:

```sh
docker compose up -d garage
set -a; source .env; set +a
bin/rails server
```

Development defaults to Disk so tests and ordinary work do not require Garage. Set
`ACTIVE_STORAGE_SERVICE=evidence_s3` to exercise Garage. Production defaults to that
service. Compose binds S3/admin ports to localhost; Garage's single-node default-bucket
startup creates the private bucket/key, and named volumes persist metadata and objects.

Manual verification:

1. Open an Execution as a participating Technician.
2. Upload `spec/fixtures/files/evidence.txt` as Technical file.
3. Confirm filename, MIME, size, uploader, and SHA-256.
4. Download through Técniqo and run `sha256sum downloaded-file`.
5. Verify the digest, cross-tenant denial, and absence of replace/delete actions.
6. Run `docker compose restart garage`; download and hash again.

## Production, backup, and migration

Garage on the same VPS is primary storage, not backup. Before production use, copy
object data plus the corresponding database backup to another failure domain and test
restoration regularly.

To migrate providers: provision a private destination; copy objects without changing
opaque keys; verify originals against Evidence SHA-256; quiesce uploads or temporarily
mirror the final delta; switch Active Storage environment/configuration; verify authorized
downloads; retain the source for a rollback window. Mirroring replicates writes/deletes
and can assist migration—it is not disaster recovery.

## Deferred security and authenticity

Malware quarantine is deferred until an explicit pending/accepted lifecycle exists.
Direct upload is deferred until orphan cleanup, post-upload validation, and trusted
server digest verification exist.

A future Evidence Authenticity Record may include Evidence ID, Organization, Work Order,
Execution, Asset, Site, authenticated actor, captured/uploaded times, filename, MIME,
size, SHA-256, review context, integrity verification, signature, and trusted timestamp.
Hotwire Native may later add native capture, local hashing, device/session context, and
server comparison. These stronger chain-of-custody claims are not implemented now.
