const express = require("express");
const verifyUser = require("../middleware/verifyUser");
const router = express.Router();
const { fetchData } = require("../database/db_connection");

// get all unreaded notifications
router.post("/getNotifications", verifyUser, async (req, res) => {
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
    const isNotificationQuery =
      "SELECT EXISTS(SELECT notificationId FROM `fullnotification` WHERE fullnotification.userId = ? AND haveReaded = 0) AS isNotification;";
    let notificationsReads,
      isNotification = 0;
    if (notificationId) {
      [notificationsReads, [{ isNotification }]] = await fetchData(
        `CALL setIsReadedNotification(?, ?);${isNotificationQuery}`,
        [userId, notificationId, userId]
      );
    } else {
      notificationsReads = await fetchData(
        "CALL setIsReadedNotification(?, ?);",
        [userId, null]
      );
    }
    res.status(200).json({
      status: true,
      message: "success",
      data: {
        isNotification,
      },
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
