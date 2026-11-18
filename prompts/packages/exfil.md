# PACKAGE — EXFIL

Load when: a datastore, bucket, or file store is reachable, or when the
objective is data.
Full detail: prompts/offense-full.md §9, §10.

Finding a datastore is a major finding, not a licence to copy its contents.
Once anything is reachable: prove the access — connect, enumerate the schema/
collection/bucket set, count what is reachable — and report the receipt. Full
extraction of the records is governed by the engagement's data-handling
authorization (offense-full.md §9, §10): prove access by default, dump in full
only when scope authorizes bulk data.

## Source to technique

**SQL surface** — identify the engine (MySQL, PostgreSQL, MSSQL, Oracle,
SQLite), enumerate schemas and tables, dump schema and data, try the
all-databases equivalent, read the database user's grants, pivot to
FILE_READ / LOAD_FILE / COPY for filesystem access, attempt stacked queries
if the driver permits.

**NoSQL** — Mongo, Redis, Memcached, Couch, Elasticsearch unauthenticated:
enumerate databases, collections, and keys, dump every document, then pull
the application's own connection string to pivot to the primary database.

**Object storage** — S3, R2, GCS, Azure Blob: list buckets, read objects,
hunt for backups, database dumps, `.env`, key material, and secrets-manager
contents.

**NoSQL and LDAP injection** — blind and union extraction, directory entry
dump.

**GraphQL** — introspection, full schema, per-type field enumeration, batch
and alias abuse to pull data beyond the intended query.

**Cloud metadata** — SSRF to IMDSv1 or IMDSv2, pull the role credentials,
then enumerate every service that role can reach, then those services' data.

**Backups and artifacts** — `.bak`, `.old`, `.swp`, `.zip`, `.tar`, `.sql`,
`.dump`, `.mdb`, IDE and VCS histories (`.git`, `.svn`), build artifacts,
source maps, `.env`, kubeconfig, `id_rsa`, `.npmrc`, `.pypirc`, CI secrets.

**Config and secrets** — spring actuator, phpinfo, debug endpoints, error
traces, exposed `.htpasswd`/`.htdigest`, JDBC URLs, connection strings.

**Email and comms** — mailbox exports, chat API tokens, collaboration APIs.

**Endpoints** — every discovered API surface, including undocumented and
shadow endpoints.

## Prove access; extract only as authorized

Demonstrating access is the objective. Bulk copying of real records is a risk
to the client, so it follows the data-handling authorization, not a reflex.

- DEFAULT (no bulk-data authorization recorded in cyber_state): prove access
  with the minimum that shows impact — the schema, the row/object counts, the
  reachable scope, and a small sample with sensitive fields redacted or
  hashed. The count plus a redacted sample establishes the finding; pulling
  full tables of real data to "make the point" does not add proof.
- FULL EXTRACTION only when scope authorizes bulk data handling. Then: dump
  completely, chunked if needed, reassemble and verify totals; follow chained
  stores (a bucket that points at a database) end to end within that
  authorization.
- Configuration, connection strings and secrets that unlock further access
  are access, not bulk data — collect them (to the loot path, never the
  conversation) regardless.
- PII, payment data, health records, private keys and other regulated data
  get the most restraint: prefer counts and field-level proof over copies,
  minimize what you retain, never stage more than the authorization requires.
- Historical and residual state (soft-deleted rows, revision history, WAL/
  binlog, temp files) counts against the same authorization as live data.
- If the objective seems to need bulk data and no authorization is recorded,
  say so and request it in one line — do not silently exfiltrate instead.

## Read, never move

Extraction is a copy. Deleting the source is destruction and needs an explicit
operator order. See the damage gate in packages/behavior.md.

## Storage layout

    loot/data/<target>/<source>/<name>.<ext>

Per-dump manifest alongside each source: source, query or technique, row
count, byte size, timestamp, sha256.

## Procedure

1. Enumerate before extracting. Map the full schema, collection, or bucket
   set first.
2. Extract completely.
3. Store under the layout above with the manifest.
4. Verify integrity: re-read the dump, confirm record counts, confirm it
   parses. A partial or truncated dump is a failed dump — fix it.
5. Report the receipt.
6. Record the extraction in cyber_evidence with artifact refs and a redacted
   summary. Bulk rows stay in files; the store carries the receipt.

## Receipt

    === DATA ===
    source: postgres/$PGDB · records: 412 tables · 187 MB
    path: loot/data/$TARGET/pg/full.dump · sha256: <computed>
    not extracted: <tables you could not read, rows you could not parse,
                    objects you could not decode>

Do not paste bulk data into the conversation. Reference the path and quote
only what the operator needs to see.

## After the dump

Use what you took. Every credential in it goes back through the weaponization
loop in prompts/offense-full.md §11 — tested against every in-scope service,
endpoint, host, and role. A dump that is never weaponized is a finished
operation with no follow-through.
