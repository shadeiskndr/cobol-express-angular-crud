#!/bin/bash
set -e

# Set environment variables for data file location
export DD_TODO_FILE=/app/data/todos.dat

# Verify COBOL executable exists
if [ ! -f /app/todo-list ]; then
  echo "COBOL executable not found, recompiling..."
  cobc -x -free -o todo-list todo-list.cbl
fi

# Make sure it's executable
chmod +x /app/todo-list

# Start the Node.js socket server
echo "Starting COBOL Backend server..."
node server.js &

# Keep the container running
echo "COBOL Backend running..."
tail -f /dev/null
