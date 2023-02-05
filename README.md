# genai-generator-service
Generator service for GenAi Discord bot

## Usage
1. Clone the repository
2. Build the docker image `docker build -t genai-generator-service .`
3. Run the docker image and expose port 3000 `docker run -v $(pwd)/messages:/data/messages -p 127.0.0.1:3000:3000 genai-generator-service` (mount the messages folder to the container if you are using LocalDataKeeper or another data keeper that uses local files)
4. gg