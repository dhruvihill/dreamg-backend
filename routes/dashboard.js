const express = require("express");
const router = express.Router();
const connection = require("../database/db_connection");
const verifyUser = require("../middleware/verifyUser");
const axios = require("axios");
// const fs = require("fs");
// const path = require("path");

const fetchData = (query, options = []) =>
  new Promise((resolve, reject) => {
    connection.query(query, options, (err, response) => {
      if (err) reject(err);
      else resolve(response);
    });
  });

router.get("/", verifyUser, async (req, res) => {
  const { userId } = req.body;
  const { authtoken } = req.headers;

  const upcomingMatchesQuery =
    "SELECT seriesName, seriesDname, matchId,matchTypeId,matchTyprString, matchStartTimeMilliSeconds,matchStartDateTime,matchStatus,venue, all_matches.displayName,team1.teamId AS `team1Id`,team1.name AS 'team1Name', team1.displayName AS 'team1DisplayName',team1.teamFlagUrlLocal AS 'team1FlagURL', team2.teamId AS `team2Id`,team2.name AS 'team2Name', team2.displayName AS 'team2DisplayName',team2.teamFlagUrlLocal AS 'team2FlagURL' FROM all_matches JOIN teams AS team1 ON all_matches.team1_id = team1.teamId JOIN teams AS team2 ON all_matches.team2_id = team2.teamId JOIN match_type ON match_type.matchTypeId = gameType WHERE matchStatus = 1 ORDER BY matchStartTimeMilliSeconds DESC LIMIT 5;";
  const isNotificationQuery =
    "SELECT COUNT(*) > 0 AS isNotification FROM notifications JOIN notification_history ON notification_history.userId = notifications.userId WHERE notifications.userId = ? AND notifications.creationTime > notification_history.lastTimeCalled";

  try {
    const upcomingMatches = await fetchData(upcomingMatchesQuery);
    const isNotification = await fetchData(isNotificationQuery, [userId]);
    if (upcomingMatches.length > 0) {
      const { data } = await axios({
        url: "http://192.168.1.32:3000/api/v1/prediction/getTrendingPredictors",
        headers: { authtoken },
      });
      // const start = Date.now();
      // while (Date.now() - start < 5000) {}
      if (data.status) {
        res.status(200).json({
          status: true,
          message: "success",
          data: {
            matches: upcomingMatches,
            predictors: [...data.data.trendingPredictors],
            news: [],
            isNotification: isNotification[0].isNotification,
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
            isNotification: 0,
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
