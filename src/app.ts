import Koa, { Context } from "koa";
import koaHelmet from "koa-helmet";
import koaLogger from "koa-logger";
import rateLimit from "koa-ratelimit";
import { LocalDataKeeper } from "./data-keeper/LocalDataKeeper";

import { symbolsCount, StringGenerator } from "./markov";

const app = new Koa();
const messagesKeeper = new LocalDataKeeper("/data/messages");

app.use(koaHelmet());
app.use(koaLogger());

app.use(async (ctx: Context, next) => {
    ctx.assert(ctx.path === "/", 404, "Not found");
    ctx.assert(ctx.method === "GET", 405, "Method not allowed");
    await next();
});

app.use(async (ctx: Context, next) => {
    ctx.assert(ctx.request.query?.channel_id, 400, "Missing channel_id");
    await next();
});

app.use(rateLimit({
    driver: "memory",
    db: new Map(),
    duration: 15000,
    id: (ctx) => ctx.request.query.channel_id as string,
    max: 5
}));

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

function startServer() {
    app.listen(
        3000,
        () => console.log("Server started on port 3000")
    );
}

startServer();