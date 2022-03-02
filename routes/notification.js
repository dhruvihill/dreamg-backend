const express = require("express");
const verifyUser = require("../middleware/verifyUser");
const router = express.Router();
const { fetchData } = require("../database/db_connection");

// get all unreaded notifications
router.post("/get_notifications", verifyUser, async (req, res) => {
  const { userId } = req.body;

  try {
    const [notifications] = await fetchData("CALL get_notifications(?)", [
      userId,
    ]);

    res.status(200).json({
      status: true,
      message: "success",
      data: { notifications: notifications },
    });
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.message,
      data: {},
    });
  }
});

// set unread notifications to readed
router.post("/setReadNotification", verifyUser, async (req, res) => {
  const { userId, notificationId } = req.body;

  try {
    let notificationsReads;
    if (notificationId) {
      notificationsReads = await fetchData("CALL set_isreaded(?, ?);", [
        userId,
        notificationId,
      ]);
    } else {
      notificationsReads = await fetchData("CALL set_mark_as_read_all(?);", [
        userId,
      ]);
    }
    res.status(200).json({
      status: true,
      message: "success",
      data: {},
    });
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.message,
      data: {},
    });
  }
});

// exporting module
module.exports = router;
