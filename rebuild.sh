#!/bin/bash

echo "Rebuilding and restarting containers..."

# Stop containers and remove volumes
docker-compose down -v

# Rebuild containers
docker-compose build cobol-backend express-api

# Start containers
docker-compose up -d

echo "Containers and volumes rebuilt and restarted!"
