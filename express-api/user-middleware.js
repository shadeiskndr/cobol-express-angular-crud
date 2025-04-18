const net = require("net");
const jwt = require("jsonwebtoken");

// Secret key for JWT
const JWT_SECRET = process.env.JWT_SECRET;

class UserService {
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
        console.log("Connected to COBOL backend for user operation");
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

  async getUser(id) {
    return this.executeOperation("GET_USER", { id });
  }

  async createUser(userData) {
    return this.executeOperation("CREATE_USER", userData);
  }

  async updateUser(userData) {
    return this.executeOperation("UPDATE_USER", userData);
  }

  async deleteUser(id) {
    return this.executeOperation("DELETE_USER", { id });
  }

  async listUsers() {
    return this.executeOperation("LIST_USERS");
  }

  async login(email, password) {
    return this.executeOperation("LOGIN", { email, password });
  }

  // JWT token generation
  generateToken(user) {
    return jwt.sign(
      {
        id: user.id,
        email: user.email,
        username: user.username,
      },
      JWT_SECRET,
      { expiresIn: "1h" }
    );
  }

  // JWT token verification
  verifyToken(token) {
    try {
      return jwt.verify(token, JWT_SECRET);
    } catch (error) {
      return null;
    }
  }
}

module.exports = new UserService();
