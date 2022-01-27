const express = require("express");
const router = express.Router();
const verifyUser = require("../middleware/verifyUser");
const { fetchData, updateLikes } = require("../database/db_connection");
const { default: axios } = require("axios");

router.post("/get_predictions", verifyUser, async (req, res) => {
  const { matchId, filter } = req.body;

  let validMatchId = true;

  // creating query to fetch predictions
  let query;
  if (matchId) {
    validMatchId = true;
    if (!/[^0-9]/g.test(matchId)) validMatchId = true;
    query =
      filter === "MOST_VIEWED"
        ? "SELECT user_team.userId, phoneNumber, firstName, lastName, displayPicture,city, registerTime, all_matches.displayName, SUM(user_team_data.userTeamViews) AS totalViews FROM user_team JOIN user_team_data ON user_team_data.userTeamId = user_team.userTeamId JOIN all_users ON user_team.userId = all_users.userId JOIN all_matches ON user_team.matchId = all_matches.matchId WHERE user_team.matchId = ? GROUP BY userId ORDER BY totalViews DESC LIMIT 20;"
        : filter === "MOST_LIKED"
        ? "SELECT user_team.userId, phoneNumber, firstName, lastName, displayPicture,city, registerTime, all_matches.displayName, SUM(user_team_data.userTeamLikes) AS totalLikes FROM user_team JOIN user_team_data ON user_team_data.userTeamId = user_team.userTeamId JOIN all_users ON user_team.userId = all_users.userId JOIN all_matches ON user_team.matchId = all_matches.matchId WHERE user_team.matchId = ? GROUP BY userId ORDER BY totalLikes DESC LIMIT 20;"
        : "SELECT user_team.userId, phoneNumber, firstName, lastName, displayPicture,city, registerTime, all_matches.displayName, SUM(user_team_data.userTeamPoints) AS totalPoints FROM user_team JOIN user_team_data ON user_team_data.userTeamId = user_team.userTeamId JOIN all_users ON user_team.userId = all_users.userId JOIN all_matches ON user_team.matchId = all_matches.matchId WHERE user_team.matchId = ? GROUP BY userId ORDER BY totalPoints DESC LIMIT 20;";
  } else {
    query =
      filter === "MOST_VIEWED"
        ? "SELECT user_team.userId, phoneNumber, firstName, lastName, displayPicture,city, registerTime, user_team.userTeamId, SUM(userTeamViews) AS totalViews FROM user_team JOIN all_users ON all_users.userId = user_team.userId JOIN user_team_data ON user_team_data.userTeamId = user_team.userTeamId GROUP BY user_team.userId ORDER BY totalViews DESC"
        : filter === "MOST_LIKED"
        ? "SELECT user_team.userId, phoneNumber, firstName,city, lastName, displayPicture, registerTime, user_team.userTeamId, SUM(userTeamLikes) AS totalLikes FROM user_team JOIN all_users ON all_users.userId = user_team.userId JOIN user_team_data ON user_team_data.userTeamId = user_team.userTeamId GROUP BY user_team.userId ORDER BY totalLikes DESC;"
        : "SELECT user_team.userId, phoneNumber, firstName, lastName, displayPicture,city, registerTime, user_team.userTeamId, SUM(userTeamPoints) AS totalPoints FROM user_team JOIN all_users ON all_users.userId = user_team.userId JOIN user_team_data ON user_team_data.userTeamId = user_team.userTeamId GROUP BY user_team.userId ORDER BY totalPoints DESC;";
  }
  try {
    if (validMatchId) {
      const result = await fetchData(query, [matchId]);

      result.forEach((element) => {
        element.displayPicture = element.displayPicture.replace(
          "http://192.168.1.32:3000",
          `${req.protocol}://${req.headers.host}`
        );
      });

      if (result.length > 0) {
        res.status(200).json({
          status: true,
          message: "success",
          data: { users: result },
        });
      } else {
        throw { message: "no team created" };
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
});

router.get("/getTrendingPredictors", verifyUser, async (req, res) => {
  const recentMatchesQuery =
    "SELECT all_matches.matchId FROM all_matches WHERE (all_matches.matchStartTimeMilliSeconds < unix_timestamp(now()) * 1000 AND all_matches.matchStatus = 3) OR all_matches.matchId = 27947 ORDER By matchStartTimeMilliSeconds DESC LIMIT 5";
  const topPredictorsQuery =
    "SELECT all_users.firstName, all_users.lastName, all_users.displayPicture, user_team.userId, SUM(user_team_data.userTeamPoints) AS totalPoints FROM user_team JOIN user_team_data ON user_team_data.userTeamId = user_team.userTeamId JOIN all_users ON all_users.userId = user_team.userId WHERE user_team.matchId IN (?) GROUP BY userId ORDER BY totalPoints DESC LIMIT 10";

  try {
    const recentMatches = await fetchData(recentMatchesQuery);
    const matchIds = recentMatches.map(({ matchId }) => matchId);
    const predictor = await fetchData(topPredictorsQuery, [matchIds.join(",")]);

    // replace server address
    predictor.forEach((trending) => {
      trending.displayPicture = trending.displayPicture.replace(
        "http://192.168.1.32:3000",
        `${req.protocol}://${req.headers.host}`
      );
    });
    res.status(200).json({
      status: true,
      message: "success",
      data: {
        trendingPredictors: predictor,
      },
    });
  } catch (error) {
    res.status(200).json({
      status: false,
      message: error.message,
      data: {},
    });
  }
});

router.post("/get_user_teams", verifyUser, async (req, res) => {
  const { createrId, matchId } = req.body;

  // Query for fetch all players playerid
  const playersQuery =
    "SELECT user_team_data.userTeamId AS userTeamId, teamTypeString, captain, userTeamLikes AS likes, viceCaptain, player1, player2, player3, player4, player5, player6, player7, player8, player9, player10, player11 FROM user_team_data JOIN user_team ON user_team.userTeamId = user_team_data.userTeamId JOIN team_type ON userTeamType = teamType WHERE user_team_data.userTeamId IN (SELECT userTeamId FROM user_team WHERE matchId = ? AND userId = ?);";
  const teamDetailsQuery =
    "SELECT team1_id AS team1Id, team1.name AS team1Name, team1.displayName AS team1DisplayName, team1.teamFlagURLLocal AS team1FlagURL, team2_id AS team2Id, team2.name AS team2Name, team2.displayName AS team2DisplayName, team2.teamFlagURLLocal AS team2FlagURL FROM all_matches JOIN teams AS team1 ON team1.teamId = team1_id JOIN teams AS team2 ON team2.teamId = team2_id WHERE matchId = ?;";
  const playerDetailsQuery =
    "SELECT match_player_relation.playerId AS playerId,players.name AS playerName,players.displayName AS playerDisplayName,player_roles.roleId AS roleId,player_roles.roleName AS roleName,players.profilePictureURLLocal AS URL, points, credits, teams.teamId AS teamId FROM match_player_relation JOIN players ON players.playerId = match_player_relation.playerId JOIN player_roles ON players.role = player_roles.roleId JOIN teams ON teams.teamId = match_player_relation.teamId WHERE match_player_relation.playerId = ? AND match_player_relation.matchId = ?;";

  try {
    if (!/[^0-9]/g.test(matchId)) {
      const players = await fetchData(playersQuery, [matchId, createrId]);
      const teamDetails = await fetchData(teamDetailsQuery, [matchId]);

      if (players.length > 0) {
        const fetchTeams = () =>
          new Promise((resolve, reject) => {
            let allTeams = [];
            players.forEach(async (team, index) => {
              try {
                let singleTeam = {
                  teams: [{ teamTotalPlayers: 0 }, { teamTotalPlayers: 0 }],
                  teamsDetails: {
                    userTeamId: team["userTeamId"],
                    creditUsed: 0,
                    teamType: team.teamTypeString,
                    totalWicketKeeper: 0,
                    totalBatsman: 0,
                    totalBowlers: 0,
                    totalAllrounders: 0,
                    captain: {},
                    viceCaptain: {},
                  },
                };

                const ignoreKeys = [
                  "captain",
                  "viceCaptain",
                  "teamTypeString",
                  "likes",
                  "userTeamId",
                ]; // keys to be ignored

                // extract single team from teamData and store it
                for (let j = 0; j < 2; j++) {
                  singleTeam.teams[j] = {
                    ...singleTeam.teams[j],
                    teamId: teamDetails[0][`team${j + 1}Id`],
                    teamName: teamDetails[0][`team${j + 1}Name`],
                    teamDisplayName: teamDetails[0][`team${j + 1}DisplayName`],
                    teamFlagURL: teamDetails[0][`team${j + 1}FlagURL`].replace(
                      "http://192.168.1.32:3000",
                      `${req.protocol}://${req.headers.host}`
                    ),
                  };
                }

                let i = 0;
                for (const key in team) {
                  if (!ignoreKeys.includes(key)) {
                    const player = await fetchData(playerDetailsQuery, [
                      team[key],
                      matchId,
                    ]);

                    // changing server address
                    player[0].URL = player[0].URL.replace(
                      "http://192.168.1.32:3000",
                      `${req.protocol}://${req.headers.host}`
                    );

                    // storing captains and vicecaptain details
                    if (team[key] === team["captain"])
                      singleTeam.teamsDetails.captain = player[0];
                    else if (team[key] === team["viceCaptain"])
                      singleTeam.teamsDetails.viceCaptain = player[0];

                    // calculating how many credits used
                    singleTeam.teamsDetails.creditUsed += player[0].credits;

                    // updating count of bowlers,batsman, wicketkeeper and allrounder
                    if (player[0].roleName === "BOWLER")
                      singleTeam.teamsDetails.totalBowlers++;
                    else if (player[0].roleName === "BATSMAN")
                      singleTeam.teamsDetails.totalBatsman++;
                    else if (player[0].roleName === "WICKET_KEEPER")
                      singleTeam.teamsDetails.totalWicketKeeper++;
                    else if (player[0].roleName === "ALL_ROUNDER")
                      singleTeam.teamsDetails.totalAllrounders++;

                    // updating count of teams total player
                    if (player[0].teamId === singleTeam.teams[0].teamId)
                      singleTeam.teams[0].teamTotalPlayers++;
                    else if (player[0].teamId === singleTeam.teams[1].teamId)
                      singleTeam.teams[1].teamTotalPlayers++;

                    i++;

                    if (i === 11) {
                      allTeams.push(singleTeam); // push single player in team allteams
                      if (players.length === index + 1) {
                        resolve(allTeams);
                      }
                    }
                  }
                }
              } catch (error) {
                reject(error);
              }
            });
          });
        const allTeams = await fetchTeams();
        res.status(200).json({
          status: true,
          message: "success",
          data: { userTeams: allTeams },
        });
      } else {
        throw { message: "user have no team created" };
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
});

router.post("/get_user_teams_predictor", verifyUser, async (req, res) => {
  const { createrId } = req.body;

  // Query for fetch all players playerid
  const playersQuery =
    "SELECT user_team.matchId, user_team_data.userTeamId AS userTeamId, teamTypeString, captain, userTeamLikes AS likes, viceCaptain, player1, player2, player3, player4, player5, player6, player7, player8, player9, player10, player11 FROM user_team_data JOIN user_team ON user_team.userTeamId = user_team_data.userTeamId JOIN team_type ON userTeamType = teamType WHERE user_team.userId = ?;";
  const teamDetailsQuery =
    "SELECT team1_id AS team1Id, team1.name AS team1Name, team1.displayName AS team1DisplayName, team1.teamFlagURLLocal AS team1FlagURL, team2_id AS team2Id, team2.name AS team2Name, team2.displayName AS team2DisplayName, team2.teamFlagURLLocal AS team2FlagURL FROM all_matches JOIN teams AS team1 ON team1.teamId = team1_id JOIN teams AS team2 ON team2.teamId = team2_id WHERE matchId = ?;";
  const playerDetailsQuery =
    "SELECT match_player_relation.playerId AS playerId,players.name AS playerName,players.displayName AS playerDisplayName,player_roles.roleId AS roleId,player_roles.roleName AS roleName,players.profilePictureURLLocal AS URL, points, credits, teams.teamId AS teamId FROM match_player_relation JOIN players ON players.playerId = match_player_relation.playerId JOIN player_roles ON players.role = player_roles.roleId JOIN teams ON teams.teamId = match_player_relation.teamId WHERE match_player_relation.playerId = ? AND match_player_relation.matchId = ?;";

  try {
    const players = await fetchData(playersQuery, [createrId]);
    if (players.length > 0) {
      const fetchTeams = () =>
        new Promise((resolve, reject) => {
          let allTeams = [];
          players.forEach(async (team, index) => {
            try {
              let singleTeam = {
                teams: [{ teamTotalPlayers: 0 }, { teamTotalPlayers: 0 }],
                teamsDetails: {
                  userTeamId: team["userTeamId"],
                  creditUsed: 0,
                  teamType: team.teamTypeString,
                  totalWicketKeeper: 0,
                  totalBatsman: 0,
                  totalBowlers: 0,
                  totalAllrounders: 0,
                  captain: {},
                  viceCaptain: {},
                },
              };
              const ignoreKeys = [
                "captain",
                "viceCaptain",
                "teamTypeString",
                "likes",
                "userTeamId",
                "matchId",
              ]; // keys to be ignored

              const teamDetails = await fetchData(teamDetailsQuery, [
                team.matchId,
              ]);
              if (teamDetails.length !== 0) {
                // extract single team from teamData and store it
                for (let j = 0; j < 2; j++) {
                  singleTeam.teams[j] = {
                    ...singleTeam.teams[j],
                    teamId: teamDetails[0][`team${j + 1}Id`],
                    teamName: teamDetails[0][`team${j + 1}Name`],
                    teamDisplayName: teamDetails[0][`team${j + 1}DisplayName`],
                    teamFlagURL: teamDetails[0][`team${j + 1}FlagURL`].replace(
                      "http://192.168.1.32:3000",
                      `${req.protocol}://${req.headers.host}`
                    ),
                  };
                }

                let i = 0;
                for (const key in team) {
                  if (!ignoreKeys.includes(key)) {
                    const player = await fetchData(playerDetailsQuery, [
                      team[key],
                      team.matchId,
                    ]);
                    // changing server address
                    player[0].URL = player[0].URL.replace(
                      "http://192.168.1.32:3000",
                      `${req.protocol}://${req.headers.host}`
                    );

                    // storing captains and vicecaptain details
                    if (team[key] === team["captain"])
                      singleTeam.teamsDetails.captain = player[0];
                    else if (team[key] === team["viceCaptain"])
                      singleTeam.teamsDetails.viceCaptain = player[0];

                    // calculating how many credits used
                    singleTeam.teamsDetails.creditUsed += player[0].credits;

                    // updating count of bowlers,batsman, wicketkeeper and allrounder
                    if (player[0].roleName === "BOWLER")
                      singleTeam.teamsDetails.totalBowlers++;
                    else if (player[0].roleName === "BATSMAN")
                      singleTeam.teamsDetails.totalBatsman++;
                    else if (player[0].roleName === "WICKET_KEEPER")
                      singleTeam.teamsDetails.totalWicketKeeper++;
                    else if (player[0].roleName === "ALL_ROUNDER")
                      singleTeam.teamsDetails.totalAllrounders++;

                    // updating count of teams total player
                    if (player[0].teamId === singleTeam.teams[0].teamId)
                      singleTeam.teams[0].teamTotalPlayers++;
                    else if (player[0].teamId === singleTeam.teams[1].teamId)
                      singleTeam.teams[1].teamTotalPlayers++;

                    i++;

                    if (i === 11) {
                      allTeams.push(singleTeam); // push single player in team allteams
                      if (players.length === index + 1) {
                        resolve(allTeams);
                      }
                    }
                  }
                }
              } else {
                throw { message: "team not exixts" };
              }
            } catch (error) {
              reject(error);
            }
          });
        });
      const allTeams = await fetchTeams();
      res.status(200).json({
        status: true,
        message: "success",
        data: { userTeams: allTeams },
      });
    } else {
      throw { message: "user have no team created" };
    }
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.message,
      data: {},
    });
  }
});

router.post("/get_user_teams_data", verifyUser, async (req, res) => {
  const { userId, teamId } = req.body;

  // queries to fetch data
  const fetchPlayerIdQuery =
    "SELECT EXISTS(SELECT userId FROM all_likes WHERE userTeamId = ? AND userId = ?) AS isUserLiked, user_team.matchId, user_team_data.userTeamId AS userTeamId, teamTypeString, captain, userTeamLikes AS likes, viceCaptain, player1, player2, player3, player4, player5, player6, player7, player8, player9, player10, player11 FROM user_team JOIN user_team_data ON user_team.userTeamId = user_team_data.userTeamId JOIN team_type ON userTeamType = teamType WHERE user_team_data.userTeamId = ? LIMIT 1;";
  const teamQuery =
    "SELECT team1_id AS team1Id, team1.name AS team1Name, team1.displayName AS team1DisplayName, team1.teamFlagURLLocal AS team1FlagURL, team2_id AS team2Id, team2.name AS team2Name, team2.displayName AS team2DisplayName, team2.teamFlagURLLocal AS team2FlagURL FROM all_matches JOIN teams AS team1 ON team1.teamId = team1_id JOIN teams AS team2 ON team2.teamId = team2_id WHERE matchId = ?;";
  const playerQuery =
    "SELECT match_player_relation.playerId AS playerId,players.name AS playerName,players.displayName AS playerDisplayName,player_roles.roleId AS roleId,player_roles.roleName AS roleName,players.profilePictureURLLocal AS URL, points, credits, teams.teamId AS teamId FROM match_player_relation JOIN players ON players.playerId = match_player_relation.playerId JOIN player_roles ON players.role = player_roles.roleId JOIN teams ON teams.teamId = match_player_relation.teamId WHERE match_player_relation.playerId = ? AND match_player_relation.matchId = ?;";

  try {
    if (!/[^0-9]/g.test(teamId)) {
      const playersIds = await fetchData(fetchPlayerIdQuery, [
        teamId,
        userId,
        teamId,
      ]);
      const teamData = await fetchData(teamQuery, [playersIds[0]?.matchId]);

      // checking if playerids exists or not
      if (playersIds?.length > 0) {
        let newAllTeams = [];

        // function to fetch all the users
        playersIds.forEach(async (team, index) => {
          // creating data structure for team
          let singleTeam = {
            players: [],
            teamsDetails: {
              ...teamData[0],
              userTeamId: team["userTeamId"],
              likes: team["likes"],
              isUserLiked: team["isUserLiked"],
              teamType: team.teamTypeString,
              captain: {},
              viceCaptain: {},
            },
          };
          let i = 0;
          const ignoreKeys = [
            "captain",
            "viceCaptain",
            "teamTypeString",
            "likes",
            "views",
            "userTeamId",
            "isUserLiked",
            "matchId",
          ];

          // looping througth playerid to get all players details
          for (const key in team) {
            if (!ignoreKeys.includes(key)) {
              const player = await fetchData(playerQuery, [
                team[key],
                team.matchId,
              ]);

              // changing server address
              player[0].URL = player[0].URL.replace(
                "http://192.168.1.32:3000",
                `${req.protocol}://${req.headers.host}`
              );

              if (team[key] === team["captain"])
                singleTeam.teamsDetails.captain = player[0];
              else if (team[key] === team["viceCaptain"])
                singleTeam.teamsDetails.viceCaptain = player[0];

              singleTeam.players.push(player[0]);
              i++;

              if (i === 11) {
                newAllTeams.push(singleTeam);
                if (playersIds.length === index + 1) {
                  res.status(200).json({
                    status: true,
                    message: "success",
                    data: {
                      teams: newAllTeams,
                    },
                  });
                }
              }
            }
          }
        });
      } else {
        throw { message: "user have no team" };
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
});

router.post("/update_user_team_likes", verifyUser, async (req, res) => {
  let { userId, teamId } = req.body;

  try {
    if (!/[^0-9]/g.test(teamId)) {
      const response = await updateLikes(userId, teamId);
      if (response["@isTeamExists"] && response["@isUserExists"]) {
        res.status(200).json({
          status: true,
          message: "success",
          data: {
            totalLikes: response["@likes"],
            isUserLiked: response["@isUserLiked"],
          },
        });
      } else {
        throw { message: "invalid input" };
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

  // if (!/[^0-9]/g.test(teamId)) {
  //   const logUser = () =>
  //     new Promise(async (resolve, reject) => {
  //       try {
  //         const responseData = await fetchData("INSERT INTO all_likes SET ?", {
  //           userTeamId: teamId,
  //           userId,
  //         });
  //         if (responseData) resolve();
  //       } catch (error) {
  //         reject(error);
  //       }
  //       // connection.query(
  //       //   "INSERT INTO all_likes SET ?",
  //       //   { userTeamId: teamId, userId },
  //       //   (err) => {
  //       //     if (err) reject(err);
  //       //     else {
  //       //       resolve();
  //       //     }
  //       //   }
  //       // );
  //     });
  //   logUser()
  //     .then(async () => {
  //       let query =
  //         "UPDATE user_team_data SET userTeamLikes = userTeamLikes + 1 WHERE userTeamId = ?";
  //       try {
  //         const response = await fetchData(query, [teamId]);
  //         if (response.affectedRows > 0) {
  //           res.status(200).json({
  //             status: true,
  //             message: "success",
  //             data: {},
  //           });
  //         } else {
  //           throw { message: "team not exists" };
  //         }
  //       } catch (error) {
  //         res.status(400).json({
  //           status: false,
  //           message: error.message,
  //           data: {},
  //         });
  //       }
  //       // connection.query(query, [teamId], (err, response) => {
  //       //   try {
  //       //     if (err) throw err;
  //       //     else {
  //       //       if (response.affectedRows > 0) {
  //       //         res.status(200).json({
  //       //           status: true,
  //       //           message: "success",
  //       //           data: {},
  //       //         });
  //       //       } else {
  //       //         throw { message: "team not exists" };
  //       //       }
  //       //     }
  //       //   } catch (error) {
  //       //     res.status(400).json({
  //       //       status: false,
  //       //       message: error.message,
  //       //       data: {},
  //       //     });
  //       //   }
  //       // });
  //     })
  //     .catch((error) => {
  //       res.status(400).json({
  //         status: false,
  //         message: error.message.includes("Duplicate entry")
  //           ? "Duplicate Entry"
  //           : error.message,
  //         data: {},
  //       });
  //     });
  // } else {
  //   res.status(400).json({
  //     status: false,
  //     message: "invalid input",
  //     data: {},
  //   });
  // }
});

router.post("/update_user_team_views", verifyUser, async (req, res) => {
  let { userId, teamId } = req.body;

  if (!/[^0-9]/g.test(teamId)) {
    const checkUserViewCountLog = () =>
      new Promise(async (resolve, reject) => {
        try {
          const response = await fetchData(
            "SELECT viewCount FROM all_views WHERE userTeamId = ? AND userId = ?",
            [teamId, userId]
          );
          if (response) resolve(response);
        } catch (error) {
          reject(error);
        }
        // connection.query(
        //   "SELECT viewCount FROM all_views WHERE userTeamId = ? AND userId = ?",
        //   [teamId, userId],
        //   (err, response) => {
        //     if (err) reject(err);
        //     else {
        //       resolve(response);
        //     }
        //   }
        // );
      });
    checkUserViewCountLog()
      .then((response) => {
        if (response.length > 0) {
          fetchData(
            "UPDATE all_views SET viewCount = viewCount + 1 WHERE userTeamId = ? AND userId = ?",
            [teamId, userId]
          )
            .then(() => {
              res.status(200).json({
                status: true,
                message: "success",
                data: {},
              });
            })
            .catch((error) => {
              res.status(400).json({
                status: false,
                message: error.message,
                data: {},
              });
            });
        } else {
          fetchData("INSERT INTO all_views SET ?", {
            userTeamId: teamId,
            userId,
          })
            .then(() => {
              res.status(200).json({
                status: true,
                message: "success",
                data: {},
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
      })
      .catch((error) => {
        res.status(400).json({
          status: false,
          message: error.message,
          data: {},
        });
      });
  } else {
    res.status(400).json({
      status: false,
      message: "invalid input",
      data: {},
    });
  }
});

router.post("/set_discussion", verifyUser, async (req, res) => {
  // userId -> whos have made request means messenger who sends the message
  // createrId -> whose team is
  const { matchId, userId, message, createrId } = req.body;
  const { authtoken } = req.headers;
  try {
    if (
      !/[^0-9]/g.test(matchId) &&
      !/[^0-9]/g.test(createrId) &&
      message.length <= 5000
    ) {
      const response = await fetchData("INSERT INTO discussion SET ? ;", {
        matchId,
        userId: createrId,
        messengerId: userId,
        message,
      });
      if (response) {
        const { data } = await axios({
          method: "POST",
          url: `${req.protocol}://${req.headers.host}/api/v1/prediction/get_discussion`,
          headers: { authtoken },
          data: {
            matchId,
            createrId,
          },
        });
        res.status(200).json({
          status: true,
          message: "success",
          data: {
            message: [...data.data.messages],
          },
        });
      }
      // connection.query(
      //   "INSERT INTO discussion SET ? ;",
      //   { matchId, userId: createrId, messengerId: userId, message },
      //   (err, response) => {
      //     try {
      //       if (err) throw err;
      //       else {
      //         res.status(200).json({
      //           status: true,
      //           message: "success",
      //           data: {},
      //         });
      //       }
      //     } catch (error) {
      //       res.status(400).json({
      //         status: false,
      //         message: error.message,
      //         data: {},
      //       });
      //     }
      //   }
      // );
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

router.post("/get_discussion", verifyUser, async (req, res) => {
  const { matchId, createrId } = req.body;

  try {
    if (!/[^0-9]/g.test(matchId) && !/[^0-9]/g.test(createrId)) {
      const response = await fetchData(
        "SELECT messengerId, displayPicture, firstName AS firstName, message,messageTime AS messageTime FROM discussion JOIN all_users ON messengerId = all_users.userId WHERE matchId = ? AND discussion.userId = ? ORDER BY messageTime DESC LIMIT 50;",
        [matchId, createrId]
      );
      res.status(200).json({
        status: true,
        message: "success",
        data: {
          messages: response,
        },
      });
      // connection.query(
      //   "SELECT messengerId, displayPicture, firstName AS firstName, message,messageTime AS messageTime FROM discussion JOIN all_users ON messengerId = all_users.userId WHERE matchId = ? AND discussion.userId = ? ORDER BY messageTime DESC LIMIT 50;",
      //   [matchId, createrId],
      //   (err, response) => {
      //     try {
      //       if (err) throw err;
      //       else {
      //         res.status(200).json({
      //           status: true,
      //           message: "success",
      //           data: {
      //             messages: response,
      //           },
      //         });
      //       }
      //     } catch (error) {
      //       res.status(400).json({
      //         status: false,
      //         message: error.message,
      //         data: {},
      //       });
      //     }
      //   }
      // );
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

router.post("/compare_teams", verifyUser, async (req, res) => {
  const { matchId } = req.body;

  const allPlayersForMatch =
    "SELECT matchId,match_player_relation.playerId AS playerId,players.name AS playerName,players.displayName AS playerDisplayName,player_roles.roleId AS roleId,player_roles.roleName AS roleName,players.profilePictureURLLocal AS URL, teams.teamId AS teamId,teams.name AS teamName,teams.displayName AS teamDisplayName, teams.teamFlagUrlLocal AS flagURL FROM match_player_relation JOIN players ON players.playerId = match_player_relation.playerId JOIN player_roles ON players.role = player_roles.roleId JOIN teams ON teams.teamId = match_player_relation.teamId WHERE matchId = ?;";
  const matchDetails =
    "SELECT matchId, matchStartTimeMilliSeconds AS matchStartTime, venue, seriesDname AS seriesDisplayName,team1_id AS team1Id,team1.displayName AS team1DisplayName, team1.name AS team1Name,team1.teamFlagUrlLocal AS team1FlagURL,team2_id AS team2Id,team2.displayName AS team2DisplayName, team2.name AS team2Name,team2.teamFlagUrlLocal AS team2FlagURL FROM `all_matches` JOIN teams AS team1 ON team1.teamId = team1_id JOIN teams AS team2 ON team2.teamId = team2_id WHERE matchId = ?;";

  if (!/[^0-9]/g.test(matchId)) {
    try {
      const response = await fetchData(allPlayersForMatch, [matchId]);
      const responseData = await fetchData(matchDetails, [matchId]);

      response.forEach((element) => {
        element.URL = element.URL.replace(
          "http://192.168.1.32:3000",
          `${req.protocol}://${req.headers.host}`
        );
        element.flagURL = element.flagURL.replace(
          "http://192.168.1.32:3000",
          `${req.protocol}://${req.headers.host}`
        );
      });
      responseData[0].team1FlagURL = responseData[0].team1FlagURL.replace(
        "http://192.168.1.32:3000",
        `${req.protocol}://${req.headers.host}`
      );
      responseData[0].team2FlagURL = responseData[0].team2FlagURL.replace(
        "http://192.168.1.32:3000",
        `${req.protocol}://${req.headers.host}`
      );
      res.status(200).json({
        status: true,
        message: "success",
        data: {
          players: response,
          matchDetails: responseData[0],
        },
      });
    } catch (error) {
      res.status(400).json({
        status: false,
        message: error.message,
        data: {},
      });
    }
    // connection.query(allPlayersForMatch, [matchId], (err, response) => {
    //   try {
    //     if (err) throw err;
    //     else {
    //       connection.query(matchDetails, [matchId], (error, responseData) => {
    //         try {
    //           if (error) throw error;
    //           else {
    //             // changing server address
    //             response.forEach((element) => {
    //               element.URL = element.URL.replace(
    //                 "http://192.168.1.32:3000",
    //                 `${req.protocol}://${req.headers.host}`
    //               );
    //               element.flagURL = element.flagURL.replace(
    //                 "http://192.168.1.32:3000",
    //                 `${req.protocol}://${req.headers.host}`
    //               );
    //             });
    //             responseData[0].team1FlagURL =
    //               responseData[0].team1FlagURL.replace(
    //                 "http://192.168.1.32:3000",
    //                 `${req.protocol}://${req.headers.host}`
    //               );
    //             responseData[0].team2FlagURL =
    //               responseData[0].team2FlagURL.replace(
    //                 "http://192.168.1.32:3000",
    //                 `${req.protocol}://${req.headers.host}`
    //               );
    //             res.status(200).json({
    //               status: true,
    //               message: "success",
    //               data: {
    //                 players: response,
    //                 matchDetails: responseData[0],
    //               },
    //             });
    //           }
    //         } catch (error) {
    //           res.status(400).json({
    //             status: false,
    //             message: error.message,
    //             data: {},
    //           });
    //         }
    //       });
    //     }
    //   } catch (error) {
    //     res.status(400).json({
    //       status: false,
    //       message: error.message,
    //       data: {},
    //     });
    //   }
    // });
  } else {
    res.status(400).json({
      status: false,
      message: "invalid input",
      data: {},
    });
  }
});

module.exports = router;
