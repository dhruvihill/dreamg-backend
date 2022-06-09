const express = require("express");
const router = express.Router();
const verifyUser = require("../middleware/verifyUser");
const verifyProfile = require("../middleware/verifyProfile");
const { fetchData, imageUrl } = require("../database/db_connection");
const { rename, writeFile } = require("fs/promises");
const { existsSync, mkdirSync } = require("fs");
const path = require("path");
const upload = require("express-fileupload");
const {
  convertTimeZone,
  convertToYYYYMMDD,
} = require("../middleware/convertTimeZone");
const { UserPan, UserBank } = require("../module/User");

// fetching user data
router.post("/userProfile", verifyUser, async (req, res) => {
  try {
    const { predictorId } = req.body;
    const timeZone = req.headers.timezone;

    const pointsQuery = `SELECT userdetails.userId, userdetails.firstName, userdetails.imageStamp, userdetails.lastName, userdetails.phoneNumber, userdetails.email, userdetails.dateOfBirth, userdetails.gender, userdetails.address, userdetails.city, userdetails.pinCode, userdetails.state, userdetails.country, (SELECT COUNT(DISTINCT matchId) FROM userTeamDetails WHERE userId = userdetails.userId) AS totalMatches, (SELECT COUNT(DISTINCT userTeamId) FROM userTeamDetails WHERE userId = userdetails.userId) AS totalTeams, COALESCE((SELECT SUM(userTeamDetails.userTeamPoints) FROM userTeamDetails WHERE userTeamDetails.teamTypeString = "MEGA_CONTEST" AND userTeamDetails.userId = userdetails.userId), 0) AS mega_contest_totalPoints, COALESCE((SELECT SUM(userTeamDetails.userTeamPoints) FROM userTeamDetails WHERE userTeamDetails.teamTypeString = "HEAD_TO_HEAD" AND userTeamDetails.userId = userdetails.userId), 0) AS head_to_head_totalPoints FROM userdetails WHERE userdetails.userId = ?;`;

    const recentMatchesQuery =
      "SELECT matchId, seriesName, seriesDname, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, (SELECT COUNT(DISTINCT userId) FROM userTeamDetails WHERE userTeamDetails.matchId = fullmatchdetails.matchId) AS totalPredictors, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE fullmatchdetails.matchStatusString != 'not_started' AND fullmatchdetails.matchId IN (SELECT DISTINCT userTeamDetails.matchId FROM userTeamDetails WHERE userTeamDetails.userId = ? ORDER BY userTeamDetails.creationTime DESC) LIMIT 5;";

    const currentMatchQuery =
      "SELECT matchId, seriesName, seriesDname, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, (SELECT COUNT(DISTINCT userId) FROM userTeamDetails WHERE userTeamDetails.matchId = fullmatchdetails.matchId) AS totalPredictors, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE fullmatchdetails.matchStatusString = 'not_started' AND fullmatchdetails.matchId IN (SELECT DISTINCT userTeamDetails.matchId FROM userTeamDetails WHERE userTeamDetails.userId = ? ORDER BY userTeamDetails.creationTime DESC) LIMIT 5;";

    if (!/[^0-9]/g.test(predictorId)) {
      const [points, recentPlayed, currentPlayed] = await fetchData(
        `${pointsQuery}${recentMatchesQuery}${currentMatchQuery}`,
        Array(7).fill(predictorId)
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
    const getUserPointsQuery = `SELECT (SELECT COUNT(DISTINCT matchId) FROM userTeamDetails WHERE userId = userdetails.userId) AS totalMatches, (SELECT COUNT(DISTINCT userTeamId) FROM userTeamDetails WHERE userId = userdetails.userId) AS totalTeams, COALESCE((SELECT SUM(userTeamDetails.userTeamPoints) FROM userTeamDetails WHERE userTeamDetails.teamTypeString = "MEGA_CONTEST" AND userTeamDetails.userId = userdetails.userId), 0) AS mega_contest_totalPoints, COALESCE((SELECT SUM(userTeamDetails.userTeamPoints) FROM userTeamDetails WHERE userTeamDetails.teamTypeString = "HEAD_TO_HEAD" AND userTeamDetails.userId = userdetails.userId), 0) AS head_to_head_totalPoints FROM userdetails WHERE userdetails.userId = ?;`;
    const [updateUserResponse, [getUserPoints]] = await fetchData(
      `${updateUserQuery}${getUserPointsQuery}`,
      [...values, body.userId, body.userId]
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

router.post("/uploadPanDetails", upload(), verifyUser, async (req, res) => {
  try {
    const { userId, userPanFullName, userPanNumber, userDateOfBirth } =
      req.body;

    if (!req.files) {
      throw { message: "no file found" };
    }

    const panProofImage = req.files.panProofImage.data;

    const panUser = new UserPan(userId);
    await panUser.InsertUserPanDetails(
      userPanFullName,
      userPanNumber,
      convertToYYYYMMDD(userDateOfBirth),
      panProofImage
    );

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        status: "success",
      },
    });
  } catch (error) {
    res.status(400).json({
      status: false,
      message:
        error.code === "ER_DUP_ENTRY" ? "Duplicate Entry" : error.message,
      data: {},
    });
  }
});

router.post("/uploadBankDetails", upload(), verifyUser, async (req, res) => {
  try {
    const {
      userId,
      userBankName,
      userBankAccountNumber,
      userBankIFSC,
      userFullName,
      userUPI,
    } = req.body;

    if (!req.files) {
      throw { message: "no file found" };
    }

    const bankProofImage = req.files.bankProofImage.data;

    const bankUser = new UserBank(userId);
    await bankUser.InsertUserBankDetails(
      userBankName,
      userBankAccountNumber,
      userBankIFSC,
      userFullName,
      userUPI,
      bankProofImage
    );

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        status: "success",
      },
    });
  } catch (error) {
    res.status(400).json({
      status: false,
      message:
        error.code === "ER_DUP_ENTRY" ? "Duplicate Entry" : error.message,
      data: {},
    });
  }
});

// exporting router
module.exports = router;
