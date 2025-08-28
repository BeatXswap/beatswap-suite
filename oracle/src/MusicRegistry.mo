// MusicRegistry.mo

import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import List "mo:base/List";
import JSON "mo:json";
import Debug "mo:base/Debug";
import Bool "mo:base/Bool";
import Cycles "mo:base/ExperimentalCycles";
import Int "mo:base/Int";
import T "types";
import Blob "mo:base/Blob";
import Nat64 "mo:base/Nat64";

// This actor stores music metadata, unlock logs, partner/genre dictionaries,
// and supports HTTP outcalls for Web2 migration.

persistent actor MusicRegistry {
  // ---------- HTTP types for management canister ----------
  type HeaderField = { name : Text; value : Text };
  type HttpResponse = { status : Nat; headers : [HeaderField]; body : Blob };
  type HttpMethod = { #get; #post; #head };
  type HttpTransform = {
    function : shared query ({ context : Blob; response : HttpResponse }) -> async HttpResponse;
    context : Blob;
  };
  type HttpRequestArgs = {
    url : Text;
    max_response_bytes : ?Nat64;
    headers : [HeaderField];
    body : ?Blob;
    method : HttpMethod;
    transform : ?HttpTransform;
  };

  // Management canister HTTP service handle
  let management : actor { http_request : (HttpRequestArgs) -> async HttpResponse } =
    actor ("aaaaa-aa");

  // ---------- Global accumulated unlock counter ----------
  var unlockedAccumulatedData : T.UnlockedAccumulated = { unlocked_acc = 0 };

  public query func getUnlockedAccumulated() : async Nat64 {
    return unlockedAccumulatedData.unlocked_acc;
  };

  // ---------- Owner management ----------
  var canister_owner : ?Text = null;

  public func setCanisterOwner(newOwner : Text) : async Text {
    if (canister_owner == null) {
      canister_owner := ?newOwner;
      return "Canister owner set!";
    } else {
      return "Canister owner is already set!";
    }
  };

  // public func getCanisterOwner() : async ?Text { return canister_owner; };

  public func updateCanisterOwner(base : ?Text, newbase : ?Text) : async Text {
    if (canister_owner == base) {
      canister_owner := newbase;
      return "Canister owner updated!";
    } else {
      return "Canister owner does not match!";
    }
  };

  // Returns the caller principal (utility)
  public query (message) func whoami() : async Principal {
    let caller : Principal = message.caller;
    return caller;
  };

  // ---------- Music work registry ----------
  var MusicWorkInfoData : List.List<T.MusicWorkInfo> = List.nil();

  public func addMusicWorkInfo(owner : ?Text, info : T.MusicWorkInfo) : async () {
    if (canister_owner == owner) {
      var replaced = false;
      MusicWorkInfoData := List.map(MusicWorkInfoData, func (mw : T.MusicWorkInfo) : T.MusicWorkInfo {
        if (mw.idx == info.idx) { replaced := true; info } else { mw }
      });
      if (not replaced) { MusicWorkInfoData := List.push(info, MusicWorkInfoData) };
    };
  };

  public func updateMusicWorkInfo(owner : ?Text, info : T.MusicWorkInfo) : async Text {
    if (canister_owner == owner) {
      MusicWorkInfoData := List.map(MusicWorkInfoData, func (mw : T.MusicWorkInfo) : T.MusicWorkInfo {
        if (mw.idx == info.idx) { info } else { mw }
      });
      return "Music work info updated";
    } else { return "Unauthorized access attempt" }
  };

  public query func getMusicWorkInfos() : async [T.MusicWorkInfo] {
    let filtered = List.filter<T.MusicWorkInfo>(MusicWorkInfoData, func (mw : T.MusicWorkInfo) : Bool {
      mw.verification_status == "show"
    });
    return List.toArray(filtered);
  };

  public query func getMusicWorkInfosByGenre(genre : Nat) : async [T.MusicWorkInfo] {
    let filtered = List.filter<T.MusicWorkInfo>(MusicWorkInfoData, func (mw : T.MusicWorkInfo) : Bool {
      mw.genre_idx == genre
    });
    return List.toArray(filtered);
  };

  // Returns JSON array like: [{ "idx": N, "contract": "0x..." }, ...]
  public query func getMusicContractAddress() : async Text {
    let infos = List.toArray(MusicWorkInfoData);
    var json : Text = "[";
    var first = true;
    var i = 0;
    let len = infos.size();
    while (i < len) {
      let info = infos[i];
      let item = "{ \"idx\": " # Nat.toText(info.idx) # ", \"contract\": \"" # info.op_neighboring_token_address # "\" }";
      if (first) { json := json # item; first := false } else { json := json # "," # item };
      i += 1;
    };
    json := json # "]";
    return json;
  };

  // ---------- Genre dictionary ----------
  var genreData : List.List<T.GenreId> = List.nil();

  public func addGenre(owner : Text, genre_idx : Nat, genre_name : Text) : async Text {
    if (canister_owner == ?owner) {
      genreData := List.push({ genre_idx = genre_idx; genre_name = genre_name }, genreData);
      return "Genre added successfully";
    } else { return "Unauthorized access attempt" }
  };

  public query func getGenres() : async [T.GenreId] {
    return List.toArray(genreData);
  };

  public func updateGenreName(owner : Text, genre_idx_target : Nat, new_name : Text) : async Text {
    if (canister_owner == ?owner) {
      genreData := List.map(genreData, func (g : T.GenreId) : T.GenreId {
        if (g.genre_idx == genre_idx_target) { { genre_idx = g.genre_idx; genre_name = new_name } } else { g }
      });
      return "Genre name updated";
    } else { return "Unauthorized access attempt" }
  };

  // ---------- Requester list ----------
  var requesterIdData : List.List<T.Requester> = List.nil();

  // Public projection without exposing requester_principal
  public query func getRequesterIds() : async [{ requester_name : Text; can_approve : Bool }] {
    let projected = List.map(requesterIdData, func (r : T.Requester) : { requester_name : Text; can_approve : Bool } {
      { requester_name = r.requester_name; can_approve = r.can_approve }
    });
    return List.toArray(projected);
  };

  public func addRequesterId(requester_principal_p : Text, requester_name_p : Text, can_approve_p : Bool) : async Text {
    requesterIdData := List.push(
      { requester_principal = requester_principal_p; requester_name = requester_name_p; can_approve = can_approve_p },
      requesterIdData
    );
    return "Requester added successfully";
  };

  // ---------- Partner list ----------
  var Partner : List.List<T.Partner> = List.nil();

  public query func getPartners() : async [T.Partner] {
    return List.toArray(Partner);
  };

  public func addPartner(owner : Text, partner_idx_p : Nat, partner_name_p : Text) : async Text {
    if (canister_owner == ?owner) {
      Partner := List.push({ partner_idx = partner_idx_p; partner_name = partner_name_p }, Partner);
      return "Partner added successfully";
    } else { return "Unauthorized access attempt" }
  };

  // ---------- Per-site unlock counts ----------
  var VerificationUnlockCountDataP : List.List<T.VerificationUnlockCount> = List.nil();
  var VerificationUnlockCountDataT : List.List<T.VerificationUnlockCount> = List.nil();
  var VerificationUnlockCountDataK : List.List<T.VerificationUnlockCount> = List.nil();

  public query func getVerificationUnlockCounts(partner_idx : Nat) : async [T.VerificationUnlockCount] {
    if (partner_idx == 1) { return List.toArray(VerificationUnlockCountDataP) }
    else if (partner_idx == 2) { return List.toArray(VerificationUnlockCountDataT) }
    else if (partner_idx == 3) { return List.toArray(VerificationUnlockCountDataK) }
    else { return [] };
  };

  // ---------- Per-site unlock detailed lists ----------
  var VerificationUnlockListDataP : List.List<T.VerificationUnlockList> = List.nil();
  var VerificationUnlockListDataT : List.List<T.VerificationUnlockList> = List.nil();
  var VerificationUnlockListDataK : List.List<T.VerificationUnlockList> = List.nil();

  public func addVerificationUnlockList(owner : ?Text, partner_idx_p : Nat, idx_p : Nat, unlock_date : Text, unlocked_at : Text, unlocked_ts : Nat64) : async Text {
    if (canister_owner == owner) {
      // Increment global accumulator
      unlockedAccumulatedData := { unlocked_acc = unlockedAccumulatedData.unlocked_acc + 1 };

      // Increment per-work total
      MusicWorkInfoData := List.map(MusicWorkInfoData, func (m : T.MusicWorkInfo) : T.MusicWorkInfo {
        if (m.idx == idx_p) { { m with unlock_total_count = m.unlock_total_count + 1 } } else { m }
      });

      // Update per-partner counters and push list item
      if (partner_idx_p == 1) {
        VerificationUnlockCountDataP := List.map(VerificationUnlockCountDataP, func (m : T.VerificationUnlockCount) : T.VerificationUnlockCount {
          if (m.idx == idx_p) { { m with unlock_count = m.unlock_count + 1 } } else { m }
        });
        VerificationUnlockListDataP := List.push({ partner_idx = partner_idx_p; idx = idx_p; unlock_date = unlock_date; unlocked_at = unlocked_at; unlocked_ts = unlocked_ts }, VerificationUnlockListDataP);
      } else if (partner_idx_p == 2) {
        VerificationUnlockCountDataT := List.map(VerificationUnlockCountDataT, func (m : T.VerificationUnlockCount) : T.VerificationUnlockCount {
          if (m.idx == idx_p) { { m with unlock_count = m.unlock_count + 1 } } else { m }
        });
        VerificationUnlockListDataT := List.push({ partner_idx = partner_idx_p; idx = idx_p; unlock_date = unlock_date; unlocked_at = unlocked_at; unlocked_ts = unlocked_ts }, VerificationUnlockListDataT);
      } else if (partner_idx_p == 3) {
        VerificationUnlockCountDataK := List.map(VerificationUnlockCountDataK, func (m : T.VerificationUnlockCount) : T.VerificationUnlockCount {
          if (m.idx == idx_p) { { m with unlock_count = m.unlock_count + 1 } } else { m }
        });
        VerificationUnlockListDataK := List.push({ partner_idx = partner_idx_p; idx = idx_p; unlock_date = unlock_date; unlocked_at = unlocked_at; unlocked_ts = unlocked_ts }, VerificationUnlockListDataK);
      };

      return "addVerificationUnlockList Success!";
    } else { return "Canister owner does not match!" }
  };

  public query func getVerificationUnlockListsByDate(partner_idx : Nat, date : Text) : async [T.VerificationUnlockList] {
    if (partner_idx == 1) {
      let filtered = List.filter<T.VerificationUnlockList>(VerificationUnlockListDataP, func (v : T.VerificationUnlockList) : Bool { v.unlock_date == date });
      return List.toArray(filtered);
    } else if (partner_idx == 2) {
      let filtered = List.filter<T.VerificationUnlockList>(VerificationUnlockListDataT, func (v : T.VerificationUnlockList) : Bool { v.unlock_date == date });
      return List.toArray(filtered);
    } else if (partner_idx == 3) {
      let filtered = List.filter<T.VerificationUnlockList>(VerificationUnlockListDataK, func (v : T.VerificationUnlockList) : Bool { v.unlock_date == date });
      return List.toArray(filtered);
    } else { return [] };
  };

  // Filter by timestamp range (input may be ms or s; max 60 days)
  public query func getVerificationUnlockListsByDateTs(partner_idx : Nat, ts_start_in : Nat64, ts_end_in : Nat64) : async [T.VerificationUnlockList] {
    if (ts_start_in == 0 or ts_end_in == 0) { return [] };

    // Normalize seconds to ms if needed
    func norm(v : Nat64) : Nat64 { if (v < 100_000_000_000) { v * 1000 } else { v } };
    var s = norm(ts_start_in);
    var e = norm(ts_end_in);

    // Swap if reversed
    if (s > e) { let tmp = s; s := e; e := tmp };

    // 60 days in ms
    let MAX_RANGE_MS : Nat64 = 60 * 24 * 60 * 60 * 1000;
    if (e - s > MAX_RANGE_MS) { return [] };

    // Pick source list
    let source =
      if (partner_idx == 1) VerificationUnlockListDataP
      else if (partner_idx == 2) VerificationUnlockListDataT
      else if (partner_idx == 3) VerificationUnlockListDataK
      else List.nil<T.VerificationUnlockList>();

    // Range filter with unit normalization for stored value
    let filtered = List.filter(source, func (v : T.VerificationUnlockList) : Bool {
      let vt = if (v.unlocked_ts < 100_000_000_000) { v.unlocked_ts * 1000 } else { v.unlocked_ts };
      vt >= s and vt <= e
    });

    List.toArray(filtered)
  };

  // ---------- Music verification list ----------
  var MusicVerificationListData : List.List<T.MusicVerificationList> = List.nil();

  public query func getMusicVerificationLists() : async [T.MusicVerificationList] {
    return List.toArray(MusicVerificationListData);
  };

  public func addMusicVerificationList(owner : Text, idx_p : Nat, requester_principal_p : Text, verification_status_p : Bool, verification_status_updated_at_p : Text) : async () {
    if (canister_owner == ?owner) {
      MusicVerificationListData := List.push(
        { idx = idx_p; requester_principal = requester_principal_p; verification_status = verification_status_p; verification_status_updated_at = verification_status_updated_at_p },
        MusicVerificationListData
      );
    }
  };

  // ---------- Daily rights holders snapshot ----------
  var DailyRightsHoldersData : List.List<T.DailyRightsHolders> = List.nil();

  public query func getDailyRightsHolders(neighboring_token_address : Text, verification_date : Text) : async [T.DailyRightsHolders] {
    let filtered = List.filter<T.DailyRightsHolders>(DailyRightsHoldersData, func (v : T.DailyRightsHolders) : Bool {
      v.neighboring_token_address == neighboring_token_address and v.verification_date == verification_date
    });
    return List.toArray(filtered);
  };

  public func addDailyRightsHolder(owner : Text, neighboring_token_address : Text, neighboring_holder_staked_address : Text, staked_amount : Text, verification_date : Text, neighboring_holder_staked_mainnet : Text) : async () {
    if (canister_owner == ?owner) {
      DailyRightsHoldersData := List.push(
        { neighboring_token_address = neighboring_token_address;
          neighboring_holder_staked_address = neighboring_holder_staked_address;
          staked_amount = staked_amount; verification_date = verification_date;
          neighboring_holder_staked_mainnet = neighboring_holder_staked_mainnet },
        DailyRightsHoldersData
      );
    }
  };

  // ---------- Seed initial data (partners, genres) ----------
  public func firstDataSet(owner : Text) : async Text {
    if (canister_owner == ?owner) {
      Partner := List.push({ partner_idx = 1; partner_name = "Web2Playform" }, Partner);  // example
      Partner := List.push({ partner_idx = 2; partner_name = "TelegramMiniApp" }, Partner);  // example
      Partner := List.push({ partner_idx = 3; partner_name = "LineMiniApp" }, Partner);  // example

      genreData := List.push({ genre_idx = 1; genre_name = "K-POP" }, genreData);
      genreData := List.push({ genre_idx = 2; genre_name = "R&B" }, genreData);
      genreData := List.push({ genre_idx = 3; genre_name = "TROT" }, genreData);
      genreData := List.push({ genre_idx = 4; genre_name = "CITY-POP" }, genreData);
      genreData := List.push({ genre_idx = 5; genre_name = "BALLAD" }, genreData);
      genreData := List.push({ genre_idx = 6; genre_name = "JAZZ" }, genreData);
      genreData := List.push({ genre_idx = 7; genre_name = "HIP HOP" }, genreData);
      genreData := List.push({ genre_idx = 8; genre_name = "INDY" }, genreData);
      genreData := List.push({ genre_idx = 9; genre_name = "ROCK" }, genreData);
      genreData := List.push({ genre_idx = 10; genre_name = "CCM" }, genreData);

      genreData := List.push({ genre_idx = 11; genre_name = "Alternatvie pop" }, genreData);
      genreData := List.push({ genre_idx = 12; genre_name = "Chillwave/R&B" }, genreData);
      genreData := List.push({ genre_idx = 13; genre_name = "HOUSE" }, genreData);
      genreData := List.push({ genre_idx = 14; genre_name = "EDM" }, genreData);
      genreData := List.push({ genre_idx = 15; genre_name = "BAND" }, genreData);
      genreData := List.push({ genre_idx = 16; genre_name = "Tropical House" }, genreData);
      genreData := List.push({ genre_idx = 17; genre_name = "Medium" }, genreData);
      genreData := List.push({ genre_idx = 18; genre_name = "POP" }, genreData);
      genreData := List.push({ genre_idx = 19; genre_name = "Chill" }, genreData);

      genreData := List.push({ genre_idx = 20; genre_name = "Alternative R&B" }, genreData);
      genreData := List.push({ genre_idx = 21; genre_name = "JAZZ POP" }, genreData);
      genreData := List.push({ genre_idx = 22; genre_name = "Modern Rock" }, genreData);
      genreData := List.push({ genre_idx = 23; genre_name = "Disco Pop" }, genreData);
      genreData := List.push({ genre_idx = 24; genre_name = "Neo Soul" }, genreData);
      genreData := List.push({ genre_idx = 25; genre_name = "CAROL" }, genreData);
      genreData := List.push({ genre_idx = 26; genre_name = "Slap House" }, genreData);
      genreData := List.push({ genre_idx = 27; genre_name = "Crossover" }, genreData);
      genreData := List.push({ genre_idx = 28; genre_name = "Dream POP" }, genreData);
      genreData := List.push({ genre_idx = 29; genre_name = "Alternative Rock" }, genreData);

      genreData := List.push({ genre_idx = 30; genre_name = "ACOUSTIC" }, genreData);
      genreData := List.push({ genre_idx = 31; genre_name = "Synth pop" }, genreData);
      genreData := List.push({ genre_idx = 32; genre_name = "Electronic K-POP" }, genreData);
      genreData := List.push({ genre_idx = 33; genre_name = "RETRO" }, genreData);
      genreData := List.push({ genre_idx = 34; genre_name = "SOUL" }, genreData);
      genreData := List.push({ genre_idx = 35; genre_name = "Rock Ballad" }, genreData);
      genreData := List.push({ genre_idx = 36; genre_name = "DANCEHALL" }, genreData);
      genreData := List.push({ genre_idx = 37; genre_name = "Latin POP" }, genreData);
      genreData := List.push({ genre_idx = 38; genre_name = "Trapsoul" }, genreData);
      genreData := List.push({ genre_idx = 39; genre_name = "REGGEATON" }, genreData);

      genreData := List.push({ genre_idx = 40; genre_name = "Trap SOUL" }, genreData);
      genreData := List.push({ genre_idx = 41; genre_name = "Acoustic Country" }, genreData);
      genreData := List.push({ genre_idx = 42; genre_name = "Emo Hip-Hop" }, genreData);
      genreData := List.push({ genre_idx = 43; genre_name = "K-pop Dance" }, genreData);
      genreData := List.push({ genre_idx = 44; genre_name = "Dance-punk" }, genreData);
      genreData := List.push({ genre_idx = 45; genre_name = "Baile Funk" }, genreData);
      genreData := List.push({ genre_idx = 46; genre_name = "UK Garage (UKG)" }, genreData);

      return "Icp info data initialized!";
    } else { return "Unauthorized access attempt" }
  };

  // ---------- Utility ----------
  private func getMusicWorkInfoMaxIdx() : Nat {
    if (List.size(MusicWorkInfoData) == 0) { return 0 }
    else {
      let maxIdx = List.foldLeft(MusicWorkInfoData, 0, func (acc : Nat, item : T.MusicWorkInfo) : Nat { Nat.max(acc, item.idx) });
      return maxIdx;
    }
  };

  // ---------- Ingestion from Web2 via JSON string ----------
  public func getMusicInfoByWeb2platformData(owner : Text, data : Text) : async Text {
    if (canister_owner != ?owner) { return "Unauthorized access attempt" };
    let decoded_text : Text = data;
    let parsed = JSON.parse(decoded_text);
    switch (parsed) {
      case (#ok(jsonValue)) {
        let getAsArrayValue = JSON.get(jsonValue, "");
        switch (getAsArrayValue) {
          case (?json) {
            switch (json) {
              case (#array(arr)) {
                for (item in arr.vals()) {
                  switch (item) {
                    case (#object_(_obj)) {
                      let idx : Nat = switch (JSON.get(item, "idx")) {
                        case (? #number(#int n)) { if (n < 0) 0 else Int.abs(n) };
                        case (? #string(t)) { switch (Nat.fromText(t)) { case (?v) v; case null 0 } };
                        case _ { 0 };
                      };
                      let title = switch (JSON.get(item, "title")) { case (? #string(t)) { t }; case _ { "" } };
                      let song_thumbnail = switch (JSON.get(item, "song_thumbnail")) { case (? #string(t)) { t }; case _ { "" } };
                      let album_idx : Nat = switch (JSON.get(item, "album_idx")) {
                        case (? #number(#int n)) { if (n < 0) 0 else Int.abs(n) };
                        case (? #string(t)) { switch (Nat.fromText(t)) { case (?v) v; case null 0 } };
                        case _ { 0 };
                      };
                      let composer = switch (JSON.get(item, "composer")) { case (? #string(t)) { t }; case _ { "" } };
                      let lyricist = switch (JSON.get(item, "lyricist")) { case (? #string(t)) { t }; case _ { "" } };
                      let arranger = switch (JSON.get(item, "arranger")) { case (? #string(t)) { t }; case _ { "" } };
                      let genre_idx : Nat = switch (JSON.get(item, "genre_idx")) {
                        case (? #number(#int n)) { if (n < 0) 0 else Int.abs(n) };
                        case (? #string(t)) { switch (Nat.fromText(t)) { case (?v) v; case null 0 } };
                        case _ { 0 };
                      };
                      let work_type = switch (JSON.get(item, "work_type")) { case (? #string(t)) { t }; case _ { "" } };
                      let music_publisher = switch (JSON.get(item, "music_publisher")) { case (? #string(t)) { t }; case _ { "" } };
                      let artist = switch (JSON.get(item, "artist")) { case (? #string(t)) { t }; case _ { "" } };
                      let musician = switch (JSON.get(item, "musician")) { case (? #string(t)) { t }; case _ { "" } };
                      let record_label = switch (JSON.get(item, "record_label")) { case (? #string(t)) { t }; case _ { "" } };
                      let release_date = switch (JSON.get(item, "release_date")) { case (? #string(t)) { t }; case _ { "" } };
                      let registration_date = switch (JSON.get(item, "registration_date")) { case (? #string(t)) { t }; case _ { "" } };
                      let requester_principal = switch (JSON.get(item, "requester_principal")) { case (? #string(t)) { t }; case _ { "" } };
                      let unlock_total_count : Nat = switch (JSON.get(item, "unlock_total_count")) {
                        case (? #number(#int n)) { if (n < 0) 0 else Int.abs(n) };
                        case (? #string(t)) { switch (Nat.fromText(t)) { case (?v) v; case null 0 } };
                        case _ { 0 };
                      };
                      let verification_status = switch (JSON.get(item, "verification_status")) { case (? #string(t)) { t }; case _ { "" } };
                      let icp_neighboring_token_address = switch (JSON.get(item, "icp_neighboring_token_address")) { case (? #string(t)) { t }; case _ { "" } };
                      let op_neighboring_token_address = switch (JSON.get(item, "op_neighboring_token_address")) { case (? #string(t)) { t }; case _ { "" } };

                      let musicWorkInfo : T.MusicWorkInfo = {
                        idx = idx; title = title; song_thumbnail = song_thumbnail; album_idx = album_idx;
                        composer = composer; lyricist = lyricist; arranger = arranger; genre_idx = genre_idx;
                        work_type = work_type; music_publisher = music_publisher; artist = artist; musician = musician;
                        record_label = record_label; release_date = release_date; registration_date = registration_date;
                        requester_principal = requester_principal; unlock_total_count = unlock_total_count;
                        verification_status = verification_status; icp_neighboring_token_address = icp_neighboring_token_address;
                        op_neighboring_token_address = op_neighboring_token_address
                      };

                      VerificationUnlockCountDataP := List.push({ partner_idx = 1; idx = idx; unlock_count = unlock_total_count }, VerificationUnlockCountDataP);
                      VerificationUnlockCountDataT := List.push({ partner_idx = 2; idx = idx; unlock_count = unlock_total_count }, VerificationUnlockCountDataT);
                      VerificationUnlockCountDataK := List.push({ partner_idx = 3; idx = idx; unlock_count = unlock_total_count }, VerificationUnlockCountDataK);

                      MusicWorkInfoData := List.push(musicWorkInfo, MusicWorkInfoData);
                    };
                    case _ {};
                  }
                }
              };
              case _ { Debug.print("jsonValue is not array") };
            }
          };
          case null { Debug.print("jsonValue is null") };
        }
      };
      case (#err(_e)) { /* ignore parse error */ };
    };
    return decoded_text;
  };

  // ---------- Web2 migration via HTTP outcall (music info) ----------
  public func getMusicInfoByWeb2platformOutcall(owner : Text) : async Text {
    if (canister_owner != ?owner) { return "Unauthorized access attempt" };

    let idx_out = getMusicWorkInfoMaxIdx();

    let host : Text = "web2platform.com";  // example host
    let url = "https://web2platform.com/getMusicInfoIcp?idx=" # Nat.toText(idx_out);  // example endpoint
    Debug.print("URL: " # url);

    let request_headers = [
      { name = "Host"; value = host },
      { name = "User-Agent"; value = "ic-http" },
      { name = "Accept"; value = "application/json" },
      { name = "Accept-Encoding"; value = "identity" }
    ];

    let http_request : HttpRequestArgs = {
      url = url; max_response_bytes = null; headers = request_headers; body = null; method = #get;
      transform = ?{ function = transform; context = Blob.fromArray([]) }
    };

    Cycles.add<system>(230_850_258_000);
    let http_response : HttpResponse = await management.http_request(http_request);

    let decoded_text : Text = switch (Text.decodeUtf8(http_response.body)) { case (null) { "No value returned" }; case (?y) { y } };

    let parsed = JSON.parse(decoded_text);
    switch (parsed) {
      case (#ok(jsonValue)) {
        let getAsArrayValue = JSON.get(jsonValue, "");
        switch (getAsArrayValue) {
          case (?json) {
            switch (json) {
              case (#array(arr)) {
                for (item in arr.vals()) {
                  switch (item) {
                    case (#object_(_obj)) {
                      let idx : Nat = switch (JSON.get(item, "idx")) {
                        case (? #number(#int n)) { if (n < 0) 0 else Int.abs(n) };
                        case (? #string(t)) { switch (Nat.fromText(t)) { case (?v) v; case null 0 } };
                        case _ { 0 };
                      };
                      let title = switch (JSON.get(item, "title")) { case (? #string(t)) { t }; case _ { "" } };
                      let song_thumbnail = switch (JSON.get(item, "song_thumbnail")) { case (? #string(t)) { t }; case _ { "" } };
                      let album_idx : Nat = switch (JSON.get(item, "album_idx")) {
                        case (? #number(#int n)) { if (n < 0) 0 else Int.abs(n) };
                        case (? #string(t)) { switch (Nat.fromText(t)) { case (?v) v; case null 0 } };
                        case _ { 0 };
                      };
                      let composer = switch (JSON.get(item, "composer")) { case (? #string(t)) { t }; case _ { "" } };
                      let lyricist = switch (JSON.get(item, "lyricist")) { case (? #string(t)) { t }; case _ { "" } };
                      let arranger = switch (JSON.get(item, "arranger")) { case (? #string(t)) { t }; case _ { "" } };
                      let genre_idx : Nat = switch (JSON.get(item, "genre_idx")) {
                        case (? #number(#int n)) { if (n < 0) 0 else Int.abs(n) };
                        case (? #string(t)) { switch (Nat.fromText(t)) { case (?v) v; case null 0 } };
                        case _ { 0 };
                      };
                      let work_type = switch (JSON.get(item, "work_type")) { case (? #string(t)) { t }; case _ { "" } };
                      let music_publisher = switch (JSON.get(item, "music_publisher")) { case (? #string(t)) { t }; case _ { "" } };
                      let artist = switch (JSON.get(item, "artist")) { case (? #string(t)) { t }; case _ { "" } };
                      let musician = switch (JSON.get(item, "musician")) { case (? #string(t)) { t }; case _ { "" } };
                      let record_label = switch (JSON.get(item, "record_label")) { case (? #string(t)) { t }; case _ { "" } };
                      let release_date = switch (JSON.get(item, "release_date")) { case (? #string(t)) { t }; case _ { "" } };
                      let registration_date = switch (JSON.get(item, "registration_date")) { case (? #string(t)) { t }; case _ { "" } };
                      let requester_principal = switch (JSON.get(item, "requester_principal")) { case (? #string(t)) { t }; case _ { "" } };
                      let unlock_total_count : Nat = switch (JSON.get(item, "unlock_total_count")) {
                        case (? #number(#int n)) { if (n < 0) 0 else Int.abs(n) };
                        case (? #string(t)) { switch (Nat.fromText(t)) { case (?v) v; case null 0 } };
                        case _ { 0 };
                      };
                      let verification_status = switch (JSON.get(item, "verification_status")) { case (? #string(t)) { t }; case _ { "" } };
                      let icp_neighboring_token_address = switch (JSON.get(item, "icp_neighboring_token_address")) { case (? #string(t)) { t }; case _ { "" } };
                      let op_neighboring_token_address = switch (JSON.get(item, "op_neighboring_token_address")) { case (? #string(t)) { t }; case _ { "" } };

                      let musicWorkInfo : T.MusicWorkInfo = {
                        idx = idx; title = title; song_thumbnail = song_thumbnail; album_idx = album_idx;
                        composer = composer; lyricist = lyricist; arranger = arranger; genre_idx = genre_idx;
                        work_type = work_type; music_publisher = music_publisher; artist = artist; musician = musician;
                        record_label = record_label; release_date = release_date; registration_date = registration_date;
                        requester_principal = requester_principal; unlock_total_count = unlock_total_count;
                        verification_status = verification_status; icp_neighboring_token_address = icp_neighboring_token_address;
                        op_neighboring_token_address = op_neighboring_token_address
                      };

                      VerificationUnlockCountDataP := List.push({ partner_idx = 1; idx = idx; unlock_count = unlock_total_count }, VerificationUnlockCountDataP);
                      VerificationUnlockCountDataT := List.push({ partner_idx = 2; idx = idx; unlock_count = unlock_total_count }, VerificationUnlockCountDataT);
                      VerificationUnlockCountDataK := List.push({ partner_idx = 3; idx = idx; unlock_count = unlock_total_count }, VerificationUnlockCountDataK);

                      MusicWorkInfoData := List.push(musicWorkInfo, MusicWorkInfoData);
                    };
                    case _ {};
                  }
                }
              };
              case _ { Debug.print("jsonValue is not array") };
            }
          };
          case null { Debug.print("jsonValue is null") };
        }
      };
      case (#err(_e)) { /* ignore parse error */ };
    };
    return decoded_text;
  };

  // ---------- Direct ingestion of unlock list from JSON string ----------
  public func getVerificationUnlockListData(partner_idx : Nat, data : Text, owner : Text) : async Text {
    if (canister_owner != ?owner) { return "Unauthorized access attempt" };
    Debug.print("Data: " # data);

    let decoded_text : Text = data;
    let parsed = JSON.parse(decoded_text);
    switch (parsed) {
      case (#ok(jsonValue)) {
        let getAsArrayValue = JSON.get(jsonValue, "");
        switch (getAsArrayValue) {
          case (?json) {
            switch (json) {
              case (#array(arr)) {
                for (item in arr.vals()) {
                  switch (item) {
                    case (#object_(_obj)) {
                      let partner_idx : Nat = switch (JSON.get(item, "partner_idx")) {
                        case (? #number(#int n)) { if (n < 0) 0 else Int.abs(n) };
                        case (? #string(t)) { switch (Nat.fromText(t)) { case (?v) v; case null 0 } };
                        case _ { 0 };
                      };
                      let idx : Nat = switch (JSON.get(item, "idx")) {
                        case (? #number(#int n)) { if (n < 0) 0 else Int.abs(n) };
                        case (? #string(t)) { switch (Nat.fromText(t)) { case (?v) v; case null 0 } };
                        case _ { 0 };
                      };
                      let unlock_date = switch (JSON.get(item, "unlock_date")) { case (? #string(t)) { t }; case _ { "" } };
                      let unlocked_at = switch (JSON.get(item, "unlocked_at")) { case (? #string(t)) { t }; case _ { "" } };
                      let unlocked_ts : Nat64 = switch (JSON.get(item, "unlocked_ts")) {
                        case (? #number(#int n)) { if (n < 0) 0 : Nat64 else Nat64.fromNat(Int.abs(n)) };
                        case (? #string(t)) { switch (Nat.fromText(t)) { case (?v) Nat64.fromNat(v); case null 0 : Nat64 } };
                        case _ { 0 : Nat64 };
                      };

                      unlockedAccumulatedData := { unlocked_acc = unlockedAccumulatedData.unlocked_acc + 1 };
                      MusicWorkInfoData := List.map(MusicWorkInfoData, func (m : T.MusicWorkInfo) : T.MusicWorkInfo {
                        if (m.idx == idx) { { m with unlock_total_count = m.unlock_total_count + 1 } } else { m }
                      });

                      if (partner_idx == 1) {
                        VerificationUnlockCountDataP := List.map(VerificationUnlockCountDataP, func (m : T.VerificationUnlockCount) : T.VerificationUnlockCount {
                          if (m.idx == idx) { { m with unlock_count = m.unlock_count + 1 } } else { m }
                        });
                        VerificationUnlockListDataP := List.push({ partner_idx = partner_idx; idx = idx; unlock_date = unlock_date; unlocked_at = unlocked_at; unlocked_ts = unlocked_ts }, VerificationUnlockListDataP);
                      } else if (partner_idx == 2) {
                        VerificationUnlockCountDataT := List.map(VerificationUnlockCountDataT, func (m : T.VerificationUnlockCount) : T.VerificationUnlockCount {
                          if (m.idx == idx) { { m with unlock_count = m.unlock_count + 1 } } else { m }
                        });
                        VerificationUnlockListDataT := List.push({ partner_idx = partner_idx; idx = idx; unlock_date = unlock_date; unlocked_at = unlocked_at; unlocked_ts = unlocked_ts }, VerificationUnlockListDataT);
                      } else if (partner_idx == 3) {
                        VerificationUnlockCountDataK := List.map(VerificationUnlockCountDataK, func (m : T.VerificationUnlockCount) : T.VerificationUnlockCount {
                          if (m.idx == idx) { { m with unlock_count = m.unlock_count + 1 } } else { m }
                        });
                        VerificationUnlockListDataK := List.push({ partner_idx = partner_idx; idx = idx; unlock_date = unlock_date; unlocked_at = unlocked_at; unlocked_ts = unlocked_ts }, VerificationUnlockListDataK);
                      }
                    };
                    case _ {};
                  }
                }
              };
              case _ { Debug.print("jsonValue is not array") };
            }
          };
          case null { Debug.print("jsonValue is null") };
        }
      };
      case (#err(_e)) { /* ignore parse error */ };
    };
    return decoded_text;
  };

  // ---------- Web2 migration via HTTP outcall (unlock list) ----------
  public func getVerificationUnlockListWeb2platformOutcall(partner_idx : Nat, owner : Text) : async Text {
    if (canister_owner != ?owner) { return "Unauthorized access attempt" };

    let host : Text = "web2platform.com";  // example host
    var url : Text = "";
    var in_idx : Nat = 0;

    if (partner_idx == 1) {
      in_idx := List.size(VerificationUnlockListDataP);
      url := "https://web2platform.com/getWeb2platformUnlock?idx=" # Nat.toText(in_idx);  // example endpoint
    } else if (partner_idx == 2) {
      in_idx := List.size(VerificationUnlockListDataT);
      url := "https://web2platform.com/getTelegramminiappUnlock?idx=" # Nat.toText(in_idx);  // example endpoint
    } else if (partner_idx == 3) {
      in_idx := List.size(VerificationUnlockListDataK);
      url := "https://web2platform.com/getLineminiappUnlock?idx=" # Nat.toText(in_idx);  // example endpoint
    } else { return "Invalid partner index" };

    Debug.print("URL: " # url);

    let request_headers = [
      { name = "Host"; value = host },
      { name = "User-Agent"; value = "ic-http" },
      { name = "Accept"; value = "application/json" },
      { name = "Accept-Encoding"; value = "identity" }
    ];

    let http_request : HttpRequestArgs = {
      url = url; max_response_bytes = null; headers = request_headers; body = null; method = #get;
      transform = ?{ function = transform; context = Blob.fromArray([]) }
    };

    Cycles.add<system>(230_850_258_000);
    let http_response : HttpResponse = await management.http_request(http_request);

    let decoded_text : Text = switch (Text.decodeUtf8(http_response.body)) { case (null) { "No value returned" }; case (?y) { y } };

    let parsed = JSON.parse(decoded_text);
    switch (parsed) {
      case (#ok(jsonValue)) {
        let getAsArrayValue = JSON.get(jsonValue, "");
        switch (getAsArrayValue) {
          case (?json) {
            switch (json) {
              case (#array(arr)) {
                for (item in arr.vals()) {
                  switch (item) {
                    case (#object_(_obj)) {
                      let partner_idx : Nat = switch (JSON.get(item, "partner_idx")) {
                        case (? #number(#int n)) { if (n < 0) 0 else Int.abs(n) };
                        case (? #string(t)) { switch (Nat.fromText(t)) { case (?v) v; case null 0 } };
                        case _ { 0 };
                      };
                      let idx : Nat = switch (JSON.get(item, "idx")) {
                        case (? #number(#int n)) { if (n < 0) 0 else Int.abs(n) };
                        case (? #string(t)) { switch (Nat.fromText(t)) { case (?v) v; case null 0 } };
                        case _ { 0 };
                      };
                      let unlock_date = switch (JSON.get(item, "unlock_date")) { case (? #string(t)) { t }; case _ { "" } };
                      let unlocked_at = switch (JSON.get(item, "unlocked_at")) { case (? #string(t)) { t }; case _ { "" } };
                      let unlocked_ts : Nat64 = switch (JSON.get(item, "unlocked_ts")) {
                        case (? #number(#int n)) { if (n < 0) 0 : Nat64 else Nat64.fromNat(Int.abs(n)) };
                        case (? #string(t)) { switch (Nat.fromText(t)) { case (?v) Nat64.fromNat(v); case null 0 : Nat64 } };
                        case _ { 0 : Nat64 };
                      };

                      unlockedAccumulatedData := { unlocked_acc = unlockedAccumulatedData.unlocked_acc + 1 };
                      MusicWorkInfoData := List.map(MusicWorkInfoData, func (m : T.MusicWorkInfo) : T.MusicWorkInfo {
                        if (m.idx == idx) { { m with unlock_total_count = m.unlock_total_count + 1 } } else { m }
                      });

                      if (partner_idx == 1) {
                        VerificationUnlockCountDataP := List.map(VerificationUnlockCountDataP, func (m : T.VerificationUnlockCount) : T.VerificationUnlockCount {
                          if (m.idx == idx) { { m with unlock_count = m.unlock_count + 1 } } else { m }
                        });
                        VerificationUnlockListDataP := List.push({ partner_idx = partner_idx; idx = idx; unlock_date = unlock_date; unlocked_at = unlocked_at; unlocked_ts = unlocked_ts }, VerificationUnlockListDataP);
                      } else if (partner_idx == 2) {
                        VerificationUnlockCountDataT := List.map(VerificationUnlockCountDataT, func (m : T.VerificationUnlockCount) : T.VerificationUnlockCount {
                          if (m.idx == idx) { { m with unlock_count = m.unlock_count + 1 } } else { m }
                        });
                        VerificationUnlockListDataT := List.push({ partner_idx = partner_idx; idx = idx; unlock_date = unlock_date; unlocked_at = unlocked_at; unlocked_ts = unlocked_ts }, VerificationUnlockListDataT);
                      } else if (partner_idx == 3) {
                        VerificationUnlockCountDataK := List.map(VerificationUnlockCountDataK, func (m : T.VerificationUnlockCount) : T.VerificationUnlockCount {
                          if (m.idx == idx) { { m with unlock_count = m.unlock_count + 1 } } else { m }
                        });
                        VerificationUnlockListDataK := List.push({ partner_idx = partner_idx; idx = idx; unlock_date = unlock_date; unlocked_at = unlocked_at; unlocked_ts = unlocked_ts }, VerificationUnlockListDataK);
                      }
                    };
                    case _ {};
                  }
                }
              };
              case _ { Debug.print("jsonValue is not array") };
            }
          };
          case null { Debug.print("jsonValue is null") };
        }
      };
      case (#err(_e)) { /* ignore parse error */ };
    };
    return decoded_text;
  };

  // ---------- HTTP transform (strip headers) ----------
  public query func transform({ context : Blob; response : HttpResponse }) : async HttpResponse {
    { response with headers = [] }
  };
}
