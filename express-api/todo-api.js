const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const todoService = require("./db-middleware");
const userService = require("./user-middleware");
const { authenticateToken } = require("./auth-middleware");

const app = express();
app.use(bodyParser.json());
app.use(cors());

// Middleware for error handling
const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

// ===== USER ROUTES =====

// Register new user
app.post(
  "/api/users/register",
  asyncHandler(async (req, res) => {
    const userData = req.body;

    if (!userData.username || !userData.email || !userData.password) {
      return res.status(400).json({
        success: false,
        error: "Missing required fields: username, email, password",
      });
    }

    // Generate a unique ID if not provided
    if (!userData.id) {
      userData.id = Math.floor(10000 + Math.random() * 90000); // 5-digit number
    }

    const result = await userService.createUser(userData);

    if (result.success === false) {
      return res.status(400).json(result);
    }

    // Don't return the password
    delete result.password;

    res.status(201).json(result);
  })
);

// Login user
app.post(
  "/api/users/login",
  asyncHandler(async (req, res) => {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        error: "Email and password are required",
      });
    }

    const result = await userService.login(email, password);

    if (result.success === false) {
      return res.status(401).json(result);
    }

    // Generate JWT token
    const token = userService.generateToken(result);

    // Return user data with token
    res.json({
      success: true,
      user: {
        id: result.id,
        username: result.username,
        email: result.email,
      },
      token,
    });
  })
);

// Get user profile
app.get(
  "/api/users/profile",
  authenticateToken,
  asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const result = await userService.getUser(userId);

    if (result.success === false) {
      return res.status(404).json(result);
    }

    // Don't return the password
    delete result.password;

    res.json(result);
  })
);

// Update user profile
app.put(
  "/api/users/profile",
  authenticateToken,
  asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const userData = { ...req.body, id: userId };

    const result = await userService.updateUser(userData);

    if (result.success === false) {
      return res.status(400).json(result);
    }

    res.json(result);
  })
);

// ===== TODO ROUTES =====

// Search todos
app.post(
  "/api/todos/search",
  authenticateToken,
  asyncHandler(async (req, res) => {
    const criteria = { ...req.body, userId: req.user.id };
    const result = await todoService.searchTodos(criteria);
    res.json(result);
  })
);

// GET todo by ID
app.get(
  "/api/todos/:id",
  authenticateToken,
  asyncHandler(async (req, res) => {
    const id = req.params.id;
    const userId = req.user.id;
    const result = await todoService.getTodo(id, userId);

    if (result.success === false) {
      return res.status(404).json(result);
    }

    // Verify the todo belongs to the authenticated user
    if (result.userId && result.userId != userId) {
      return res.status(403).json({
        success: false,
        error: "You don't have permission to access this todo",
      });
    }

    res.json(result);
  })
);

// GET all todos
app.get(
  "/api/todos",
  authenticateToken,
  asyncHandler(async (req, res) => {
    const userId = req.user.id;
    const result = await todoService.listTodos(userId);
    res.json(result);
  })
);

// CREATE new todo
app.post(
  "/api/todos",
  authenticateToken,
  asyncHandler(async (req, res) => {
    const todoData = req.body;

    if (!todoData.description) {
      return res.status(400).json({
        success: false,
        error: "Missing required field: description", // NEW
      });
    }

    // Set default values if not provided
    if (!todoData.status) {
      todoData.status = "PENDING";
    }

    if (!todoData.estimatedTime) {
      todoData.estimatedTime = 0;
    }

    // Associate the todo with the authenticated user - ENSURE NUMERIC FORMAT
    todoData.userId = parseInt(req.user.id, 10);

    // The COBOL backend will generate the ID
    const payloadForCobol = { ...todoData };
    delete payloadForCobol.id; // Ensure no ID is sent

    // Debug output
    console.log(`Creating todo for userId: ${todoData.userId}`);
    console.log(`Payload for COBOL:`, payloadForCobol); // Log what's sent

    const result = await todoService.createTodo(payloadForCobol); // NEW

    if (result.success === false) {
      // Log the raw COBOL error if available
      console.error(
        "COBOL createTodo failed:",
        result.error,
        result.rawOutput || ""
      );
      return res.status(400).json(result);
    }

    // The 'result' should now contain the generated ID from COBOL
    console.log("COBOL createTodo successful, result:", result);
    res.status(201).json(result); // Send the full result back (including generated ID)
  })
);

// UPDATE todo
app.put(
  "/api/todos/:id",
  authenticateToken,
  asyncHandler(async (req, res) => {
    const id = req.params.id;
    const userId = req.user.id;

    // First check if the todo exists and belongs to the user
    const existingTodo = await todoService.getTodo(id, userId);

    if (existingTodo.success === false) {
      return res.status(404).json(existingTodo);
    }

    if (existingTodo.userId && existingTodo.userId != userId) {
      return res.status(403).json({
        success: false,
        error: "You don't have permission to update this todo",
      });
    }

    const todoData = { ...req.body, id, userId };

    const result = await todoService.updateTodo(todoData);

    if (result.success === false) {
      return res.status(404).json(result);
    }

    res.json(result);
  })
);

// DELETE todo
app.delete(
  "/api/todos/:id",
  authenticateToken,
  asyncHandler(async (req, res) => {
    const id = req.params.id;
    const userId = req.user.id;

    // First check if the todo exists and belongs to the user
    const existingTodo = await todoService.getTodo(id, userId);

    if (existingTodo.success === false) {
      return res.status(404).json(existingTodo);
    }

    if (existingTodo.userId && existingTodo.userId != userId) {
      return res.status(403).json({
        success: false,
        error: "You don't have permission to delete this todo",
      });
    }

    const result = await todoService.deleteTodo(id, userId);

    if (result.success === false) {
      return res.status(404).json(result);
    }

    res.json(result);
  })
);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error("Unhandled error:", err);
  res.status(500).json({
    success: false,
    error: "Server error",
    message:
      process.env.NODE_ENV === "production"
        ? "An unexpected error occurred"
        : err.message,
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Todo List API server running on port ${PORT}`);
});
