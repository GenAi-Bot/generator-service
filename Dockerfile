FROM nimlang/nim:alpine

RUN apk update
RUN apk add --no-cache pcre-dev

WORKDIR /app
COPY . .

RUN ["nimble", "-y", "--mm:orc", "-d:release", "--opt:speed", "build"]

EXPOSE 3000/tcp

ENTRYPOINT [ "./bin/genai_generator" ]
