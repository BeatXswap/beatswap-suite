import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';
import { join } from 'path';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);
  app.setBaseViewsDir(join(__dirname, '..', 'views'));
  app.setViewEngine('ejs');

  app.enableCors({
    origin:'*',
    methods: 'GET,HEAD,PUT,PATCH,POST',
    allowedHeaders: 'Content-Type, Authorization',
  })

  app.use((req, res, next) => {
    const oldJson = res.json;
    res.json = function (data) {
      return oldJson.call(this, JSON.parse(JSON.stringify(data, (_, v) =>
      typeof v === 'bigint' ? v.toString():v)));
    };
    next();
  });

  await app.listen(process.env.PORT ?? 3000);
}
bootstrap();
