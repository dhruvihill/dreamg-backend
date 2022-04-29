const momentTimeZone = require("moment-timezone");

const convertTimeZone = (time, timeZone) => {
  // here time is milliseconds
  if (time && timeZone && typeof timeZone === "string") {
    time = new Date(parseInt(time));
    const newTime = momentTimeZone
      .tz(time, timeZone)
      .format("DD/MM/YYYY, HH:mm:ss");
    return [newTime, time.getTime().toString()];
  }
  time = new Date(time);
  const newTime = momentTimeZone(time).utc().format("DD/MM/YYYY, HH:mm:ss");
  return [newTime, new Date(time).getTime().toString()];
};

module.exports = convertTimeZone;
