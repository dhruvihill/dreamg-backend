const jwt = require("jsonwebtoken");

const verifyUser = async (req, res, next) => {
  const { authtoken } = req.headers;

  try {
    if (authtoken) {
      const result = await jwt.verify(authtoken, process.env.JWT_SECRET_KEY);
      req.body.userId = result.user.userId;
      next();
    } else {
      // console.log(req.baseUrl, req.originalUrl);
      if (
        req.originalUrl === "/api/v1/getdashboarddata" ||
        req.originalUrl === "/api/v1/matches/get_matches" ||
        req.originalUrl === "/api/v1/prediction/get_user_teams_data"
      ) {
        req.body.userId = null;
        next();
        return;
      }
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
