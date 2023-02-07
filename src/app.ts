import Koa, { Context } from "koa";
import koaHelmet from "koa-helmet";
import koaLogger from "koa-logger";
import { createClient } from "redis";
import { LocalDataKeeper } from "./data-keeper/LocalDataKeeper";

import { symbolsCount, StringGenerator } from "./markov";

const RATELIMIT_MAX_REQUESTS = 5;
const RATELIMIT_TIME = 15 * 1e3;

const app = new Koa();
const redisClient = createClient({
    url: process.env.REDIS_URL
});
const messagesKeeper = new LocalDataKeeper(process.env.MESSAGES_PATH || "/data/messages");

app.use(koaHelmet());
app.use(koaLogger());

app.use(async (ctx: Context, next) => {
    ctx.assert(ctx.path === "/", 404, "Not found");
    ctx.assert(ctx.method === "GET", 405, "Method not allowed");
    await next();
});

app.use(async (ctx: Context, next) => {
    ctx.assert(ctx.request.query?.channel_id, 400, "Missing channel_id");
    if (Array.isArray(ctx.request.query.channel_id))
        ctx.request.query.channel_id = ctx.request.query.channel_id[0];
    await next();
});

app.use(async (ctx: Context, next) => {
    const key = `rate-limit:${ctx.request.query.channel_id}`;
    const rateLimit = await redisClient.get(key);
    if (rateLimit) {
        const [count, timestamp] = rateLimit.split(":");
        const [countInt, timestampInt] = [parseInt(count), parseInt(timestamp)];
        if (countInt >= RATELIMIT_MAX_REQUESTS && Date.now() - timestampInt < RATELIMIT_TIME) {
            ctx.throw(429, `Rate limit exceeded, try again in ${Math.ceil((RATELIMIT_TIME - (Date.now() - timestampInt)) / 1e3)} seconds`);
        } else if (Date.now() - timestampInt >= RATELIMIT_TIME) {
            await redisClient.set(key, "1:" + Date.now());
        } else {
            await redisClient.set(key, `${countInt + 1}:${timestampInt}`);
        }
    } else {
        await redisClient.set(key, "1:" + Date.now());
    }
    await next();
});

app.use(async (ctx: Context, next) => {
    const {
        max_symbols: maxSymbols,
        channel_id: channelID,
        filter_links: filterLinks,
        count,
        begin
    } = ctx.request.query;

    const stringsCount = parseInt(Array.isArray(count) ? count[0] : count as string) || 1;
    ctx.assert(stringsCount > 0, 400, "Invalid count");

    const messages = await messagesKeeper.get(channelID as string, filterLinks === "true");
    ctx.assert(messages.length > 0, 400, "No messages found");

    const generator = new StringGenerator(messages);

    messages.length = 0;

    const result: string[] = [];
    const beginString = begin ? Array.isArray(begin) ? begin[0] : begin : undefined;
    const maxSymbolsValidator = symbolsCount(1, maxSymbols ? parseInt(maxSymbols as string) : Infinity);
    for (let i = 0; i < stringsCount; i++) {
        try {
            const generate = generator.generate({
                begin: beginString,
                attempts: 5000,
                validator: maxSymbolsValidator
            });
            if (typeof generate === "string") result.push(generate);
        } catch (e) {
            generator.clear();
            const err = e as Error;
            if (err.message.startsWith("Not enough samples")) ctx.throw(400, err.message);
            else ctx.throw(500, "Failed to generate string");
        }
    }
    generator.clear();
    ctx.assert(result.length > 0, 500, "Failed to generate string");
    ctx.body = result;
    await next();
});

async function startServer() {
    await redisClient.connect();
    app.listen(
        3000,
        () => console.log("Server started on port 3000")
    );
}

startServer();