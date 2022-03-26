const express = require("express");
const router = express.Router();
const jwt = require("jsonwebtoken");
const { fetchData } = require("../database/db_connection");
// const errors = require("../errorCode");

// Creating user
router.post("/register", async (req, res) => {
  // getting data from body
  const { number: phoneNumber } = req.body;
  try {
    if (
      (phoneNumber.length === 10 || phoneNumber.length === 11) &&
      !/[^0-9]/g.test(phoneNumber)
    ) {
      // registering user
      const result = await fetchData("CALL register_user(?);", [phoneNumber]);

      // creating auth token
      const jwtData = { user: { userId: result[0][0].userId } };
      const token = await jwt.sign(jwtData, process.env.JWT_SECRET_KEY);

      // sending response
      res.status(200).json({
        status: true,
        message: "success",
        data: {
          authToken: token,
          userId: result[0][0].userId,
        },
      });
    } else {
      res.status(400).json({
        status: false,
        message: "invalid input",
      });
    }
  } catch (error) {
    // sending response
    // if (error.sqlMessage) {
    //   if (error.code === "ER_DUP_ENTRY") {
    //     res.status(error.databaseErrors.handledError.ER_DUP_ENTRY.code).json({
    //       status: false,
    //       message: error.databaseErrors.handledError.ER_DUP_ENTRY.message,
    //       data: {},
    //     });
    //     return;
    //   } else {
    //     res.status(error.databaseErrors.unhandledError.code).json({
    //       status: false,
    //       message: error.databaseErrors.unhandledError.message,
    //       data: {},
    //     });
    //   }
    // }
    res.status(400).json({
      status: false,
      message: error.sqlMessage ? error.sqlMessage : error.message,
      data: {},
    });
  }
});

// checking user exists or not
router.post("/login", async (req, res) => {
  const { number: phoneNumber } = req.body; // getting data from body

  const regx = /[^0-9]/g;

  // return true if any other character rather than 0-9
  try {
    if (regx.test(phoneNumber) || phoneNumber.length !== 10) {
      throw { message: "invalid input" };
    } else {
      // fetching user details
      const userDetails = await fetchData(
        "SELECT userId, phoneNumber, firstName, lastName FROM userdetails WHERE phoneNumber = ?;",
        [phoneNumber]
      );
      if (userDetails.length > 0) {
        // creating auth token
        const jwtData = {
          user: {
            userId: userDetails[0].userId,
          },
        };
        const token = await jwt.sign(jwtData, process.env.JWT_SECRET_KEY);

        userDetails[0].authToken = token;

        // sending response
        res.status(200).json({
          status: true,
          message: "success",
          data: userDetails[0],
        });
      } else {
        throw { message: "user does not exists" };
      }
    }
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage ? error.sqlMessage : error.message,
      data: {},
    });
  }
});

// checking user exists or not
router.post("/checkUser", async (req, res) => {
  const { phoneNumber } = req.body;

  const regx = /[^0-9]/g;

  // return true if any other character rather than 0-9

  try {
    const responseQuery =
      "SELECT userId FROM userdetails WHERE phoneNumber = ?";
    if (regx.test(phoneNumber) || phoneNumber.length !== 10) {
      throw { message: "invalid input" };
    } else {
      const responseData = await fetchData(responseQuery, [phoneNumber]);
      if (responseData.length === 1) {
        // sending response
        res.status(200).json({
          status: true,
          message: "success",
          data: { userId: responseData[0].userId },
        });
      } else {
        throw { message: "user does not exists" };
      }
    }
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage ? error.sqlMessage : error.message,
      data: {},
    });
  }
});

// exporting module
module.exports = router;
