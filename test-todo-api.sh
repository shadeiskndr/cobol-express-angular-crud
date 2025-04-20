bash:test-todo-api.sh
#!/bin/bash

API_URL="http://localhost:3000/api"
USER_EMAIL="testuser@example.com"
USER_PASS="TestPassword123"
USER_NAME="testuser"

echo "1. Attempt login before registration (should fail)"
curl -s -X POST "$API_URL/users/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$USER_EMAIL\",\"password\":\"$USER_PASS\"}"
echo -e "\n---"

echo "2. Register user"
curl -s -X POST "$API_URL/users/register" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USER_NAME\",\"email\":\"$USER_EMAIL\",\"password\":\"$USER_PASS\"}"
echo -e "\n---"

echo "3. Register same user again (should fail)"
curl -s -X POST "$API_URL/users/register" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USER_NAME\",\"email\":\"$USER_EMAIL\",\"password\":\"$USER_PASS\"}"
echo -e "\n---"

echo "4. Login with wrong password (should fail)"
curl -s -X POST "$API_URL/users/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$USER_EMAIL\",\"password\":\"WrongPassword\"}"
echo -e "\n---"

echo "5. Login with correct password (should succeed)"
LOGIN_RESPONSE=$(curl -s -X POST "$API_URL/users/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$USER_EMAIL\",\"password\":\"$USER_PASS\"}")
echo "$LOGIN_RESPONSE"
echo -e "\n---"

TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*' | grep -o '[^"]*$')
if [ -z "$TOKEN" ]; then
  echo "Failed to get token, aborting further tests."
  exit 1
fi

echo "6. Access profile without token (should fail)"
curl -s -X GET "$API_URL/users/profile"
echo -e "\n---"

echo "7. Access profile with token (should succeed)"
curl -s -X GET "$API_URL/users/profile" \
  -H "Authorization: Bearer $TOKEN"
echo -e "\n---"

echo "8. Create todo without description (should fail)"
curl -s -X POST "$API_URL/todos" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{}"
echo -e "\n---"

echo "9. Create todo with valid data (should succeed)"
TODO_RESPONSE=$(curl -s -X POST "$API_URL/todos" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description":"Test todo from script","status":"PENDING","estimatedTime":30}')
echo "$TODO_RESPONSE"
echo -e "\n---"

TODO_ID=$(echo "$TODO_RESPONSE" | grep -o '"id":[0-9]*' | grep -o '[0-9]*')
if [ -z "$TODO_ID" ]; then
  echo "Failed to create todo, aborting further todo tests."
  exit 1
fi

echo "10. Create todo with invalid token (should fail)"
curl -s -X POST "$API_URL/todos" \
  -H "Authorization: Bearer invalidtoken" \
  -H "Content-Type: application/json" \
  -d '{"description":"Should fail"}'
echo -e "\n---"

echo "11. Get non-existent todo (should fail)"
curl -s -X GET "$API_URL/todos/999999" \
  -H "Authorization: Bearer $TOKEN"
echo -e "\n---"

echo "12. Update non-existent todo (should fail)"
curl -s -X PUT "$API_URL/todos/999999" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description":"Update attempt"}'
echo -e "\n---"

echo "13. Delete non-existent todo (should fail)"
curl -s -X DELETE "$API_URL/todos/999999" \
  -H "Authorization: Bearer $TOKEN"
echo -e "\n---"

echo "14. Delete created todo (should succeed)"
curl -s -X DELETE "$API_URL/todos/$TODO_ID" \
  -H "Authorization: Bearer $TOKEN"
echo -e "\n---"

echo "15. Get deleted todo (should fail)"
curl -s -X GET "$API_URL/todos/$TODO_ID" \
  -H "Authorization: Bearer $TOKEN"
echo -e "\n---"

echo "16. Try to create todo with missing token (should fail)"
curl -s -X POST "$API_URL/todos" \
  -H "Content-Type: application/json" \
  -d '{"description":"No token"}'
echo -e "\n---"

echo "All edge case tests completed."
