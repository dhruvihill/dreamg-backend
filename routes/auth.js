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

  try {
    const result = await fetchData("CALL register_user(?);", [phoneNumber]);
    const jwtData = { user: { userId: result[0][0].userId } };
    const token = await jwt.sign(jwtData, process.env.JWT_SECRET_KEY);
    res.status(200).json({
      status: true,
      message: "success",
      data: {
        authToken: token,
        userId: result[0][0].userId,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage ? error.sqlMessage : error.message,
      data: {},
    });
  }
});

// checking user exists or not
router.post("/login", async (req, res) => {
  const { number: phoneNumber } = req.body; // getting data from body

  const regx = /[^0-9]/g;

  // return true if any other character rather than 0-9
  try {
    if (regx.test(phoneNumber) || phoneNumber.length !== 10) {
      throw { message: "invalid input" };
    } else {
      const userDetails = await fetchData(
        "SELECT userId, phoneNumber, firstName, lastName FROM userdetails WHERE phoneNumber = ?;",
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
    }
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage ? error.sqlMessage : error.message,
      data: {},
    });
  }
});

// checking user exists or not
router.post("/check_user", async (req, res) => {
  const { phoneNumber } = req.body;

  const regx = /[^0-9]/g;

  // return true if any other character rather than 0-9
  const responseQuery = "SELECT userId FROM userdetails WHERE phoneNumber = ?";

  try {
    if (regx.test(phoneNumber) || phoneNumber.length !== 10) {
      throw { message: "invalid input" };
    } else {
      const responseData = await fetchData(responseQuery, [phoneNumber]);
      if (responseData.length === 1) {
        res.status(200).json({
          status: true,
          message: "success",
          data: { userId: responseData[0].userId },
        });
      } else {
        throw { message: "user does not exists" };
      }
    }
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage ? error.sqlMessage : error.message,
      data: {},
    });
  }
});

// fetching user data
router.post("/getuserprofile", verifyUser, async (req, res) => {
  const { predictorId } = req.body;

  // const pointsQuery = `SELECT all_users.userId, all_users.firstName, all_users.lastName, all_users.phoneNumber, all_users.displayPicture, email,dateOfBirth,gender,address,city,pinCode,state,country,
  // (SELECT COUNT(DISTINCT matchId) FROM user_team WHERE userId = ?) AS totalMatches,
  // (SELECT COUNT(DISTINCT userTeamId) FROM user_team WHERE userId = ?) AS totalTeams,
  // COALESCE((SELECT SUM(user_team_data.userTeamPoints) FROM all_users JOIN user_team ON user_team.userId = all_users.userId JOIN user_team_data ON user_team.userTeamId = user_team_data.userTeamId AND userTeamType = (SELECT teamType FROM team_type WHERE teamTypeString = "MEGA_CONTEST") WHERE all_users.userId = ?), 0) AS mega_contest_totalPoints,
  // COALESCE((SELECT SUM(user_team_data.userTeamPoints) FROM all_users JOIN user_team ON user_team.userId = all_users.userId JOIN user_team_data ON user_team.userTeamId = user_team_data.userTeamId AND userTeamType = (SELECT teamType FROM team_type WHERE teamTypeString = "HEAD_TO_HEAD") WHERE all_users.userId = ?), 0) AS head_to_head_totalPoints
  // FROM all_users WHERE all_users.userId = ?;`;

  const pointsQuery = `SELECT userId, firstName, lastName, phoneNumber, displayPicture, email, dateOfBirth, gender, address, city, pinCode, state, country,
  (SELECT COUNT(DISTINCT matchId) FROM fullteamdetails WHERE userId = ?) AS totalMatches,
  (SELECT COUNT(DISTINCT userTeamId) FROM fullteamdetails WHERE userId = ?) AS totalTeams,
  COALESCE((SELECT SUM(userTeamPoints) AS totalPoints FROM fullteamdetails WHERE userId = ? GROUP BY userTeamType HAVING userTeamType = 1), 0) AS mega_contest_totalPoints,
  COALESCE((SELECT SUM(userTeamPoints) AS totalPoints FROM fullteamdetails WHERE userId = ? GROUP BY userTeamType HAVING userTeamType = 2), 0) AS head_to_head_totalPoints FROM userdetails WHERE userId = ?;`;

  const recentMatchesQuery =
    "SELECT matchId, seriesName, seriesDname, matchTypeId, matchTyprString, matchStartTimeMilliSeconds, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team1FlagURL, team2Id, team2Name, team2DisplayName, team2FlagURL, (SELECT COUNT(DISTINCT userId) FROM fullteamdetails WHERE fullteamdetails.matchId = fullmatchdetails.matchId) AS totalPredictors, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE fullmatchdetails.matchStatus != 1 AND fullmatchdetails.matchId IN (SELECT DISTINCT fullteamdetails.matchId FROM fullteamdetails WHERE fullteamdetails.userId = ? ORDER BY fullteamdetails.creationTime DESC) LIMIT 5;";
  const currentMatchQuery =
    "SELECT matchId, seriesName, seriesDname, matchTypeId, matchTyprString, matchStartTimeMilliSeconds, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team1FlagURL, team2Id, team2Name, team2DisplayName, team2FlagURL, (SELECT COUNT(DISTINCT userId) FROM fullteamdetails WHERE fullteamdetails.matchId = fullmatchdetails.matchId) AS totalPredictors, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE fullmatchdetails.matchStatus = 1 AND fullmatchdetails.matchId IN (SELECT DISTINCT fullteamdetails.matchId FROM fullteamdetails WHERE fullteamdetails.userId = ? ORDER BY fullteamdetails.creationTime DESC) LIMIT 5;";

  // SELECT fullmatchdetails.matchId, seriesName, seriesDname,matchTypeId,matchTyprString, matchStartTimeMilliSeconds,matchStartDateTime,venue, displayName, team1Id, team1Name, team1DisplayName, team1FlagURL, team2Id, team2Name, team2DisplayName, team2FlagURL FROM fullmatchdetails JOIN fullteamdetails ON fullmatchdetails.matchId = fullteamdetails.matchId WHERE fullteamdetails.userId = ? AND fullmatchdetails.matchStatus = 1 GROUP BY fullmatchdetails.matchId ORDER BY fullteamdetails.creationTime DESC LIMIT 5;

  // "SELECT matchId, seriesName, seriesDname,matchTypeId,matchTyprString, matchStartTimeMilliSeconds,matchStartDateTime,venue, all_matches.displayName,team1.teamId AS `team1Id`,team1.name AS 'team1Name', team1.displayName AS 'team1DisplayName',team1.teamFlagUrlLocal AS 'team1FlagURL', team2.teamId AS `team2Id`,team2.name AS 'team2Name', team2.displayName AS 'team2DisplayName',team2.teamFlagUrlLocal AS 'team2FlagURL' FROM all_matches JOIN teams AS team1 ON all_matches.team1_id = team1.teamId JOIN teams AS team2 ON all_matches.team2_id = team2.teamId JOIN match_type ON match_type.matchTypeId = gameType WHERE matchId IN (SELECT DISTINCT user_team.matchId FROM user_team JOIN user_team_data ON user_team.userTeamId = user_team_data.userTeamId WHERE userId = ? ORDER BY user_team_data.creationTime DESC) LIMIT 5";

  try {
    if (!/[^0-9]/g.test(predictorId)) {
      const [points, recentPlayed, currentPlayed] = await fetchData(
        `${pointsQuery}${recentMatchesQuery}${currentMatchQuery}`,
        Array(11).fill(predictorId)
      );

      if (points.length > 0) {
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
        currentPlayed.forEach((macth) => {
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
            currentPlayed,
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

    try {
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
      )} WHERE userId = ?;`;
      const getUserPointsQuery = `SELECT (SELECT COUNT(DISTINCT matchId) FROM user_team WHERE userId = ?) AS totalMatches,
      (SELECT COUNT(DISTINCT userTeamId) FROM user_team WHERE userId = ?) AS totalTeams,
      COALESCE((SELECT SUM(user_team_data.userTeamPoints) FROM all_users JOIN user_team ON user_team.userId = all_users.userId JOIN user_team_data ON user_team.userTeamId = user_team_data.userTeamId AND userTeamType = (SELECT teamType FROM team_type WHERE teamTypeString = "MEGA_CONTEST") WHERE all_users.userId = ?), 0) AS mega_contest_totalPoints, 
      COALESCE((SELECT SUM(user_team_data.userTeamPoints) FROM all_users JOIN user_team ON user_team.userId = all_users.userId JOIN user_team_data ON user_team.userTeamId = user_team_data.userTeamId AND userTeamType = (SELECT teamType FROM team_type WHERE teamTypeString = "HEAD_TO_HEAD") WHERE all_users.userId = ?), 0) AS head_to_head_totalPoints 
      FROM all_users WHERE all_users.userId = ?;`;
      const [updateUserResponse, [getUserPoints]] = await fetchData(
        `${updateUserQuery}${getUserPointsQuery}`,
        [...values, body.userId, ...Array(5).fill(body.userId)]
      );

      if (updateUserResponse.affectedRows > 0) {
        res.status(200).json({
          status: true,
          message: "success",
          data: {
            ...body,
            ...getUserPoints,
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

// exporting module
module.exports = router;
