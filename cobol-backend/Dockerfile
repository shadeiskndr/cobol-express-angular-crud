FROM olegkunitsyn/gnucobol:3.1

WORKDIR /app

# Install Node.js and required dependencies
RUN apk update && apk add --no-cache \
    procps \
    netcat-openbsd \
    nodejs \
    npm

# Copy COBOL programs and compile them
COPY todo-list.cbl .
COPY user-management.cbl .
RUN cobc -x -free -o todo-list todo-list.cbl
RUN cobc -x -free -o user-management user-management.cbl

# Copy server code
COPY server.js .

# Create data directory
RUN mkdir -p /app/data

# Copy and make entrypoint executable
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

# Expose port for socket communication
EXPOSE 8080

CMD ["./entrypoint.sh"]
