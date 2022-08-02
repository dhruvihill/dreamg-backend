const yup = require("yup");

const registerUserSchema = yup.object().shape({
  number: yup
    .string("number must be a string")
    .length(10, "number must be of 10 characters")
    .matches(/^\d+$/, "number must be a valid number")
    .required("number is required"),
});
const loginUserSchema = yup.object().shape({
  number: yup
    .string("number must be a string")
    .length(10, "number must be of 10 characters")
    .matches(/^\d+$/, "number must be a valid number")
    .required("number is required"),
});
const checkUserSchema = yup.object().shape({
  phoneNumber: yup
    .string("number must be a string")
    .length(10, "number must be of 10 characters")
    .matches(/^\d+$/, "number must be a valid number")
    .required("number is required"),
});

module.exports = {
  registerUserSchema,
  loginUserSchema,
  checkUserSchema,
};
