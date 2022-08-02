const { ValidationError } = require("../module/Exception/index");

const validateSchema = (schema, data) => {
  return new Promise(async (resolve, reject) => {
    try {
      await schema.validate(data, {
        abortEarly: false,
      });
      resolve();
    } catch (error) {
      const newError = new ValidationError(error.message, error?.inner || []);
      reject(newError);
    }
  });
};

module.exports = validateSchema;
