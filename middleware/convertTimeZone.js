const moment = require("moment");

const convertTimeZone = (time, timeZone) => {
  // time will be timestamp of database ex: 2022-04-07T14:00:00.000Z
  // timeZone will be timeZone of user ex: 330

  if (time && (timeZone || timeZone === 0) && typeof timeZone === "number") {
    if (timeZone === 0) {
      const newTime = moment(time).utc(timeZone).format();
      return [newTime, new Date(newTime).getTime().toString()];
    }
    const newTime = moment(time).utcOffset(timeZone).format();
    return [newTime, new Date(newTime).getTime().toString()];
  } else {
    return [null, null];
  }
};

module.exports = convertTimeZone;
