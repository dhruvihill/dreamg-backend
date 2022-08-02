const express = require("express");
const router = express.Router();
const User = require("../../module/User/User");
const { validateSchema } = require("../../utils/index");
const {
  registerUserSchema,
  loginUserSchema,
  checkUserSchema,
} = require("./Schemas/Validation/index");

// Creating user
router.post("/register", async (req, res, next) => {
  // getting data from body
  const { number: phoneNumber } = req.body;
  try {
    await validateSchema(registerUserSchema, req.body);

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
  } catch (error) {
    next(error);
  }
});

// checking user exists or not
router.post("/login", async (req, res, next) => {
  try {
    const { number: phoneNumber } = req.body; // getting data from body

    await validateSchema(loginUserSchema, req.body);

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
  } catch (error) {
    next(error);
  }
});

// checking user exists or not
router.post("/checkUser", async (req, res, next) => {
  try {
    const { phoneNumber } = req.body;

    await validateSchema(checkUserSchema, req.body);

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
  } catch (error) {
    next(error);
  }
});

// exporting module
module.exports = router;
