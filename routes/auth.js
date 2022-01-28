const express = require("express");
const router = express.Router();
const jwt = require("jsonwebtoken");
const verifyUser = require("../middleware/verifyUser");
const verifyProfile = require("../middleware/verifyProfile");
const { fetchData } = require("../database/db_connection");

// Creating user
router.post("/register", async (req, res) => {
  // getting data from body
  const { number: phoneNumber } = req.body;

  const regx = /[^0-9]/g;

  // return true if any other character rather than 0-9
  if (regx.test(phoneNumber) || phoneNumber.length !== 10) {
    res.status(400).json({
      status: false,
      message: "invalid input",
      data: {},
    });
  } else {
    try {
      const result = await fetchData("INSERT INTO all_users SET ?", {
        phoneNumber,
      });
      const jwtData = { user: { userId: result.insertId } };
      const token = await jwt.sign(jwtData, process.env.JWT_SECRET_KEY);
      res.status(200).json({
        status: true,
        message: "success",
        data: {
          authToken: token,
          userId: result.insertId,
        },
      });
    } catch (error) {
      res.status(400).json({
        status: false,
        message: error.message.includes("Duplicate entry")
          ? "Duplicate entry"
          : error.message,
        data: {},
      });
    }
  }
});

// checking user exists or not
router.post("/login", async (req, res) => {
  const { number: phoneNumber } = req.body; // getting data from body

  const regx = /[^0-9]/g;

  // return true if any other character rather than 0-9
  if (regx.test(phoneNumber) || phoneNumber.length !== 10) {
    res.status(400).json({
      status: false,
      message: "invalid input",
      data: {},
    });
    // res.status(400).json({
    //   status: false,
    //   message: "invalid input",
    //   data: {},
    // });
  } else {
    try {
      const userDetails = await fetchData(
        "SELECT userId,phoneNumber,firstName,lastName FROM all_users where phoneNumber = ?",
        [phoneNumber]
      );
      if (userDetails.length > 0) {
        const jwtData = {
          user: {
            userId: userDetails[0].userId,
          },
        };
        const token = await jwt.sign(jwtData, process.env.JWT_SECRET_KEY);
        userDetails[0].authToken = token;
        res.status(200).json({
          status: true,
          message: "success",
          data: userDetails[0],
        });
      } else {
        throw { message: "user does not exists" };
      }
    } catch (error) {
      res.status(400).json({
        status: false,
        message: error.message,
        data: {},
      });
    }
  }
});

// checking user exists or not
router.post("/check_user", async (req, res) => {
  const { phoneNumber } = req.body;

  const regx = /[^0-9]/g;

  // return true if any other character rather than 0-9
  if (regx.test(phoneNumber) || phoneNumber.length !== 10) {
    res.status(400).json({
      status: false,
      message: "invalid input",
      data: {},
    });
  } else {
    const responseQuery = "SELECT userId FROM all_users WHERE phoneNumber = ?";

    try {
      const responseData = await fetchData(responseQuery, [phoneNumber]);
      if (responseData.length > 0) {
        res.status(200).json({
          status: true,
          message: "success",
          data: { userId: responseData[0].userId },
        });
      } else {
        throw { message: "user does not exists" };
      }
    } catch (error) {
      res.status(400).json({
        status: false,
        message: error.message.includes("Duplicate entry")
          ? "Duplicate entry"
          : error.message,
        data: {},
      });
    }
  }
});

// fetching user data
router.post("/getuserprofile", verifyUser, async (req, res) => {
  const { predictorId } = req.body;

  const pointsQuery = `SELECT all_users.userId, all_users.firstName, all_users.lastName, all_users.phoneNumber, all_users.displayPicture, email,dateOfBirth,gender,address,city,pinCode,state,country,
  (SELECT COUNT(DISTINCT matchId) FROM user_team WHERE userId = ?) AS totalMatches,
  (SELECT COUNT(DISTINCT userTeamId) FROM user_team WHERE userId = ?) AS totalTeams,
  (SELECT SUM(user_team_data.userTeamPoints) FROM all_users JOIN user_team ON user_team.userId = all_users.userId JOIN user_team_data ON user_team.userTeamId = user_team_data.userTeamId AND userTeamType = (SELECT teamType FROM team_type WHERE teamTypeString = "MEGA_CONTEST") WHERE all_users.userId = ?) AS mega_contest_totalPoints, 
  (SELECT SUM(user_team_data.userTeamPoints) FROM all_users JOIN user_team ON user_team.userId = all_users.userId JOIN user_team_data ON user_team.userTeamId = user_team_data.userTeamId AND userTeamType = (SELECT teamType FROM team_type WHERE teamTypeString = "HEAD_TO_HEAD") WHERE all_users.userId = ?) AS head_to_head_totalPoints 
  FROM all_users WHERE all_users.userId = ?;`;
  const matchesQuery =
    "SELECT matchId, seriesName, seriesDname,matchTypeId,matchTyprString, matchStartTimeMilliSeconds,matchStartDateTime,venue, all_matches.displayName,team1.teamId AS `team1Id`,team1.name AS 'team1Name', team1.displayName AS 'team1DisplayName',team1.teamFlagUrlLocal AS 'team1FlagURL', team2.teamId AS `team2Id`,team2.name AS 'team2Name', team2.displayName AS 'team2DisplayName',team2.teamFlagUrlLocal AS 'team2FlagURL' FROM all_matches JOIN teams AS team1 ON all_matches.team1_id = team1.teamId JOIN teams AS team2 ON all_matches.team2_id = team2.teamId JOIN match_type ON match_type.matchTypeId = gameType WHERE matchId IN (SELECT DISTINCT user_team.matchId FROM user_team WHERE userId = ? ORDER BY number DESC) LIMIT 5;";

  try {
    if (!/[^0-9]/g.test(predictorId)) {
      const points = await fetchData(pointsQuery, [
        predictorId,
        predictorId,
        predictorId,
        predictorId,
        predictorId,
        predictorId,
      ]);
      if (points.length > 0) {
        // changing response null to 0
        points[0].mega_contest_totalPoints =
          points[0].mega_contest_totalPoints | 0;
        points[0].head_to_head_totalPoints =
          points[0].head_to_head_totalPoints | 0;

        // fetching last 5 matches of user
        const recentPlayed = await fetchData(matchesQuery, [predictorId]);

        // changing address in url
        const serverAddress = `${req.protocol}://${req.headers.host}`;
        points[0].displayPicture = points[0].displayPicture.replace(
          "http://192.168.1.32:3000",
          serverAddress
        );
        recentPlayed.forEach((macth) => {
          macth.team1FlagURL = macth.team1FlagURL.replace(
            "http://192.168.1.32:3000",
            serverAddress
          );
          macth.team2FlagURL = macth.team2FlagURL.replace(
            "http://192.168.1.32:3000",
            serverAddress
          );
        });

        res.status(200).json({
          status: true,
          message: "success",
          data: {
            userDetails: points[0],
            recentPlayed,
          },
        });
      } else {
        throw { message: "user does not exists" };
      }
    } else {
      throw { message: "invalid input" };
    }
  } catch (error) {
    res.status(200).json({
      status: false,
      message: error.message,
      data: {},
    });
  }
});

// Inserting firstname lastname in user
router.post(
  "/updateuserprofile",
  verifyUser,
  verifyProfile,
  async (req, res) => {
    const body = req.body;
    let keys = [],
      values = [];
    for (const key in body) {
      if (key !== "userId") {
        keys.push(`${key} = ?`);
        values.push(body[key]);
      }
    }

    const updateUserQuery = `UPDATE all_users SET ${keys.join(
      ","
    )} WHERE userId = ?`;

    try {
      const updateUserResponse = await fetchData(updateUserQuery, [
        ...values,
        body.userId,
      ]);
      delete body.userId;
      if (updateUserResponse.affectedRows > 0) {
        res.status(200).json({
          status: true,
          message: "success",
          data: {
            ...body,
          },
        });
      } else {
        throw { message: "user does not exists" };
      }
    } catch (error) {
      res.status(400).json({
        status: false,
        message: error.message,
        data: {},
      });
    }
  }
);

module.exports = router;
