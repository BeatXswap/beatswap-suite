# Web2-to-Web3 Metadata Mapping Guide

Metadata is organized into two categories:

- Requester (Track Submission Data from Web2)
- Protocol (On-Chain Augmented Data)

## Category Split

- Requester:
  - music_work_info
- Protocol:
  - genre
  - requester
  - music_verification_list
  - partner
  - verification_unlock_count
  - verification_unlock_list
  - verification_rights_pos_address_list
  - daily_rights_holders

## Requester

### music_work_info

- idx (Nat): Unique song ID. Primary Key.
- title (Text): Song title.
- song_thumbnail (Text, optional, null = ""): Song image URL. Use a default image when null.
- album_idx (Nat): Album unique ID. Reference key to the album DB.
- composer (Text): Composer. Multiple values allowed.
- lyricist (Text, optional, null = ""): Lyricist. Required when work_type is "Vocal", null when "Instrumental". Multiple values allowed.
- arranger (Text, optional, null = ""): Arranger. Multiple values allowed.
- genre_idx (Nat): Genre ID. References genre.genre_idx.
- work_type (Text): "Vocal" or "Instrumental".
- music_publisher (Text, optional, null = ""): Music publisher or distributor.
- artist (Text): Main artist or group.
- musician (Text, optional, null = ""): Participating musicians or performers, excluding the main artist. Multiple values allowed.
- record_label (Text, optional, null = ""): Record label.
- release_date (Text): Release date. Format "YYYY-MM-DD".
- registration_date (Text): Metadata registration datetime. Format "YYYY-MM-DD hh:mm:ss".
- requester_principal (Text): Principal of the submitter.
- unlock_total_count (Nat): Cumulative unlock count. Initial value 0.
- verification_status (Bool): Public visibility of the track metadata.
- icp_neighboring_token_address (Text, optional, null = ""): ICP mainnet neighboring rights FT contract address.
- op_neighboring_token_address (Text, optional, null = ""): Optimism mainnet neighboring rights FT contract address. Note: ICP uses canister or principal addresses, and Optimism uses EVM addresses. At least one of the two fields must be provided.

## Protocol

### genre

- genre_idx (Nat): Genre ID.
- genre_name (Text): Genre name, e.g., "Ballad", "EDM", "Hip-hop".

### requester

- requester_principal (Text): Registrant principal.
- requester_name (Text): Registrant name.
- can_approve (Bool): Whether the user has track-approval rights. true means approval is allowed.

### music_verification_list

- idx (Nat): Unique song ID. References music_work_info.idx.
- requester_principal (Text): Principal of the user who changed the status. Only users with requester.can_approve = true are allowed.
- verification_status (Bool): Public status of the song.
- verification_status_updated_at (Text): Status change datetime. Format "YYYY-MM-DD hh:mm:ss".

### partner

- partner_idx (Nat): External streaming platform ID.
- partner_name (Text): External streaming platform name, e.g., "Web2Platform", "TelegramMiniApp", "LineMiniApp".

### verification_unlock_count

- partner_idx (Nat): Streaming platform ID.
- idx (Nat): Unique song ID. References music_work_info.idx.
- unlock_count (Nat): Cumulative unlocks on that platform.

### verification_unlock_list

- partner_idx (Nat): Streaming platform ID.
- idx (Nat): Unique song ID. References music_work_info.idx.
- unlock_date (Text): Date value. Format "YYYY-MM-DD".
- unlocked_at (Text): Unlock timestamp. Format "YYYY-MM-DD hh:mm:ss".

### verification_rights_pos_address_list

- right_pos_address_idx (Nat): Unique PoS address ID.
- is_neighboring_pos_address (Bool): true indicates neighboring rights; false indicates a copyright PoS contract address.
- rights_pos_address (Text): Music RWA token staking address for rights verification.
- rights_pos_address_mainnet (Text): Mainnet name of the staking address.
- rights_pos_address_mainnet_version (Nat): Version number for redeployments on the same mainnet.
- requester_principal (Text): Principal of the user who registered or changed the status.
- is_used_for_verification (Bool): Whether this address is used for verification. If false, it is not used for rights proof.
- is_used_for_verification_updated_at (Text): Initial registration or status change date. Format "YYYY-MM-DD hh:mm:ss".

### daily_rights_holders

- neighboring_token_address (Text): Neighboring rights token contract address. Use music_work_info.icp_neighboring_token_address or op_neighboring_token_address.
- neighboring_holder_staked_address (Text): Mainnet staker address.
- staked_amount (Text): Staked amount.
- verification_date (Text): Verification date. Format "YYYY-MM-DD".
- neighboring_holder_staked_mainnet (Text): Mainnet name, e.g., "ICP", "Optimism".

## Sample JSON Example

```json
{
  "music_work_info": {
    "idx": 1,
    "title": "Example Song",
    "song_thumbnail": "https://example.com/cover.jpg",
    "album_idx": 1,
    "composer": "Composer A, Composer B",
    "lyricist": "Lyricist A",
    "arranger": "Arranger A",
    "genre_idx": 1,
    "work_type": "Vocal",
    "music_publisher": "Publisher Name",
    "artist": "Artist Name",
    "musician": "Session Player 1, Session Player 2",
    "record_label": "Label Name",
    "release_date": "2025-08-01",
    "registration_date": "2025-08-01 09:05:03",
    "requester_principal": "xlmdg-pyaaa-aaaaa-aaafQ-cai",
    "unlock_total_count": 1,
    "verification_status": true,
    "icp_neighboring_token_address": "ryjl3-tyaaa-aaaaa-aaaba-cai",
    "op_neighboring_token_address": "0x1234567890abcdef1234567890abcdef12345678"
  },
  "genre": {
    "genre_idx": 1,
    "genre_name": "Pop"
  },
  "requester": {
    "requester_principal": "xlmdg-pyaaa-aaaaa-aaafQ-cai",
    "requester_name": "Requester Name",
    "can_approve": true
  },
  "music_verification_list": {
    "idx": 1,
    "requester_principal": "xlmdg-pyaaa-aaaaa-aaafQ-cai",
    "verification_status": true,
    "verification_status_updated_at": "2025-08-01 10:11:12"
  },
  "partner": {
    "partner_idx": 1,
    "partner_name": "Web2Platform"
  },
  "verification_unlock_count": {
    "partner_idx": 1,
    "idx": 1,
    "unlock_count": 1
  },
  "verification_unlock_list": {
    "partner_idx": 1,
    "idx": 1,
    "unlock_date": "2025-08-01",
    "unlocked_at": "2025-08-01 12:34:56"
  },
  "verification_rights_pos_address_list": {
    "right_pos_address_idx": 1,
    "is_neighboring_pos_address": true,
    "rights_pos_address": "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd",
    "rights_pos_address_mainnet": "Optimism",
    "rights_pos_address_mainnet_version": 1,
    "requester_principal": "xlmdg-pyaaa-aaaaa-aaafQ-cai",
    "is_used_for_verification": true,
    "is_used_for_verification_updated_at": "2025-08-01 12:34:56"
  },
  "daily_rights_holders": {
    "neighboring_token_address": "0x1234567890abcdef1234567890abcdef12345678",
    "neighboring_holder_staked_address": "0xaaaaaaaabbbbbbbbccccccccddddddddeeeeeeee",
    "staked_amount": "1000",
    "verification_date": "2025-08-01",
    "neighboring_holder_staked_mainnet": "Optimism"
  }
}
```
