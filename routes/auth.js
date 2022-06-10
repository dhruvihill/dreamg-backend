const express = require("express");
const router = express.Router();
const jwt = require("jsonwebtoken");
const { fetchData } = require("../database/db_connection");
const User = require("../module/User/User");
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
      const user = new User();
      const data = await user.RegisterUser(phoneNumber);

      // sending response
      res.status(200).json({
        status: true,
        message: "success",
        data: {
          ...data,
        },
      });
    } else {
      res.status(400).json({
        status: false,
        message: "invalid input",
      });
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
router.post("/login", async (req, res) => {
  const { number: phoneNumber } = req.body; // getting data from body

  const regx = /[^0-9]/g;

  // return true if any other character rather than 0-9
  try {
    if (regx.test(phoneNumber) || phoneNumber.length !== 10) {
      throw { message: "invalid input" };
    } else {
      const newUser = new User();
      const data = await newUser.LoginUser(phoneNumber);

      if (data) {
        res.status(200).json({
          status: true,
          message: "success",
          data,
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
    if (regx.test(phoneNumber) || phoneNumber.length !== 10) {
      throw { message: "invalid input" };
    } else {
      const newUser = new User();
      await newUser.CheckUser(phoneNumber);

      if (newUser.id) {
        // sending response
        res.status(200).json({
          status: true,
          message: "success",
          data: { userId: newUser.id },
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
