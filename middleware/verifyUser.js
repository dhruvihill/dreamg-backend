const jwt = require("jsonwebtoken");

const verifyUser = async (req, res, next) => {
  let { authorization: authtoken } = req.headers;

  if (!authtoken) {
    authtoken = req.headers.authtoken;
  } else {
    authtoken = authtoken.split(" ")[1];
  }

  try {
    if (authtoken) {
      // verifying auth token

      const result = await jwt.verify(authtoken, process.env.JWT_SECRET_KEY);

      // setting user id to req object
      req.body.userId = result.user.userId;
      next();
    } else {
      // ignoring auth token for following routes
      if (
        req.originalUrl === "/api/v1/getDashboardData" ||
        req.originalUrl === "/api/v1/matches/getMatches" ||
        req.originalUrl === "/api/v1/userTeams/getUserTeamPlayers" ||
        req.originalUrl === "/api/v1/user/userProfile" ||
        req.originalUrl === "/api/v1/system"
      ) {
        // setting user id to req object
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
