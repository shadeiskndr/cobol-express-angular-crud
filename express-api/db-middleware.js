const net = require("net");
const fs = require("fs");
const path = require("path");

class TodoListService {
  constructor() {}

  async executeOperation(operation, data = {}) {
    return new Promise((resolve, reject) => {
      // Prepare request payload
      const payload = {
        operation,
        ...data,
      };

      const client = new net.Socket();
      let responseData = "";

      client.connect(8080, "cobol-backend", () => {
        console.log("Connected to COBOL backend");
        client.write(JSON.stringify(payload));
      });

      client.on("data", (data) => {
        responseData += data.toString();
      });

      client.on("close", () => {
        try {
          // First, check if the response contains debug output mixed with JSON
          if (responseData.includes("DEBUG:")) {
            console.log("Response contains debug output, cleaning...");
            // Extract only the JSON part (assuming it's at the beginning or end)
            const jsonMatch = responseData.match(/(\{.*\})/s);
            if (jsonMatch) {
              responseData = jsonMatch[0];
            }
          }

          // Clean up numeric values with leading zeros before parsing
          responseData = responseData
            .replace(/"id":0+(\d+)/g, '"id":$1')
            .replace(/"userId":0+(\d+)/g, '"userId":$1')
            .replace(/"estimatedTime":0+(\d+)/g, '"estimatedTime":$1');

          // Try to parse the JSON
          let result;
          try {
            result = JSON.parse(responseData);
          } catch (parseError) {
            // If parsing fails, try to extract just the JSON part
            const jsonMatch = responseData.match(/(\{.*\})/s);
            if (jsonMatch) {
              const extractedJson = jsonMatch[0]
                .replace(/"id":0+(\d+)/g, '"id":$1')
                .replace(/"userId":0+(\d+)/g, '"userId":$1')
                .replace(/"estimatedTime":0+(\d+)/g, '"estimatedTime":$1');

              result = JSON.parse(extractedJson);
            } else {
              throw parseError;
            }
          }

          resolve(result);
        } catch (err) {
          console.error(
            `Failed to parse COBOL output: ${err.message}. Raw output: ${responseData}`
          );
          // Return a structured error object instead of throwing
          resolve({
            success: false,
            error: `Failed to parse COBOL output: ${err.message}`,
            rawOutput: responseData.substring(0, 200), // Include part of the raw output for debugging
          });
        }
      });

      client.on("error", (err) => {
        reject(new Error(`Connection to COBOL backend failed: ${err.message}`));
      });

      // Set timeout for connection
      client.setTimeout(10000);
      client.on("timeout", () => {
        client.destroy();
        reject(new Error("Connection to COBOL backend timed out"));
      });
    });
  }

  async getTodo(id, userId) {
    return this.executeOperation("GET", { id, userId });
  }

  async createTodo(todoData) {
    return this.executeOperation("CREATE", todoData);
  }

  async updateTodo(todoData) {
    return this.executeOperation("UPDATE", todoData);
  }

  async deleteTodo(id, userId) {
    return this.executeOperation("DELETE", { id, userId });
  }

  async listTodos(userId) {
    return this.executeOperation("LIST", { userId });
  }

  // Advanced features
  async searchTodos(criteria) {
    return this.executeOperation("SEARCH", criteria);
  }
}

module.exports = new TodoListService();
