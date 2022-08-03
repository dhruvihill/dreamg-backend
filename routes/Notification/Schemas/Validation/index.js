const yup = require("yup");

const getNotificationsRequestSchema = yup.object().shape({
  userId: yup.number().required().strict(),
});

const setReadNotificationRequestSchema = yup.object().shape({
  userId: yup.number().required().strict(),
  notificationId: yup.number().strict(),
});

module.exports = {
  getNotificationsRequestSchema,
  setReadNotificationRequestSchema,
};
