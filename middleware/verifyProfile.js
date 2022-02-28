const validator = require("validator");

const verifyProfile = async (req, res, next) => {
  const body = req.body;

  // keys that can not change
  const canNotChange = [
    "userId",
    "phoneNumber",
    "registerTime",
    "userType",
    "isVerified",
  ];
  try {
    let allCorrect = true;

    // loop through all the keys in the body
    for (const key in body) {
      // if the key is in the canNotChange array
      if (canNotChange.includes(key)) {
        if (key !== "userId") {
          throw { message: "invalid input" };
        }
      } else {
        // checking all values for string
        if (typeof body[key] === "string") {
          // firstName lastName changed
          if (["firstName", "lastName"].includes(key)) {
            body[key].length > 30 || body[key].length === 0
              ? (allCorrect = false)
              : null;
          } else if (key === "email") {
            // checking email
            if (body[key] !== "") {
              validator.isEmail(body[key]) ? null : (allCorrect = false);
            }
          } else if (key === "pinCode") {
            // checking pinCode
            let regx = /[^0-9]/g;
            if (body[key] !== "" && regx.test(body[key])) allCorrect = false;
          } else if (key === "dateOfBirth") {
            // checking dateOfBirth
            if (
              body[key] !== "" &&
              !(
                validator.isDate(body[key]) &&
                validator.isBefore(body[key], Date())
              )
            ) {
              allCorrect = false;
            }
          } else if (key === "gender") {
            // checking gender
            if (body[key] !== "" && !["male", "female"].includes(body[key])) {
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
