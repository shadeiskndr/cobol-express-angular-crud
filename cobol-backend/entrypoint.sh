#!/bin/bash
set -e

# Set environment variables for data file location
export DD_CUSTOMER_FILE=/app/data/customers.dat
export DD_TRANSACTION_FILE=/app/data/transactions.dat

# Verify COBOL executable exists
if [ ! -f /app/customer-database ]; then
  echo "COBOL executable not found, recompiling..."
  cobc -x -free -o customer-database customer-database.cbl
fi

# Make sure it's executable
chmod +x /app/customer-database

# Start the Node.js socket server
echo "Starting COBOL Backend server..."
node server.js &

# Keep the container running
echo "COBOL Backend running..."
tail -f /dev/null
