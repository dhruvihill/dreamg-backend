const express = require("express");
const router = express.Router();
const verifyUser = require("../middleware/verifyUser");
const { fetchData, getPlayers } = require("../database/db_connection");

router.post("/getplayers", verifyUser, async (req, res) => {
  const { matchId } = req.body;

  // const allPlayersQuery = `SELECT matchId,match_player_relation.playerId AS playerId,players.name AS playerName,players.displayName AS playerDisplayName,player_roles.roleId AS roleId,player_roles.roleName AS roleName,players.profilePictureURLLocal AS URL, points, credits, teams.teamId AS teamId,teams.name AS teamName,teams.displayName AS teamDisplayName FROM match_player_relation JOIN players ON players.playerId = match_player_relation.playerId JOIN player_roles ON players.role = player_roles.roleId JOIN teams ON teams.teamId = match_player_relation.teamId WHERE matchId = ?;`;
  // const playerDetailsQuery = `SELECT (SELECT COUNT(*) FROM user_team_data WHERE ? IN (captain) AND user_team_data.userTeamId IN (SELECT user_team.userTeamId AS userTeamId FROM user_team WHERE matchId = ?)) * 100 / (SELECT COUNT(userId) FROM user_team WHERE matchId = ?) AS captainBy, (SELECT COUNT(*) FROM user_team_data WHERE ? IN (viceCaptain) AND user_team_data.userTeamId IN (SELECT user_team.userTeamId AS userTeamId FROM user_team WHERE matchId = ?)) * 100 / (SELECT COUNT(userId) FROM user_team WHERE matchId = ?) AS viceCaptainBy, (SELECT COUNT(*) FROM user_team_data WHERE ? IN (player1,player2,player3,player4,player5,player6,player7,player8,player9,player10,player11) AND user_team_data.userTeamId IN (SELECT user_team.userTeamId AS userTeamId FROM user_team WHERE matchId = ?)) * 100 / (SELECT COUNT(userId) FROM user_team WHERE matchId = ?) AS selectedBy;`;

  try {
    if (!/[^0-9]/g.test(matchId)) {
      // const allPlayers = await fetchData(allPlayersQuery, [matchId]);
      const data = await getPlayers(matchId);

      if (data[0][0].isMatchIdCorrect) {
        data[1]?.forEach((player) => {
          player.captainBy = parseFloat(player.captainBy.toFixed(2));
          player.viceCaptainBy = parseFloat(player.viceCaptainBy.toFixed(2));
          player.selectedBy = parseFloat(player.selectedBy.toFixed(2));
          // changing url address
          player.URL = player.URL.replace(
            "http://192.168.1.32:3000",
            `${req.protocol}://${req.headers.host}`
          );
        });
        res.status(200).json({
          status: true,
          message: "success",
          data: {
            players: data[1],
          },
        });
      } else {
        throw { message: "invalid input" };
      }

      // if (allPlayers.length > 0) {
      //   const calculateSelectedBy = () => {
      //     return new Promise((resolve, reject) => {
      //       allPlayers.forEach(async (player, index) => {
      //         try {
      //           const playerDetails = await fetchData(playerDetailsQuery, [
      //             player.playerId,
      //             matchId,
      //             matchId,
      //             player.playerId,
      //             matchId,
      //             matchId,
      //             player.playerId,
      //             matchId,
      //             matchId,
      //           ]);
      //           player.captainBy = parseFloat(
      //             playerDetails[0].captainBy.toFixed(2)
      //           );
      //           player.viceCaptainBy = parseFloat(
      //             playerDetails[0].viceCaptainBy.toFixed(2)
      //           );
      //           player.selectedBy = parseFloat(
      //             playerDetails[0].selectedBy.toFixed(2)
      //           );
      //           // changing url address
      //           player.URL = player.URL.replace(
      //             "http://192.168.1.32:3000",
      //             `${req.protocol}://${req.headers.host}`
      //           );

      //           if (index === allPlayers.length - 1) resolve();
      //         } catch (error) {
      //           reject(error);
      //         }
      //       });
      //     });
      //   };
      //   calculateSelectedBy()
      //     .then(() => {
      //       res.status(200).json({
      //         status: true,
      //         message: "success",
      //         data: {
      //           players: allPlayers,
      //         },
      //       });
      //     })
      //     .catch((error) => {
      //       res.status(400).json({
      //         status: false,
      //         message: error.message,
      //         data: {},
      //       });
      //     });
      // } else {
      //   throw { message: "invalid matchId" };
      // }
    } else {
      throw { message: "invalid input" };
    }
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.message,
      data: {},
    });
  }
});

router.post("/setteam", verifyUser, async (req, res) => {
  const { userTeamType, matchId, players, captain, viceCaptain, userId } =
    req.body;

  const newSet = new Set(players);

  const regx = /[^0-9]/g;

  let correctInput = true;
  [userTeamType, matchId, ...players, captain, viceCaptain].forEach((id) => {
    if (regx.test(id)) {
      correctInput = false;
    }
  });

  if (
    newSet.size === 11 &&
    correctInput &&
    players.includes(captain) &&
    players.includes(viceCaptain)
  ) {
    let allowInsert = true;
    try {
      // check all the players exists in matchId
      for (let index = 0; index < 11; index++) {
        const playerExists = await fetchData(
          "SELECT EXISTS(SELECT * FROM match_player_relation WHERE matchId = ? AND playerId = ?) AS playerExists;",
          [matchId, players[index]]
        );
        if (!playerExists[0].playerExists) allowInsert = false;
      }

      if (allowInsert) {
        const setPlayersQuery = "INSERT INTO user_team_data SET ?";
        const setTeamQuery = "INSERT INTO user_team SET ?";
        const options = {
          captain,
          viceCaptain,
          player1: players[0],
          player2: players[1],
          player3: players[2],
          player4: players[3],
          player5: players[4],
          player6: players[5],
          player7: players[6],
          player8: players[7],
          player9: players[8],
          player10: players[9],
          player11: players[10],
        };

        try {
          const setPlayers = await fetchData(setPlayersQuery, options);

          if (setPlayers.insertId) {
            try {
              await fetchData(setTeamQuery, {
                matchId,
                userId,
                userTeamId: setPlayers.insertId,
                userTeamType,
              });
              res.status(200).json({
                status: true,
                message: "success",
                data: {},
              });
            } catch (error) {
              fetchData(
                "DELETE FROM `user_team_data` WHERE `user_team_data`.`userTeamId` = ?",
                [setPlayers.insertId]
              ).catch((err) => {});
              res.status(400).json({
                status: false,
                message: error.message.includes("Duplicate entry")
                  ? "Duplicate entry"
                  : error.message,
                data: {},
              });
            }
          } else {
            throw { message: "team not inserted" };
          }
        } catch (error) {
          res.status(400).json({
            status: false,
            message: error.message.includes("Duplicate entry")
              ? "Duplicate entry"
              : error.message,
            data: {},
          });
        }
      } else {
        throw { message: "invalid input" };
      }
    } catch (error) {
      res.status(400).json({
        status: false,
        message: error.message,
        data: {},
      });
    }
  } else {
    res.status(400).json({
      status: false,
      message: "invalid input",
      data: {},
    });
  }
});

module.exports = router;

// (SELECT COUNT(*) FROM user_team_data WHERE 3391 IN (captain) AND user_team_data.userTeamId IN (SELECT user_team.userTeamId AS userTeamId FROM user_team WHERE matchId = 27947)) * 100 / (SELECT COUNT(DISTINCT userId) FROM user_team WHERE matchId = 27947) AS captainBy;

// Query to insert match-player-relation
// connection.query("SELECT matchId from all_matches", (err, res) => {
// if (err) console.log(err.sqlMessage);
// else {
//   res.forEach((matchId) => {
//     axios({
//       url: "https://www.my11circle.com/api/lobbyApi/matches/v1/getMatchSquad",
//       method: "POST",
//       headers: { Cookie: "SSID=SSIDb8c3b007-7d70-43a3-9f11-e8a61fcbcc51" },
//       data: { matchId: matchId.matchId },
//     })
//       .then((res) => {
//         console.log(res);
// const query = "INSERT INTO match_player_relation SET ?";
// res.data.players.forEach((player) => {
//   const queryObject = {
//     matchId: matchId.matchId,
//     playerId: player.id,
//     teamId: player.teamId,
//     credits: player.credits | 0,
//     points: player.points | 0,
//   };
//   connection.query(query, queryObject, (err, response) => {
//     if (err) {
//       if (err.sqlMessage.includes("Duplicate")) {
//         console.log("ERROR: Duplicate Entry")
//       } else {
//         console.log(err.sqlMessage);
//       }
//     }
//     else {
//       // console.log(response);
//     }
//   });
// });
//         })
//         .catch((err) => {
//           console.log("Axios: ", err);
//         });
//     });
//   }
// });

// Query to insert all players match By match
// connection.query("SELECT matchId from all_matches", (err, res) => {
//   if (err) console.log(err.sqlMessage);
//   else {
//     res.forEach((matchId) => {
//       axios({
//         url: "https://www.my11circle.com/api/lobbyApi/matches/v1/getMatchSquad",
//         method: "POST",
//         headers: { Cookie: "SSID=SSIDf877b52a-fb99-4e80-96a3-ad87b28b963b" },
//         data: { matchId: matchId.matchId },
//       })
//         .then((res) => {
//           const query = "INSERT INTO players SET ?";
//           res.data.players.forEach((player) => {
//             const queryObject = {
//               playerId: player.id,
//               name: player.name,
//               displayName: player.dName,
//               role: player.role,
//               url: player.imgURL,
//             };
//             connection.query(query, queryObject, (err, response) => {
//               if (err) console.log(err.sqlMessage);
//               else {
//                 console.log(response);
//               }
//             });
//           });
//         })
//         .catch((err) => {
//           console.log("Axios: ", err);
//         });
//     });
//   }
// });
