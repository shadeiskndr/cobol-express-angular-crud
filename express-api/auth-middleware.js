const userService = require("./user-middleware");

// Middleware to authenticate JWT token
const authenticateToken = (req, res, next) => {
  // Get the token from the Authorization header
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1]; // Bearer TOKEN format

  if (!token) {
    return res.status(401).json({
      success: false,
      error: "Authentication required",
    });
  }

  // Verify the token
  const user = userService.verifyToken(token);
  if (!user) {
    return res.status(403).json({
      success: false,
      error: "Invalid or expired token",
    });
  }

  // Add the user info to the request object
  req.user = user;
  next();
};

module.exports = { authenticateToken };
