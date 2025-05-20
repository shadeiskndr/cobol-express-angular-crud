FROM olegkunitsyn/gnucobol:3.1

WORKDIR /app

# Fix Alpine 3.12 repositories (use archive mirror)
RUN sed -i 's|dl-cdn.alpinelinux.org|dl-4.alpinelinux.org|g' /etc/apk/repositories && \
    apk update && apk add --no-cache \
    procps \
    netcat-openbsd \
    nodejs \
    npm \
    dos2unix

# Copy COBOL program
COPY combined-program.cbl .
RUN cobc -x -free -o combined-program combined-program.cbl

# Copy server code
COPY server.js .

# Copy and fix entrypoint script
COPY entrypoint.sh .
RUN dos2unix entrypoint.sh && chmod +x entrypoint.sh

# Create data directory
RUN mkdir -p /app/data

EXPOSE 8080

CMD ["./entrypoint.sh"]