const net = require("net");
const { spawn } = require("child_process");
const fs = require("fs");

// Configuration
const PORT = 8080;
const COBOL_PROGRAM = "/app/combined-program";

// Helper function to extract valid JSON from a string
function extractValidJson(str) {
  // First try: direct JSON parse (for clean outputs)
  try {
    // Remove any trailing whitespace or null bytes that might be present
    const cleaned = str.trim().replace(/\0+$/, "");
    JSON.parse(cleaned);
    return cleaned; // If it parses, return it directly
  } catch (e) {
    // If direct parse fails, try more advanced extraction
  }

  // Second try: balanced braces approach
  let result = null;
  let depth = 0;
  let startPos = -1;

  // Find the last complete JSON object in the string
  for (let i = 0; i < str.length; i++) {
    if (str[i] === "{") {
      if (depth === 0) {
        startPos = i;
      }
      depth++;
    } else if (str[i] === "}") {
      depth--;
      if (depth === 0 && startPos !== -1) {
        // Found a complete JSON object
        const potentialJson = str.substring(startPos, i + 1);
        try {
          // Verify it's valid JSON
          JSON.parse(potentialJson);
          result = potentialJson;
          // Don't break - continue to find the last valid JSON
        } catch (e) {
          console.log(
            "Found invalid JSON object:",
            potentialJson.substring(0, 50) + "..."
          );
        }
      }
    }
  }

  return result;
}

// Helper function to clean up JSON numbers and fix common issues
function cleanupJsonNumbers(jsonString) {
  // First replace numeric IDs with leading zeros
  let cleaned = jsonString.replace(/"id":0+(\d+)/g, '"id":$1');
  cleaned = cleaned.replace(/"userId":0+(\d+)/g, '"userId":$1');
  cleaned = cleaned.replace(/"estimatedTime":0+(\d+)/g, '"estimatedTime":$1');

  // Fix missing values
  cleaned = cleaned.replace(/"estimatedTime":,/g, '"estimatedTime":0,');
  cleaned = cleaned.replace(/"estimatedTime":}/g, '"estimatedTime":0}');

  // Fix truncated status values
  cleaned = cleaned.replace(/"status":"IN_PROGRES"/g, '"status":"IN_PROGRESS"');

  // Fix any other common issues
  cleaned = cleaned.replace(/:,/g, ":null,");
  cleaned = cleaned.replace(/:}/g, ":null}");

  return cleaned;
}

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
      console.log("Environment variables:");
      console.log("DD_TODO_FILE:", process.env.DD_TODO_FILE);
      console.log("DD_USER_FILE:", process.env.DD_USER_FILE);

      // Execute COBOL program with the payload
      console.log("Spawning COBOL process with path:", COBOL_PROGRAM);
      const cobolProcess = spawn(COBOL_PROGRAM, [], {
        stdio: ["pipe", "pipe", "pipe"],
        cwd: "/app", // Set the working directory explicitly
        env: { ...process.env }, // Pass all environment variables
      });

      let outputData = "";
      let errorData = "";

      cobolProcess.stdout.on("data", (data) => {
        const dataStr = data.toString();
        console.log("Raw COBOL output:", dataStr);
        outputData += dataStr;
      });

      cobolProcess.stderr.on("data", (data) => {
        console.error("COBOL stderr:", data.toString());
        errorData += data.toString();
      });

      // Add explicit error handler for the COBOL process
      cobolProcess.on("error", (error) => {
        console.error("COBOL process error:", error.toString());
        errorData += error.toString();
      });

      cobolProcess.on("close", (code, signal) => {
        console.log(
          `COBOL process exited with code ${code}, and signal: ${signal}`
        );

        if (code !== 0 || signal) {
          console.error(
            `COBOL process failed: code=${code}, signal=${signal}, error=${errorData}`
          );

          // More detailed error response
          socket.write(
            JSON.stringify({
              success: false,
              error: `COBOL process failed with code ${code}${
                signal ? ` and signal ${signal}` : ""
              }`,
              details: errorData || "No error details available",
              operation: payload.operation,
            })
          );
        } else {
          console.log("COBOL process completed successfully");

          // Extract valid JSON from the output
          try {
            // Try to extract valid JSON
            const validJson = extractValidJson(outputData);

            if (validJson) {
              // Clean up the JSON to fix number formatting
              const jsonOutput = cleanupJsonNumbers(validJson);

              try {
                // Test if it's valid JSON after cleaning
                JSON.parse(jsonOutput);
                console.log(
                  "Successfully extracted and cleaned JSON output:",
                  jsonOutput
                );
                socket.write(jsonOutput);
              } catch (e) {
                console.error("Failed to parse cleaned JSON:", e.message);
                socket.write(
                  JSON.stringify({
                    success: false,
                    error: "Failed to parse COBOL output: " + e.message,
                    rawOutput: validJson.substring(0, 200),
                  })
                );
              }
            } else {
              // No valid JSON found - try a more aggressive approach with regex
              const jsonRegex = /(\{[\s\S]*?\})/g;
              const matches = [...outputData.matchAll(jsonRegex)];

              if (matches.length > 0) {
                // Get the last match (most likely the actual response)
                let lastJsonCandidate = matches[matches.length - 1][0];

                // Clean up and try to parse
                lastJsonCandidate = cleanupJsonNumbers(lastJsonCandidate);

                try {
                  JSON.parse(lastJsonCandidate);
                  console.log(
                    "Found JSON using regex fallback:",
                    lastJsonCandidate
                  );
                  socket.write(lastJsonCandidate);
                } catch (e) {
                  console.error(
                    "Failed to parse JSON from regex fallback:",
                    e.message
                  );
                  socket.write(
                    JSON.stringify({
                      success: false,
                      error: "Failed to extract valid JSON from COBOL output",
                      rawOutput: outputData.substring(0, 200),
                    })
                  );
                }
              } else {
                // No JSON found at all
                socket.write(
                  JSON.stringify({
                    success: false,
                    error: "No JSON found in COBOL output",
                    rawOutput: outputData.substring(0, 200),
                  })
                );
              }
            }
          } catch (e) {
            console.error("Error processing COBOL output:", e);
            const jsonOutput = JSON.stringify({
              success: false,
              error: "Failed to process COBOL output",
              exception: e.message,
              rawOutput: outputData.substring(0, 200),
            });
            socket.write(jsonOutput);
          }
        }
        socket.end();
      });

      // Set a timeout for the COBOL process
      const timeout = setTimeout(() => {
        console.error("COBOL process timed out after 10 seconds");
        cobolProcess.kill();
        socket.write(
          JSON.stringify({
            success: false,
            error: "COBOL process timed out",
            operation: payload.operation,
          })
        );
        socket.end();
      }, 10000);

      // Clear the timeout if the process completes
      cobolProcess.on("close", () => {
        clearTimeout(timeout);
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
