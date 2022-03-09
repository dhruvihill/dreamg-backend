const express = require("express");
const router = express.Router();
const verifyUser = require("../middleware/verifyUser");
const verifyProfile = require("../middleware/verifyProfile");
const { fetchData, imageUrl } = require("../database/db_connection");

// fetching user data
router.post("/userProfile", verifyUser, async (req, res) => {
  const { predictorId } = req.body;

  try {
    const pointsQuery = `SELECT userId, firstName, lastName, phoneNumber, email, dateOfBirth, gender, address, city, pinCode, state, country,
      (SELECT COUNT(DISTINCT matchId) FROM fullteamdetails WHERE userId = ?) AS totalMatches,
      (SELECT COUNT(DISTINCT userTeamId) FROM fullteamdetails WHERE userId = ?) AS totalTeams,
      COALESCE((SELECT SUM(userTeamPoints) AS totalPoints FROM fullteamdetails WHERE userId = ? GROUP BY userTeamType HAVING userTeamType = 1), 0) AS mega_contest_totalPoints,
      COALESCE((SELECT SUM(userTeamPoints) AS totalPoints FROM fullteamdetails WHERE userId = ? GROUP BY userTeamType HAVING userTeamType = 2), 0) AS head_to_head_totalPoints FROM userdetails WHERE userId = ?;`;

    const recentMatchesQuery =
      "SELECT matchId, seriesName, seriesDname, matchTypeId, matchTyprString, matchStartTimeMilliSeconds, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, (SELECT COUNT(DISTINCT userId) FROM fullteamdetails WHERE fullteamdetails.matchId = fullmatchdetails.matchId) AS totalPredictors, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE fullmatchdetails.matchStatus != 1 AND fullmatchdetails.matchId IN (SELECT DISTINCT fullteamdetails.matchId FROM fullteamdetails WHERE fullteamdetails.userId = ? ORDER BY fullteamdetails.creationTime DESC) LIMIT 5;";
    const currentMatchQuery =
      "SELECT matchId, seriesName, seriesDname, matchTypeId, matchTyprString, matchStartTimeMilliSeconds, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, (SELECT COUNT(DISTINCT userId) FROM fullteamdetails WHERE fullteamdetails.matchId = fullmatchdetails.matchId) AS totalPredictors, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE fullmatchdetails.matchStatus = 1 AND fullmatchdetails.matchId IN (SELECT DISTINCT fullteamdetails.matchId FROM fullteamdetails WHERE fullteamdetails.userId = ? ORDER BY fullteamdetails.creationTime DESC) LIMIT 5;";

    if (!/[^0-9]/g.test(predictorId)) {
      const [points, recentPlayed, currentPlayed] = await fetchData(
        `${pointsQuery}${recentMatchesQuery}${currentMatchQuery}`,
        Array(11).fill(predictorId)
      );

      if (points.length > 0) {
        const serverAddress = `${req.protocol}://${req.headers.host}`;

        // user profile picture
        points[0].displayPicture = imageUrl(
          __dirname,
          "../",
          `/public/images/user/${predictorId}.jpg`,
          serverAddress
        );

        // adding teamFlag image url to matches
        recentPlayed.forEach(async (macth) => {
          macth.team1FlagURL = imageUrl(
            __dirname,
            "../",
            `/public/images/teamflag/${macth.team1Id}.jpg`,
            serverAddress
          );
          macth.team2FlagURL = imageUrl(
            __dirname,
            "../",
            `/public/images/teamflag/${macth.team2Id}.jpg`,
            serverAddress
          );
        });
        currentPlayed.forEach((macth) => {
          macth.team1FlagURL = imageUrl(
            __dirname,
            "../",
            `/public/images/teamflag/${macth.team1Id}.jpg`,
            serverAddress
          );
          macth.team2FlagURL = imageUrl(
            __dirname,
            "../",
            `/public/images/teamflag/${macth.team2Id}.jpg`,
            serverAddress
          );
        });

        points[0].dateOfBirth = parseInt(points[0].dateOfBirth);

        // sending response
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
router.post("/updateProfile", verifyUser, verifyProfile, async (req, res) => {
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
});

// exporting router
module.exports = router;
