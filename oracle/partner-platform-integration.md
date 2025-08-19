# Partner Platform Integration

BeatSwap supports external integration via canister queries and APIs for metadata and rights data.

## External Streaming Services

- Purpose: Allow streaming platforms to fetch verified music metadata (title, artist, ownership) from the Core Canister for in-app display.
- Mapping: Maps platform-specific partner IDs to IC Principal IDs representing rights holders.

## Royalty Settlement Support

BeatSwap enables external services—like marketplaces or licensing agents—to query daily rights ownership and associated token/staking data for accurate royalty attribution.

- Daily rights holder addresses
- Tokenized rights by chain
- Associated staking contracts

Accessible via canister query methods or off-chain API interfaces.
