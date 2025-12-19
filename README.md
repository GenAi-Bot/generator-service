## Project moved to GitLab
If you want to track new updates, check [GitLab repository](https://gitlab.com/genai-bot/generator-service) (and an org as a whole, if that's interested you)

# genai-generator-service
Generator service for GenAi Discord bot

## `keeper` module disclaimer
Implementation of `getMessages` (for `kkLocal`) is made for an abstract usage. If you are using this program in your project (like Discord bot), make sure to store encrypted messages and modify `keepers.nim` to decrypt lines of messages in `getMessages` method (more information in [keepers.nim](src/keepers.nim))

## Usage
#### Environment variables:
* `PORT` - which port should be taken by this application (defualt `3000`)
* `MAX_ATTEMPTS` - how much generator can attempt to re-generate text in case of failure (default `5`)
* `MAX_LINES` - how much messages/lines application should request from keeper (default `-1` - all messages)

##### Redis related
* `REDIS_HOST` - address of Redis server (optional, if not specified - rate limit will be ignored)
* `REDIS_PORT` - port of Redis server (default `6379`)

##### Keeper related
* `KEEPER_URL` - URL address of remote messages storage (optional, should include placeholders: `{channel_id}`, `{max_lines}` and `{clean_uri}`)
* `KEEPER_PATH` - path to folder with `{channel_id}.txt` messages files (default `/data/messages`, ignored if `KEEPER_URL` specified)


1. Clone the repository
2. Build the docker image `docker build -t genai/message-generator .`
3. Run the docker image and expose port 3000 `docker run -v $(pwd)/messages:/data/messages -p 127.0.0.1:3000:3000 genai/message-generator`
4. gg
