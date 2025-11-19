const express = require("express");
const router = express.Router();
const deviceController = require("../controllers/deviceController");
const { auth } = require("../middleware/auth");

// All device routes require authentication
router.use(auth);

router.post("/power", deviceController.setPower);
router.post("/buzzer", deviceController.setBuzzer);
router.get("/state", deviceController.getDeviceState);

module.exports = router;
