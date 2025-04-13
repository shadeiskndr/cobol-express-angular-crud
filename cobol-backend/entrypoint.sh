#!/bin/bash
set -e

# Set environment variables for data file location
export DD_TODO_FILE=/app/data/todos.dat
export DD_USER_FILE=/app/data/users.dat
export DD_SEQUENCE_FILE=/app/data/sequence.dat

# Verify COBOL executable exists
if [ ! -f /app/combined-program ]; then
  echo "COBOL program executable not found, compiling..."
  cobc -x -free -o combined-program combined-program.cbl
fi

# Make sure it's executable
chmod +x /app/combined-program

mkdir -p /app/data
chmod -R 777 /app/data

# Start the Node.js socket server
echo "Starting COBOL Backend server..."
node server.js &

# Keep the container running
echo "COBOL Backend running..."
tail -f /dev/null
