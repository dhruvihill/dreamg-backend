const logger = require("./logger");
const validateSchema = require("./validateSchema");
const prisma = require("./prismaClient");

module.exports = {
  logger,
  validateSchema,
  prisma,
};
