#!/bin/bash
set -e

# Set environment variables for data file location
export DD_TODO_FILE=/app/data/todos.dat
export DD_USER_FILE=/app/data/users.dat

# Verify COBOL executables exist
if [ ! -f /app/todo-list ]; then
  echo "COBOL todo-list executable not found, recompiling..."
  cobc -x -free -o todo-list todo-list.cbl
fi

if [ ! -f /app/user-management ]; then
  echo "COBOL user-management executable not found, recompiling..."
  cobc -x -free -o user-management user-management.cbl
fi

# Make sure they're executable
chmod +x /app/todo-list
chmod +x /app/user-management

# Start the Node.js socket server
echo "Starting COBOL Backend server..."
node server.js &

# Keep the container running
echo "COBOL Backend running..."
tail -f /dev/null
