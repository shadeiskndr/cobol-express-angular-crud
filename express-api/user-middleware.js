const net = require("net");
const jwt = require("jsonwebtoken");

// Secret key for JWT
const JWT_SECRET =
  process.env.JWT_SECRET ||
  "66c3b5554dedf8a063401cb1f9216ac6238bbb081ac646a39e014716eff079ebdb3d0b3024660a939ee80ca03c8ca693a8267427118589ef94d7e4e3b5460018a8870eb1471ed44002f33e33a1ef8e3836988344366876829b2c29a3ad94e7ae4f3105c743e9dc76e60fadaebff4b60bde58ef22ea6c9215bcaf15f344c7d394b1e9d40c05cc7f538768595a9b903b485c3a338daffac2029e2ce4109232bcf6b00e1d17d18cff716131661c494195a49ab876102076e08637687dba23f10dd9d9288d97adec14fb7c73a02eaef3aef08905cca71b22a69f72ea6d7a32aa5b7a08adaeba1564d56c239b2f5e7807404ec7472c42d7b298b4aba8faddf4836f94";

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
      { expiresIn: "24h" }
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
