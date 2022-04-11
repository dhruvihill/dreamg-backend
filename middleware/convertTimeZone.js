const moment = require("moment");

const convertTimeZone = (time, timeZone) => {
  // time will be timestamp of database ex: 2022-04-07T14:00:00.000Z
  // timeZone will be timeZone of user ex: 330

  if (time && timeZone && typeof timeZone === "string") {
    timeZone = timeZone.substr(4);

    if (timeZone.includes("00:00") || timeZone === "") {
      const newTime = moment(time).utc().format();
      const newTime2 = newTime.replace("Z", "+00:00");
      return [newTime2, new Date(newTime).getTime().toString()];
    }
    const newTime = moment(time).utcOffset(timeZone).format();
    return [newTime, new Date(newTime).getTime().toString()];
  } else {
    return [time, timeZone.toString()];
  }
};

module.exports = convertTimeZone;
