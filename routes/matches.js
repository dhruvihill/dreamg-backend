const express = require("express");
const router = express.Router();
const verifyUser = require("../middleware/verifyUser");
const { fetchData } = require("../database/db_connection");

router.post("/get_matches", verifyUser, async (req, res) => {
  const { userId, matchType } = req.body;
  try {
    // "SELECT (SELECT COUNT(DISTINCT userId) FROM user_team WHERE user_team.matchId = all_matches.matchId) AS totalPredictors, (SELECT COALESCE((SELECT DISTINCT userId FROM `user_team` WHERE matchId = all_matches.matchId AND userId = ?), 0)) AS isUserTeamCreated, seriesName, seriesDname, matchId,matchTypeId,matchTyprString, matchStartTimeMilliSeconds,matchStartDateTime,match_status.matchStatusString,venue, all_matches.displayName,team1.teamId AS `team1Id`,team1.name AS 'team1Name', team1.displayName AS 'team1DisplayName',team1.teamFlagUrlLocal AS 'team1FlagURL', team2.teamId AS `team2Id`,team2.name AS 'team2Name', team2.displayName AS 'team2DisplayName',team2.teamFlagUrlLocal AS 'team2FlagURL' FROM all_matches JOIN teams AS team1 ON all_matches.team1_id = team1.teamId JOIN teams AS team2 ON all_matches.team2_id = team2.teamId JOIN match_type ON match_type.matchTypeId = gameType JOIN match_status ON all_matches.matchStatus = match_status.matchStatus WHERE matchStatusString = ? ORDER BY matchStartTimeMilliSeconds LIMIT 10;",
    if (["UPCOMING", "LIVE", "RECENT", "CANCELED"].includes(matchType)) {
      const result = await fetchData(
        `SELECT (SELECT COUNT(DISTINCT userId) FROM fullteamdetails WHERE fullteamdetails.matchId = fullmatchdetails.matchId) AS totalPredictors, (SELECT COALESCE((SELECT DISTINCT userId FROM fullteamdetails WHERE fullteamdetails.matchId = fullmatchdetails.matchId AND userId = ?), 0)) AS isUserTeamCreated, seriesName, seriesDname, matchId, matchTypeId, matchTyprString, matchStartTimeMilliSeconds, matchStartDateTime, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team1FlagURL, team2Id, team2Name, team2DisplayName, team2FlagURL FROM fullmatchdetails WHERE matchStatusString = ? ORDER BY matchStartTimeMilliSeconds LIMIT 10;`,
        [userId, matchType]
      );

      // changing server url
      const serverAddress = `${req.protocol}://${req.headers.host}`;
      result.forEach((match) => {
        match.team1FlagURL = match.team1FlagURL
          ? match.team1FlagURL.replace(
              "http://192.168.1.32:3000",
              serverAddress
            )
          : "";
        match.team2FlagURL = match.team2FlagURL
          ? match.team2FlagURL.replace(
              "http://192.168.1.32:3000",
              serverAddress
            )
          : "";
      });
      res.status(200).json({
        status: true,
        message: "success",
        data: {
          matches: result,
        },
      });
    } else {
      throw { message: "invalid input" };
    }
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage ? error.sqlMessage : error.message,
      data: {},
    });
  }
});

router.post("/recentPlayed", verifyUser, async (req, res) => {
  const { predictorId } = req.body;
  const serverAddress = `${req.protocol}://${req.headers.host}`;

  try {
    const matchesQuery =
      "SELECT matchId, seriesName, seriesDname,matchTypeId,matchTyprString, matchStartTimeMilliSeconds,matchStartDateTime,venue, all_matches.displayName,team1.teamId AS `team1Id`,team1.name AS 'team1Name', team1.displayName AS 'team1DisplayName',team1.teamFlagUrlLocal AS 'team1FlagURL', team2.teamId AS `team2Id`,team2.name AS 'team2Name', team2.displayName AS 'team2DisplayName',team2.teamFlagUrlLocal AS 'team2FlagURL' FROM all_matches JOIN teams AS team1 ON all_matches.team1_id = team1.teamId JOIN teams AS team2 ON all_matches.team2_id = team2.teamId JOIN match_type ON match_type.matchTypeId = gameType WHERE matchId IN (SELECT DISTINCT user_team.matchId FROM user_team JOIN user_team_data ON user_team.userTeamId = user_team_data.userTeamId WHERE userId = ? ORDER BY user_team_data.creationTime DESC)";

    const recentPlayed = await fetchData(matchesQuery, [predictorId]);

    recentPlayed.forEach((match) => {
      match.team1FlagURL = match.team1FlagURL
        ? match.team1FlagURL.replace("http://192.168.1.32:3000", serverAddress)
        : "";
      match.team2FlagURL = match.team2FlagURL
        ? match.team2FlagURL.replace("http://192.168.1.32:3000", serverAddress)
        : "";
    });

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        recentPlayed: recentPlayed,
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

module.exports = router;
