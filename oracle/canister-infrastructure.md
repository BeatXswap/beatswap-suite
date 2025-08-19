# Canister Infrastructure

The Internet Computer Canister modules form the foundation of BeatSwap's backend. Each module is deployed as an independent smart contract with a clearly separated responsibility.

## Core Canister – Copyright Metadata Oracle

The Core Canister functions as a metadata oracle for copyright-related music data. It stores structured, verifiable metadata on-chain and acts as a trusted source of truth for downstream applications such as streaming interfaces, DApps, and royalty distributors.

## Core Canister – Data Schema Summary

| Category                              | Key                               | Type | Description |
|---------------------------------------|-----------------------------------|------|-------------|
| music_work_info                       | idx                               | Nat  | Unique song ID (Primary Key). This is the internal identifier for the track, assigned sequentially in the order of its registration. |
| music_work_info                       | title                             | Text | The title of the song. |
| music_work_info                       | song_thumbnail                    | Text | URL of the song’s image/thumbnail. If this is null (= ""), a default album image URL will be used to represent the song. |
| music_work_info                       | album_idx                         | Nat  | Album unique ID. This is a reference key linking the song to an album in the album database. |
| music_work_info                       | composer                          | Text | Composer(s) of the song. Multiple composer names can be listed (for example, separated by commas). |
| music_work_info                       | lyricist                          | Text | Lyricist(s) of the song. This field is required for vocal tracks (work_type = "Vocal") and should be null (= "") for instrumental tracks (since instrumental pieces have no lyrics). Multiple lyricist names can be listed if applicable. |
| music_work_info                       | arranger                          | Text | Arranger(s) of the song. Multiple names can be included, and if there is no specific arranger information, this field can be null (= ""). |
| music_work_info                       | genre_idx                         | Nat  | Genre idx of the song. References genre.genre_idx. |
| music_work_info                       | work_type                         | Text | The type of the musical work, which can only be "Vocal" or "Instrumental". |
| music_work_info                       | music_publisher                   | Text | The music publisher or distributor/copyright holder of the song. This can be null (= "") if the information is not available or not applicable. |
| music_work_info                       | artist                            | Text | The main artist or band name. This is the primary performing artist for the track. |
| music_work_info                       | musician                          | Text | Participating musicians and performers other than the main artist. For example, session musicians, featured artists, etc., can be listed here. Multiple names are allowed, and it can be null (= "") if there are no additional contributors. |
| music_work_info                       | record_label                      | Text | The record label of the release. This is the label or record company under which the song was released, and can be null (= "") if not provided. |
| music_work_info                       | release_date                      | Text | The release date of the song (the date the music was published), in the format "YYYY-MM-DD". |
| music_work_info                       | registration_date                 | Text | The date the song’s metadata was registered in the system, in the format "YYYY-MM-DD hh:mm:ss". |
| music_work_info                       | requester_principal               | Text | The Principal ID of the user who requested the song’s registration. This is the user’s unique identifier on the ICP blockchain (their Internet Identity principal). The principal recorded here should correspond to a pre-approved user account (it references an entry in the requester table). |
| music_work_info                       | unlock_total_count                | Nat  | The total number of times this song has been unlocked across all platforms. This starts at 0 for a new song and increments whenever a user unlocks the song. |
| music_work_info                       | verification_status               | Bool | Whether the song’s metadata is publicly visible (approved) on-chain. A value of false means the song is still unverified/unapproved (metadata not yet public), while true means an approver has verified and published the metadata on-chain. |
| music_work_info                       | icp_neighboring_token_address     | Text | The neighboring rights FT (fungible token) contract address on the ICP mainnet for this song. This address represents the on-chain token for the song’s neighboring (transmission) rights. This can be null (= "") if not applicable or not yet available, but at least one of the two neighboring token address fields must be provided for on-chain rights verification to be possible. |
| music_work_info                       | op_neighboring_token_address      | Text | The neighboring rights FT contract address on the Optimism mainnet for this song. This serves the same purpose as the above, but on Optimism (an Ethereum Layer 2 network). One of these two addresses (icp_neighboring_token_address or this field) is required to enable on-chain rights verification for the track. |
| genre                                 | genre_idx                         | Nat  | Genre ID. A unique identifier for a genre within the system. |
| genre                                 | genre_name                        | Text | Genre name. A human-readable name of the genre, e.g., "Ballad", "EDM", "Hip-hop". |
| requester                             | requester_principal               | Text | The Principal ID of the user who submitted the song registration request. This uniquely identifies the user on ICP. |
| requester                             | requester_name                    | Text | The name of the user who requested the song registration. |
| requester                             | can_approve                       | Bool | The role of the user, indicating whether they are an approver (song approver). If true, this user has the authority to approve/verify songs (i.e., an approver); if false, the user is a regular user without approval rights. |
| music_verification_list               | idx                               | Nat  | Song unique ID (the idx from the corresponding music_work_info record). This identifies which song the verification record pertains to. |
| music_verification_list               | requester_principal               | Text | The Principal ID of the user who changed the song’s status. This must be a user whose can_approve role in the requester table is true (i.e., an approver). It records which approver performed the verification or status change. |
| music_verification_list               | verification_status               | Bool | The song’s public status at the time of this record. true indicates the song was made public (approved) in this change, while false indicates it was made private or unapproved. |
| music_verification_list               | verification_status_updated_at    | Text | The date on which the status change occurred, in YYYY-MM-DD hh:mm:ss format. This marks when the song was approved or when its status was changed. |
| partner                               | partner_idx                       | Nat  | External streaming platform ID. A unique identifier assigned within the system to each integrated platform or partner service. |
| partner                               | partner_name                      | Text | Name of the external streaming platform. For example, "Web2Platform", "TelegramMiniApp", "LineMiniApp", etc. |
| verification_unlock_count             | partner_idx                       | Nat  | Streaming platform ID. Indicates which platform the unlock count is associated with (refers to an entry in the partner list). |
| verification_unlock_count             | idx                               | Nat  | Song unique ID (the idx from music_work_info). Indicates which song this unlock count record is for. |
| verification_unlock_count             | unlock_count                      | Nat  | The cumulative number of times the song has been unlocked on the given platform. For instance, if the song has been unlocked 10 times on a particular platform, this value would be 10 for that platform’s record. |
| verification_unlock_list              | partner_idx                       | Nat  | Streaming platform ID where an unlock event occurred. |
| verification_unlock_list              | idx                               | Nat  | Song unique ID (music_work_info.idx) for which the unlock event happened. |
| verification_unlock_list              | unlock_date                       | Text | Date of the unlock event. (format "YYYY-MM-DD"). |
| verification_unlock_list              | unlocked_at                       | Text | Timestamp of the unlock event. (format "YYYY-MM-DD hh:mm:ss"). |
| verification_rights_pos_address_list  | right_pos_address_idx             | Nat  | Unique identifier for the rights verification address record. A single track can have multiple rights verification addresses, and this index distinguishes each entry. |
| verification_rights_pos_address_list  | is_neighboring_pos_address        | Bool | Whether this address pertains to neighboring rights. true if the address is for a neighboring rights contract, and false if it represents a main copyright rights contract. |
| verification_rights_pos_address_list  | rights_pos_address                | Text | The blockchain address used in the rights verification PoS process. This could be a smart contract or token address (e.g., an ICP principal or an Ethereum-based address) that represents the rights for the track. |
| verification_rights_pos_address_list  | rights_pos_address_mainnet        | Text | The name of the mainnet network where this rights address is deployed. For example, "ICP" if the address is on the Internet Computer, or "Optimism" if it is on the Optimism network. |
| verification_rights_pos_address_list  | rights_pos_address_mainnet_version| Nat  | The version number of the rights verification contract on the given mainnet. This number increments if the rights contract is updated or redeployed; this field records the current version in use. |
| verification_rights_pos_address_list  | requester_principal               | Text | The Principal ID of the user who recorded or manages this address entry. Typically, this would be the principal of an approver account that registered the rights verification address in the system. |
| verification_rights_pos_address_list  | is_used_for_verification          | Bool | Indicates whether this address is currently being used for rights verification. true means the system is actively using this address to verify rights ownership (for example, to check staked tokens), while false means it is not currently in use for verification. |
| verification_rights_pos_address_list  | is_used_for_verification_updated_at | Text | The timestamp when the is_used_for_verification status was last updated. The format is a datetime string such as "YYYY-MM-DD hh:mm:ss". |
| daily_rights_holders                  | neighboring_token_address         | Text | The song’s neighboring rights token contract address. This field identifies which track’s rights are referenced by tying the record to the token contract address (either the ICP or Optimism address stored in the song’s music_work_info). |
| daily_rights_holders                  | neighboring_holder_staked_address | Text | The address of a rights holder (staker) on the mainnet who has staked tokens for this song’s rights. For example, this could be a blockchain address that holds or stakes a certain amount of the song’s neighboring rights token. |
| daily_rights_holders                  | staked_amount                     | Text | The amount of tokens staked by the holder at the time of the snapshot. This is recorded as a string (it may be a very large number or include decimals, so storing it as text ensures precision), e.g., "1000" to indicate 1000 tokens staked. |
| daily_rights_holders                  | verification_date                 | Text | The date of the verification snapshot, in YYYY-MM-DD format. This represents the date on which the staked amount was recorded for the rights holder. |
| daily_rights_holders                  | neighboring_holder_staked_mainnet | Text | The name of the mainnet network where the staking took place. For example, "ICP" if the staking is on the Internet Computer, or "Optimism" if on the Optimism network. |

## Data Model Diagram

![Data Model Diagram](https://www.plantuml.com/plantuml/svg/lLPVRzis47_dfpZefTq0Q-zU5tHTDg0OiWxTK61F0YsThKCeKYDFJO8bttqIJT6M8ZeE3DHFqls_t_tkvFUEfUMkKQAc2g4aMoeKxfPqAwriG956VcWHZENQ22PM21zGybztieLhoH9kJ8LA2DIzyW6ofdDK5dV6tXQajoO3wM0cW_y4mFT0rVqQ_f3SlwnM0i07NyFVU3-8dD6xWkkksMX9QY-6jwPbCbggxmI0L9kkAOwYbAPfZKCROwW7IoKvNlIsLkeTsYNT3hN561dWtRlVVWSsUtaUjLTN0i1tDK0K0i7Rx8iffShW4RAFsh7j6jJS2_h80OcssoXozN9oQJcMF7gGr4kc5ajZgqB93QfblKBfiAWa7yhR6jj8XkoV_hUwkLbTNsTxsnqvjdBmVia1wdhTD6ldWkU_7Jf6MxIMT4cj78k9m4MJVC7OmzXfPSeUICDI5QNfD8zJ_OgMjbJk2tCikNDh-62CwdLKjeL6sjKROsdWYxb5NSYgikZS4YBcLVPF1rhxeNio-wT0uIbH0f63LCicO7WS9_RlOyMt42y5PGmT3Ox30vHI5x9jhVcA0Pkd-KPEO5Jas1UGqFbodl5_liVvk0ENC-3qd9TqHTSEBAqAoMSnTJBDLbhMOGRXEKmWlCrdEieJKvtK5wZiIUmp9BK-PymuXtlKvD4Ym7tkO4BfnncztqkLHtOabD-sxZEELp1z1HcI45ZQrUoArhZnB2JWI1W66ddjH3ad5Bd99JeoZQn_dY8k_4BsHfBMo6UO3FlkoEYndilNTzzFvx0gUjWdzoHqapQuQ94hIUfXd4LjL8NM-LajAVniNZZ_KulWEPmSpwwPvIXk_6gDqabpvx0tcN0sqxxlDp_DV_0PbK_bQceTFDEBsOx1arcj7X_3PsmDMVo6mUeAuakMyelp7tmNo314MH1dGgI-DI7mF5yVFXGLoabuNrfMyZg7qE6S-S3XSKJhw3LBnpcpGP6wjfVNyHgSnJbNxdBKtonkQ9xSJcWabpKwC1h1R87l36m9LUM0zBmdiRZzJtc-r7mwPRzS9_zWmgVFO4xe-pQrOGHVnr3qlCoV6HHAnsDJsSbq6HWBsSc4GmQ63SBmLv0gh7BnyPS_eNFee9IQXZ7yS9XES4Ft8tngcHfopTxsroyt1sKkK5SmT2B4-_wnQvJu7m00)

## Motoko Record Type Definitions

```motoko
module {

  // Track Info (music_work_info)
  type music_work_info = {
    idx : Nat;
    title : Text;
    song_thumbnail : Text;
    album_idx : Nat;
    composer : Text;
    lyricist : Text;
    arranger : Text;
    genre_idx : Nat;
    work_type : Text;
    music_publisher : Text;
    artist : Text;
    musician : Text;
    record_label : Text;
    release_date : Text;
    registration_date : Text;
    requester_principal : Text;
    unlock_total_count : Nat;
    verification_status : Bool;
    icp_neighboring_token_address : Text;
    op_neighboring_token_address : Text;
  };

  // Genre Info (genre)
  type genre = {
    genre_idx : Nat;
    genre_name : Text;
  };

  // Requester Info (requester)
  type requester = {
    requester_principal : Text;
    requester_name : Text;
    can_approve : Bool;
  };

  // Track Verification History (music_verification_list)
  type music_verification_list = {
    idx : Nat;
    requester_principal : Text;
    verification_status : Bool;
    verification_status_updated_at : Text;
  };

  // Streaming Platform Info (partner)
  type partner = {
    partner_idx : Nat;
    partner_name : Text;
  };

  // Unlock Counts (verification_unlock_count)
  type verification_unlock_count = {
    partner_idx : Nat;
    idx : Nat;
    unlock_count : Nat;
  };

  // Unlock Event Log (verification_unlock_list)
  type verification_unlock_list = {
    partner_idx : Nat;
    idx : Nat;
    unlock_date : Text;
    unlocked_at : Text;
  };

  // Verification Rights PoS Address List (verification_rights_pos_address_list)
  type verification_rights_pos_address_list = {
    right_pos_address_idx : Nat;
    is_neighboring_pos_address : Bool;
    rights_pos_address : Text;
    rights_pos_address_mainnet : Text;
    rights_pos_address_mainnet_version : Nat;
    requester_principal : Text;
    is_used_for_verification : Bool;
    is_used_for_verification_updated_at : Text;
  };

  // Daily Rights Holders (daily_rights_holders)
  type daily_rights_holders = {
    neighboring_token_address : Text;
    neighboring_holder_staked_address : Text;
    staked_amount : Text;
    verification_date : Text;
    neighboring_holder_staked_mainnet : Text;
  };
}
```
