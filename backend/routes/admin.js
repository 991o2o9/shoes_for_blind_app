const express = require("express");
const router = express.Router();
const adminController = require("../controllers/adminController");
const { auth, adminAuth } = require("../middleware/auth");

// All admin routes require authentication and admin role
router.use(auth);
router.use(adminAuth);

router.get("/users", adminController.getAllUsers);

module.exports = router;
