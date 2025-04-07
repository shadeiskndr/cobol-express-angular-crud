const net = require("net");
const fs = require("fs");
const path = require("path");

class CustomerDatabaseService {
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
          const result = JSON.parse(responseData);
          resolve(result);
        } catch (err) {
          reject(
            new Error(
              `Failed to parse COBOL output: ${err.message}. Raw output: ${responseData}`
            )
          );
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

  async getCustomer(id) {
    return this.executeOperation("GET", { id });
  }

  async createCustomer(customerData) {
    return this.executeOperation("CREATE", customerData);
  }

  async updateCustomer(customerData) {
    return this.executeOperation("UPDATE", customerData);
  }

  async deleteCustomer(id) {
    return this.executeOperation("DELETE", { id });
  }

  async listCustomers() {
    return this.executeOperation("LIST");
  }

  // Advanced features
  async searchCustomers(criteria) {
    return this.executeOperation("SEARCH", criteria);
  }

  async getCustomerTransactions(id) {
    return this.executeOperation("TRANSACTIONS", { id });
  }
}

module.exports = new CustomerDatabaseService();
