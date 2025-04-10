#!/bin/bash

# Base URL
API_URL="http://localhost:3000/api"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to add delay between requests
wait_between_requests() {
  echo -e "${RED}Waiting 2 seconds before next request...${NC}"
  sleep 2
}

echo "Starting API tests..."

# Register user
echo -e "\n${GREEN}Testing user registration...${NC}"
REGISTER_RESPONSE=$(curl -s -X POST "$API_URL/users/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "password123"
  }')
echo $REGISTER_RESPONSE
wait_between_requests

# Login
echo -e "\n${GREEN}Testing user login...${NC}"
echo "Email: test@example.com"
echo "Password: password123"
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/users/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }')
echo $LOGIN_RESPONSE

# Extract token
TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*' | sed 's/"token":"//')
echo -e "\nToken: $TOKEN"
wait_between_requests

# Get user profile
echo -e "\n${GREEN}Testing get user profile...${NC}"
curl -s -X GET "$API_URL/users/profile" \
  -H "Authorization: Bearer $TOKEN"
wait_between_requests

# Create todo
echo -e "\n${GREEN}Testing todo creation...${NC}"
curl -s -X POST "$API_URL/todos" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "id": 1001,
    "description": "Test todo item",
    "dueDate": "2025-05-01",
    "estimatedTime": 120,
    "status": "PENDING"
  }'
wait_between_requests

# List todos
echo -e "\n${GREEN}Testing todo listing...${NC}"
curl -s -X GET "$API_URL/todos" \
  -H "Authorization: Bearer $TOKEN"
wait_between_requests

# Get specific todo
echo -e "\n${GREEN}Testing get specific todo...${NC}"
curl -s -X GET "$API_URL/todos/1001" \
  -H "Authorization: Bearer $TOKEN"
wait_between_requests

# Update todo
echo -e "\n${GREEN}Testing todo update...${NC}"
curl -s -X PUT "$API_URL/todos/1001" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "description": "Updated todo item",
    "status": "IN_PROGRESS"
  }'
wait_between_requests

# Search todos
echo -e "\n${GREEN}Testing todo search...${NC}"
curl -s -X POST "$API_URL/todos/search" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "status": "IN_PROGRESS",
    "minTime": 100,
    "maxTime": 200
  }'
wait_between_requests

# Delete todo
echo -e "\n${GREEN}Testing todo deletion...${NC}"
curl -s -X DELETE "$API_URL/todos/1001" \
  -H "Authorization: Bearer $TOKEN"
wait_between_requests

# Test authentication failure
echo -e "\n${GREEN}Testing authentication failure...${NC}"
curl -s -X GET "$API_URL/todos"

echo -e "\n${GREEN}Tests completed!${NC}"
