const express = require("express");
const router = express.Router();
const verifyUser = require("../middleware/verifyUser");
const { fetchData, imageUrl } = require("../database/db_connection");

// get matches according to its status
router.post("/get_matches", verifyUser, async (req, res) => {
  const { userId, matchType, pageNumber } = req.body;

  try {
    // "SELECT (SELECT COUNT(DISTINCT userId) FROM user_team WHERE user_team.matchId = all_matches.matchId) AS totalPredictors, (SELECT COALESCE((SELECT DISTINCT userId FROM `user_team` WHERE matchId = all_matches.matchId AND userId = ?), 0)) AS isUserTeamCreated, seriesName, seriesDname, matchId,matchTypeId,matchTyprString, matchStartTimeMilliSeconds,matchStartDateTime,match_status.matchStatusString,venue, all_matches.displayName,team1.teamId AS `team1Id`,team1.name AS 'team1Name', team1.displayName AS 'team1DisplayName',team1.teamFlagUrlLocal AS 'team1FlagURL', team2.teamId AS `team2Id`,team2.name AS 'team2Name', team2.displayName AS 'team2DisplayName',team2.teamFlagUrlLocal AS 'team2FlagURL' FROM all_matches JOIN teams AS team1 ON all_matches.team1_id = team1.teamId JOIN teams AS team2 ON all_matches.team2_id = team2.teamId JOIN match_type ON match_type.matchTypeId = gameType JOIN match_status ON all_matches.matchStatus = match_status.matchStatus WHERE matchStatusString = ? ORDER BY matchStartTimeMilliSeconds LIMIT 10;",
    if (
      ["UPCOMING", "LIVE", "RECENT", "CANCELED"].includes(matchType) &&
      pageNumber &&
      pageNumber > 0 &&
      !/[^0-9]/.test(pageNumber) &&
      !/[^0-9]/.test(userId)
    ) {
      const [result, [{ totalResult }]] = await fetchData(
        `SELECT (SELECT COUNT(DISTINCT userId) FROM fullteamdetails WHERE fullteamdetails.matchId = fullmatchdetails.matchId) AS totalPredictors, seriesName, seriesDname, matchId, matchTypeId, matchTyprString, matchStartTimeMilliSeconds, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE matchStatusString = ? ORDER BY matchStartTimeMilliSeconds LIMIT ?, 10; SELECT COUNT(*) AS totalResult FROM fullmatchdetails WHERE matchStatusString = ?;`,
        [userId, userId, matchType, (pageNumber - 1) * 10, matchType]
      );

      const totalPages = Math.ceil(totalResult / 10);

      // changing server url
      const serverAddress = `${req.protocol}://${req.he / aders.host}`;
      result.forEach((match) => {
        match.team1FlagURL = imageUrl(
          __dirname,
          "../",
          `/public/images/teamflag/${match.team1Id}.jpg`,
          serverAddress
        );
        match.team2FlagURL = imageUrl(
          __dirname,
          "../",
          `/public/images/teamflag/${match.team2Id}.jpg`,
          serverAddress
        );
      });
      res.status(200).json({
        status: true,
        message: "success",
        data: {
          matches: result,
          totalPages,
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

// get recent matches of predictor (live, recent, cancelled)
router.post("/recentPlayed", async (req, res) => {
  const { predictorId, pageNumber } = req.body;
  const serverAddress = `${req.protocol}://${req.headers.host}`;

  try {
    if (predictorId && predictorId > 0 && !/[^0-9]/g.test(predictorId)) {
      const matchesQuery =
        "SELECT matchId, seriesName, seriesDname, matchTypeId, matchTyprString, matchStartTimeMilliSeconds, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, (SELECT COUNT(DISTINCT userId) FROM fullteamdetails WHERE fullteamdetails.matchId = fullmatchdetails.matchId) AS totalPredictors, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE fullmatchdetails.matchStatus != 1 AND fullmatchdetails.matchId IN (SELECT DISTINCT fullteamdetails.matchId FROM fullteamdetails WHERE fullteamdetails.userId = ? ORDER BY fullteamdetails.creationTime DESC) LIMIT ?, 20;SELECT COUNT(*) AS totalMatches FROM fullmatchdetails WHERE fullmatchdetails.matchStatus != 1 AND fullmatchdetails.matchId IN (SELECT DISTINCT fullteamdetails.matchId FROM fullteamdetails WHERE fullteamdetails.userId = ? ORDER BY fullteamdetails.creationTime DESC);";

      const [recentPlayed, [{ totalMatches }]] = await fetchData(matchesQuery, [
        predictorId,
        predictorId,
        predictorId,
        (pageNumber - 1) * 20,
      ]);

      const totalPages = Math.ceil(totalMatches / 20);

      if (recentPlayed.length > 0) {
        recentPlayed.forEach((match) => {
          match.team1FlagURL = imageUrl(
            __dirname,
            "../",
            `/public/images/teamflag/${match.team1Id}.jpg`,
            serverAddress
          );
          match.team2FlagURL = imageUrl(
            __dirname,
            "../",
            `/public/images/teamflag/${match.team2Id}.jpg`,
            serverAddress
          );
        });

        res.status(200).json({
          status: true,
          message: "success",
          data: {
            recentPlayed: recentPlayed,
            totalPages,
          },
        });
      } else {
        throw { message: "invalid input" };
      }
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

// get current matches of predictor (upcoming)
router.post("/currentPlayed", async (req, res) => {
  const { predictorId, pageNumber } = req.body;
  const serverAddress = `${req.protocol}://${req.headers.host}`;

  try {
    if (
      predictorId &&
      pageNumber &&
      pageNumber > 0 &&
      !/[^0-9]/g.test(predictorId) &&
      !/[^0-9]/g.test(pageNumber)
    ) {
      const matchesQuery =
        "SELECT matchId, seriesName, seriesDname, matchTypeId, matchTyprString, matchStartTimeMilliSeconds, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, (SELECT COUNT(DISTINCT userId) FROM fullteamdetails WHERE fullteamdetails.matchId = fullmatchdetails.matchId) AS totalPredictors, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE fullmatchdetails.matchStatus = 1 AND fullmatchdetails.matchId IN (SELECT DISTINCT fullteamdetails.matchId FROM fullteamdetails WHERE fullteamdetails.userId = ? ORDER BY fullteamdetails.creationTime DESC) LIMIT ?, 20;SELECT COUNT(*) AS totalMatches FROM fullmatchdetails WHERE fullmatchdetails.matchStatus = 1 AND fullmatchdetails.matchId IN (SELECT DISTINCT fullteamdetails.matchId FROM fullteamdetails WHERE fullteamdetails.userId = ? ORDER BY fullteamdetails.creationTime DESC);";
      const [currentPlayed, [{ totalMatches }]] = await fetchData(
        matchesQuery,
        [
          predictorId,
          predictorId,
          predictorId,
          (pageNumber - 1) * 20,
          predictorId,
        ]
      );

      if (currentPlayed.length > 0) {
        currentPlayed.forEach((match) => {
          match.team1FlagURL = imageUrl(
            __dirname,
            "../",
            `/public/images/teamflag/${match.team1Id}.jpg`,
            serverAddress
          );
          match.team2FlagURL = imageUrl(
            __dirname,
            "../",
            `/public/images/teamflag/${match.team2Id}.jpg`,
            serverAddress
          );
        });

        const totalPages = Math.ceil(totalMatches / 20);

        res.status(200).json({
          status: true,
          message: "success",
          data: {
            currentPlayed: currentPlayed,
            totalPages,
          },
        });
      } else {
        throw { message: "invalid input" };
      }
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

// exporting module
module.exports = router;
