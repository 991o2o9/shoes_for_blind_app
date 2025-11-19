// In a real implementation, this would communicate with Arduino via Bluetooth
// For now, we'll simulate the device state

let deviceState = {
  power: false,
  buzzer: false,
};

exports.setPower = async (req, res) => {
  try {
    const { state } = req.body;

    if (typeof state !== "boolean") {
      return res.status(400).json({ error: "State must be boolean" });
    }

    deviceState.power = state;

    // Here you would send command to Arduino via Bluetooth
    // For now, just log the action
    console.log(`Device power set to: ${state}`);

    res.json({
      success: true,
      state: deviceState.power,
      message: `Device ${state ? "turned ON" : "turned OFF"}`,
    });
  } catch (error) {
    res.status(500).json({ error: "Server error" });
  }
};

exports.setBuzzer = async (req, res) => {
  try {
    const { state } = req.body;

    if (typeof state !== "boolean") {
      return res.status(400).json({ error: "State must be boolean" });
    }

    deviceState.buzzer = state;

    // Here you would send command to Arduino via Bluetooth
    // For now, just log the action
    console.log(`Buzzer set to: ${state}`);

    res.json({
      success: true,
      state: deviceState.buzzer,
      message: `Buzzer ${state ? "turned ON" : "turned OFF"}`,
    });
  } catch (error) {
    res.status(500).json({ error: "Server error" });
  }
};

exports.getDeviceState = async (req, res) => {
  res.json({
    power: deviceState.power,
    buzzer: deviceState.buzzer,
  });
};
