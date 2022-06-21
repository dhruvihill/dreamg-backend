const express = require("express");
const router = express.Router();
const verifyUser = require("../middleware/verifyUser");
const axios = require("axios");
const { fetchData, imageUrl } = require("../database/db_connection");
const { convertTimeZone } = require("../middleware/convertTimeZone");
const MatchStatistics = require("../module/MatchStatistics");
const Coins = require("../module/Coins");

// getting dashboard data upcominng matches, predictors, news and isNotification
router.get("/", verifyUser, async (req, res) => {
  try {
    const { userId } = req.body;
    const timeZone = req.headers.timezone;

    const isNotificationQuery =
      "SELECT EXISTS(SELECT notificationId FROM `fullnotification` WHERE fullnotification.userId = ? AND haveReaded = 0) AS isNotification;";
    const upcomingMatchesQuery =
      "SELECT * FROM (SELECT EXISTS(SELECT * FROM fullmatchdetails AS innerFullMatch WHERE (innerFullMatch.team1Id IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id) OR innerFullMatch.team2Id IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id)) AND innerFullMatch.matchStartDateTime < fullmatchdetails.matchStartDateTime AND innerFullMatch.matchTournamentId IN (fullmatchdetails.matchTournamentId) AND innerFullMatch.matchStatusString IN ('live', 'not_started')) AS isDisabled, (SELECT COUNT(DISTINCT userId) FROM userTeamDetails WHERE userTeamDetails.matchId = fullmatchdetails.matchId) AS totalPredictors, seriesName, seriesDname, matchId, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE matchStatusString = 'not_started' AND fullmatchdetails.matchStartDateTime > (UNIX_TIMESTAMP(now()) * 1000) ORDER BY matchStartDateTime) AS upcomingMatches WHERE upcomingMatches.isDisabled = 0 LIMIT 5;";
    const coinDetailsQuery =
      "SELECT coins, EXISTS(SELECT * FROM coinHistory JOIN coinTransitSource ON coinHistory.spendSource = coinTransitSource.sourceId WHERE coinHistory.userId = userdetails.userId AND coinTransitSource.sourceName = 'DAILY_APP_OPEN' AND DATEDIFF(coinHistory.timeZone, NOW()) = 0) AS isTodayCollected FROM `userdetails` WHERE userdetails.userId = ?;";
    let isNotification = 0;
    let upcomingMatches = [];
    let coinDetails = {};

    if (userId) {
      [upcomingMatches, [{ isNotification }], [coinDetails]] = await fetchData(
        `${upcomingMatchesQuery}${isNotificationQuery}${coinDetailsQuery}`,
        [userId, userId, userId, userId]
      );
    } else {
      upcomingMatches = await fetchData(upcomingMatchesQuery, [userId, userId]);
    }

    const serverAddress = `${req.protocol}://${req.headers.host}`;
    const { data } = await axios({
      url: `${serverAddress}/api/v1/userTeams/getTrendingPredictors`,
    });

    // let newMatchStatistics;
    // if (upcomingMatches.length > 0) {
    //   newMatchStatistics = new MatchStatistics(upcomingMatches[0].matchId);
    //   await newMatchStatistics.getMatchDetails();
    //   await newMatchStatistics.getPitchReport();
    //   await newMatchStatistics.getFantacyPoints();
    // }

    // changing url to original server
    upcomingMatches.forEach((match) => {
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

    if (data.status) {
      res.status(200).json({
        status: true,
        message: "success",
        data: {
          matches: upcomingMatches,
          predictors: [...data.data.trendingPredictors],
          news: [],
          isNotification: isNotification,
          coinDetails,
        },
      });
    } else {
      res.status(200).json({
        status: true,
        message: "success",
        data: {
          matches: upcomingMatches,
          predictors: [],
          news: [],
          isNotification: isNotification,
          coinDetails,
        },
      });
    }
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.message,
      data: {
        matches: [],
        predictors: [],
        news: [],
        isNotification: 0,
        coinDetails: {},
      },
    });
  }
});

// exporting module
module.exports = router;
