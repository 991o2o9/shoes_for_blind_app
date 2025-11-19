const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const dotenv = require("dotenv");

dotenv.config();

const app = express();

// Middleware
app.use(
  cors({
    origin: [
      "http://localhost:3000",
      "http://localhost:41296",
      "http://127.0.0.1:3000",
      "http://127.0.0.1:41296",
      "http://192.168.0.110:3000", // Ваш IP адрес
    ],
    credentials: true,
  })
);
app.use(express.json());

// Connect to MongoDB
mongoose
  .connect(process.env.MONGO_URL)
  .then(() => {
    console.log("Connected to MongoDB");
    createDefaultAdmin();
  })
  .catch((err) => console.error("MongoDB connection error:", err));

// Routes
app.use("/auth", require("./routes/auth"));
app.use("/admin", require("./routes/admin"));
app.use("/device", require("./routes/device"));

const PORT = process.env.PORT || 3000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT} on all interfaces`);
});

// Create default admin user
async function createDefaultAdmin() {
  const User = require("./models/User");
  try {
    const adminExists = await User.findOne({ login: "admin" });
    if (!adminExists) {
      const bcrypt = require("bcryptjs");
      const hashedPassword = await bcrypt.hash("admin123", 10);

      await User.create({
        login: "admin",
        password: hashedPassword,
        role: "admin",
        lastLogin: new Date(),
      });
      console.log("Default admin user created");
    }
  } catch (error) {
    console.error("Error creating default admin:", error);
  }
}
