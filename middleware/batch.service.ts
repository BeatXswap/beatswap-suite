import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import * as moment from 'moment-timezone';
import { AppService } from './app.service';

@Injectable()
export class BatchService {
    private readonly logger = new Logger(BatchService.name);

    constructor(private readonly appService: AppService) {};

    // @Cron('0 */1 * * * *')
    @Cron('0 10 0 * * *') //Daily 00:10
    async addDailyRightsHolder() {
        const now = moment().tz('Asia/Seoul').format('YYYY-MM-DD HH:mm:ss');
        this.logger.log(`addDailyRightsHolder Batch Start : ${now} (KST)`);


        await this.appService.addDailyRightsHolder();
    }

}