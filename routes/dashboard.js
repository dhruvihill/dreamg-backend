const express = require("express");
const router = express.Router();
const verifyUser = require("../middleware/verifyUser");
const axios = require("axios");
const { fetchData } = require("../database/db_connection");

// getting dashboard data upcominng matches, predictors, news and isNotification
router.get("/", verifyUser, async (req, res) => {
  const { userId } = req.body;

  const isNotificationQuery =
    "SELECT EXISTS(SELECT notificationId FROM `fullnotification` WHERE fullnotification.userId = ? AND haveReaded = 0) AS isNotification;";
  const upcomingMatchesQuery =
    "SELECT (SELECT COUNT(DISTINCT userId) FROM fullteamdetails WHERE fullteamdetails.matchId = fullmatchdetails.matchId) AS totalPredictors, seriesName, seriesDname, matchId, matchTypeId, matchTyprString, matchStartTimeMilliSeconds, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team1FlagURL, team2Id, team2Name, team2DisplayName, team2FlagURL, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT fullteamdetails.userTeamId FROM fullteamdetails WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = fullmatchdetails.matchId AND fullteamdetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE matchStatus = 1 ORDER BY matchStartTimeMilliSeconds DESC LIMIT 5;";

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

    const { data } = await axios({
      url: `${req.protocol}://${req.headers.host}/api/v1/prediction/getTrendingPredictors`,
    });

    if (upcomingMatches.length > 0) {
      // changing url to original server
      upcomingMatches.forEach((match) => {
        match.team1FlagURL = match.team1FlagURL
          ? match.team1FlagURL.replace(
              "http://192.168.1.32:3000",
              `${req.protocol}://${req.headers.host}`
            )
          : "";
        match.team2FlagURL = match.team2FlagURL
          ? match.team2FlagURL.replace(
              "http://192.168.1.32:3000",
              `${req.protocol}://${req.headers.host}`
            )
          : "";
      });

      if (data.status) {
        // changing server address
        data.data.trendingPredictors.forEach((pre) => {
          pre.displayPicture = pre.displayPicture.replace(
            "http://192.168.1.32:3000",
            `${req.protocol}://${req.headers.host}`
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

// adding new column 'teamFlagUrlLocal' in teams database
// connection.query("SELECT playerId,url FROM players", (err, response) => {
//   if (err) console.log(err);
//   else {
//     response.forEach((element) => {
//       if (element.url) {
//         const URL =
//           "localhost:3000" +
//           `/public/images/profilepicture/${element.playerId}.jpg`;
//         connection.query(
//           "UPDATE players SET profilePictureURLLocal = ? WHERE playerId = ?",
//           [URL, element.playerId],
//           (error, respo) => {
//             console.log(error);
//           }
//         );
//       }
//     });
//   }
// });

// downloading images
// const downloadImage = (url, imageName) => {
//   return new Promise((resolve, reject) => {
//     axios({
//       url,
//       responseType: "stream",
//     })
//       .then((response) => {
//         response.data
//           .pipe(fs.createWriteStream(`./public/images/profilepicture/${imageName}.jpg`))
//           .on("finish", () => resolve("success"))
//           .on("error", (e) => reject(e.message));
//       })
//       .catch((error) => {
//         reject(error.message);
//       });
//   });
// };
// (async () => {
//   connection.query("SELECT url, playerId FROM players;", (err, res) => {
//     if (err) console.log("Image:", err.sqlMessage);
//     else {
//       res.forEach((element) => {
//         if (element.url) {
//           downloadImage(element.url, element.playerId)
//             .then((response) => {
//               // console.log(response);
//             })
//             .catch((error) => {
//               console.log(error);
//             });
//         }
//       });
//     }
//   });
// })();

// creating time field in db
// connection.query(
//   "SELECT matchId, matchStartTimeMilliSeconds FROM all_matches",
//   (err, response) => {
//     if (err) console.log(err);
//     else {
//       response.forEach((element) => {
//         const newDate = new Date(parseInt(element.matchStartTimeMilliSeconds));
//         const newDateFormat = newDate.toLocaleString();
//         connection.query(
//           "UPDATE all_matches SET matchStartDateTime = ? WHERE matchId = ?",
//           [newDateFormat, element.matchId],
//           (error, respo) => {}
//         );
//       });
//     }
//   }
// );

// insering matches in database
// fs.readFile("./live.json", "utf-8", async (err, data) => {
//   data = await JSON.parse(data);
//   data.matches["3"].forEach((element) => {
//     const {
//       matchId,
//       seriesName,
//       seriesDname,
//       gameType,
//       gameTypeStr,
//       team1: { id: team1_id },
//       team2: { id: team2_id },
//       matchStartTime,
//       matchFreezeTime,
//       matchStatus,
//       venue,
//       displayName,
//       seriesId,
//       addInfo: { matchKey },
//     } = element;
//     const newDate = new Date(parseInt(matchStartTime));
//     const newDateFormat = newDate.toLocaleString();
//     const query = "INSERT INTO all_matches SET ?";
//     const queryArray = {
//       matchId,
//       seriesName,
//       seriesDname,
//       gameType,
//       gameTypeStr,
//       team1_id,
//       team2_id,
//       matchStartTimeMilliSeconds: matchStartTime,
//       matchFreezeTimeMilliSeconds: matchFreezeTime,
//       matchStatus,
//       venue,
//       displayName,
//       seriesId,
//       matchKey,
//       matchStartDateTime: newDateFormat
//     };
//     // console.log(queryArray);
//     connection.query(query, queryArray, (error, response) => {
//       if (error) console.log(error);
//       else {
//         console.log(response);
//       }
//     });
//   });
// });

// inserting teams in database
// fs.readFile("./live.json", "utf-8", async (err, data) => {
//   data = await JSON.parse(data);
//   data.matches["1"].forEach((element) => {
//     connection.query(
//       "INSERT INTO teams SET ?",
//       {
//         teamId: element.team1.id,
//         name: element.team1.name,
//         displayName: element.team1.dName,
//         teamFlagUrl: element.team1.teamFlagURL,
//       },
//       (err, response) => {
//         if (err) {
//           console.log(err.sqlMessage);
//         }
//       }
//     );
//   });
//   data.matches["1"].forEach((element) => {
//     connection.query(
//       "INSERT INTO teams SET ?",
//       {
//         teamId: element.team2.id,
//         name: element.team2.name,
//         displayName: element.team2.dName,
//         teamFlagUrl: element.team2.teamFlagURL,
//       },
//       (err, response) => {
//         if (err) {
//           console.log(err.sqlMessage);
//         }
//       }
//     );
//   });
// });
