const express = require("express");
const router = express.Router();
const verifyUser = require("../middleware/verifyUser");
const verifyProfile = require("../middleware/verifyProfile");
const { fetchData, imageUrl } = require("../database/db_connection");
const { rename, writeFile } = require("fs/promises");
const { existsSync, mkdirSync } = require("fs");
const path = require("path");
const upload = require("express-fileupload");
const convertTimeZone = require("../middleware/convertTimeZone");

// fetching user data
router.post("/userProfile", verifyUser, async (req, res) => {
  try {
    const { predictorId } = req.body;
    const timeZone = req.headers.timezone;

    const pointsQuery = `SELECT userId, firstName, imageStamp, lastName, phoneNumber, email, dateOfBirth, gender, address, city, pinCode, state, country,
      (SELECT COUNT(DISTINCT matchId) FROM fullteamdetails WHERE userId = ?) AS totalMatches,
      (SELECT COUNT(DISTINCT userTeamId) FROM fullteamdetails WHERE userId = ?) AS totalTeams,
      COALESCE((SELECT SUM(userTeamPoints) AS totalPoints FROM fullteamdetails WHERE userId = ? GROUP BY userTeamType HAVING userTeamType = 1), 0) AS mega_contest_totalPoints,
      COALESCE((SELECT SUM(userTeamPoints) AS totalPoints FROM fullteamdetails WHERE userId = ? GROUP BY userTeamType HAVING userTeamType = 2), 0) AS head_to_head_totalPoints FROM userdetails WHERE userId = ?;`;

    const recentMatchesQuery =
      "SELECT matchId, seriesName, seriesDname, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartTimeMilliSeconds, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, (SELECT COUNT(DISTINCT userId) FROM fullteamdetails WHERE fullteamdetails.matchId = fullmatchdetails.matchId) AS totalPredictors, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE fullmatchdetails.matchStatusString != 'not_started' AND fullmatchdetails.matchId IN (SELECT DISTINCT fullteamdetails.matchId FROM fullteamdetails WHERE fullteamdetails.userId = ? ORDER BY fullteamdetails.creationTime DESC) LIMIT 5;";
    const currentMatchQuery =
      "SELECT matchId, seriesName, seriesDname, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartTimeMilliSeconds, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, (SELECT COUNT(DISTINCT userId) FROM fullteamdetails WHERE fullteamdetails.matchId = fullmatchdetails.matchId) AS totalPredictors, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE fullmatchdetails.matchStatusString = 'not_started' AND fullmatchdetails.matchId IN (SELECT DISTINCT fullteamdetails.matchId FROM fullteamdetails WHERE fullteamdetails.userId = ? ORDER BY fullteamdetails.creationTime DESC) LIMIT 5;";

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
          `${process.env.USER_IMAGE_URL}${points[0].imageStamp}.jpg`,
          serverAddress
        );
        delete points[0].imageStamp;

        // adding teamFlag image url to matches
        recentPlayed.forEach(async (match) => {
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
        currentPlayed.forEach((match) => {
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
    const updateUserQuery = `UPDATE users SET ${keys.join(
      ","
    )} WHERE userId = ?;`;
    const getUserPointsQuery = `SELECT (SELECT COUNT(DISTINCT matchId) FROM user_team WHERE userId = ?) AS totalMatches,
        (SELECT COUNT(DISTINCT userTeamId) FROM user_team WHERE userId = ?) AS totalTeams,
        COALESCE((SELECT SUM(user_team_data.userTeamPoints) FROM users JOIN user_team ON user_team.userId = users.userId JOIN user_team_data ON user_team.userTeamId = user_team_data.userTeamId AND userTeamType = (SELECT teamType FROM team_type WHERE teamTypeString = "MEGA_CONTEST") WHERE users.userId = ?), 0) AS mega_contest_totalPoints, 
        COALESCE((SELECT SUM(user_team_data.userTeamPoints) FROM users JOIN user_team ON user_team.userId = users.userId JOIN user_team_data ON user_team.userTeamId = user_team_data.userTeamId AND userTeamType = (SELECT teamType FROM team_type WHERE teamTypeString = "HEAD_TO_HEAD") WHERE users.userId = ?), 0) AS head_to_head_totalPoints 
        FROM users WHERE users.userId = ?;`;
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

router.post("/uploadProfilePicture", upload(), verifyUser, async (req, res) => {
  const { userId } = req.body;

  try {
    if (!req.files) {
      throw { message: "no file found" };
    }

    const user = {
      userId,
      time: new Date().getTime(),
    };
    const newImageStamp = btoa(JSON.stringify(user));

    const [[{ imageStamp }], imageStampSet] = await fetchData(
      "SELECT imageStamp FROM userdetails WHERE userdetails.userId = ?;UPDATE users SET imageStamp = ? WHERE users.userId = ?;",
      [userId, newImageStamp, userId]
    );

    if (
      !existsSync(path.join(__dirname, "../", `${process.env.USER_IMAGE_URL}`))
    ) {
      mkdirSync(path.join(__dirname, "../", `${process.env.USER_IMAGE_URL}`));
    }
    if (
      !existsSync(
        path.join(__dirname, "../", `${process.env.OLD_USER_IMAGE_URL}`)
      )
    ) {
      mkdirSync(
        path.join(__dirname, "../", `${process.env.OLD_USER_IMAGE_URL}`)
      );
    }
    if (
      imageStamp &&
      existsSync(
        path.join(
          __dirname,
          "../",
          process.env.USER_IMAGE_URL + imageStamp + ".jpg"
        )
      )
    ) {
      rename(
        path.join(
          __dirname,
          "../",
          process.env.USER_IMAGE_URL + imageStamp + ".jpg"
        ),
        path.join(
          __dirname,
          "../",
          process.env.OLD_USER_IMAGE_URL + imageStamp + ".jpg"
        )
      );
    }

    if (imageStampSet.affectedRows > 0) {
      await writeFile(
        path.join(
          __dirname,
          `..${process.env.USER_IMAGE_URL}${newImageStamp}.jpg`
        ),
        req.files.profilePicture.data
      );

      res.status(200).json({
        status: true,
        message: "success",
        data: {
          profilePicture: `${req.protocol}://${req.headers.host}${process.env.USER_IMAGE_URL}${newImageStamp}.jpg`,
        },
      });
    } else {
      throw { message: "some error occured" };
    }
  } catch (error) {
    res.status(400).json({
      status: false,
      message: "some error occured",
      data: {},
    });
  }
});

// exporting router
module.exports = router;
