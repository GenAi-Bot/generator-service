FROM nimlang/nim:2.2.6-alpine-regular AS builder

RUN apk add --no-cache pcre-dev

WORKDIR /app
COPY . .

RUN nimble install -y
RUN nimble build -y -d:release --opt:speed --mm:orc --threads:on

FROM alpine:3.22.2

RUN apk add --no-cache pcre

WORKDIR /app

COPY --from=builder /app/bin/genai_generator ./genai_generator

EXPOSE 3000/tcp

ENTRYPOINT [ "./genai_generator" ]
