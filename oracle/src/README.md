## Canister Logic & Oracle Implementation
- **Files:** [`./MusicRegistry.mo`](./MusicRegistry.mo), [`./types.mo`](./types.mo)
- **Purpose:** Store and retrieve music track metadata (title, album, credits, genre, publisher, token addresses, etc.). Maintain reference data such as partners and genres. Track unlock counts per partner and detailed unlock logs. Gate write operations behind a simple owner model (`setCanisterOwner`).
- **Highlights:**
  - Persistent in-memory lists for works, partners, genres, unlock counts, and unlock logs.
  - Query methods for visible tracks (e.g., `verification_status == "show"`), tracks by genre, per-partner unlock counts, and date/range-filtered unlock logs.

## Dashboard Functional Prototype
- **Hosted URL:** <https://oracle.beatswap.io>
- **Purpose:** Front-end prototype that reads from the canister and presents real-time track metadata and basic interactions (e.g., viewing, **streaming unlock–payment info**).

## Metadata Migration Script
- **Files:** [`./Web2MetadataMigration.mo`](./Web2MetadataMigration.mo), [`./types.mo`](./types.mo)
- **Purpose:** Demonstrate HTTPS outcalls and JSON parsing to transform Web2 metadata/unlock logs into the on-chain format used by `MusicRegistry.mo`.
- **Highlights:**
  - Placeholder endpoints (e.g., `<partner-api.example.com>`) showing: pulling arrays of JSON objects; defensive parsing of numbers/strings; timestamp normalization (seconds vs. milliseconds); incremental updates to unlock totals and per-partner counters.
  - Owner-gated entry points to prevent unauthorized imports.
  - HTTPS outcalls consume cycles; ensure sufficient cycles and reachable endpoints before enabling real imports.
