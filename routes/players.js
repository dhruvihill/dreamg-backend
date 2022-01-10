const express = require("express");
const router = express.Router();
// const axios = require("axios");
const connection = require("../database/db_connection");

// SELECT (SELECT COUNT(*) AS selectedBy FROM user_team_data WHERE 3391 IN (player1,player2,player3,player4,player5,player6,player7,player8,player9,player10,player11) AND user_team_data.userTeamId IN (SELECT user_team.userTeamId AS userTeamId FROM user_team WHERE matchId = 27947)) * 100 / (SELECT COUNT(*) FROM user_team WHERE matchId = 27947) AS selectedBy, ((SELECT COUNT(*) AS selectedBy FROM user_team_data WHERE 3391 IN (captain) AND user_team_data.userTeamId IN (SELECT user_team.userTeamId AS userTeamId FROM user_team WHERE matchId = 27947)) * 100 / (SELECT COUNT(*) FROM user_team WHERE matchId = 27947)) AS captainSelectedBy, ((SELECT COUNT(*) AS selectedBy FROM user_team_data WHERE 3391 IN (viceCaptain) AND user_team_data.userTeamId IN (SELECT user_team.userTeamId AS userTeamId FROM user_team WHERE matchId = 27947)) * 100 / (SELECT COUNT(*) FROM user_team WHERE matchId = 27947)) as viceCaptainSelectedBy;

router.post("/getplayers", (req, res) => {
  const { matchId } = req.body;

  query = `SELECT matchId,match_player_relation.playerId AS playerId,players.name AS playerName,players.displayName AS playerDisplayName,player_roles.roleId AS roleId,player_roles.roleName AS roleName,players.profilePictureURLLocal AS URL, points, credits, teams.teamId AS teamId,teams.name AS teamName,teams.displayName AS teamDisplayName FROM match_player_relation JOIN players ON players.playerId = match_player_relation.playerId JOIN player_roles ON players.role = player_roles.roleId JOIN teams ON teams.teamId = match_player_relation.teamId WHERE matchId = ?;`;
  playerQueryOld = `SELECT COUNT(*) AS selectedBy FROM user_team_data WHERE ? IN (player1,player2,player3,player4,player5,player6,player7,player8,player9,player10,player11) AND user_team_data.userTeamId IN (SELECT user_team.userTeamId AS userTeamId FROM user_team WHERE matchId = ?) UNION SELECT COUNT(*) FROM user_team WHERE matchId = ?;`;
  playerQueryNew = `SELECT (SELECT COUNT(*) FROM user_team_data WHERE ? IN (captain) AND user_team_data.userTeamId IN (SELECT user_team.userTeamId AS userTeamId FROM user_team WHERE matchId = ?)) * 100 / (SELECT COUNT(DISTINCT userId) FROM user_team WHERE matchId = ?) AS captainBy, (SELECT COUNT(*) FROM user_team_data WHERE ? IN (viceCaptain) AND user_team_data.userTeamId IN (SELECT user_team.userTeamId AS userTeamId FROM user_team WHERE matchId = ?)) * 100 / (SELECT COUNT(DISTINCT userId) FROM user_team WHERE matchId = ?) AS viceCaptainBy, (SELECT COUNT(*) FROM user_team_data WHERE ? IN (player1,player2,player3,player4,player5,player6,player7,player8,player9,player10,player11) AND user_team_data.userTeamId IN (SELECT user_team.userTeamId AS userTeamId FROM user_team WHERE matchId = ?)) * 100 / (SELECT COUNT(DISTINCT userId) FROM user_team WHERE matchId = ?) AS selectedBy;`;
  connection.query(query, [matchId], (err, response) => {
    try {
      if (err) throw err;
      else {
        if (response.length > 0) {
          const calculateSelectedBy = () => {
            return new Promise((resolve, reject) => {
              response.forEach((player, index) => {
                connection.query(
                  playerQueryNew,
                  [player.playerId, matchId, matchId,player.playerId, matchId, matchId,player.playerId, matchId, matchId],
                  (error, responseData) => {
                    try {
                      if (error) throw error;
                      else {
                        // if (responseData.length > 1) {
                          player.captainBy = parseFloat(responseData[0].captainBy.toFixed(2));
                          player.viceCaptainBy = parseFloat(responseData[0].viceCaptainBy.toFixed(2));
                          player.selectedBy = parseFloat(responseData[0].selectedBy.toFixed(2));
                          // if (responseData[1].selectedBy > 0) {
                          //   player.selectedBy = parseFloat(((responseData[0].selectedBy * 100) / responseData[1].selectedBy).toFixed(2));
                          // } else {
                          //   player.selectedBy = 0;
                          // }
                        // } else {
                        //   player.selectedBy = 0;
                        // }
                        if (index === response.length - 1) {
                          resolve();
                        }
                      }
                    } catch (error) {
                      reject(error);
                    }
                  }
                );
              });
            });
          };
          calculateSelectedBy()
            .then(() => {
              res.status(200).json({
                status: true,
                message: "success",
                data: {
                  players: response,
                },
              });
            })
            .catch((error) => {
              res.status(400).json({
                status: false,
                message: error.message,
                data: {
                  players: [],
                },
              });
            });
        } else {
          throw { message: "invalid matchId" };
        }
      }
    } catch (error) {
      res.status(400).json({
        status: false,
        message: error.message,
        data: {},
      });
    }
  });
});

router.post("/setteam", (req, res) => {
  const { userTeamType, matchId, players, captain, viceCaptain, userId } = req.body;

  const query = "INSERT INTO user_team_data SET ?";
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
  connection.query(query, options, (err, response) => {
    try {
      if (err) throw err;
      else {
        connection.query(
          "INSERT INTO user_team SET ?",
          { matchId, userId, userTeamId: response.insertId, userTeamType },
          (middleErr, middleResponse) => {
            try {
              if (middleErr) throw middleErr;
              else {
                let responseArray = [];
                const fetchData = () => {
                  return new Promise((resolve, reject) => {
                    players.forEach((playerId) => {
                      innerQuery = `SELECT match_player_relation.playerId AS playerId,players.name AS playerName,players.displayName AS playerDisplayName,player_roles.roleId AS roleId,player_roles.roleName AS roleName,players.profilePictureURLLocal AS URL, points, credits, teams.teamId AS teamId,teams.name AS teamName,teams.displayName AS teamDisplayName FROM match_player_relation JOIN players ON players.playerId = match_player_relation.playerId JOIN player_roles ON players.role = player_roles.roleId JOIN teams ON teams.teamId = match_player_relation.teamId WHERE match_player_relation.playerId = ? AND match_player_relation.matchId = ?;`;
                      innerQueryOptions = [playerId, matchId];
                      connection.query(
                        innerQuery,
                        innerQueryOptions,
                        (innerErr, innerResponse) => {
                          try {
                            if (innerErr) throw innerErr;
                            else {
                              const playerDetails = {
                                matchId,
                                playerId, 
                                playerName: innerResponse[0].playerName,
                                playerDisplayName:
                                  innerResponse[0].playerDisplayName,
                                captain: playerId == captain,
                                viceCaptain: playerId == viceCaptain,
                                roleId: innerResponse[0].roleId,
                                roleName: innerResponse[0].roleName,
                                URL: innerResponse[0].URL,
                                points: innerResponse[0].points,
                                credits: innerResponse[0].credits,
                                teamId: innerResponse[0].teamId,
                                teamName: innerResponse[0].teamName,
                                teamDisplayName:
                                  innerResponse[0].teamDisplayName,
                              };
                              responseArray.push(playerDetails);
                              if (responseArray.length === 11) {
                                resolve();
                              }
                            }
                          } catch (error) {
                            reject(error);
                          }
                        }
                      );
                    });
                  });
                };
                fetchData()
                  .then(() => {
                    res.status(200).json({
                      status: true,
                      message: "success",
                      data: {
                        players: responseArray,
                      },
                    });
                  })
                  .catch((error) => {
                    res.status(400).json({
                      status: false,
                      message: error.message,
                      data: {},
                    });
                  });
              }
            } catch (error) {
              connection.query(
                "DELETE FROM `user_team_data` WHERE `user_team_data`.`userTeamId` = ?",
                [response.insertId],
                (errors) => {
                  if (errors) {
                  }
                }
              );
              res.status(400).json({
                status: false,
                message: error.message.includes("Duplicate entry")
                  ? "Duplicate entry"
                  : error.message,
                data: {},
              });
            }
          }
        );
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
  });
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


