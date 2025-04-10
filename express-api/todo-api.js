const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const todoService = require("./db-middleware");

const app = express();
app.use(bodyParser.json());
app.use(cors());

// Middleware for error handling
const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

// Search todos
app.post(
  "/api/todos/search",
  asyncHandler(async (req, res) => {
    const criteria = req.body;
    const result = await todoService.searchTodos(criteria);
    res.json(result);
  })
);

// GET todo by ID
app.get(
  "/api/todos/:id",
  asyncHandler(async (req, res) => {
    const id = req.params.id;
    const result = await todoService.getTodo(id);

    if (result.success === false) {
      return res.status(404).json(result);
    }

    res.json(result);
  })
);

// GET all todos
app.get(
  "/api/todos",
  asyncHandler(async (req, res) => {
    const result = await todoService.listTodos();
    res.json(result);
  })
);

// CREATE new todo
app.post(
  "/api/todos",
  asyncHandler(async (req, res) => {
    const todoData = req.body;

    if (!todoData.id || !todoData.description) {
      return res.status(400).json({
        success: false,
        error: "Missing required fields: id, description",
      });
    }

    // Set default values if not provided
    if (!todoData.status) {
      todoData.status = "PENDING";
    }

    if (!todoData.estimatedTime) {
      todoData.estimatedTime = 0;
    }

    const result = await todoService.createTodo(todoData);

    if (result.success === false) {
      return res.status(400).json(result);
    }

    res.status(201).json(result);
  })
);

// UPDATE todo
app.put(
  "/api/todos/:id",
  asyncHandler(async (req, res) => {
    const id = req.params.id;
    const todoData = { ...req.body, id };

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
  asyncHandler(async (req, res) => {
    const id = req.params.id;
    const result = await todoService.deleteTodo(id);

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
