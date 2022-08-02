const {
  ApplicationError,
  DuplicationError,
} = require("../module/Exception/index");
const { Prisma } = require("@prisma/client");

const exception = (err, req, res, next) => {
  if (err instanceof ApplicationError) {
    if (err?.details) {
      return res.status(err.status).json({
        status: "error",
        name: err.name,
        message: err.message,
        details: err.details,
      });
    }

    return res.status(err.status).json({
      status: "error",
      name: err.name,
      message: err.message,
    });
  } else if (err instanceof Prisma.PrismaClientKnownRequestError) {
    if (err.code === "P2002") {
      const error = new DuplicationError(
        `Duplicate entry for ${err?.meta?.target}`
      );
      return res.status(error.status).json({
        status: "error",
        name: error.name,
        message: error.message,
      });
    }
    return res.status(err.status).json({
      status: "error",
      message: "Internal server error",
    });
  } else {
    return res.status(500).json({
      status: "error",
      message: "Internal server error",
    });
  }
};

module.exports = exception;
