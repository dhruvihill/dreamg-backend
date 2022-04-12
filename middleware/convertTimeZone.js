const moment = require("moment");

const convertTimeZone = (time, timeZone) => {
  // time will be timestamp of database ex: 2022-04-07T14:00:00.000Z
  // timeZone will be timeZone of user ex: 330

  if (time && timeZone && typeof timeZone === "string") {
    timeZone = timeZone.substr(4);
    const regx = /^([+-](?:2[0-3]|[01][0-9]):[0-5][0-9])$/;

    if (regx.test(timeZone)) {
      if (timeZone.includes("00:00") || timeZone === "") {
        const newTime = moment(time).utc().format();
        const newTime2 = newTime.replace("Z", "");
        return [newTime2, new Date(newTime).getTime().toString()];
      }
      const newTime = moment(time).utcOffset(timeZone).format();
      const newTime2 = newTime.replace(timeZone, "");
      return [newTime2, new Date(newTime).getTime().toString()];
    } else {
      return [null, null];
    }
  } else {
    return [null, null];
  }
};

module.exports = convertTimeZone;
