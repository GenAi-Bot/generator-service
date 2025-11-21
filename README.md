# genai-generator-service
Generator service for GenAi Discord bot

## Licensing
There is no license in this repository as this is open source for evaluation purposes only, use in commercial/personal applications is prohibited (excluding [GenAi bot project](https://genai.bot/))

## Usage
0. This service can be used with Redis for rate limiting
1. Clone the repository
2. Build the docker image `docker build -t genai/message-generator .`
3. Run the docker image and expose port 3000 `docker run -v $(pwd)/messages:/data/messages --network cool-network -p 127.0.0.1:3000:3000 genai/message-generator` (declare `REDIS_HOST` and `REDIS_PORT` environment variables if using redis; mount the messages folder to the container if you are using `LocalKeeper` or another data keeper that uses local files)
4. gg
