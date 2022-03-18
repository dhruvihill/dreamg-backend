const express = require("express");
const router = express.Router();
const verifyUser = require("../middleware/verifyUser");
const { fetchData, imageUrl } = require("../database/db_connection");
const path = require("path");

// get players by match id
router.post("/getPlayers", async (req, res) => {
  const { matchId, userTeamId } = req.body;

  try {
    if (!/[^0-9]/g.test(matchId)) {
      let data;
      if (userTeamId && !/[^0-9]/g.test(userTeamId) && userTeamId > 0) {
        [data] = await fetchData("CALL get_players(?, ?);", [
          matchId,
          userTeamId,
        ]);
      } else {
        [data] = await fetchData("CALL get_players(?, ?);", [matchId, 0]);
      }
      const serverAddress = `${req.protocol}://${req.headers.host}`;

      data?.forEach((player) => {
        player.captainBy = parseFloat(player.captainBy.toFixed(2));
        player.viceCaptainBy = parseFloat(player.viceCaptainBy.toFixed(2));
        player.selectedBy = parseFloat(player.selectedBy.toFixed(2));
        // changing url address
        player.URL = imageUrl(
          __dirname,
          "../",
          `${process.env.PLAYER_IMAGE_URL}${player.playerId}.jpg`,
          serverAddress
        );
      });
      res.status(200).json({
        status: true,
        message: "success",
        data: {
          players: data,
        },
      });
    } else {
      throw { message: "invalid input" };
    }
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage ? error.sqlMessage : error.message,
      data: {},
    });
  }
});

// set team of matchId, userId, teamType
router.post("/setTeam", verifyUser, async (req, res) => {
  const {
    userTeamType,
    matchId,
    players,
    captain,
    viceCaptain,
    userId,
    userTeamId,
  } = req.body;

  try {
    const regx = /[^0-9]/g;
    let correctInput = true;
    [userTeamType, matchId, ...players, captain, viceCaptain].forEach((id) => {
      if (regx.test(id)) {
        correctInput = false;
      }
    });
    if (
      players.length === 11 &&
      correctInput &&
      players.includes(captain) &&
      players.includes(viceCaptain)
    ) {
      let message;
      if (userTeamId && !regx.test(userTeamId) && userTeamId > 0) {
        [[{ message }]] = await fetchData("CALL set_team(?, ?, ?, ?, ?, ?,?)", [
          userTeamType,
          matchId,
          userId,
          captain,
          viceCaptain,
          userTeamId,
          [...players],
        ]);
      } else {
        [[{ message }]] = await fetchData("CALL set_team(?, ?, ?, ?, ?, ?,?)", [
          userTeamType,
          matchId,
          userId,
          captain,
          viceCaptain,
          0,
          [...players],
        ]);
      }
      if (message === "success") {
        res.status(200).json({
          status: true,
          message: "success",
          data: {},
        });
      }
    } else {
      console.log(error.sqlMessage);
      throw { message: "invalid input" };
    }
  } catch (error) {
    console.log(error.sqlMessage, userId);
    res.status(400).json({
      status: false,
      message: error.sqlMessage ? error.sqlMessage : error.message,
      data: {},
    });
  }
});

// get predictors by match id or with no match id and match status
router.post("/getPredictions", async (req, res) => {
  const { matchId, filter, pageNumber } = req.body;

  let validMatchId = true;

  // creating query to fetch predictions
  try {
    let totalPredictorsQuery = "";
    let query;
    if (matchId) {
      validMatchId = true;
      if (!/[^0-9]/g.test(matchId)) validMatchId = true;
      else {
        throw { message: "invalid input" };
      }
      totalPredictorsQuery =
        "SELECT COUNT(*) AS totalPredictors FROM fullteamdetails WHERE matchId = ?;";
      query =
        filter === "MOST_VIEWED"
          ? "SELECT userdetails.userId, fullmatchdetails.displayName, SUM(fullteamdetails.userTeamViews) AS totalViews, phoneNumber, firstName, lastName, city, registerTime FROM userdetails JOIN fullteamdetails ON fullteamdetails.userId = userdetails.userId JOIN fullmatchdetails ON fullmatchdetails.matchId = fullteamdetails.matchId WHERE fullteamdetails.matchId = ? GROUP BY userdetails.userId ORDER BY totalViews DESC LIMIT ?, 20;"
          : filter === "MOST_LIKED"
          ? "SELECT userdetails.userId, userdetails.imageStamp AS imageStamp, fullmatchdetails.displayName, SUM(fullteamdetails.userTeamLikes) AS totalLikes, phoneNumber, firstName, lastName, city, registerTime FROM userdetails JOIN fullteamdetails ON fullteamdetails.userId = userdetails.userId JOIN fullmatchdetails ON fullmatchdetails.matchId = fullteamdetails.matchId WHERE fullteamdetails.matchId = ? GROUP BY userdetails.userId ORDER BY totalLikes DESC LIMIT ?, 20;"
          : "SELECT userdetails.userId, userdetails.imageStamp AS imageStamp, fullmatchdetails.displayName, SUM(fullteamdetails.userTeamPoints) AS totalPoints, phoneNumber, firstName, lastName, city, registerTime FROM userdetails JOIN fullteamdetails ON fullteamdetails.userId = userdetails.userId JOIN fullmatchdetails ON fullmatchdetails.matchId = fullteamdetails.matchId WHERE fullteamdetails.matchId = ? GROUP BY userdetails.userId ORDER BY totalPoints DESC LIMIT ?, 20;";
    } else {
      totalPredictorsQuery =
        "SELECT COUNT(*) AS totalPredictors FROM fullteamdetails;";
      query =
        filter === "MOST_VIEWED"
          ? "SELECT userdetails.userId, userdetails.imageStamp AS imageStamp, fullmatchdetails.displayName, SUM(fullteamdetails.userTeamViews) AS totalViews, phoneNumber, firstName, lastName, city, registerTime FROM userdetails JOIN fullteamdetails ON fullteamdetails.userId = userdetails.userId JOIN fullmatchdetails ON fullmatchdetails.matchId = fullteamdetails.matchId GROUP BY userdetails.userId ORDER BY totalViews DESC LIMIT ?, 20;"
          : filter === "MOST_LIKED"
          ? "SELECT userdetails.userId, userdetails.imageStamp AS imageStamp, fullmatchdetails.displayName, SUM(fullteamdetails.userTeamLikes) AS totalLikes, phoneNumber, firstName, lastName, city, registerTime FROM userdetails JOIN fullteamdetails ON fullteamdetails.userId = userdetails.userId JOIN fullmatchdetails ON fullmatchdetails.matchId = fullteamdetails.matchId GROUP BY userdetails.userId ORDER BY totalLikes DESC LIMIT ?, 20;"
          : "SELECT userdetails.userId, userdetails.imageStamp AS imageStamp, fullmatchdetails.displayName, SUM(fullteamdetails.userTeamPoints) AS totalPoints, phoneNumber, firstName, lastName, city, registerTime FROM userdetails JOIN fullteamdetails ON fullteamdetails.userId = userdetails.userId JOIN fullmatchdetails ON fullmatchdetails.matchId = fullteamdetails.matchId GROUP BY userdetails.userId ORDER BY totalPoints DESC LIMIT ?, 20;";
    }
    if (
      validMatchId &&
      pageNumber &&
      pageNumber > 0 &&
      !/[^0-9]/g.test(pageNumber)
    ) {
      const serverAddress = `${req.protocol}://${req.headers.host}`;
      let result, totalPredictors;
      if (matchId) {
        [result, [{ totalPredictors }]] = await fetchData(
          `${query}${totalPredictorsQuery}`,
          [matchId, (pageNumber - 1) * 20, matchId]
        );
      } else {
        [result, [{ totalPredictors }]] = await fetchData(
          `${query}${totalPredictorsQuery}`,
          [(pageNumber - 1) * 20, matchId]
        );
      }

      result.forEach((element) => {
        element.displayPicture = imageUrl(
          __dirname,
          "../",
          `${process.env.USER_IMAGE_URL}${element.imageStamp}.jpg`,
          serverAddress
        );
        delete element.imageStamp;
      });

      const totalPages = Math.ceil(totalPredictors / 20);
      res.status(200).json({
        status: true,
        message: "success",
        data: { users: result, totalPages, currentPage: pageNumber },
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

// getting expert predictors
router.post("/getExpertPredictor", async (req, res) => {
  const { matchId } = req.body;

  try {
    const serverAddress = `${req.protocol}://${req.headers.host}`;
    const regx = /[^0-9]/g;

    if (!matchId || regx.test(matchId)) {
      throw { message: "invalid input" };
    }

    const fetchUserTeamDetails = () => {
      return new Promise(async (resolve, reject) => {
        try {
          const [userTeamDetails] = await fetchData(
            "CALL get_user_team(?, ?, ?);",
            [matchId, 0, 0]
          );

          let userTeams = [];
          if (userTeamDetails && userTeamDetails.length) {
            let counter = 0;
            userTeamDetails.forEach(async (team) => {
              try {
                // changing server url
                team.team1FlagURL = imageUrl(
                  __dirname,
                  "../",
                  `${process.env.TEAM_IMAGE_URL}${team.team1Id}.jpg`,
                  serverAddress
                );
                team.team2FlagURL = imageUrl(
                  __dirname,
                  "../",
                  `${process.env.TEAM_IMAGE_URL}${team.team2Id}.jpg`,
                  serverAddress
                );

                // creating instance of user team
                let userTeamInstance = {
                  teams: [
                    {
                      teamTotalPlayers: 0,
                      teamId: team.team1Id,
                      teamName: team.team1Name,
                      teamDisplayName: team.team1DisplayName,
                      teamFlagURL: team.team1FlagURL,
                    },
                    {
                      teamTotalPlayers: 0,
                      teamId: team.team2Id,
                      teamName: team.team2Name,
                      teamDisplayName: team.team2DisplayName,
                      teamFlagURL: team.team2FlagURL,
                    },
                  ],
                  teamsDetails: {
                    userTeamId: team.userTeamId,
                    creditUsed: 0,
                    teamType: team.teamTypeString,
                    totalBatsman: 0,
                    totalBowlers: 0,
                    totalWicketKeeper: 0,
                    totalAllrounders: 0,
                    captain: {},
                    viceCaptain: {},
                  },
                  userDetails: {
                    userId: team.userId,
                    firstName: team.firstName,
                    lastName: team.lastName,
                    displayPicture: imageUrl(
                      __dirname,
                      "../",
                      `${process.env.USER_IMAGE_URL}${team.imageStamp}.jpg`,
                      serverAddress
                    ),
                  },
                };

                // feching all players
                const [players] = await fetchData(
                  "CALL get_userteam_details(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",
                  [
                    team.matchId,
                    team.player1,
                    team.player2,
                    team.player3,
                    team.player4,
                    team.player5,
                    team.player6,
                    team.player7,
                    team.player8,
                    team.player9,
                    team.player10,
                    team.player11,
                  ]
                );

                // loop through all players
                players.forEach((player) => {
                  player.URL = imageUrl(
                    __dirname,
                    "../",
                    `${process.env.PLAYER_IMAGE_URL}${player.playerId}.jpg`,
                    serverAddress
                  );

                  // incrementing total players
                  if (player.teamId === userTeamInstance.teams[0].teamId)
                    userTeamInstance.teams[0].teamTotalPlayers++;
                  else if (player.teamId === userTeamInstance.teams[1].teamId)
                    userTeamInstance.teams[1].teamTotalPlayers++;

                  // incrementing players roles
                  if (player.roleId === 1) {
                    userTeamInstance.teamsDetails.totalBatsman++;
                  } else if (player.roleId === 2) {
                    userTeamInstance.teamsDetails.totalBowlers++;
                  } else if (player.roleId === 3) {
                    userTeamInstance.teamsDetails.totalWicketKeeper++;
                  } else if (player.roleId === 4) {
                    userTeamInstance.teamsDetails.totalAllrounders++;
                  }

                  // total credits used
                  userTeamInstance.teamsDetails.creditUsed += player.credits;
                });

                // stroing captain and vice captain
                [userTeamInstance.teamsDetails.captain] = players.filter(
                  (player) => {
                    return player.playerId === team.captain;
                  }
                );
                [userTeamInstance.teamsDetails.viceCaptain] = players.filter(
                  (player) => {
                    return player.playerId === team.viceCaptain;
                  }
                );

                // pushing teams into user teams
                userTeams.push(userTeamInstance);
                counter++;
                // resolving promise
                if (counter === userTeamDetails.length) {
                  resolve([userTeams]);
                }
              } catch (error) {
                reject(error);
              }
            });
          } else {
            resolve([userTeams]);
          }
        } catch (error) {
          reject(error);
        }
      });
    };

    const [userTeams] = await fetchUserTeamDetails();

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        userTeams,
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

// getting trending predictors by points
router.get("/getTrendingPredictors", async (req, res) => {
  const recentMatchesQuery =
    "SELECT DISTINCT fullmatchdetails.matchId FROM fullmatchdetails JOIN fullteamdetails ON fullteamdetails.matchId = fullmatchdetails.matchId WHERE (fullmatchdetails.matchStartTimeMilliSeconds < unix_timestamp(now()) * 1000 AND fullmatchdetails.matchStatus != 3) ORDER BY matchStartTimeMilliSeconds DESC LIMIT 5";
  const topPredictorsQuery =
    "SELECT userdetails.userId, userdetails.imageStamp, firstName, lastName, SUM(fullteamdetails.userTeamPoints) AS totalPoints FROM fullteamdetails JOIN userdetails ON userdetails.userId = fullteamdetails.userId WHERE matchId IN (30100, 30096,30030) GROUP BY fullteamdetails.userId ORDER BY totalPoints DESC LIMIT 10";

  try {
    const serverAddress = `${req.protocol}://${req.headers.host}`;
    const recentMatches = await fetchData(recentMatchesQuery);
    const matchIds = recentMatches.map(({ matchId }) => matchId);
    const predictor = await fetchData(topPredictorsQuery, [matchIds.join(",")]);

    // replace server address
    predictor.forEach((trending) => {
      trending.displayPicture = imageUrl(
        __dirname,
        "../",
        `${process.env.USER_IMAGE_URL}${trending.imageStamp}.jpg`,
        serverAddress
      );
      delete trending.imageStamp;
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
router.post("/getUserTeamsByMatch", async (req, res) => {
  const { createrId, matchId } = req.body;

  try {
    const regx = /[^0-9]/g;

    if (!createrId || !matchId || regx.test(matchId) || regx.test(createrId)) {
      throw { message: "invalid input" };
    }

    const fetchUserTeamDetails = () => {
      return new Promise(async (resolve, reject) => {
        try {
          const serverAddress = `${req.protocol}://${req.headers.host}`;
          const [[userDetails], userTeamDetails] = await fetchData(
            "CALL get_user_team(?, ?, ?);",
            [matchId, createrId, 0]
          );

          if (userDetails) {
            // change server address
            userDetails.displayPicture = imageUrl(
              __dirname,
              "../",
              `${process.env.USER_IMAGE_URL}${userDetails.imageStamp}.jpg`,
              serverAddress
            );
            delete userDetails.imageStamp;
          }

          let userTeams = [];
          let counter = 0;
          if (userTeamDetails && userTeamDetails.length) {
            userTeamDetails?.forEach(async (team) => {
              try {
                // changing server url
                team.team1FlagURL = imageUrl(
                  __dirname,
                  "../",
                  `${process.env.TEAM_IMAGE_URL}${team.team1Id}.jpg`,
                  serverAddress
                );
                team.team2FlagURL = imageUrl(
                  __dirname,
                  "../",
                  `${process.env.TEAM_IMAGE_URL}${team.team2Id}.jpg`,
                  serverAddress
                );

                // creating instance of user team
                let userTeamInstance = {
                  teams: [
                    {
                      teamTotalPlayers: 0,
                      teamId: team.team1Id,
                      teamName: team.team1Name,
                      teamDisplayName: team.team1DisplayName,
                      teamFlagURL: team.team1FlagURL,
                    },
                    {
                      teamTotalPlayers: 0,
                      teamId: team.team2Id,
                      teamName: team.team2Name,
                      teamDisplayName: team.team2DisplayName,
                      teamFlagURL: team.team2FlagURL,
                    },
                  ],
                  teamsDetails: {
                    userTeamId: team.userTeamId,
                    creditUsed: 0,
                    teamType: team.teamTypeString,
                    totalBatsman: 0,
                    totalBowlers: 0,
                    totalWicketKeeper: 0,
                    totalAllrounders: 0,
                    captain: {},
                    viceCaptain: {},
                  },
                };

                // feching all players
                const [players] = await fetchData(
                  "CALL get_userteam_details(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",
                  [
                    team.matchId,
                    team.player1,
                    team.player2,
                    team.player3,
                    team.player4,
                    team.player5,
                    team.player6,
                    team.player7,
                    team.player8,
                    team.player9,
                    team.player10,
                    team.player11,
                  ]
                );

                // loop through all players
                players.forEach((player) => {
                  // changing server url
                  player.URL = imageUrl(
                    __dirname,
                    "../",
                    `${process.env.PLAYER_IMAGE_URL}${player.playerId}.jpg`,
                    serverAddress
                  );

                  // incrementing total players
                  if (player.teamId === userTeamInstance.teams[0].teamId)
                    userTeamInstance.teams[0].teamTotalPlayers++;
                  else if (player.teamId === userTeamInstance.teams[1].teamId)
                    userTeamInstance.teams[1].teamTotalPlayers++;

                  // incrementing players roles
                  if (player.roleId === 1) {
                    userTeamInstance.teamsDetails.totalBatsman++;
                  } else if (player.roleId === 2) {
                    userTeamInstance.teamsDetails.totalBowlers++;
                  } else if (player.roleId === 3) {
                    userTeamInstance.teamsDetails.totalWicketKeeper++;
                  } else if (player.roleId === 4) {
                    userTeamInstance.teamsDetails.totalAllrounders++;
                  }

                  // total credits used
                  userTeamInstance.teamsDetails.creditUsed += player.credits;
                });

                // stroing captain and vice captain
                [userTeamInstance.teamsDetails.captain] = players.filter(
                  (player) => {
                    return player.playerId === team.captain;
                  }
                );
                [userTeamInstance.teamsDetails.viceCaptain] = players.filter(
                  (player) => {
                    return player.playerId === team.viceCaptain;
                  }
                );

                // pushing teams into user teams
                userTeams.push(userTeamInstance);
                counter++;

                // resolving promise
                if (counter === userTeamDetails.length) {
                  resolve([userTeams, userDetails]);
                }
              } catch (error) {
                reject(error);
              }
            });
          } else {
            resolve([userTeams, userDetails]);
          }
        } catch (error) {
          reject(error);
        }
      });
    };

    const [userTeams, userDetails] = await fetchUserTeamDetails();

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        userTeams,
        userDetails: userDetails || [],
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

// getting teams with user id
router.post("/getUserTeamsAll", async (req, res) => {
  const { createrId, pageNumber } = req.body;

  try {
    const regx = /[^0-9]/g;

    if (
      !createrId ||
      regx.test(createrId) ||
      regx.test(pageNumber) ||
      pageNumber < 1 ||
      !pageNumber
    ) {
      throw { message: "invalid input" };
    }

    const fetchUserTeamDetails = () => {
      return new Promise(async (resolve, reject) => {
        try {
          const serverAddress = `${req.protocol}://${req.headers.host}`;
          const [[userDetails], userTeamDetails, [{ totalUserTeams }]] =
            await fetchData("CALL get_user_team(?, ?, ?);", [
              0,
              createrId,
              (pageNumber - 1) * 20,
            ]);

          const totalPages = Math.ceil(totalUserTeams / 20);

          if (userDetails && userTeamDetails.length) {
            // change server address
            userDetails.displayPicture = imageUrl(
              __dirname,
              "../",
              `${process.env.USER_IMAGE_URL}${userDetails.imageStamp}.jpg`,
              serverAddress
            );
          }
          let userTeams = [];
          if (userTeamDetails) {
            let counter = 0;
            userTeamDetails.forEach(async (team) => {
              try {
                // changing server url
                team.team1FlagURL = imageUrl(
                  __dirname,
                  "../",
                  `${process.env.TEAM_IMAGE_URL}${team.team1Id}.jpg`,
                  serverAddress
                );
                team.team2FlagURL = imageUrl(
                  __dirname,
                  "../",
                  `${process.env.TEAM_IMAGE_URL}${team.team2Id}.jpg`,
                  serverAddress
                );

                // creating instance of user team
                let userTeamInstance = {
                  teams: [
                    {
                      teamTotalPlayers: 0,
                      teamId: team.team1Id,
                      teamName: team.team1Name,
                      teamDisplayName: team.team1DisplayName,
                      teamFlagURL: team.team1FlagURL,
                    },
                    {
                      teamTotalPlayers: 0,
                      teamId: team.team2Id,
                      teamName: team.team2Name,
                      teamDisplayName: team.team2DisplayName,
                      teamFlagURL: team.team2FlagURL,
                    },
                  ],
                  teamsDetails: {
                    userTeamId: team.userTeamId,
                    creditUsed: 0,
                    teamType: team.teamTypeString,
                    totalBatsman: 0,
                    totalBowlers: 0,
                    totalWicketKeeper: 0,
                    totalAllrounders: 0,
                    captain: {},
                    viceCaptain: {},
                  },
                };

                // feching all players
                const [players] = await fetchData(
                  "CALL get_userteam_details(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",
                  [
                    team.matchId,
                    team.player1,
                    team.player2,
                    team.player3,
                    team.player4,
                    team.player5,
                    team.player6,
                    team.player7,
                    team.player8,
                    team.player9,
                    team.player10,
                    team.player11,
                  ]
                );

                // loop through all players
                players.forEach((player) => {
                  // changing server url
                  player.URL = imageUrl(
                    __dirname,
                    "../",
                    `${process.env.PLAYER_IMAGE_URL}${player.playerId}.jpg`,
                    serverAddress
                  );

                  // incrementing total players
                  if (player.teamId === userTeamInstance.teams[0].teamId)
                    userTeamInstance.teams[0].teamTotalPlayers++;
                  else if (player.teamId === userTeamInstance.teams[1].teamId)
                    userTeamInstance.teams[1].teamTotalPlayers++;

                  // incrementing players roles
                  if (player.roleId === 1) {
                    userTeamInstance.teamsDetails.totalBatsman++;
                  } else if (player.roleId === 2) {
                    userTeamInstance.teamsDetails.totalBowlers++;
                  } else if (player.roleId === 3) {
                    userTeamInstance.teamsDetails.totalWicketKeeper++;
                  } else if (player.roleId === 4) {
                    userTeamInstance.teamsDetails.totalAllrounders++;
                  }

                  // total credits used
                  userTeamInstance.teamsDetails.creditUsed += player.credits;
                });

                // stroing captain and vice captain
                [userTeamInstance.teamsDetails.captain] = players.filter(
                  (player) => {
                    return player.playerId === team.captain;
                  }
                );
                [userTeamInstance.teamsDetails.viceCaptain] = players.filter(
                  (player) => {
                    return player.playerId === team.viceCaptain;
                  }
                );

                // pushing teams into user teams
                userTeams.push(userTeamInstance);

                counter++;

                // resolving promise
                if (counter === userTeamDetails.length) {
                  resolve([userTeams, userDetails, totalPages]);
                }
              } catch (error) {
                reject(error);
              }
            });
          } else {
            resolve([userTeams, userDetails, totalPages]);
          }
        } catch (error) {
          reject(error);
        }
      });
    };

    const [userTeams, userDetails, totalPages] = await fetchUserTeamDetails();

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        userTeams: userTeams,
        userDetails: userDetails || [],
        totalPages,
        currentPage: pageNumber,
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

// getting team data of team
router.post("/getUserTeamPlayers", verifyUser, async (req, res) => {
  const { userId, teamId } = req.body;

  // queries to fetch data
  const fetchPlayerIdQuery =
    "SELECT EXISTS(SELECT userId FROM fulllikesdetails WHERE userTeamId = ? AND userId = ?) AS isUserLiked, matchId, userTeamId, teamTypeString, captain, userTeamLikes AS likes, viceCaptain, player1, player2, player3, player4, player5, player6, player7, player8, player9, player10, player11 FROM fullteamdetails WHERE userTeamId = ?;";
  const teamQuery =
    "SELECT team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName FROM fullmatchdetails WHERE matchId = ?;";
  const playerQuery =
    "SELECT DISTINCT playerId, fullplayerdetails.name AS playerName, fullplayerdetails.displayName AS playerDisplayName, roleId, roleName, points, credits, fullplayerdetails.teamId, allteams.displayName AS teamDisplayName FROM fullplayerdetails JOIN allteams ON allteams.teamId = fullplayerdetails.teamId WHERE playerId = ? AND matchId = ?;";

  try {
    if (!/[^0-9]/g.test(teamId)) {
      const serverAddress = `${req.protocol}://${req.headers.host}`;
      const playersIds = await fetchData(fetchPlayerIdQuery, [
        teamId,
        userId,
        teamId,
      ]);
      const teamData = await fetchData(teamQuery, [playersIds[0]?.matchId]);

      if (teamData.length > 0) {
        teamData[0].team1FlagURL = imageUrl(
          __dirname,
          "../",
          `${process.env.TEAM_IMAGE_URL}${teamData[0].team1Id}.jpg`,
          serverAddress
        );
        teamData[0].team2FlagURL = imageUrl(
          __dirname,
          "../",
          `${process.env.TEAM_IMAGE_URL}${teamData[0].team2Id}.jpg`,
          serverAddress
        );
      }

      // checking if playerids exists or not
      let newAllTeams = [];

      // function to fetch all the users
      if (playersIds && playersIds.length > 0) {
        let counter = 0;
        playersIds.forEach(async (team) => {
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
              player[0].URL = imageUrl(
                __dirname,
                "../",
                `${process.env.PLAYER_IMAGE_URL}${player[0].playerId}.jpg`,
                serverAddress
              );

              if (team[key] === team["captain"])
                singleTeam.teamsDetails.captain = player[0];
              else if (team[key] === team["viceCaptain"])
                singleTeam.teamsDetails.viceCaptain = player[0];

              singleTeam.players.push(player[0]);
              i++;

              if (i === 11) {
                newAllTeams.push(singleTeam);
                counter++;
                if (playersIds.length === counter) {
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
        res.status(200).json({
          status: true,
          message: "success",
          data: {
            teams: [],
          },
        });
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
router.post("/updateUserTeamLikes", verifyUser, async (req, res) => {
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
});

// update views of team
router.post("/updateUserTeamViews", verifyUser, async (req, res) => {
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
});

// setting discussion by match id, user id, team id
router.post("/setDiscussion", verifyUser, async (req, res) => {
  // userId -> whos have made request means messenger who sends the message
  // createrId -> whose team is
  const { matchId, userId, message, createrId } = req.body;
  const serverAddress = `${req.protocol}://${req.headers.host}`;
  try {
    const regx = /[^0-9]/g;
    if (
      matchId &&
      userId &&
      createrId &&
      message !== "" &&
      !regx.test(matchId) &&
      !regx.test(userId) &&
      !regx.test(createrId)
    ) {
      const [[discussionObject]] = await fetchData(
        "CALL set_discussion(?, ?, ?, ?)",
        [matchId, userId, createrId, message]
      );

      if (discussionObject) {
        discussionObject.displayPicture = imageUrl(
          __dirname,
          "../",
          `${process.env.USER_IMAGE_URL}${discussionObject.imageStamp}.jpg`,
          serverAddress
        );
        delete discussionObject.imageStamp;
        discussionObject.messengerId = parseInt(discussionObject.messengerId);
      }

      res.status(200).json({
        status: true,
        message: "success",
        data: {
          messages: discussionObject || {},
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

// getting discussion match id and user id
router.post("/getDiscussion", async (req, res) => {
  const { matchId, createrId, pageNumber } = req.body;

  try {
    if (
      !/[^0-9]/g.test(matchId) &&
      !/[^0-9]/g.test(createrId) &&
      pageNumber &&
      pageNumber > 0 &&
      !/[^0-9]/g.test(pageNumber)
    ) {
      const serverAddress = `${req.protocol}://${req.headers.host}`;
      const [response, [{ totalMessages }]] = await fetchData(
        "SELECT messengerId, imageStamp, firstName, message, messageTime FROM `fulldiscussion` JOIN userdetails ON userdetails.userId = fulldiscussion.messengerId WHERE matchId = ? AND fulldiscussion.userId = ? ORDER BY messageTime DESC LIMIT ?, 50;SELECT COUNT (*) AS totalMessages FROM fulldiscussion WHERE matchId = ? AND fulldiscussion.userId = ?",
        [matchId, createrId, (pageNumber - 1) * 50, matchId, createrId]
      );

      const totalPages = Math.ceil(totalMessages / 50);

      response?.forEach((message) => {
        message.displayPicture = imageUrl(
          __dirname,
          "../",
          `${process.env.USER_IMAGE_URL}${message.imageStamp}.jpg`,
          serverAddress
        );
        delete message.imageStamp;
      });

      res.status(200).json({
        status: true,
        message: "success",
        data: {
          messages: response,
          totalPages,
          currentPage: pageNumber,
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

// comapring teams by match id
router.post("/compareTeams", async (req, res) => {
  const { matchId } = req.body;

  const allPlayersForMatch =
    "SELECT matchId, playerId, fullplayerdetails.name AS playerName, fullplayerdetails.displayName AS playerDisplayName, roleId, roleName, fullplayerdetails.teamId, allteams.name AS teamName, allteams.displayName AS teamDisplayName FROM fullplayerdetails JOIN allteams ON allteams.teamId = fullplayerdetails.teamId WHERE matchId = ?;";
  const matchDetails =
    "SELECT matchId, matchStartTimeMilliSeconds AS matchStartTime, venue, seriesDname AS seriesDisplayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName FROM fullmatchdetails WHERE matchId = ?;";

  try {
    if (!/[^0-9]/g.test(matchId)) {
      const serverAddress = `${req.protocol}://${req.headers.host}`;
      const response = await fetchData(allPlayersForMatch, [matchId]);
      const responseData = await fetchData(matchDetails, [matchId]);

      response.forEach((element) => {
        element.URL = imageUrl(
          __dirname,
          "../",
          `${process.env.PLAYER_IMAGE_URL}${element.playerId}.jpg`,
          serverAddress
        );
        element.flagURL = imageUrl(
          __dirname,
          "../",
          `${process.env.TEAM_IMAGE_URL}${element.teamId}.jpg`,
          serverAddress
        );
      });
      if (responseData.length > 0) {
        responseData[0].team1FlagURL = imageUrl(
          __dirname,
          "../",
          `${process.env.TEAM_IMAGE_URL}${responseData[0].team1Id}.jpg`,
          serverAddress
        );
        responseData[0].team2FlagURL = imageUrl(
          __dirname,
          "../",
          `${process.env.TEAM_IMAGE_URL}${responseData[0].team2Id}.jpg`,
          serverAddress
        );
      }
      res.status(200).json({
        status: true,
        message: "success",
        data: {
          players: response,
          matchDetails: responseData[0] || [],
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
