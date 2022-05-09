const express = require("express");
const router = express.Router();
const verifyUser = require("../middleware/verifyUser");
const { fetchData, imageUrl } = require("../database/db_connection");

// set team of matchId, userId, teamType
router.post("/setTeam", verifyUser, async (req, res) => {
  let {
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

      players.splice(players.indexOf(captain), 1);
      players.splice(players.indexOf(viceCaptain), 1);

      if (userTeamId && !regx.test(userTeamId) && userTeamId > 0) {
        message = await fetchData("CALL setUserTeam(?, ?, ?, ?, ?, ?, ?);", [
          matchId,
          userId,
          userTeamId,
          userTeamType,
          captain,
          viceCaptain,
          [...players],
        ]);
      } else {
        message = await fetchData("CALL setUserTeam(?, ?, ?, ?, ?, ?, ?);", [
          matchId,
          userId,
          0,
          userTeamType,
          captain,
          viceCaptain,
          [...players],
        ]);
      }
      if (message && message[0] && message[0][0]?.message === "success") {
        res.status(200).json({
          status: true,
          message: "success",
          data: {},
        });
      } else {
        throw new Error("something went wrong");
      }
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

router.post("/getUserTeamsByMatch", async (req, res) => {
  try {
    const { createrId, matchId } = req.body;
    const regx = /[^0-9]/g;

    if (!createrId || !matchId || regx.test(matchId) || regx.test(createrId)) {
      throw { message: "invalid input" };
    }
    const serverAddress = `${req.protocol}://${req.headers.host}`;
    const [userDetails, matchTeamDetails, playerDetails, userTeamDetails] =
      await fetchData("CALL getUserTeam(?, ?);", [matchId, createrId]);

    const fetchUserTeamDetails = () => {
      return new Promise((resolve, reject) => {
        try {
          if (userDetails && userDetails.length > 0) {
            // adding image url in user
            userDetails[0].displayPicture = imageUrl(
              __dirname,
              "../",
              `${process.env.USER_IMAGE_URL}${userDetails[0].imageStamp}.jpg`,
              serverAddress
            );
            delete userDetails[0].imageStamp;

            if (matchTeamDetails && matchTeamDetails.length > 0) {
              matchTeamDetails.forEach((team) => {
                team.teamFlagURL = imageUrl(
                  __dirname,
                  "../",
                  `${process.env.TEAM_IMAGE_URL}${team.teamId}.jpg`,
                  serverAddress
                );
              });

              if (userTeamDetails && userTeamDetails.length > 0) {
                if (
                  playerDetails &&
                  playerDetails.length === userTeamDetails.length * 11
                ) {
                  const userTeams = [];
                  const totalTeams = userTeamDetails.length;
                  let currentTeam = 0;

                  userTeamDetails.forEach((userTeam) => {
                    const userTeamInstance = {
                      teams: [],
                      teamsDetails: {},
                    };
                    userTeamInstance.teams = matchTeamDetails;
                    userTeamInstance.teamsDetails = userTeam;
                    userTeamInstance.teamsDetails.captain = playerDetails.find(
                      (player) => {
                        player.URL = imageUrl(
                          __dirname,
                          "../",
                          `${process.env.PLAYER_IMAGE_URL}${player.playerId}.jpg`,
                          serverAddress
                        );
                        return (
                          player.userTeamId == userTeam.userTeamId &&
                          player.isCaptain == 1
                        );
                      }
                    );
                    userTeamInstance.teamsDetails.viceCaptain =
                      playerDetails.find((player) => {
                        player.URL = imageUrl(
                          __dirname,
                          "../",
                          `${process.env.PLAYER_IMAGE_URL}${player.playerId}.jpg`,
                          serverAddress
                        );
                        return (
                          player.userTeamId == userTeam.userTeamId &&
                          player.isViceCaptain == 1
                        );
                      });

                    userTeams.push(userTeamInstance);

                    currentTeam++;
                    if (currentTeam >= totalTeams) {
                      resolve(userTeams);
                    }
                  });
                } else {
                  throw new Error("something went wrong");
                }
              } else {
                throw new Error("teams does not exists");
              }
            } else {
              throw new Error("match does not exists");
            }
          } else {
            throw new Error("user does not exists");
          }
        } catch (error) {
          reject(error);
        }
      });
    };

    const userTeams = await fetchUserTeamDetails();

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        userTeams: userTeams || [],
        userDetails: userDetails[0] || [],
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

// depreacated for now
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

router.post("/getUserTeamPlayers", verifyUser, async (req, res) => {
  try {
    const { userId, teamId } = req.body;

    const matchTeamQuery =
      "SELECT team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName FROM userTeamDetails JOIN fullmatchdetails ON fullmatchdetails.matchId = userTeamDetails.matchId WHERE userTeamDetails.userTeamId = ?;";

    const userTeamDetailsQuery =
      "SELECT userTeamId, teamTypeString, EXISTS(SELECT * FROM fulllikesdetails WHERE fulllikesdetails.userTeamId = userTeamDetails.userTeamId AND fulllikesdetails.userId = ?) AS isUserLiked, (SELECT COUNT(*) FROM fulllikesdetails WHERE fulllikesdetails.userTeamId = userTeamDetails.userTeamId) AS likes FROM userTeamDetails WHERE userTeamDetails.userTeamId = ?;";

    const userTeamPlayers =
      "SELECT fullplayerdetails.playerId AS playerId, userTeamPlayersDetails.isCaptain, userTeamPlayersDetails.isViceCaptain, fullplayerdetails.name AS playerName, fullplayerdetails.displayName AS playerDisplayName, roleId, roleName, COALESCE(points, 0) AS points, IF(fullmatchdetails.isPointsCalculated, CONCAT(COALESCE(points, 0), ' Pt'), CONCAT(COALESCE(credits, 0), ' Cr')) AS showStr, COALESCE(credits, 0) As credits, fullplayerdetails.teamId, allteams.displayName AS teamDisplayName FROM userTeamDetails JOIN userTeamPlayersDetails ON userTeamPlayersDetails.userTeamId = userTeamDetails.userTeamId JOIN fullplayerdetails ON fullplayerdetails.playerId = userTeamPlayersDetails.playerId AND fullplayerdetails.matchId = userTeamDetails.matchId JOIN allteams ON allteams.teamId = fullplayerdetails.teamId JOIN fullmatchdetails ON fullmatchdetails.matchId = userTeamDetails.matchId WHERE userTeamDetails.userTeamId = ?;";

    if (!/[^0-9]/g.test(teamId)) {
      const serverAddress = `${req.protocol}://${req.headers.host}`;

      const [matchTeamDetails, userTeamPlayersDetails, userTeamDetails] =
        await fetchData(
          `${matchTeamQuery}${userTeamPlayers}${userTeamDetailsQuery}`,
          [teamId, teamId, userId, teamId]
        );

      if (matchTeamDetails && matchTeamDetails.length > 0) {
        if (userTeamPlayersDetails && userTeamPlayersDetails.length > 0) {
          // adding team flag
          matchTeamDetails[0].team1FlagURL = imageUrl(
            __dirname,
            "../",
            `${process.env.TEAM_IMAGE_URL}${matchTeamDetails[0].team1Id}.jpg`,
            serverAddress
          );
          matchTeamDetails[0].team2FlagURL = imageUrl(
            __dirname,
            "../",
            `${process.env.TEAM_IMAGE_URL}${matchTeamDetails[0].team2Id}.jpg`,
            serverAddress
          );

          userTeamPlayersDetails.forEach((player) => {
            player.URL = imageUrl(
              __dirname,
              "../",
              `${process.env.TEAM_IMAGE_URL}${player.playerId}.jpg`,
              serverAddress
            );
          });

          const teamInstance = [
            {
              players: userTeamPlayersDetails,
              teamsDetails: {
                ...matchTeamDetails[0],
                userTeamId: userTeamDetails["userTeamId"],
                likes: userTeamDetails["likes"],
                isUserLiked: userTeamDetails["isUserLiked"],
                teamType: userTeamDetails.teamTypeString,
                captain: userTeamPlayersDetails.find(
                  (player) => player.isCaptain === 1
                ),
                viceCaptain: userTeamPlayersDetails.find(
                  (player) => player.isViceCaptain === 1
                ),
              },
            },
          ];

          res.status(200).json({
            status: true,
            message: "success",
            data: {
              teams: teamInstance,
            },
          });
        } else {
          throw new Error("team not found");
        }
      } else {
        throw new Error("team not found");
      }

      // if (matchTeamDetails.length > 0) {
      //   matchTeamDetails[0].team1FlagURL = imageUrl(
      //     __dirname,
      //     "../",
      //     `${process.env.TEAM_IMAGE_URL}${teamData[0].team1Id}.jpg`,
      //     serverAddress
      //   );
      //   matchTeamDetails[0].team2FlagURL = imageUrl(
      //     __dirname,
      //     "../",
      //     `${process.env.TEAM_IMAGE_URL}${teamData[0].team2Id}.jpg`,
      //     serverAddress
      //   );
      // }
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

// exporting module
module.exports = router;
