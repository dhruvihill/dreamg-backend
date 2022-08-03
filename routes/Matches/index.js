const express = require("express");
const router = express.Router();
const verifyUser = require("../../middleware/verifyUser");
const { fetchData, imageUrl } = require("../../database/db_connection");
const { convertTimeZone } = require("../../middleware/convertTimeZone");
const {
  getMatchesReqBodySchema,
  recentPlayedReqBodySchema,
  currentPlayedReqBodySchema,
} = require("./Schemas/Validation/index");
const { validateSchema } = require("../../utils/index");

// get matches according to its status
router.post("/getMatches", verifyUser, async (req, res, next) => {
  try {
    const { userId, pageNumber, matchType } = req.body;
    const timeZone = req.headers.timezone;

    await validateSchema(getMatchesReqBodySchema, req.body);

    // SELECT * FROM fullmatchdetails AS innerFullMatch WHERE (innerFullMatch.team1Id IN (1, 2) OR innerFullMatch.team2Id IN (1, 2)) AND innerFullMatch.matchStartDateTime < 1653228000000 AND innerFullMatch.matchStatusString NOT IN ('ended', 'closed') ORDER BY `innerFullMatch`.`matchId` ASC;

    let matchQuery = "";
    if (matchType === "UPCOMING") {
      matchQuery = `SELECT EXISTS(SELECT * FROM fullmatchdetails AS innerFullMatch WHERE (innerFullMatch.team1Id IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id) OR innerFullMatch.team2Id IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id)) AND innerFullMatch.matchStartDateTime < fullmatchdetails.matchStartDateTime AND innerFullMatch.matchTournamentId IN (fullmatchdetails.matchTournamentId) AND innerFullMatch.matchStatusString IN ('live', 'not_started')) AS isDisabled, fullmatchdetails.isLineUpOut AS isLineUpOut, (SELECT COUNT(DISTINCT userId) FROM userTeamDetails WHERE userTeamDetails.matchId = fullmatchdetails.matchId) AS totalPredictors, seriesName, seriesDname, matchId, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE matchStatusString = 'not_started' AND fullmatchdetails.matchStartDateTime > (UNIX_TIMESTAMP(now()) * 1000) ORDER BY matchStartDateTime LIMIT ?, 10; SELECT COUNT(*) AS totalResult FROM fullmatchdetails WHERE matchStatusString = 'not_started' AND fullmatchdetails.matchStartDateTime > (UNIX_TIMESTAMP(now()) * 1000) ORDER BY fullmatchdetails.matchStartDateTime ASC;`;
    } else if (matchType === "LIVE") {
      matchQuery = `SELECT (SELECT COUNT(DISTINCT userId) FROM userTeamDetails WHERE userTeamDetails.matchId = fullmatchdetails.matchId) AS totalPredictors, seriesName, seriesDname, matchId, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE matchStatusString = 'live' AND (UNIX_TIMESTAMP(now()) - 604800) * 1000 < matchStartDateTime ORDER BY matchStartDateTime DESC LIMIT ?, 10; SELECT COUNT(*) AS totalResult FROM fullmatchdetails WHERE matchStatusString = 'live';`;
    } else if (matchType === "RECENT") {
      matchQuery = `SELECT (SELECT COUNT(DISTINCT userId) FROM userTeamDetails WHERE userTeamDetails.matchId = fullmatchdetails.matchId) AS totalPredictors, seriesName, seriesDname, fullmatchdetails.matchId, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated,EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated, scorcardDetails.matchResultString AS matchResultString FROM fullmatchdetails JOIN scorcardDetails ON scorcardDetails.matchId = fullmatchdetails.matchId WHERE matchStatusString = 'ended' OR matchStatusString = 'closed' ORDER BY matchStartDateTime DESC LIMIT ?, 10; SELECT COUNT(*) AS totalResult FROM fullmatchdetails WHERE matchStatusString = 'ended' OR matchStatusString = 'closed';`;
    } else if (matchType === "CANCELED") {
      matchQuery = `SELECT (SELECT COUNT(DISTINCT userId) FROM userTeamDetails WHERE userTeamDetails.matchId = fullmatchdetails.matchId) AS totalPredictors, seriesName, seriesDname, matchId, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE matchStatusString = 'cancelled' ORDER BY matchStartDateTime DESC LIMIT ?, 10; SELECT COUNT(*) AS totalResult FROM fullmatchdetails WHERE matchStatusString = 'cancelled'`;
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
      // matchStartDateTime is milliseconds
      [match.matchStartDateTime, match.matchStartTimeMilliSeconds] =
        convertTimeZone(match.matchStartDateTime, timeZone);

      match.remainingMatchStartTime = (
        parseInt(match.matchStartTimeMilliSeconds) - Date.now()
      ).toString();

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
  } catch (error) {
    next(error);
  }
});

// get recent matches of predictor (live, recent, cancelled)
router.post("/recentPlayed", async (req, res, next) => {
  try {
    const { predictorId, pageNumber } = req.body;
    const timeZone = req.headers.timezone;
    const serverAddress = `${req.protocol}://${req.headers.host}`;

    await validateSchema(currentPlayedReqBodySchema, req.body);

    const matchesQuery =
      "SELECT fullmatchdetails.matchId AS matchId, scorcardDetails.matchResultString, seriesName, seriesDname, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, (SELECT COUNT(DISTINCT userId) FROM userTeamDetails WHERE userTeamDetails.matchId = fullmatchdetails.matchId) AS totalPredictors, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails JOIN scorcardDetails ON scorcardDetails.matchId = fullmatchdetails.matchId WHERE fullmatchdetails.matchStatusString != 'not_started' AND fullmatchdetails.matchId IN (SELECT DISTINCT userTeamDetails.matchId FROM userTeamDetails WHERE userTeamDetails.userId = ? ORDER BY userTeamDetails.creationTime DESC) LIMIT ?, 20;SELECT COUNT(*) AS totalMatches FROM fullmatchdetails WHERE fullmatchdetails.matchStatusString != 'not_started' AND fullmatchdetails.matchId IN (SELECT DISTINCT userTeamDetails.matchId FROM userTeamDetails WHERE userTeamDetails.userId = ? ORDER BY userTeamDetails.creationTime DESC);";

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

      match.remainingMatchStartTime = (
        parseInt(match.matchStartTimeMilliSeconds) - Date.now()
      ).toString();

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
  } catch (error) {
    next(error);
  }
});

// get current matches of predictor (upcoming)
router.post("/currentPlayed", async (req, res, next) => {
  try {
    const { predictorId, pageNumber } = req.body;
    const timeZone = req.headers.timezone;
    const serverAddress = `${req.protocol}://${req.headers.host}`;

    await validateSchema(currentPlayedReqBodySchema, req.body);

    const matchesQuery =
      "SELECT matchId, seriesName, seriesDname, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, (SELECT COUNT(DISTINCT userId) FROM userTeamDetails WHERE userTeamDetails.matchId = fullmatchdetails.matchId) AS totalPredictors, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE fullmatchdetails.matchStatusString = 'not_started' AND fullmatchdetails.matchId IN (SELECT DISTINCT userTeamDetails.matchId FROM userTeamDetails WHERE userTeamDetails.userId = ? ORDER BY userTeamDetails.creationTime DESC) LIMIT ?, 20;SELECT COUNT(*) AS totalMatches FROM fullmatchdetails WHERE fullmatchdetails.matchStatusString = 'not_started' AND fullmatchdetails.matchId IN (SELECT DISTINCT userTeamDetails.matchId FROM userTeamDetails WHERE userTeamDetails.userId = ? ORDER BY userTeamDetails.creationTime DESC);";
    const [currentPlayed, [{ totalMatches }]] = await fetchData(matchesQuery, [
      predictorId,
      predictorId,
      predictorId,
      (pageNumber - 1) * 20,
      predictorId,
    ]);

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

      match.remainingMatchStartTime = (
        parseInt(match.matchStartTimeMilliSeconds) - Date.now()
      ).toString();

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
  } catch (error) {
    next(error);
  }
});

// exporting module
module.exports = router;
