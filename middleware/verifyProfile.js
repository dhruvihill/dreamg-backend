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

        if (typeof body[key] === "string" || key === "dateOfBirth") {
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
            if (body[key]) {
              const date = new Date(body[key]);
              const year = date.getFullYear();
              const month =
                date.getMonth() + 1 < 10
                  ? "0" + (date.getMonth() + 1)
                  : date.getMonth() + 1;
              const day =
                date.getDate() + 1 < 10 ? "0" + date.getDate() : date.getDate();
              if (
                !(
                  validator.isDate(`${year}/${month}/${day}`) &&
                  validator.isBefore(
                    `${year - 12}/${month}/${day}`,
                    `${year}/${month}/${day}`
                  )
                )
              ) {
                allCorrect = false;
              }
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

console.log(validator.isBefore("2024/10/18", "2020/1/1"));
