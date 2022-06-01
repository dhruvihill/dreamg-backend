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
        isNotificationEnabled: userId ? false : true,
        isAdEnabled: userId ? false : true,
        adTypes: {
          banner: userId ? false : true,
          video: userId ? false : true,
          inline: userId ? false : true,
          fullscreen: userId ? false : true,
        },
      },
    });
  } catch (error) {
    res.status(400).json({ status: false, message: error.message, data: {} });
  }
});

module.exports = router;
