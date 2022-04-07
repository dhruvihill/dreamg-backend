const express = require("express");
const router = express.Router();
const verifyUser = require("../middleware/verifyUser");
const axios = require("axios");
const { fetchData, imageUrl } = require("../database/db_connection");
const convertTimeZone = require("../middleware/convertTimeZone");

// getting dashboard data upcominng matches, predictors, news and isNotification
router.get("/", verifyUser, async (req, res) => {
  try {
    const { userId } = req.body;
    const timeZone = req.headers.timezone;

    const isNotificationQuery =
      "SELECT EXISTS(SELECT notificationId FROM `fullnotification` WHERE fullnotification.userId = ? AND haveReaded = 0) AS isNotification;";
    const upcomingMatchesQuery =
      "SELECT (SELECT COUNT(DISTINCT userId) FROM fullteamdetails WHERE fullteamdetails.matchId = fullmatchdetails.matchId) AS totalPredictors, seriesName, seriesDname, matchId, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartTimeMilliSeconds, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE matchStatusString = 'not_started' AND fullmatchdetails.matchStartTimeMilliSeconds > (UNIX_TIMESTAMP(now()) * 1000) ORDER BY matchStartTimeMilliSeconds LIMIT 5;";
    let isNotification = 0;
    let upcomingMatches = [];

    if (userId) {
      [upcomingMatches, [{ isNotification }]] = await fetchData(
        `${upcomingMatchesQuery}${isNotificationQuery}`,
        [userId, userId, userId]
      );
    } else {
      upcomingMatches = await fetchData(upcomingMatchesQuery, [userId, userId]);
    }

    const serverAddress = `${req.protocol}://${req.headers.host}`;
    const { data } = await axios({
      url: `${serverAddress}/api/v1/userTeams/getTrendingPredictors`,
    });

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
        convertTimeZone(match.matchStartDateTime, parseInt(timeZone));

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
      // match.matchStartDateTime = new Date(
      //   parseInt(match.matchStartTimeMilliSeconds)
      // );
      // match.matchStartDateTime =
      //   (match.matchStartDateTime.getDate() > 9
      //     ? match.matchStartDateTime.getDate()
      //     : "0" + match.matchStartDateTime.getDate()) +
      //   "/" +
      //   (match.matchStartDateTime.getMonth() > 8
      //     ? match.matchStartDateTime.getMonth() + 1
      //     : "0" + (match.matchStartDateTime.getMonth() + 1)) +
      //   "/" +
      //   match.matchStartDateTime.getFullYear() +
      //   ", " +
      //   (match.matchStartDateTime.getHours() > 9
      //     ? match.matchStartDateTime.getHours()
      //     : "0" + match.matchStartDateTime.getHours()) +
      //   ":" +
      //   (match.matchStartDateTime.getMinutes() > 9
      //     ? match.matchStartDateTime.getMinutes()
      //     : "0" + match.matchStartDateTime.getMinutes()) +
      //   ":" +
      //   (match.matchStartDateTime.getSeconds() > 9
      //     ? match.matchStartDateTime.getSeconds()
      //     : "0" + match.matchStartDateTime.getSeconds());
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
      },
    });
  }
});

// exporting module
module.exports = router;
