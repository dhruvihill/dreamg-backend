const express = require("express");
const verifyUser = require("../../middleware/verifyUser");
const router = express.Router();
const { fetchData } = require("../../database/db_connection");
const { validateSchema } = require("../../utils/index");
const {
  getNotificationsRequestSchema,
  setReadNotificationRequestSchema,
} = require("./Schemas/Validation/index");

// get all unreaded notifications
router.post("/getNotifications", verifyUser, async (req, res, next) => {
  try {
    const { userId } = req.body;

    await validateSchema(getNotificationsRequestSchema, req.body);

    const [notifications] = await fetchData("CALL get_notifications(?)", [
      userId,
    ]);

    res.status(200).json({
      status: true,
      message: "success",
      data: { notifications: notifications },
    });
  } catch (error) {
    next(error);
  }
});

// set unread notifications to readed
router.post("/setReadNotification", verifyUser, async (req, res, next) => {
  try {
    const { userId, notificationId } = req.body;

    await validateSchema(setReadNotificationRequestSchema, req.body);

    const isNotificationQuery =
      "SELECT EXISTS(SELECT notificationId FROM `fullnotification` WHERE fullnotification.userId = ? AND haveReaded = 0) AS isNotification;";
    let notificationsReads,
      isNotification = 0;
    if (notificationId) {
      [notificationsReads, [{ isNotification }]] = await fetchData(
        `UPDATE notifications SET isReaded = 1 WHERE notifications.userId = ? AND notifications.notificationId = ?;${isNotificationQuery}`,
        [userId, notificationId, userId]
      );
    } else {
      notificationsReads = await fetchData(
        "UPDATE notifications SET isReaded = 1 WHERE notifications.userId = ?;",
        [userId]
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
    next(error);
  }
});

// exporting module
module.exports = router;
