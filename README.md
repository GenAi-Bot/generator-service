# genai-generator-service
Generator service for GenAi Discord bot

## Usage
0. This service requires a redis server (for rate limiting)
1. Clone the repository
2. Build the docker image `docker build -t genai-generator-service .`
3. Run the docker image and expose port 3000 `docker run -v $(pwd)/messages:/data/messages -e REDIS_HOST=cool_redis_db REDIS_PORT=6379 --network cool-network -p 127.0.0.1:3000:3000 genai-generator-service` (mount the messages folder to the container if you are using LocalKeeper or another data keeper that uses local files)
4. gg