const express = require("express");
const verifyUser = require("../middleware/verifyUser");
const router = express.Router();
const { fetchData } = require("../database/db_connection");

router.post("/get_notifications", verifyUser, async (req, res) => {
  const { userId } = req.body;

  const updateLastTimeCalledQuery =
    "UPDATE notification_history SET lastTimeCalled = CURRENT_TIMESTAMP() WHERE userId = ?";
  const setLastTimeCalledQuery = "INSERT INTO notification_history SET ?";
  const fetchNotificationsQuery =
    "SELECT notificationId,notificationType,notificationMessage,creationTime, creationTime < lastTimeCalled AS haveReaded FROM notifications JOIN notification_history ON notifications.userId = notification_history.userId WHERE notifications.userId = ? ORDER BY creationTime DESC LIMIT 30;";

  try {
    const notifications = await fetchData(fetchNotificationsQuery, [userId]);
    res.status(200).json({
      status: true,
      message: "success",
      data: { notifications: notifications },
    });
    const updateLastTimeCalled = await fetchData(updateLastTimeCalledQuery, [
      userId,
    ]);
    if (updateLastTimeCalled.changedRows === 0)
      fetchData(setLastTimeCalledQuery, { userId });
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.message,
      data: {},
    });
  }
});

module.exports = router;
