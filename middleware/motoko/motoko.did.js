export const idlFactory = ({ IDL }) => {
  const MusicWorkInfo = IDL.Record({
    'idx' : IDL.Nat,
    'musician' : IDL.Text,
    'title' : IDL.Text,
    'registration_date' : IDL.Text,
    'lyricist' : IDL.Text,
    'record_label' : IDL.Text,
    'work_type' : IDL.Text,
    'release_date' : IDL.Text,
    'music_publisher' : IDL.Text,
    'song_thumbnail' : IDL.Text,
    'genre_idx' : IDL.Nat,
    'op_neighboring_token_address' : IDL.Text,
    'verification_status' : IDL.Text,
    'composer' : IDL.Text,
    'artist' : IDL.Text,
    'icp_neighboring_token_address' : IDL.Text,
    'album_idx' : IDL.Nat,
    'arranger' : IDL.Text,
    'requester_principal' : IDL.Text,
    'unlock_total_count' : IDL.Nat,
  });
  const DailyRightsHolders = IDL.Record({
    'neighboring_holder_staked_address' : IDL.Text,
    'staked_amount' : IDL.Text,
    'neighboring_token_address' : IDL.Text,
    'verification_date' : IDL.Text,
    'neighboring_holder_staked_mainnet' : IDL.Text,
  });
  const GenreId = IDL.Record({
    'genre_name' : IDL.Text,
    'genre_idx' : IDL.Nat,
  });
  const MusicVerificationList = IDL.Record({
    'idx' : IDL.Nat,
    'verification_status' : IDL.Bool,
    'verification_status_updated_at' : IDL.Text,
    'requester_principal' : IDL.Text,
  });
  const Partner = IDL.Record({
    'partner_idx' : IDL.Nat,
    'partner_name' : IDL.Text,
  });
  const VerificationUnlockCount = IDL.Record({
    'idx' : IDL.Nat,
    'partner_idx' : IDL.Nat,
    'unlock_count' : IDL.Nat,
  });
  const VerificationUnlockList = IDL.Record({
    'idx' : IDL.Nat,
    'unlock_date' : IDL.Text,
    'partner_idx' : IDL.Nat,
    'unlocked_at' : IDL.Text,
    'unlocked_ts' : IDL.Nat64,
  });
  const HeaderField = IDL.Record({ 'value' : IDL.Text, 'name' : IDL.Text });
  const HttpResponse = IDL.Record({
    'status' : IDL.Nat,
    'body' : IDL.Vec(IDL.Nat8),
    'headers' : IDL.Vec(HeaderField),
  });
  return IDL.Service({
    'addDailyRightsHolder' : IDL.Func(
        [IDL.Text, IDL.Text, IDL.Text, IDL.Text, IDL.Text, IDL.Text],
        [],
        [],
      ),
    'addGenre' : IDL.Func([IDL.Text, IDL.Nat, IDL.Text], [IDL.Text], []),
    'addMusicVerificationList' : IDL.Func(
        [IDL.Text, IDL.Nat, IDL.Text, IDL.Bool, IDL.Text],
        [],
        [],
      ),
    'addMusicWorkInfo' : IDL.Func([IDL.Opt(IDL.Text), MusicWorkInfo], [], []),
    'addPartner' : IDL.Func([IDL.Text, IDL.Nat, IDL.Text], [IDL.Text], []),
    'addRequesterId' : IDL.Func([IDL.Text, IDL.Text, IDL.Bool], [IDL.Text], []),
    'addVerificationUnlockList' : IDL.Func(
        [IDL.Opt(IDL.Text), IDL.Nat, IDL.Nat, IDL.Text, IDL.Text, IDL.Nat64],
        [IDL.Text],
        [],
      ),
    'firstDataSet' : IDL.Func([IDL.Text], [IDL.Text], []),
    'getDailyRightsHolders' : IDL.Func(
        [IDL.Text, IDL.Text],
        [IDL.Vec(DailyRightsHolders)],
        ['query'],
      ),
    'getGenres' : IDL.Func([], [IDL.Vec(GenreId)], ['query']),
    'getMusicContractAddress' : IDL.Func([], [IDL.Text], ['query']),
    'getMusicInfoByPaykhanData' : IDL.Func(
        [IDL.Text, IDL.Text],
        [IDL.Text],
        [],
      ),
    'getMusicInfoByPaykhanOutcall' : IDL.Func([IDL.Text], [IDL.Text], []),
    'getMusicVerificationLists' : IDL.Func(
        [],
        [IDL.Vec(MusicVerificationList)],
        ['query'],
      ),
    'getMusicWorkInfos' : IDL.Func([], [IDL.Vec(MusicWorkInfo)], ['query']),
    'getMusicWorkInfosByGenre' : IDL.Func(
        [IDL.Nat],
        [IDL.Vec(MusicWorkInfo)],
        ['query'],
      ),
    'getPartners' : IDL.Func([], [IDL.Vec(Partner)], ['query']),
    'getRequesterIds' : IDL.Func(
        [],
        [
          IDL.Vec(
            IDL.Record({
              'requester_name' : IDL.Text,
              'can_approve' : IDL.Bool,
            })
          ),
        ],
        ['query'],
      ),
    'getUnlockedAccumulated' : IDL.Func([], [IDL.Nat64], ['query']),
    'getVerificationUnlockCounts' : IDL.Func(
        [IDL.Nat],
        [IDL.Vec(VerificationUnlockCount)],
        ['query'],
      ),
    'getTotalVerificationUnlockCount' : IDL.Func(
      [IDL.Nat],
      [IDL.Nat],
      ['query'],
    ),
    'getVerificationUnlockListData' : IDL.Func(
        [IDL.Nat, IDL.Text, IDL.Text],
        [IDL.Text],
        [],
      ),
    'getVerificationUnlockListPaykhanOutcall' : IDL.Func(
        [IDL.Nat, IDL.Text],
        [IDL.Text],
        [],
      ),
    'getVerificationUnlockListsByDate' : IDL.Func(
        [IDL.Nat, IDL.Text],
        [IDL.Vec(VerificationUnlockList)],
        ['query'],
      ),
    'getVerificationUnlockListsByDateTs' : IDL.Func(
        [IDL.Nat, IDL.Nat64, IDL.Nat64],
        [IDL.Vec(VerificationUnlockList)],
        ['query'],
      ),
    'setCanisterOwner' : IDL.Func([IDL.Text], [IDL.Text], []),
    'transform' : IDL.Func(
        [
          IDL.Record({
            'context' : IDL.Vec(IDL.Nat8),
            'response' : HttpResponse,
          }),
        ],
        [HttpResponse],
        ['query'],
      ),
    'updateCanisterOwner' : IDL.Func(
        [IDL.Opt(IDL.Text), IDL.Opt(IDL.Text)],
        [IDL.Text],
        [],
      ),
    'updateGenreName' : IDL.Func([IDL.Text, IDL.Nat, IDL.Text], [IDL.Text], []),
    'updateMusicWorkInfo' : IDL.Func(
        [IDL.Opt(IDL.Text), MusicWorkInfo],
        [IDL.Text],
        [],
      ),
    'whoami' : IDL.Func([], [IDL.Principal], ['query']),
  });
};
export const init = ({ IDL }) => { return []; };
