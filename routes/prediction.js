const express = require("express");
const router = express.Router();
const verifyUser = require("../middleware/verifyUser");
const { fetchData } = require("../database/db_connection");

// get predictors by match id or with no match id and match status
router.post("/get_predictions", async (req, res) => {
  const { matchId, filter } = req.body;

  let validMatchId = true;

  // creating query to fetch predictions
  try {
    let query;
    if (matchId) {
      validMatchId = true;
      if (!/[^0-9]/g.test(matchId)) validMatchId = true;
      else {
        throw { message: "invalid input" };
      }
      query =
        filter === "MOST_VIEWED"
          ? "SELECT userdetails.userId, fullmatchdetails.displayName, SUM(fullteamdetails.userTeamViews) AS totalViews, phoneNumber, firstName, lastName, displayPicture, city, registerTime FROM userdetails JOIN fullteamdetails ON fullteamdetails.userId = userdetails.userId JOIN fullmatchdetails ON fullmatchdetails.matchId = fullteamdetails.matchId WHERE fullteamdetails.matchId = ? GROUP BY userdetails.userId ORDER BY totalViews DESC LIMIT 20;"
          : filter === "MOST_LIKED"
          ? "SELECT userdetails.userId, fullmatchdetails.displayName, SUM(fullteamdetails.userTeamLikes) AS totalLikes, phoneNumber, firstName, lastName, displayPicture, city, registerTime FROM userdetails JOIN fullteamdetails ON fullteamdetails.userId = userdetails.userId JOIN fullmatchdetails ON fullmatchdetails.matchId = fullteamdetails.matchId WHERE fullteamdetails.matchId = ? GROUP BY userdetails.userId ORDER BY totalLikes DESC LIMIT 20;"
          : "SELECT userdetails.userId, fullmatchdetails.displayName, SUM(fullteamdetails.userTeamPoints) AS totalPoints, phoneNumber, firstName, lastName, displayPicture, city, registerTime FROM userdetails JOIN fullteamdetails ON fullteamdetails.userId = userdetails.userId JOIN fullmatchdetails ON fullmatchdetails.matchId = fullteamdetails.matchId WHERE fullteamdetails.matchId = ? GROUP BY userdetails.userId ORDER BY totalPoints DESC LIMIT 20;";
    } else {
      query =
        filter === "MOST_VIEWED"
          ? "SELECT userdetails.userId, fullmatchdetails.displayName, SUM(fullteamdetails.userTeamViews) AS totalViews, phoneNumber, firstName, lastName, displayPicture, city, registerTime FROM userdetails JOIN fullteamdetails ON fullteamdetails.userId = userdetails.userId JOIN fullmatchdetails ON fullmatchdetails.matchId = fullteamdetails.matchId GROUP BY userdetails.userId ORDER BY totalViews DESC LIMIT 20;"
          : filter === "MOST_LIKED"
          ? "SELECT userdetails.userId, fullmatchdetails.displayName, SUM(fullteamdetails.userTeamLikes) AS totalLikes, phoneNumber, firstName, lastName, displayPicture, city, registerTime FROM userdetails JOIN fullteamdetails ON fullteamdetails.userId = userdetails.userId JOIN fullmatchdetails ON fullmatchdetails.matchId = fullteamdetails.matchId GROUP BY userdetails.userId ORDER BY totalLikes DESC LIMIT 20;"
          : "SELECT userdetails.userId, fullmatchdetails.displayName, SUM(fullteamdetails.userTeamPoints) AS totalPoints, phoneNumber, firstName, lastName, displayPicture, city, registerTime FROM userdetails JOIN fullteamdetails ON fullteamdetails.userId = userdetails.userId JOIN fullmatchdetails ON fullmatchdetails.matchId = fullteamdetails.matchId GROUP BY userdetails.userId ORDER BY totalPoints DESC LIMIT 20;";
    }
    if (validMatchId) {
      const result = await fetchData(query, [matchId]);

      result.forEach((element) => {
        element.displayPicture = element.displayPicture
          ? element.displayPicture.replace(
              "http://192.168.1.32:3000",
              `${req.protocol}://${req.headers.host}`
            )
          : "";
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
      message: error.sqlMessage || error.message,
      data: {},
    });
  }
});

// getting expert predictors
router.post("/getExpertPredictor", async (req, res) => {
  const { matchId } = req.body;
});

// getting trending predictors by points
router.get("/getTrendingPredictors", async (req, res) => {
  const recentMatchesQuery =
    "SELECT matchId FROM fullmatchdetails WHERE (fullmatchdetails.matchStartTimeMilliSeconds < unix_timestamp(now()) * 1000 AND fullmatchdetails.matchStatus = 3) OR fullmatchdetails.matchId = 27947 ORDER BY matchStartTimeMilliSeconds DESC LIMIT 5;";
  const topPredictorsQuery =
    "SELECT userdetails.userId, firstName, lastName, displayPicture, SUM(fullteamdetails.userTeamPoints) AS totalPoints FROM fullteamdetails JOIN userdetails ON userdetails.userId = fullteamdetails.userId WHERE fullteamdetails.matchId IN (27947) GROUP BY fullteamdetails.userId ORDER BY totalPoints DESC LIMIT 10;";

  try {
    const recentMatches = await fetchData(recentMatchesQuery);
    const matchIds = recentMatches.map(({ matchId }) => matchId);
    const predictor = await fetchData(topPredictorsQuery, [matchIds.join(",")]);

    // replace server address
    predictor.forEach((trending) => {
      trending.displayPicture = trending.displayPicture
        ? trending.displayPicture.replace(
            "http://192.168.1.32:3000",
            `${req.protocol}://${req.headers.host}`
          )
        : "";
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
      message: error.sqlMessage || error.message,
      data: {},
    });
  }
});

// getting teams by match id and user id
router.post("/get_user_teams", async (req, res) => {
  const { createrId, matchId } = req.body;

  // Query for fetch all players playerid

  // SELECT userTeamId, teamTypeString, captain, userTeamLikes AS likes, viceCaptain, player1, player2, player3, player4, player5, player6, player7, player8, player9, player10, player11, team1Id, team1Name, team1DisplayName, team1FlagURL, team2Id, team2Name, team2DisplayName, team2FlagURL FROM fullteamdetails JOIN fullmatchdetails ON fullmatchdetails.matchId = fullteamdetails.matchId WHERE fullteamdetails.userId = ? AND fullteamdetails.matchId = ?;

  const userTeamDetailsQuery = `SELECT userTeamId, teamTypeString, captain, userTeamLikes AS likes, viceCaptain, player1, player2, player3, player4, player5, player6, player7, player8, player9, player10, player11, team1Id, team1Name, team1DisplayName, team1FlagURL, team2Id, team2Name, team2DisplayName, team2FlagURL FROM fullteamdetails JOIN fullmatchdetails ON fullmatchdetails.matchId = fullteamdetails.matchId WHERE fullteamdetails.userId = 9 AND fullteamdetails.matchId = 27947;`;

  const playersQuery =
    "SELECT userTeamId, teamTypeString, captain, userTeamLikes AS likes, viceCaptain, player1, player2, player3, player4, player5, player6, player7, player8, player9, player10, player11 FROM fullteamdetails WHERE matchId = ? AND userId = ?;";
  const teamDetailsQuery =
    "SELECT team1Id, team1Name, team1DisplayName, team1FlagURL, team2Id, team2Name, team2DisplayName, team2FlagURL FROM fullmatchdetails WHERE matchId = ?;";
  const playerDetailsQuery =
    "SELECT DISTINCT playerId, name AS playerName, displayName AS playerDisplayName, roleId, roleName, profilePictureURLLocal AS URL, points, credits, teamId FROM fullplayerdetails WHERE playerId = ? AND matchId = ?;";
  const userDetailsQuery =
    "SELECT `firstName`, `lastName`, `displayPicture` FROM userdetails WHERE userId = ?;";

  try {
    if (!/[^0-9]/g.test(matchId) && !/[^0-9]/g.test(createrId)) {
      // const players = await fetchData(playersQuery, [matchId, createrId]);
      // const teamDetails = await fetchData(teamDetailsQuery, [matchId]);

      const [players, teamDetails, [userDetails]] = await fetchData(
        `${playersQuery}${teamDetailsQuery}${userDetailsQuery}`,
        [matchId, createrId, matchId, createrId]
      );

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
                    teamFlagURL: teamDetails[0][`team${j + 1}FlagURL`]
                      ? teamDetails[0][`team${j + 1}FlagURL`].replace(
                          "http://192.168.1.32:3000",
                          `${req.protocol}://${req.headers.host}`
                        )
                      : "",
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
                    player[0].URL = player[0].URL
                      ? player[0].URL.replace(
                          "http://192.168.1.32:3000",
                          `${req.protocol}://${req.headers.host}`
                        )
                      : "";

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
          data: { userTeams: allTeams, userDetails: userDetails },
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
      message: error.sqlMessage || error.message,
      data: {},
    });
  }
});

// getting teams with user id
router.post("/get_user_teams_predictor", async (req, res) => {
  const { createrId } = req.body;

  // Query for fetch all players playerid
  const playersQuery =
    "SELECT matchId, userTeamId, teamTypeString, captain, userTeamLikes AS likes, viceCaptain, player1, player2, player3, player4, player5, player6, player7, player8, player9, player10, player11 FROM fullteamdetails WHERE userId = ?;";
  const teamDetailsQuery =
    "SELECT team1Id, team1Name, team1DisplayName, team1FlagURL, team2Id, team2Name, team2DisplayName, team2FlagURL FROM fullmatchdetails WHERE matchId = ?;";
  const playerDetailsQuery =
    "SELECT DISTINCT playerId, name AS playerName, displayName AS playerDisplayName, roleId, roleName, profilePictureURLLocal AS URL, points, credits, teamId FROM fullplayerdetails WHERE playerId = ? AND matchId = ?;";
  const userDetailsQuery =
    "SELECT `firstName`, `lastName`, `displayPicture` FROM userdetails WHERE userId = ?;";

  try {
    const players = await fetchData(playersQuery, [createrId]);
    const [userDetails] = await fetchData(userDetailsQuery, [createrId]);
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
                    teamFlagURL: teamDetails[0][`team${j + 1}FlagURL`]
                      ? teamDetails[0][`team${j + 1}FlagURL`].replace(
                          "http://192.168.1.32:3000",
                          `${req.protocol}://${req.headers.host}`
                        )
                      : "",
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
                    player[0].URL = player[0].URL
                      ? player[0].URL.replace(
                          "http://192.168.1.32:3000",
                          `${req.protocol}://${req.headers.host}`
                        )
                      : "";

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
        data: { userTeams: allTeams, userDetails },
      });
    } else {
      throw { message: "user have no team created" };
    }
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage || error.message,
      data: {},
    });
  }
});

// getting team data of team
router.post("/get_user_teams_data", verifyUser, async (req, res) => {
  const { userId, teamId } = req.body;

  // queries to fetch data
  const fetchPlayerIdQuery =
    "SELECT EXISTS(SELECT userId FROM fulllikesdetails WHERE userTeamId = ? AND userId = ?) AS isUserLiked, matchId, userTeamId, teamTypeString, captain, userTeamLikes AS likes, viceCaptain, player1, player2, player3, player4, player5, player6, player7, player8, player9, player10, player11 FROM fullteamdetails WHERE userTeamId = ?;";
  const teamQuery =
    "SELECT team1Id, team1Name, team1DisplayName, team1FlagURL, team2Id, team2Name, team2DisplayName, team2FlagURL FROM fullmatchdetails WHERE matchId = ?;";
  const playerQuery =
    "SELECT DISTINCT playerId, fullplayerdetails.name AS playerName, fullplayerdetails.displayName AS playerDisplayName, roleId, roleName, profilePictureURLLocal AS URL, points, credits, fullplayerdetails.teamId, allteams.displayName AS teamDisplayName FROM fullplayerdetails JOIN allteams ON allteams.teamId = fullplayerdetails.teamId WHERE playerId = ? AND matchId = ?;";

  try {
    if (!/[^0-9]/g.test(teamId)) {
      const playersIds = await fetchData(fetchPlayerIdQuery, [
        teamId,
        userId,
        teamId,
      ]);
      const teamData = await fetchData(teamQuery, [playersIds[0]?.matchId]);

      teamData[0].team1FlagURL = teamData[0].team1FlagURL
        ? teamData[0].team1FlagURL.replace(
            "http://192.168.1.32:3000",
            `${req.protocol}://${req.headers.host}`
          )
        : "";
      teamData[0].team2FlagURL = teamData[0].team2FlagURL
        ? teamData[0].team1FlagURL.replace(
            "http://192.168.1.32:3000",
            `${req.protocol}://${req.headers.host}`
          )
        : "";

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
              player[0].URL = player[0].URL
                ? player[0].URL.replace(
                    "http://192.168.1.32:3000",
                    `${req.protocol}://${req.headers.host}`
                  )
                : "";

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
      message: error.sqlMessage || error.message,
      data: {},
    });
  }
});

// update likes of team
router.post("/update_user_team_likes", verifyUser, async (req, res) => {
  let { userId, teamId } = req.body;

  try {
    if (!/[^0-9]/g.test(teamId)) {
      const [[response]] = await fetchData("CALL update_likes(?, ?);", [
        teamId,
        userId,
      ]);

      res.status(200).json({
        status: true,
        message: "success",
        data: {
          totalLikes: response["likes"],
          isUserLiked: response["isUserLiked"],
        },
      });
    } else {
      throw { message: "invalid input" };
    }
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage || error.message,
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

// update views of team
router.post("/update_user_team_views", verifyUser, async (req, res) => {
  let { userId, teamId } = req.body;

  try {
    if (!/[^0-9]/g.test(teamId)) {
      const [[{ message }]] = await fetchData("CALL update_views(?, ?)", [
        teamId,
        userId,
      ]);
      if (message === "success") {
        res.status(200).json({
          status: true,
          message: "success",
          data: {},
        });
      } else {
        res.status(200).json({
          status: true,
          message: "success",
          data: {},
        });
      }
    }
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage || error.message,
      data: {},
    });
  }

  // if (!/[^0-9]/g.test(teamId)) {
  //   const checkUserViewCountLog = () =>
  //     new Promise(async (resolve, reject) => {
  //       try {
  //         const response = await fetchData(
  //           "SELECT viewCount FROM all_views WHERE userTeamId = ? AND userId = ?",
  //           [teamId, userId]
  //         );
  //         if (response) resolve(response);
  //       } catch (error) {
  //         reject(error);
  //       }
  //       // connection.query(
  //       //   "SELECT viewCount FROM all_views WHERE userTeamId = ? AND userId = ?",
  //       //   [teamId, userId],
  //       //   (err, response) => {
  //       //     if (err) reject(err);
  //       //     else {
  //       //       resolve(response);
  //       //     }
  //       //   }
  //       // );
  //     });
  //   checkUserViewCountLog()
  //     .then((response) => {
  //       if (response.length > 0) {
  //         fetchData(
  //           "UPDATE all_views SET viewCount = viewCount + 1 WHERE userTeamId = ? AND userId = ?",
  //           [teamId, userId]
  //         )
  //           .then(() => {
  //             res.status(200).json({
  //               status: true,
  //               message: "success",
  //               data: {},
  //             });
  //           })
  //           .catch((error) => {
  //             res.status(400).json({
  //               status: false,
  //               message: error.message,
  //               data: {},
  //             });
  //           });
  //       } else {
  //         fetchData("INSERT INTO all_views SET ?", {
  //           userTeamId: teamId,
  //           userId,
  //         })
  //           .then(() => {
  //             res.status(200).json({
  //               status: true,
  //               message: "success",
  //               data: {},
  //             });
  //           })
  //           .catch((error) => {
  //             res.status(400).json({
  //               status: false,
  //               message: error.message,
  //               data: {},
  //             });
  //           });
  //       }
  //     })
  //     .catch((error) => {
  //       res.status(400).json({
  //         status: false,
  //         message: error.message,
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

// setting discussion by match id, user id, team id
router.post("/set_discussion", verifyUser, async (req, res) => {
  // userId -> whos have made request means messenger who sends the message
  // createrId -> whose team is
  const { matchId, userId, message, createrId } = req.body;
  try {
    const [[discussionObject]] = await fetchData(
      "CALL set_discussion(?, ?, ?, ?)",
      [matchId, userId, createrId, message]
    );

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        messages: discussionObject,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage || error.message,
      data: {},
    });
  }
});

// getting discussion match id and user id
router.post("/get_discussion", async (req, res) => {
  const { matchId, createrId } = req.body;

  try {
    if (!/[^0-9]/g.test(matchId) && !/[^0-9]/g.test(createrId)) {
      const response = await fetchData(
        "SELECT messengerId, displayPicture, firstName message, messageTime FROM `fulldiscussion` JOIN userdetails ON userdetails.userId = fulldiscussion.userId WHERE matchId = ? AND fulldiscussion.userId = ? ORDER BY messageTime DESC LIMIT 50;",
        [matchId, createrId]
      );

      response.forEach((message) => {
        message.displayPicture = message.displayPicture
          ? message.displayPicture.replace(
              "http://192.168.1.32:3000",
              `${req.protocol}://${req.headers.host}`
            )
          : "";
      });

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
      message: error.sqlMessage || error.message,
      data: {},
    });
  }
});

// comapring teams by match id
router.post("/compare_teams", async (req, res) => {
  const { matchId } = req.body;

  const allPlayersForMatch =
    "SELECT matchId, playerId, fullplayerdetails.name AS playerName, fullplayerdetails.displayName AS playerDisplayName, roleId, roleName, url AS URL, fullplayerdetails.teamId, allteams.name AS teamName, allteams.displayName AS teamDisplayName, teamFlagURLLocal AS flagURL FROM fullplayerdetails JOIN allteams ON allteams.teamId = fullplayerdetails.teamId WHERE matchId = ?;";
  const matchDetails =
    "SELECT matchId, matchStartTimeMilliSeconds AS matchStartTime, venue, seriesDname AS seriesDisplayName, team1Id, team1Name, team1DisplayName, team1FlagURL, team2Id, team2Name, team2DisplayName, team2FlagURL FROM fullmatchdetails WHERE matchId = ?;";

  try {
    if (!/[^0-9]/g.test(matchId)) {
      const response = await fetchData(allPlayersForMatch, [matchId]);
      const responseData = await fetchData(matchDetails, [matchId]);

      response.forEach((element) => {
        element.URL = element.URL
          ? element.URL.replace(
              "http://192.168.1.32:3000",
              `${req.protocol}://${req.headers.host}`
            )
          : "";
        element.flagURL = element.URL
          ? element.flagURL.replace(
              "http://192.168.1.32:3000",
              `${req.protocol}://${req.headers.host}`
            )
          : "";
      });
      responseData[0].team1FlagURL = responseData[0].team1FlagURL
        ? responseData[0].team1FlagURL.replace(
            "http://192.168.1.32:3000",
            `${req.protocol}://${req.headers.host}`
          )
        : "";
      responseData[0].team2FlagURL = responseData[0].team2FlagURL
        ? responseData[0].team1FlagURL.replace(
            "http://192.168.1.32:3000",
            `${req.protocol}://${req.headers.host}`
          )
        : "";
      res.status(200).json({
        status: true,
        message: "success",
        data: {
          players: response,
          matchDetails: responseData[0],
        },
      });
    } else {
      throw { message: "invalid input" };
    }
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage || error.message,
      data: {},
    });
  }
});

// exporting module
module.exports = router;
