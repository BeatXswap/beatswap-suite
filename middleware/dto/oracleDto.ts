import { Expose,Type } from 'class-transformer';
import { IsInt } from 'class-validator';

export class oracleDto {
    @Type(() => Number)
    idx: number;
    idxList: number[];
    @Type(() => Number)
    genre_idx: number;
    musician: string;
    music_publisher: string;
    song_thumbnail: string;
    op_neighboring_token_address: string;
    icp_neighboring_token_address: string;
    @Type(() => Number)
    album_idx: number;
    arranger: string;
    requester_principal: string;
    @Type(() => Number)
    unlock_total_count: number;
    requestName:string;
    can_approve: boolean;
    address: string;
    partner_idx: number;
    partner_name: string;
    unlock_date: string;
    unlocked_at: string;
    startTs: number;
    endTs: number;
}