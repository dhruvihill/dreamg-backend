const express = require("express");
const router = express.Router();
const verifyUser = require("../../middleware/verifyUser");

router.post("/", verifyUser, (req, res, next) => {
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
          inLine: userId ? false : true,
          fullScreenBanner: userId ? false : true,
          fullScreenVideo: userId ? false : true,
        },
      },
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
