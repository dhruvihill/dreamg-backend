const express = require("express");
const connection = require("../database/db_connection");
const router = express.Router();

router.post("/get_notifications", (req, res) => {
  const { userId } = req.body;

  const changeNotificationHistory = () => {
    connection.query("UPDATE notification_history SET lastTimeCalled = CURRENT_TIMESTAMP() WHERE userId = ?", [userId], (err, response) => {
        try {
            if (err) throw err;
            else {
              if (response.changedRows === 0) {
                  connection.query("INSERT INTO notification_history SET ?", {userId})
              }
            }
        } catch (error) {
          res.status(400).json({
              status: false,
              message: error.message,
              data: {}
          });
        }
    });
  }

  connection.query(
    "SELECT notificationId userId,notificationType,notificationMessage,creationTime, creationTime < lastTimeCalled AS haveReaded FROM notifications JOIN notification_history ON notifications.userId = notification_history.userId ORDER BY creationTime DESC LIMIT 30",
    [userId],
    (err, notifications) => {
        try {
            if (err) throw err;
            else {
                res.status(200).json({
                    status: true,
                    message: "success",
                    data: {
                        notifications: notifications
                    }
                });
                changeNotificationHistory();
            }
        } catch (error) {
            res.status(400).json({
                status: false,
                message: error.message,
                data: {}
            });
        }
    }
  );

});

module.exports = router;
