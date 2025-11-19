const User = require("../models/User");

exports.getAllUsers = async (req, res) => {
  try {
    const users = await User.find({}, "login role lastLogin createdAt").sort({
      createdAt: -1,
    });

    res.json({
      users: users.map((user) => ({
        id: user._id,
        login: user.login,
        role: user.role,
        lastLogin: user.lastLogin,
        createdAt: user.createdAt,
      })),
    });
  } catch (error) {
    res.status(500).json({ error: "Server error" });
  }
};
