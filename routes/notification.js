const express = require("express");
const verifyUser = require("../middleware/verifyUser");
const router = express.Router();
const { fetchData } = require("../database/db_connection");

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

router.post("/setReadNotification", verifyUser, async (req, res) => {
  const { userId, notificationId } = req.body;

  try {
    const done = await fetchData("CALL set_isreaded(?, ?);", [
      userId,
      notificationId,
    ]);

    if (done.affectedRows === 1) {
      res.status(200).json({
        status: true,
        message: "success",
        data: {},
      });
    } else {
      throw { message: "some error occured" };
    }
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.message,
      data: {},
    });
  }
});

module.exports = router;
