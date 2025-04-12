#!/bin/bash

# Base URL
API_URL="http://localhost:3000/api"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to add delay between requests
wait_between_requests() {
  echo -e "${RED}Waiting 2 seconds before next request...${NC}"
  sleep 2
}

echo -e "${GREEN}Starting Multi-User API tests...${NC}"

# Login as User A
echo -e "\n${BLUE}Logging in as User A...${NC}"
LOGIN_A_RESPONSE=$(curl -s -X POST "$API_URL/users/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "userA@example.com",
    "password": "passwordA123"
  }')
echo $LOGIN_A_RESPONSE

# Register User A
echo -e "\n${BLUE}Registering User A...${NC}"
REGISTER_A_RESPONSE=$(curl -s -X POST "$API_URL/users/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "userA",
    "email": "userA@example.com",
    "password": "passwordA123"
  }')
echo $REGISTER_A_RESPONSE
wait_between_requests

# Register User B
echo -e "\n${BLUE}Registering User B...${NC}"
REGISTER_B_RESPONSE=$(curl -s -X POST "$API_URL/users/register" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "userB",
    "email": "userB@example.com",
    "password": "passwordB123"
  }')
echo $REGISTER_B_RESPONSE
wait_between_requests

# Login as User A
echo -e "\n${BLUE}Logging in as User A...${NC}"
LOGIN_A_RESPONSE=$(curl -s -X POST "$API_URL/users/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "userA@example.com",
    "password": "passwordA123"
  }')
echo $LOGIN_A_RESPONSE

# Extract token for User A
TOKEN_A=$(echo $LOGIN_A_RESPONSE | grep -o '"token":"[^"]*' | sed 's/"token":"//')
echo -e "\nToken A: $TOKEN_A"
wait_between_requests

# List User A's todos
echo -e "\n${BLUE}Listing User A's todos:${NC}"
curl -s -X GET "$API_URL/todos" \
  -H "Authorization: Bearer $TOKEN_A"
wait_between_requests

# Create todos for User A
echo -e "\n${BLUE}Creating todos for User A...${NC}"
# Todo 1 for User A - PENDING
curl -s -X POST "$API_URL/todos" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN_A" \
  -d '{
    "id": 2001,
    "description": "User A - PENDING todo",
    "dueDate": "2025-05-01",
    "estimatedTime": 60,
    "status": "PENDING"
  }'
wait_between_requests

# Todo 2 for User A - IN_PROGRESS
curl -s -X POST "$API_URL/todos" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN_A" \
  -d '{
    "id": 2002,
    "description": "User A - IN_PROGRESS todo",
    "dueDate": "2025-05-02",
    "estimatedTime": 120,
    "status": "IN_PROGRESS"
  }'
wait_between_requests

# List User A's todos
echo -e "\n${BLUE}Listing User A's todos:${NC}"
curl -s -X GET "$API_URL/todos" \
  -H "Authorization: Bearer $TOKEN_A"
wait_between_requests

# "Log out" User A (just stop using the token)
echo -e "\n${YELLOW}Logging out User A...${NC}"

# Login as User B
echo -e "\n${BLUE}Logging in as User B...${NC}"
LOGIN_B_RESPONSE=$(curl -s -X POST "$API_URL/users/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "userB@example.com",
    "password": "passwordB123"
  }')
echo $LOGIN_B_RESPONSE

# Extract token for User B
TOKEN_B=$(echo $LOGIN_B_RESPONSE | grep -o '"token":"[^"]*' | sed 's/"token":"//')
echo -e "\nToken B: $TOKEN_B"
wait_between_requests

# List User B's todos
echo -e "\n${BLUE}Listing User B's todos:${NC}"
curl -s -X GET "$API_URL/todos" \
  -H "Authorization: Bearer $TOKEN_B"
wait_between_requests

# Create todos for User B
echo -e "\n${BLUE}Creating todos for User B...${NC}"
# Todo 1 for User B - PENDING
curl -s -X POST "$API_URL/todos" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN_B" \
  -d '{
    "id": 3001,
    "description": "User B - PENDING todo",
    "dueDate": "2025-06-01",
    "estimatedTime": 45,
    "status": "PENDING"
  }'
wait_between_requests

# Todo 2 for User B - IN_PROGRESS
curl -s -X POST "$API_URL/todos" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN_B" \
  -d '{
    "id": 3002,
    "description": "User B - IN_PROGRESS todo",
    "dueDate": "2025-06-02",
    "estimatedTime": 90,
    "status": "IN_PROGRESS"
  }'
wait_between_requests

# List User B's todos
echo -e "\n${BLUE}Listing User B's todos:${NC}"
curl -s -X GET "$API_URL/todos" \
  -H "Authorization: Bearer $TOKEN_B"
wait_between_requests

# Search todos as User B - should only see User B's todos with status PENDING
echo -e "\n${YELLOW}Testing todo search as User B (status=PENDING)...${NC}"
echo -e "${YELLOW}Expected: Only User B's PENDING todos should appear${NC}"
curl -s -X POST "$API_URL/todos/search" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN_B" \
  -d '{
    "status": "PENDING"
  }'
wait_between_requests

# Search todos as User B - should only see User B's todos with status IN_PROGRESS
echo -e "\n${YELLOW}Testing todo search as User B (status=IN_PROGRESS)...${NC}"
echo -e "${YELLOW}Expected: Only User B's IN_PROGRESS todos should appear${NC}"
curl -s -X POST "$API_URL/todos/search" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN_B" \
  -d '{
    "status": "IN_PROGRESS"
  }'
wait_between_requests

# "Log out" User B (just stop using the token)
echo -e "\n${YELLOW}Logging out User B...${NC}"

# Login as User A again
echo -e "\n${BLUE}Logging in as User A again...${NC}"
LOGIN_A_RESPONSE=$(curl -s -X POST "$API_URL/users/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "userA@example.com",
    "password": "passwordA123"
  }')

# Extract token for User A
TOKEN_A=$(echo $LOGIN_A_RESPONSE | grep -o '"token":"[^"]*' | sed 's/"token":"//')
echo -e "\nToken A: $TOKEN_A"
wait_between_requests

# Search todos as User A - should only see User A's todos with status PENDING
echo -e "\n${YELLOW}Testing todo search as User A (status=PENDING)...${NC}"
echo -e "${YELLOW}Expected: Only User A's PENDING todos should appear${NC}"
curl -s -X POST "$API_URL/todos/search" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN_A" \
  -d '{
    "status": "PENDING"
  }'
wait_between_requests

# Search todos as User A - should only see User A's todos with status IN_PROGRESS
echo -e "\n${YELLOW}Testing todo search as User A (status=IN_PROGRESS)...${NC}"
echo -e "${YELLOW}Expected: Only User A's IN_PROGRESS todos should appear${NC}"
curl -s -X POST "$API_URL/todos/search" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN_A" \
  -d '{
    "status": "IN_PROGRESS"
  }'
wait_between_requests

# Clean up - delete User A's todos
echo -e "\n${BLUE}Cleaning up - deleting User A's todos...${NC}"
curl -s -X DELETE "$API_URL/todos/2001" \
  -H "Authorization: Bearer $TOKEN_A"
wait_between_requests

curl -s -X DELETE "$API_URL/todos/2002" \
  -H "Authorization: Bearer $TOKEN_A"
wait_between_requests

# Clean up - delete User B's todos
echo -e "\n${BLUE}Cleaning up - deleting User B's todos...${NC}"
curl -s -X DELETE "$API_URL/todos/3001" \
  -H "Authorization: Bearer $TOKEN_B"
wait_between_requests

curl -s -X DELETE "$API_URL/todos/3002" \
  -H "Authorization: Bearer $TOKEN_B"
wait_between_requests

echo -e "\n${GREEN}Multi-User Tests completed!${NC}"
