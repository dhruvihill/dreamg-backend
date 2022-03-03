const express = require("express");
const router = express.Router();
const verifyUser = require("../middleware/verifyUser");
const axios = require("axios");
const { fetchData, imageUrl } = require("../database/db_connection");

// getting dashboard data upcominng matches, predictors, news and isNotification
router.get("/", verifyUser, async (req, res) => {
  const { userId } = req.body;

  const isNotificationQuery =
    "SELECT EXISTS(SELECT notificationId FROM `fullnotification` WHERE fullnotification.userId = ? AND haveReaded = 0) AS isNotification;";
  const upcomingMatchesQuery =
    "SELECT (SELECT COUNT(DISTINCT userId) FROM fullteamdetails WHERE fullteamdetails.matchId = fullmatchdetails.matchId) AS totalPredictors, seriesName, seriesDname, matchId, matchTypeId, matchTyprString, matchStartTimeMilliSeconds, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE matchStatus = 1 ORDER BY matchStartTimeMilliSeconds DESC LIMIT 10;";

  try {
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
      url: `${serverAddress}/api/v1/prediction/getTrendingPredictors`,
    });

    if (upcomingMatches.length > 0) {
      // changing url to original server
      upcomingMatches.forEach((match) => {
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
        match.matchStartDateTime = new Date(
          parseInt(match.matchStartTimeMilliSeconds)
        );
        match.matchStartDateTime =
          (match.matchStartDateTime.getDate() > 9
            ? match.matchStartDateTime.getDate()
            : "0" + match.matchStartDateTime.getDate()) +
          "/" +
          (match.matchStartDateTime.getMonth() > 8
            ? match.matchStartDateTime.getMonth() + 1
            : "0" + (match.matchStartDateTime.getMonth() + 1)) +
          "/" +
          match.matchStartDateTime.getFullYear() +
          ", " +
          (match.matchStartDateTime.getHours() > 9
            ? match.matchStartDateTime.getHours()
            : "0" + match.matchStartDateTime.getHours()) +
          ":" +
          (match.matchStartDateTime.getMinutes() > 9
            ? match.matchStartDateTime.getMinutes()
            : "0" + match.matchStartDateTime.getMinutes()) +
          ":" +
          (match.matchStartDateTime.getSeconds() > 9
            ? match.matchStartDateTime.getSeconds()
            : "0" + match.matchStartDateTime.getSeconds());
      });

      if (data.status) {
        // changing server address
        data.data.trendingPredictors.forEach((pre) => {
          pre.displayPicture = imageUrl(
            __dirname,
            "../",
            `/public/images/user/${pre.userId}.jpg`,
            serverAddress
          );
        });

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
    } else {
      throw { message: "no matches available" };
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
