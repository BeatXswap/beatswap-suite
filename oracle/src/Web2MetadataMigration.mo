// Web2MetadataMigration.mo
// Example-only snippet: HTTP outcalls + JSON parsing for migrating music
// metadata and unlock logs. Requires: mo:json, cycles, and the management
// canister http_request interface. Endpoints are placeholders.

import Text "mo:base/Text";
import Nat "mo:base/Nat";
import List "mo:base/List";
import JSON "mo:json";
import Debug "mo:base/Debug";
import Cycles "mo:base/ExperimentalCycles";
import Int "mo:base/Int";
import T "types";
import Blob "mo:base/Blob";
import Nat64 "mo:base/Nat64";

persistent actor Web2MetadataMigration {

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

  // -------- HTTP types & management canister handle --------
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

  let management : actor { http_request : (HttpRequestArgs) -> async HttpResponse } =
    actor ("aaaaa-aa");

  // -------- Minimal state used by the snippet --------
  var unlockedAccumulatedData = { unlocked_acc : Nat64 = 0 };

  var MusicWorkInfoData : List.List<T.MusicWorkInfo> = List.nil();

  var VerificationUnlockCountDataP : List.List<T.VerificationUnlockCount> = List.nil();
  var VerificationUnlockCountDataT : List.List<T.VerificationUnlockCount> = List.nil();
  var VerificationUnlockCountDataK : List.List<T.VerificationUnlockCount> = List.nil();

  var VerificationUnlockListDataP : List.List<T.VerificationUnlockList> = List.nil();
  var VerificationUnlockListDataT : List.List<T.VerificationUnlockList> = List.nil();
  var VerificationUnlockListDataK : List.List<T.VerificationUnlockList> = List.nil();

  // Helper: current max idx in MusicWorkInfoData
  private func getMusicWorkInfoMaxIdx() : Nat {
    if (List.size(MusicWorkInfoData) == 0) { 0 }
    else {
      List.foldLeft<T.MusicWorkInfo, Nat>(
        MusicWorkInfoData,
        0,
        func (acc : Nat, item : T.MusicWorkInfo) : Nat { Nat.max(acc, item.idx) },
      )
    }
  };

  // ---------- HTTP transform (strip headers) ----------
  public query func transform({ context : Blob; response : HttpResponse }) : async HttpResponse {
    { response with headers = [] }
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
      { name = "Accept-Encoding"; value = "identity" },
    ];

    let http_request : HttpRequestArgs = {
      url = url;
      max_response_bytes = null;
      headers = request_headers;
      body = null;
      method = #get;
      transform = ?{ function = transform; context = Blob.fromArray([]) };
    };

    Cycles.add<system>(230_850_258_000);
    let http_response : HttpResponse = await management.http_request(http_request);

    let decoded_text : Text =
      switch (Text.decodeUtf8(http_response.body)) { case (null) "No value returned"; case (?y) y };

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
                      let title = switch (JSON.get(item, "title")) { case (? #string(t)) t; case _ "" };
                      let song_thumbnail = switch (JSON.get(item, "song_thumbnail")) { case (? #string(t)) t; case _ "" };
                      let album_idx : Nat = switch (JSON.get(item, "album_idx")) {
                        case (? #number(#int n)) { if (n < 0) 0 else Int.abs(n) };
                        case (? #string(t)) { switch (Nat.fromText(t)) { case (?v) v; case null 0 } };
                        case _ { 0 };
                      };
                      let composer = switch (JSON.get(item, "composer")) { case (? #string(t)) t; case _ "" };
                      let lyricist = switch (JSON.get(item, "lyricist")) { case (? #string(t)) t; case _ "" };
                      let arranger = switch (JSON.get(item, "arranger")) { case (? #string(t)) t; case _ "" };
                      let genre_idx : Nat = switch (JSON.get(item, "genre_idx")) {
                        case (? #number(#int n)) { if (n < 0) 0 else Int.abs(n) };
                        case (? #string(t)) { switch (Nat.fromText(t)) { case (?v) v; case null 0 } };
                        case _ { 0 };
                      };
                      let work_type = switch (JSON.get(item, "work_type")) { case (? #string(t)) t; case _ "" };
                      let music_publisher = switch (JSON.get(item, "music_publisher")) { case (? #string(t)) t; case _ "" };
                      let artist = switch (JSON.get(item, "artist")) { case (? #string(t)) t; case _ "" };
                      let musician = switch (JSON.get(item, "musician")) { case (? #string(t)) t; case _ "" };
                      let record_label = switch (JSON.get(item, "record_label")) { case (? #string(t)) t; case _ "" };
                      let release_date = switch (JSON.get(item, "release_date")) { case (? #string(t)) t; case _ "" };
                      let registration_date = switch (JSON.get(item, "registration_date")) { case (? #string(t)) t; case _ "" };
                      let requester_principal = switch (JSON.get(item, "requester_principal")) { case (? #string(t)) t; case _ "" };
                      let unlock_total_count : Nat = switch (JSON.get(item, "unlock_total_count")) {
                        case (? #number(#int n)) { if (n < 0) 0 else Int.abs(n) };
                        case (? #string(t)) { switch (Nat.fromText(t)) { case (?v) v; case null 0 } };
                        case _ { 0 };
                      };
                      let verification_status = switch (JSON.get(item, "verification_status")) { case (? #string(t)) t; case _ "" };
                      let icp_neighboring_token_address = switch (JSON.get(item, "icp_neighboring_token_address")) { case (? #string(t)) t; case _ "" };
                      let op_neighboring_token_address = switch (JSON.get(item, "op_neighboring_token_address")) { case (? #string(t)) t; case _ "" };

                      let musicWorkInfo : T.MusicWorkInfo = {
                        idx = idx;
                        title = title;
                        song_thumbnail = song_thumbnail;
                        album_idx = album_idx;
                        composer = composer;
                        lyricist = lyricist;
                        arranger = arranger;
                        genre_idx = genre_idx;
                        work_type = work_type;
                        music_publisher = music_publisher;
                        artist = artist;
                        musician = musician;
                        record_label = record_label;
                        release_date = release_date;
                        registration_date = registration_date;
                        requester_principal = requester_principal;
                        unlock_total_count = unlock_total_count;
                        verification_status = verification_status;
                        icp_neighboring_token_address = icp_neighboring_token_address;
                        op_neighboring_token_address = op_neighboring_token_address;
                      };

                      VerificationUnlockCountDataP :=
                        List.push({ partner_idx = 1; idx = idx; unlock_count = unlock_total_count }, VerificationUnlockCountDataP);
                      VerificationUnlockCountDataT :=
                        List.push({ partner_idx = 2; idx = idx; unlock_count = unlock_total_count }, VerificationUnlockCountDataT);
                      VerificationUnlockCountDataK :=
                        List.push({ partner_idx = 3; idx = idx; unlock_count = unlock_total_count }, VerificationUnlockCountDataK);

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
    } else {
      return "Invalid partner index";
    };

    Debug.print("URL: " # url);

    let request_headers = [
      { name = "Host"; value = host },
      { name = "User-Agent"; value = "ic-http" },
      { name = "Accept"; value = "application/json" },
      { name = "Accept-Encoding"; value = "identity" },
    ];

    let http_request : HttpRequestArgs = {
      url = url;
      max_response_bytes = null;
      headers = request_headers;
      body = null;
      method = #get;
      transform = ?{ function = transform; context = Blob.fromArray([]) };
    };

    Cycles.add<system>(230_850_258_000);
    let http_response : HttpResponse = await management.http_request(http_request);

    let decoded_text : Text =
      switch (Text.decodeUtf8(http_response.body)) { case (null) "No value returned"; case (?y) y };

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
                      let unlock_date = switch (JSON.get(item, "unlock_date")) { case (? #string(t)) t; case _ "" };
                      let unlocked_at = switch (JSON.get(item, "unlocked_at")) { case (? #string(t)) t; case _ "" };
                      let unlocked_ts : Nat64 = switch (JSON.get(item, "unlocked_ts")) {
                        case (? #number(#int n)) { if (n < 0) 0 : Nat64 else Nat64.fromNat(Int.abs(n)) };
                        case (? #string(t)) { switch (Nat.fromText(t)) { case (?v) Nat64.fromNat(v); case null 0 : Nat64 } };
                        case _ { 0 : Nat64 };
                      };

                      unlockedAccumulatedData := { unlocked_acc = unlockedAccumulatedData.unlocked_acc + 1 };

                      MusicWorkInfoData := List.map(
                        MusicWorkInfoData,
                        func (m : T.MusicWorkInfo) : T.MusicWorkInfo {
                          if (m.idx == idx) { { m with unlock_total_count = m.unlock_total_count + 1 } } else { m }
                        },
                      );

                      if (partner_idx == 1) {
                        VerificationUnlockCountDataP := List.map(
                          VerificationUnlockCountDataP,
                          func (m : T.VerificationUnlockCount) : T.VerificationUnlockCount {
                            if (m.idx == idx) { { m with unlock_count = m.unlock_count + 1 } } else { m }
                          },
                        );
                        VerificationUnlockListDataP := List.push(
                          { partner_idx = partner_idx; idx = idx; unlock_date = unlock_date; unlocked_at = unlocked_at; unlocked_ts = unlocked_ts },
                          VerificationUnlockListDataP,
                        );
                      } else if (partner_idx == 2) {
                        VerificationUnlockCountDataT := List.map(
                          VerificationUnlockCountDataT,
                          func (m : T.VerificationUnlockCount) : T.VerificationUnlockCount {
                            if (m.idx == idx) { { m with unlock_count = m.unlock_count + 1 } } else { m }
                          },
                        );
                        VerificationUnlockListDataT := List.push(
                          { partner_idx = partner_idx; idx = idx; unlock_date = unlock_date; unlocked_at = unlocked_at; unlocked_ts = unlocked_ts },
                          VerificationUnlockListDataT,
                        );
                      } else if (partner_idx == 3) {
                        VerificationUnlockCountDataK := List.map(
                          VerificationUnlockCountDataK,
                          func (m : T.VerificationUnlockCount) : T.VerificationUnlockCount {
                            if (m.idx == idx) { { m with unlock_count = m.unlock_count + 1 } } else { m }
                          },
                        );
                        VerificationUnlockListDataK := List.push(
                          { partner_idx = partner_idx; idx = idx; unlock_date = unlock_date; unlocked_at = unlocked_at; unlocked_ts = unlocked_ts },
                          VerificationUnlockListDataK,
                        );
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
}
