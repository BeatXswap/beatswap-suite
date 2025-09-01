import { Injectable, Logger, Res } from '@nestjs/common';
import { HttpAgent, Actor } from '@dfinity/agent';
import { ConfigService } from '@nestjs/config';
import { idlFactory as myIdlFactory } from './motoko/motoko.did.js';
import * as httpMocks from 'node-mocks-http';
import { EventEmitter } from 'stream';
import * as moment from 'moment-timezone';
import { oracleDto } from './dto/oracleDto.js';


const web3Router = require('./web3/web.js').default;

const gnere = {
            1:'K-Pop',
            2:'R&B',
            3:'Trot',
            4:'City-Pop',
            5:'Ballad',
            6:'Jazz',
            7:'Hip Hop',
            8:'Indy',
            9:'Rock',
            10:'CCM',
            11:'Alternatvie Pop',
            12:'Chillwave/R&B',
            13:'House',
            14:'EDM',
            15:'Band',
            16:'Tropical House',
            17:'Medium',
            18:'Pop',
            19:'Chill',
            20:'Alternative R&B',
            21:'Jazz Pop',
            22:'Modern Rock',
            23:'Disco Pop',
            24:'Neo Soul',
            25:'CAROL',
            26:'Slap House',
            27:'Crossover',
            28:'Dream POP',
            29:'Alternative Rock',
            30:'Acoustic',
            31:'Synth pop',
            32:'Electronic K-POP',
            33:'Retro',
            34:'Soul',
            35:'Rock Ballad',
            36:'Dancehall',
            37:'Latin POP',
            38:'Trapsoul',
            39:'Reggeaton',
            40:'Trap SOUL',
            41:'Acoustic Country',
            42:'Emo Hip-Hop',
            43:'K-Pop Dance',
            44:'Dance-Punk',
            45:'Baile Funk',
            46:'UK Garage (UKG)'
        };

@Injectable()
export class AppService {
    constructor(private configService: ConfigService) {}

    
    private readonly logger = new Logger(AppService.name);

    private actor: any;
    
    async onModuleInit() {
        const agent = new HttpAgent({host: 'https://ic0.app'});
        const CANISTER_ID = this.configService.get<string>('CANISTER_ID');

        if(!CANISTER_ID){
            this.logger.error('Cannot find CANISTER_ID');
            throw new Error('Cannot find CANISTER_ID');
        }


        await agent.fetchRootKey();

        this.actor = Actor.createActor(myIdlFactory, {
            agent,
            canisterId: CANISTER_ID,
        });
    }

    async addRightsHolder() {
        const OWNER_KEY = this.configService.get<string>('OWNER_KEY');

        if(!OWNER_KEY){
            this.logger.error('Cannot find OWNER_KEY');
            throw new Error('Cannot find OWNER_KEY');
        }
        const musicInfo = await this.actor.getMusicWorkInfos();
        const now = moment().tz('Asia/Seoul');
        for(let i = 0; i < musicInfo.length; i++) {
            const holder = await this.actor.getDailyRightsHolders(musicInfo[i].op_neighboring_token_address, now.format('YYYY-MM-DD'));
            if(JSON.stringify(holder) !== '[]') {
                this.logger.log('Data already exists');
                continue;
            }
        
            const req = httpMocks.createRequest({
                method: 'GET',
                url: '/getStaker',
                query: { contract_address: musicInfo[i].op_neighboring_token_address},
            });
            this.logger.log(`song contract_address :: ${musicInfo[i].op_neighboring_token_address}`);
        
            const res = httpMocks.createResponse({ eventEmitter: EventEmitter });

            await new Promise((resolve, reject) => {
                res.on('end', resolve);
                res.on('finish', resolve);
                res.on('error', reject);

                web3Router.handle(req, res, (err:any) => {
                    if(err) return reject(err);

                    setImmediate(() => {
                    if(!res.writableEnded) {
                        reject(new Error('Router not Response'));
                    }
                    })
                })
            });
            const data = res._getData();
            this.logger.log(`holder Data ::  ${JSON.stringify(data)}`);
            for(let j = 0; j < data.length; j++) {
                try {
                    await this.actor.addDailyRightsHolder(OWNER_KEY, musicInfo[i].op_neighboring_token_address, data[j].userMetaId, data[j].userStakingAmount.toString(), now.format('YYYY-MM-DD'), '<mainnet');
                } catch (err) {
                    this.logger.error(`addDailyRightsHolder rate ::: ${musicInfo[i].op_neighboring_token_address} || ${err.message}`);
                }
            }
        }
    }

    async addDailyRightsHolder() {
        const OWNER_KEY = this.configService.get<string>('OWNER_KEY');

        if(!OWNER_KEY){
            this.logger.error('Cannot find OWNER_KEY');
            throw new Error('Cannot find OWNER_KEY');
        }

        const musicInfo = await this.actor.getMusicWorkInfos();
        const now = moment().tz('Asia/Seoul');


        this.logger.log(`musicInfo length ${musicInfo.length}`);
        for(let i = 0; i < musicInfo.length; i++) {
            const req = httpMocks.createRequest({
                method: 'GET',
                url: '/getStaker',
                query: { contract_address: musicInfo[i].op_neighboring_token_address},
            });
            this.logger.log(`song contract_address ${musicInfo[i].op_neighboring_token_address}`);
        
            const res = httpMocks.createResponse({ eventEmitter: EventEmitter });
    
            await new Promise((resolve, reject) => {
                res.on('end', resolve);
                res.on('finish', resolve);
                res.on('error', reject);
    
                web3Router.handle(req, res, (err:any) => {
                    if(err) return reject(err);
    
                    setImmediate(() => {
                    if(!res.writableEnded) {
                        reject(new Error('Router not Response'));
                    }
                    })
                })
            });
            const data = res._getData();
            this.logger.log(`holder Data ::  ${JSON.stringify(data)}`);
            for(let j = 0; j < data.length; j++) {
                try {
                    await this.actor.addDailyRightsHolder(OWNER_KEY, musicInfo[i].op_neighboring_token_address, data[j].userMetaId, data[j].userStakingAmount.toString(), now.format('YYYY-MM-DD'), '<mainnet>');
                } catch (err) {
                    this.logger.error(`addDailyRightsHolder rate ::: ${musicInfo[i].op_neighboring_token_address}`, err.message);
                }
            }
        }
    }

    async addMusicInfo(): Promise<any> {
        const OWNER_KEY = this.configService.get<string>('OWNER_KEY');

        if(!OWNER_KEY){
            this.logger.error('Cannot find OWNER_KEY');
            throw new Error('Cannot find OWNER_KEY');
        }

        const res = await this.actor.getMusicInfoByPaykhan(OWNER_KEY);

        if(res === '[]') {
            this.logger.log('Nothing to update');
            return {response: 'Nothing to update'};
        }
        
        this.logger.log('reponse ::',res);

        return this.addMusicInfo();
    }


    async addVerificationUnlockListPayKhan(idx: number): Promise<any> {
        const OWNER_KEY = this.configService.get<string>('OWNER_KEY');

        if(!OWNER_KEY){
            this.logger.error('Cannot find OWNER_KEY');
            throw new Error('Cannot find OWNER_KEY');
        }
        
        const res = await this.actor.getVerificationUnlockListPaykhan(idx, OWNER_KEY);

        if(res === '[]') {
            this.logger.log('Nothing to update');
            return {response: 'Nothing to update'};
        }
        
        this.logger.log('response ::',res);

        return this.addVerificationUnlockListPayKhan(idx);
    }

    async addPaykhanMusicWorkInfo(n: number = 597): Promise<any> {
        const OWNER_KEY = this.configService.get<string>('OWNER_KEY');

        if(!OWNER_KEY){
            this.logger.error('Cannot find OWNER_KEY');
            throw new Error('Cannot find OWNER_KEY');
        }

        const url = "https://web2platform.com/getMusicInfoIcp?idx="+n;  // example endpoint
       
        try {
            const response = await fetch(url);
            const data = await response.text();
            if(data == '[]') {
                return {response: 'Nothing to update'};
            }
            const lastIdx = JSON.parse(data).at(-1).idx;
            n = lastIdx;
            this.logger.log(`response url ::: ${url}`);
            
            
            await this.actor.getMusicInfoByPaykhanData(OWNER_KEY, data);
            
        } catch(error) {
            this.logger.log(error);
        }
        return this.addPaykhanMusicWorkInfo(n);
    }

    async addPartnerUnlockInfo(partnerIdx: number,n: number = 0): Promise<any> {
        //1349400
        const OWNER_KEY = this.configService.get<string>('OWNER_KEY');

        if(!OWNER_KEY){
            this.logger.error('Cannot find OWNER_KEY');
            throw new Error('Cannot find OWNER_KEY');
        }
        const now = moment().tz('Asia/Seoul');
        let url = "";
        
        
        try {
            if (partnerIdx == 1) {
                url = "https://web2platform.com/getWeb2platformUnlock?idx="+n;  // example endpoint
            } else if (partnerIdx == 2) {
                url = "https://web2platform.com/getTelegramminiappUnlock?idx="+n;  // example endpoint
            } else if (partnerIdx == 3) {
                url = "https://web2platform.com/getLineminiappUnlock?idx="+n;  // example endpoint
            } 

            const response = await fetch(url);
            const data = await response.text();
            
            if(data === '[]') {
                return {response: 'Nothing to update'};
            } 

            const jsonData = JSON.parse(data);

            const duplicateCheck = new Date("2025-08-26 20:00:00");

            const dataFilter = jsonData.filter(item => new Date(item.unlocked_at) <= duplicateCheck);
        
            this.logger.log(`response url ::: ${url}`);
            this.logger.log(`response filter ::: ${JSON.stringify(dataFilter)}`);
            await this.actor.getVerificationUnlockListData(partnerIdx, JSON.stringify(dataFilter), OWNER_KEY);
        } catch(error) {
            this.logger.log(error);
        }
    
        return this.addPartnerUnlockInfo(partnerIdx,n+50);
    }

    async getUnlockCount(body: any[]): Promise<any> {

        const jsonData = Object.values(
            body.reduce((acc, cur) => {
            if(!acc[cur.idx]) {
                acc[cur.idx] = { ...cur, unlock_count: Number(cur.unlock_count) || 0 };
            } else {
                acc[cur.idx].unlock_count += Number(cur.unlock_count);
            }
            return acc;
            }, {})
        );

        return jsonData;
    }

    async getMusicWorkInfos(): Promise<any> {
        const res = await this.actor.getMusicWorkInfos();

        for(let i = 0; i < res.length; i++) {
            res[i].genre_idx = gnere[Number(res[i].genre_idx)] || 'Unknown';
            const songIdx = res[i].idx;
            Object.assign(res[i], {musicFile:`https://<file storage url>/${songIdx}.mp3`});
        }

        const sorted = res.sort((a,b)=> Number(a.idx) - Number(b.idx));

        return sorted;
    }


    async getMusicWorkInfosByGenre(genreIdx: number): Promise<any> {
        const res = await this.actor.getMusicWorkInfosByGenre(genreIdx);

        for(let i = 0; i < res.length; i++) {
           res[i].genre_idx = gnere[Number(res[i].genre_idx)] || 'Unknown';

           Object.assign(res[i], {musicFile:`https://<file storage url>/${res[i].title} - ${res[i].artist} (PVW).mp3`});
        }

        const sorted = res.sort((a,b)=> Number(a.idx) - Number(b.idx));
        return sorted;
    }

    async getDailyRightsHolders(address: string): Promise<any> {
        type Item = {
            neighboring_holder_staked_address: string;
            neighboring_holder_staked_mainnet: string;
            ratio: string;  
        };

        const now = moment().tz('Asia/Seoul');
        const date = now.format('YYYY-MM-DD');

        const res = await this.actor.getDailyRightsHolders(address, date);
        let sumAmount = 0;
        
        for(let i = 0; i < res.length; i++) {
            sumAmount += Number(res[i].staked_amount);
            if(i == res.length-1){
                for(let j = res.length-1; j >= 0; j--){
                    const ratio = this.roundTo((res[j].staked_amount/sumAmount)*100, 2);
                    this.logger.log(`amount ::: [${res[j].staked_amount}] / [${sumAmount}]`);
                    this.logger.log(`ratio ::: [${ratio}]%`);
                    Object.assign(res[j], {"ratio": `${ratio}%`});
                }
            }
        }
        
        const sorted = res.sort((a,b)=> Number(b.staked_amount) - Number(a.staked_amount));

        const limit = sorted.map(({staked_amount,neighboring_token_address,verification_date, ...rest})=>rest).slice(0, 20);

        return limit;
    }

    async getGenres(): Promise<any> {
        const res = Object.values(gnere);
        

        return res;
    }

    async getPartners(): Promise<string> {
        return await this.actor.getPartners();
    }

    async getTotalUnlockCount(): Promise<number> {
        return await this.actor.getUnlockedAccumulated();
    }

    async getTotalVerificationUnlockCount(partnerIdx: number): Promise<number> {
        return await this.actor.getTotalVerificationUnlockCount(partnerIdx);
    }

    async getVerificationUnlockListsByDate(partnerIdx: number, unlockDate: string): Promise<string> {
        return await this.actor.getVerificationUnlockListsByDate(partnerIdx,unlockDate);
    }

    async getVerificationUnlockListsByDateTs(partnerIdx: number, startTs: number, endTs: number): Promise<string> {
        return await this.actor.getVerificationUnlockListsByDateTs(partnerIdx,startTs,endTs);
    }

    async addMusicWorkInfo(body: oracleDto): Promise<string> {
        const OWNER_KEY = this.configService.get<string>('OWNER_KEY');

        if(!OWNER_KEY){
            this.logger.error('Cannot find OWNER_KEY');
            throw new Error('Cannot find OWNER_KEY');
        }
        const OWNER = [OWNER_KEY];

        return await this.actor.addMusicWorkInfo(OWNER, body);
    }


    async updateMusicWorkInfo(body: oracleDto): Promise<string> {
        const OWNER_KEY = this.configService.get<string>('OWNER_KEY');

        if(!OWNER_KEY){
            this.logger.error('Cannot find OWNER_KEY');
            throw new Error('Cannot find OWNER_KEY');
        }
        const OWNER = [OWNER_KEY];

        return await this.actor.updateMusicWorkInfo(OWNER, body);
    }

    async addPartner(partnerIdx: number, partnerName: string) {
        const OWNER_KEY = this.configService.get<string>('OWNER_KEY');

        if(!OWNER_KEY){
            this.logger.error('Cannot find OWNER_KEY');
            throw new Error('Cannot find OWNER_KEY');
        }


        await this.actor.addPartner(OWNER_KEY, partnerIdx, partnerName);
    }
    
    async addRequesterId(requestName: string, requestPrincipal: string, canApprove: boolean) {
        await this.actor.addRequesterId(requestName, requestPrincipal, canApprove);
    }

    async addVerificationUnlockList(partnerIdx: number, idxList: number[]): Promise<string> {
        const OWNER_KEY = this.configService.get<string>('OWNER_KEY');

        if(!OWNER_KEY){
            this.logger.error('Cannot find OWNER_KEY');
            throw new Error('Cannot find OWNER_KEY');
        }

        const now = moment().tz('Asia/Seoul');
        const tsSeconds = moment().unix();
    

        const jsonArray = idxList.map((idx) => ({
             partner_idx: partnerIdx, 
             idx: idx, 
             unlock_date: now.format('YYYY-MM-DD'),
             unlocked_at: now.format('YYYY-MM-DD HH:mm:ss'),
             unlocked_ts: tsSeconds
            }));
        
        
       return await this.actor.getVerificationUnlockListData(partnerIdx, JSON.stringify(jsonArray), OWNER_KEY);
    }

    roundTo(num:number, digits: number) {
        const factor = Math.pow(10, digits);
        return Math.round(num*factor)/ factor;
    }
}
