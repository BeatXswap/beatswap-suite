import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Bool "mo:base/Bool";
import Nat64 "mo:base/Nat64";

// Shared type definitions for music metadata, unlock logs, and dictionaries.
module {
  public type MusicWorkInfo = {
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
    verification_status : Text;
    icp_neighboring_token_address : Text;
    op_neighboring_token_address : Text;
  };

  public type GenreId = {
    genre_idx : Nat;
    genre_name : Text;
  };

  public type Requester = {
    requester_principal : Text;
    requester_name : Text;
    can_approve : Bool;
  };

  public type MusicVerificationList = {
    idx : Nat;                      // music work idx
    requester_principal : Text;
    verification_status : Bool;     // current verification state
    verification_status_updated_at : Text; // last updated timestamp (string)
  };

  public type Partner = {
    partner_idx : Nat;
    partner_name : Text;
  };

  public type VerificationUnlockCount = {
    partner_idx : Nat;
    idx : Nat;          // music work idx
    unlock_count : Nat;
  };

  public type VerificationUnlockList = {
    partner_idx : Nat;
    idx : Nat;          // music work idx
    unlock_date : Text;
    unlocked_at : Text;
    unlocked_ts : Nat64; // Unix timestamp (seconds or milliseconds; caller may normalize)
  };

  public type VerificationRightsPosAddressList = {
    right_pos_address_idx : Nat;
    is_neighboring_pos_address : Bool;
    rights_pos_address : Text;
    rights_pos_address_mainnet : Text;
    rights_pos_address_mainnet_version : Nat;
    requester_principal : Text;
    is_used_for_verification : Bool;
    is_used_for_verification_updated_at : Text;
  };

  public type DailyRightsHolders = {
    neighboring_token_address : Text;
    neighboring_holder_staked_address : Text;
    staked_amount : Text;        // string-encoded amount
    verification_date : Text;    // YYYY-MM-DD
    neighboring_holder_staked_mainnet : Text;
  };

  public type UnlockedAccumulated = {
    unlocked_acc : Nat64;
  };
}
