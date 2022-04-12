const momentTimeZone = require("moment-timezone");

const convertTimeZone = (time, timeZone) => {
  if (time && timeZone && typeof timeZone === "string") {
    const newTime = momentTimeZone
      .tz(time, timeZone)
      .format("DD/MM/YYYY, HH:mm:ss");
    return [newTime, new Date(newTime).getTime().toString()];
  }
  const newTime = momentTimeZone(time).utc().format("DD/MM/YYYY, HH:mm:ss");
  return [newTime, new Date(newTime).getTime().toString()];
};

module.exports = convertTimeZone;
