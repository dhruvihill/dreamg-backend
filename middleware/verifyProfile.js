const validator = require("validator");

const verifyProfile = async (req, res, next) => {
  const body = req.body;
  const canNotChange = [
    "userId",
    "phoneNumber",
    "registerTime",
    "userType",
    "isVerified",
  ];
  try {
    let allCorrect = true;
    for (const key in body) {
      if (canNotChange.includes(key)) {
        if (key !== "userId") {
          throw { message: "invalid input" };
        }
      } else {
        if (typeof body[key] === "string") {
          if (["firstName", "lastName"].includes(key)) {
            body[key].length > 30 ? (allCorrect = false) : null;
          } else if (key === "email") {
            validator.isEmail(body[key]) ? null : (allCorrect = false);
          } else if (key === "pinCode") {
            let regx = /[^0-9]/g;
            if (regx.test(body[key])) allCorrect = false;
          } else if (key === "dateOfBirth") {
            if (
              !(
                validator.isDate(body[key]) &&
                validator.isBefore(body[key], Date())
              )
            ) {
              allCorrect = false;
            }
          } else if (key === "gender") {
            if (!["male", "female"].includes(body[key])) {
              allCorrect = false;
            }
          }
        } else {
          throw { message: "invalid input" };
        }
      }
    }
    if (allCorrect) next();
    else throw { message: "invalid input" };
  } catch (error) {
    return res.status(400).json({
      status: false,
      message: error.message,
      data: {},
    });
  }
};

module.exports = verifyProfile;