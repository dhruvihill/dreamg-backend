const jwt = require("jsonwebtoken");

const verifyUser = async (req, res, next) => {
  const { authtoken } = req.headers;

  try {
    if (authtoken) {
      const result = await jwt.verify(
        authtoken,
        "FJSD357&*T4VH^&$%MZX#&HFWE()*78E#&$(*^)"
      );
      req.body.userId = result.user.userId;
      next();
    } else {
      throw { message: "authtoken not provided" };
    }
  } catch (error) {
    res.status(400).json({
      status: false,
      message:
        error.message == "invalid signature" ? "invalid token" : error.message,
      data: {},
    });
  }
};

module.exports = verifyUser;
