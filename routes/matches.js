const express = require("express");
const router = express.Router();
const verifyUser = require("../middleware/verifyUser");
const { fetchData, imageUrl } = require("../database/db_connection");
const convertTimeZone = require("../middleware/convertTimeZone");

// get matches according to its status
router.post("/getMatches", verifyUser, async (req, res) => {
  try {
    const { userId, pageNumber } = req.body;
    const timeZone = req.headers.timezone;
    let matchType = req.body.matchType;

    if (
      ["UPCOMING", "LIVE", "RECENT", "CANCELED"].includes(matchType) &&
      pageNumber &&
      pageNumber > 0 &&
      !/[^0-9]/.test(pageNumber)
    ) {
      let matchQuery = "";
      if (matchType === "UPCOMING") {
        matchQuery = `SELECT (SELECT COUNT(DISTINCT userId) FROM fullteamdetails WHERE fullteamdetails.matchId = fullmatchdetails.matchId) AS totalPredictors, seriesName, seriesDname, matchId, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartTimeMilliSeconds, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE matchStatusString = 'not_started' AND fullmatchdetails.matchStartTimeMilliSeconds > (UNIX_TIMESTAMP(now()) * 1000) ORDER BY matchStartTimeMilliSeconds LIMIT ?, 10; SELECT COUNT(*) AS totalResult FROM fullmatchdetails WHERE matchStatusString = 'not_started' AND fullmatchdetails.matchStartTimeMilliSeconds > (UNIX_TIMESTAMP(now()) * 1000);`;
      } else if (matchType === "LIVE") {
        matchQuery = `SELECT (SELECT COUNT(DISTINCT userId) FROM fullteamdetails WHERE fullteamdetails.matchId = fullmatchdetails.matchId) AS totalPredictors, seriesName, seriesDname, matchId, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartTimeMilliSeconds, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE matchStatusString = 'live' AND (UNIX_TIMESTAMP(now()) - 604800) * 1000 < matchStartTimeMilliSeconds ORDER BY matchStartTimeMilliSeconds DESC LIMIT ?, 10; SELECT COUNT(*) AS totalResult FROM fullmatchdetails WHERE matchStatusString = 'live';`;
      } else if (matchType === "RECENT") {
        matchQuery = `SELECT (SELECT COUNT(DISTINCT userId) FROM fullteamdetails WHERE fullteamdetails.matchId = fullmatchdetails.matchId) AS totalPredictors, seriesName, seriesDname, matchId, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartTimeMilliSeconds, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE matchStatusString = 'ended' OR matchStatusString = 'closed' ORDER BY matchStartTimeMilliSeconds DESC LIMIT ?, 10; SELECT COUNT(*) AS totalResult FROM fullmatchdetails WHERE matchStatusString = 'ended' OR matchStatusString = 'closed';`;
      } else if (matchType === "CANCELED") {
        matchQuery = `SELECT (SELECT COUNT(DISTINCT userId) FROM fullteamdetails WHERE fullteamdetails.matchId = fullmatchdetails.matchId) AS totalPredictors, seriesName, seriesDname, matchId, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartTimeMilliSeconds, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE matchStatusString = 'cancelled' ORDER BY matchStartTimeMilliSeconds DESC LIMIT ?, 10; SELECT COUNT(*) AS totalResult FROM fullmatchdetails WHERE matchStatusString = 'cancelled'`;
      }
      const [result, [{ totalResult }]] = await fetchData(matchQuery, [
        userId,
        userId,
        (pageNumber - 1) * 10,
      ]);

      const totalPages = Math.ceil(totalResult / 10);

      // changing server url
      const serverAddress = `${req.protocol}://${req.headers.host}`;
      result.forEach((match) => {
        if (match.matchStatusString === "not_started") {
          match.matchStatusString = "UPCOMING";
        } else if (match.matchStatusString === "live") {
          match.matchStatusString = "LIVE";
        } else if (
          match.matchStatusString === "ended" ||
          match.matchStatusString === "closed"
        ) {
          match.matchStatusString = "RECENT";
        } else if (match.matchStatusString === "cancelled") {
          match.matchStatusString = "CANCELED";
        }

        // converting time zone
        [match.matchStartDateTime, match.matchStartTimeMilliSeconds] =
          convertTimeZone(match.matchStartDateTime, timeZone);

        match.team1FlagURL = imageUrl(
          __dirname,
          "../",
          `${process.env.TEAM_IMAGE_URL}${match.team1Id}.jpg`,
          serverAddress
        );
        match.team2FlagURL = imageUrl(
          __dirname,
          "../",
          `${process.env.TEAM_IMAGE_URL}${match.team2Id}.jpg`,
          serverAddress
        );
      });
      res.status(200).json({
        status: true,
        message: "success",
        data: {
          matches: result,
          totalPages,
          currentPage: pageNumber,
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
  try {
    const { predictorId, pageNumber } = req.body;
    const timeZone = req.headers.timezone;
    const serverAddress = `${req.protocol}://${req.headers.host}`;

    if (
      predictorId &&
      predictorId > 0 &&
      !/[^0-9]/g.test(predictorId) &&
      pageNumber &&
      pageNumber > 0 &&
      !/[^0-9]/g.test(pageNumber)
    ) {
      const matchesQuery =
        "SELECT matchId, seriesName, seriesDname, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartTimeMilliSeconds, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, (SELECT COUNT(DISTINCT userId) FROM fullteamdetails WHERE fullteamdetails.matchId = fullmatchdetails.matchId) AS totalPredictors, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE fullmatchdetails.matchStatusString != 'not_started' AND fullmatchdetails.matchId IN (SELECT DISTINCT fullteamdetails.matchId FROM fullteamdetails WHERE fullteamdetails.userId = ? ORDER BY fullteamdetails.creationTime DESC) LIMIT ?, 20;SELECT COUNT(*) AS totalMatches FROM fullmatchdetails WHERE fullmatchdetails.matchStatusString != 'not_started' AND fullmatchdetails.matchId IN (SELECT DISTINCT fullteamdetails.matchId FROM fullteamdetails WHERE fullteamdetails.userId = ? ORDER BY fullteamdetails.creationTime DESC);";

      const [recentPlayed, [{ totalMatches }]] = await fetchData(matchesQuery, [
        predictorId,
        predictorId,
        predictorId,
        (pageNumber - 1) * 20,
        predictorId,
      ]);

      const totalPages = Math.ceil(totalMatches / 20);

      recentPlayed.forEach((match) => {
        if (match.matchStatusString === "not_started") {
          match.matchStatusString = "UPCOMING";
        } else if (match.matchStatusString === "live") {
          match.matchStatusString = "LIVE";
        } else if (
          match.matchStatusString === "ended" ||
          match.matchStatusString === "closed"
        ) {
          match.matchStatusString = "RECENT";
        } else if (match.matchStatusString === "cancelled") {
          match.matchStatusString = "CANCELED";
        }

        // converting time zone
        [match.matchStartDateTime, match.matchStartTimeMilliSeconds] =
          convertTimeZone(match.matchStartDateTime, timeZone);

        match.team1FlagURL = imageUrl(
          __dirname,
          "../",
          `${process.env.TEAM_IMAGE_URL}${match.team1Id}.jpg`,
          serverAddress
        );
        match.team2FlagURL = imageUrl(
          __dirname,
          "../",
          `${process.env.TEAM_IMAGE_URL}${match.team2Id}.jpg`,
          serverAddress
        );
      });

      res.status(200).json({
        status: true,
        message: "success",
        data: {
          recentPlayed: recentPlayed,
          totalPages,
          pageNumber,
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

// get current matches of predictor (upcoming)
router.post("/currentPlayed", async (req, res) => {
  try {
    const { predictorId, pageNumber } = req.body;
    const timeZone = req.headers.timezone;
    const serverAddress = `${req.protocol}://${req.headers.host}`;

    if (
      predictorId &&
      pageNumber &&
      pageNumber > 0 &&
      !/[^0-9]/g.test(predictorId) &&
      !/[^0-9]/g.test(pageNumber)
    ) {
      const matchesQuery =
        "SELECT matchId, seriesName, seriesDname, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartTimeMilliSeconds, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, (SELECT COUNT(DISTINCT userId) FROM fullteamdetails WHERE fullteamdetails.matchId = fullmatchdetails.matchId) AS totalPredictors, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE fullmatchdetails.matchStatusString = 'not_started' AND fullmatchdetails.matchId IN (SELECT DISTINCT fullteamdetails.matchId FROM fullteamdetails WHERE fullteamdetails.userId = ? ORDER BY fullteamdetails.creationTime DESC) LIMIT ?, 20;SELECT COUNT(*) AS totalMatches FROM fullmatchdetails WHERE fullmatchdetails.matchStatusString = 'not_started' AND fullmatchdetails.matchId IN (SELECT DISTINCT fullteamdetails.matchId FROM fullteamdetails WHERE fullteamdetails.userId = ? ORDER BY fullteamdetails.creationTime DESC);";
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

      currentPlayed.forEach((match) => {
        if (match.matchStatusString === "not_started") {
          match.matchStatusString = "UPCOMING";
        } else if (match.matchStatusString === "live") {
          match.matchStatusString = "LIVE";
        } else if (
          match.matchStatusString === "ended" ||
          match.matchStatusString === "closed"
        ) {
          match.matchStatusString = "RECENT";
        } else if (match.matchStatusString === "cancelled") {
          match.matchStatusString = "CANCELED";
        }
        // converting time zone
        [match.matchStartDateTime, match.matchStartTimeMilliSeconds] =
          convertTimeZone(match.matchStartDateTime, timeZone);

        match.team1FlagURL = imageUrl(
          __dirname,
          "../",
          `${process.env.TEAM_IMAGE_URL}${match.team1Id}.jpg`,
          serverAddress
        );
        match.team2FlagURL = imageUrl(
          __dirname,
          "../",
          `${process.env.TEAM_IMAGE_URL}${match.team2Id}.jpg`,
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
          pageNumber,
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

// exporting module
module.exports = router;
