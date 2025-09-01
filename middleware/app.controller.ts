import { Controller, Get, Post, Body, Req, Logger, ValidationPipe } from '@nestjs/common';
import { AppService } from './app.service';
import { oracleDto } from './dto/oracleDto';
import { Request } from 'express';

@Controller('oracle')
export class AppController {
    constructor(private readonly appService: AppService) {}

    private readonly logger = new Logger(AppController.name);

    @Get('test')
    async test() {
        return { status: 'success' };
    }

    @Post('getMusicWorkInfos')
    async getMusicWorkInfos() {
        return this.appService.getMusicWorkInfos();
    }

    @Post('getGenres')
    async getGenres() {
        return this.appService.getGenres();
    }

    @Post('getPartners')
    async getPartners() {
        return this.appService.getPartners();
    }

    @Post('getMusicWorkInfosByGenre')
    async getMusicWorkInfosByGenre(@Body() body: oracleDto) {
        return this.appService.getMusicWorkInfosByGenre(body.genre_idx);
    }

    @Post('getDailyRightsHolders')
    async getDailyRightsHolders(@Body() body: oracleDto) {
        return this.appService.getDailyRightsHolders(body.address);
    }
    
    @Post('getTotalUnlockCount')
    async getTotalUnlockCount() {
        const totalCount = await this.appService.getTotalUnlockCount();
        return { totalCount : Number(totalCount) };
    }

    @Post('getTotalVerificationUnlockCount')
    async getTotalVerificationUnlockCount(@Body() body: oracleDto) {
        const totalCount = await this.appService.getTotalVerificationUnlockCount(body.partner_idx);
        return { totalCount : Number(totalCount) };
    }

    @Post('getVerificationUnlockListsByDate')
    async getVerificationUnlockListsByDate(@Body() body: oracleDto) {
        return await this.appService.getVerificationUnlockListsByDate(body.partner_idx, body.unlock_date);
    }

    @Post('getVerificationUnlockListsByTS')
    async getVerificationUnlockListsByTS(@Body() body: oracleDto) {
        return await this.appService.getVerificationUnlockListsByDateTs(body.partner_idx, body.startTs, body.endTs);
    }

    @Post('updateMusicWorkInfo')
    async updateMusicWorkInfo(@Body(new ValidationPipe({ transform: true })) body: oracleDto) {

        try {
            await this.appService.updateMusicWorkInfo(body);
        } catch(e) {
            console.log("error", e);
            return { success: false };
        }
        return { success: true };
    }

    @Post('addPartner')
    async addPartner(@Body() body: oracleDto) {

        try {
            await this.appService.addPartner(body.partner_idx, body.partner_name);
        } catch(e) {
            console.log("error", e.getMessage);
            return { success: false };
        }
        return { success: true };
    }

    @Post('addRequesterId')
    async addRequesterId(@Body() body: oracleDto) {

        try {
            await this.appService.addRequesterId(body.requestName, body.requester_principal, body.can_approve);
        } catch(e) {
            console.log("error", e.getMessage);
            return { success: false };
        }
        return { success: true };
    }

    @Post('addVerificationUnlockList')
    async addVerificationUnlockList(@Req() req: Request, @Body() body: oracleDto) {
        const clientIp = req.ip?.replace('::ffff:', '');

        try {
            const res = await this.appService.addVerificationUnlockList(body.partner_idx, body.idxList);
            this.logger.log(res);
        } catch(e) {
            console.log("error",e);
            return { success: false };
        }

        return { success: true };
    }

    @Post('addRightsHolder')
    async addRightsHolder() {
        try {
            const response = await this.appService.addRightsHolder();
            this.logger.log(response);
        }   catch(e) {
            console.log("error",e);
            return { success: false };
        }

        return { success: true };
    }

    @Post('getUnlockCount')
    async getUnlockCount(@Body() body: any[]) {
        this.logger.log(body);
        const response = await this.appService.getUnlockCount(body);
        return response;
    }
}