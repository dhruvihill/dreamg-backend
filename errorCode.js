const errors = {
  databaseErrors: {
    handledError: {
      ER_DUP_ENTRY: { message: "Duplicate entry", code: 200 },
    },
    unhandledError: {
      message: "some internal error occured",
      code: 501,
    },
  },
  serverErrors: {
    handledError: {},
    unhandledError: {
      message: "some internal error occured",
      code: 501,
    },
  },
};

module.exports = errors;
