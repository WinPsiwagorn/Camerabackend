# Motion Detection Microservice - Quick Start

## Build and Run

# Build only motion-detect
docker-compose build motion-detect

# Start motion-detect service
docker-compose up -d motion-detect

# View logs
docker-compose logs -f motion-detect

# Check if running
curl http://localhost:8081/api/detection/health
