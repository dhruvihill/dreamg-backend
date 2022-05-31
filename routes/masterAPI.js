const express = require("express");
const router = express.Router();
const verifyUser = require("../middleware/verifyUser");

router.post("/", verifyUser, (req, res) => {
  try {
    const { userId } = req.body;

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        appVersion: "1.0.0",
        isNotificationEnabled: true,
        isAdEnabled: true,
        adTypes: {
          banner: true,
          video: true,
          inline: true,
          fullscreen: true,
        },
      },
    });
  } catch (error) {
    res.status(400).json({ status: false, message: error.message, data: {} });
  }
});

module.exports = router;
