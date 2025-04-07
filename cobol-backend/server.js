const net = require("net");
const { spawn } = require("child_process");
const fs = require("fs");

// Configuration
const PORT = 8080;
const COBOL_PROGRAM = "/app/customer-database";

// Create server
const server = net.createServer((socket) => {
  console.log("Express API connected");

  let dataBuffer = "";

  socket.on("data", (data) => {
    dataBuffer += data.toString();

    try {
      // Try to parse as JSON to see if we have complete data
      const payload = JSON.parse(dataBuffer);
      dataBuffer = ""; // Reset buffer after successful parse

      console.log(`Received operation: ${payload.operation}`);
      console.log("Sending to COBOL:", JSON.stringify(payload));

      // Execute COBOL program with the payload
      const cobolProcess = spawn(COBOL_PROGRAM, [], {
        stdio: ["pipe", "pipe", "pipe"],
        cwd: "/app", // Set the working directory explicitly
      });

      let outputData = "";
      let errorData = "";

      cobolProcess.stdout.on("data", (data) => {
        const dataStr = data.toString();
        console.log("Raw COBOL output:", dataStr);
        outputData += dataStr;
      });

      cobolProcess.stderr.on("data", (data) => {
        errorData += data.toString();
      });

      cobolProcess.on("close", (code) => {
        if (code !== 0) {
          console.error(`COBOL process exited with code ${code}: ${errorData}`);
          socket.write(
            JSON.stringify({
              success: false,
              error: `COBOL process exited with code ${code}`,
              details: errorData,
            })
          );
        } else {
          console.log("COBOL process completed successfully");
          // Trim whitespace from the final COBOL output before sending
          const trimmedOutput = outputData.trim();
          console.log("Trimmed COBOL output:", trimmedOutput); // Log trimmed output
          socket.write(trimmedOutput); // Send the trimmed output
        }
        socket.end();
      });

      // Send payload to COBOL program
      cobolProcess.stdin.write(JSON.stringify(payload));
      cobolProcess.stdin.end();
    } catch (e) {
      // If we can't parse as JSON, we've received incomplete data
      // Keep accumulating in the buffer
      if (dataBuffer.length > 10000) {
        // Safety valve - don't allow buffer to grow too large
        socket.write(
          JSON.stringify({
            success: false,
            error: "Request too large",
          })
        );
        socket.end();
        dataBuffer = "";
      }
    }
  });

  socket.on("error", (err) => {
    console.error("Socket error:", err);
  });
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`COBOL server listening on port ${PORT}`);
});
