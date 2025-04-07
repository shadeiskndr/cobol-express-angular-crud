const express = require("express");
const bodyParser = require("body-parser");
const cors = require("cors");
const customerDB = require("./db-middleware");

const app = express();
app.use(bodyParser.json());
app.use(cors());

// Middleware for error handling
const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

// GET customer by ID
app.get(
  "/api/customers/:id",
  asyncHandler(async (req, res) => {
    const id = req.params.id;
    const result = await customerDB.getCustomer(id);

    if (result.success === false) {
      return res.status(404).json(result);
    }

    res.json(result);
  })
);

// GET all customers
app.get(
  "/api/customers",
  asyncHandler(async (req, res) => {
    const result = await customerDB.listCustomers();
    res.json(result);
  })
);

// CREATE new customer
app.post(
  "/api/customers",
  asyncHandler(async (req, res) => {
    const customerData = req.body;

    if (!customerData.id || !customerData.name || !customerData.email) {
      return res.status(400).json({
        success: false,
        error: "Missing required fields: id, name, email",
      });
    }

    const result = await customerDB.createCustomer(customerData);

    if (result.success === false) {
      return res.status(400).json(result);
    }

    res.status(201).json(result);
  })
);

// UPDATE customer
app.put(
  "/api/customers/:id",
  asyncHandler(async (req, res) => {
    const id = req.params.id;
    const customerData = { ...req.body, id };

    const result = await customerDB.updateCustomer(customerData);

    if (result.success === false) {
      return res.status(404).json(result);
    }

    res.json(result);
  })
);

// DELETE customer
app.delete(
  "/api/customers/:id",
  asyncHandler(async (req, res) => {
    const id = req.params.id;
    const result = await customerDB.deleteCustomer(id);

    if (result.success === false) {
      return res.status(404).json(result);
    }

    res.json(result);
  })
);

// Search customers (advanced feature)
app.post(
  "/api/customers/search",
  asyncHandler(async (req, res) => {
    const criteria = req.body;
    const result = await customerDB.searchCustomers(criteria);
    res.json(result);
  })
);

// Get customer transactions (advanced feature)
app.get(
  "/api/customers/:id/transactions",
  asyncHandler(async (req, res) => {
    const id = req.params.id;
    const result = await customerDB.getCustomerTransactions(id);

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
  console.log(`Server running on port ${PORT}`);
});
