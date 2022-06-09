const express = require("express");
const router = express.Router({ mergeParams: true });
const MatchStatistics = require("../module/MatchStatistics");
const { fetchData, imageUrl } = require("../database/db_connection");
const { convertTimeZone } = require("../middleware/convertTimeZone");

// get players by match id
router.post("/getPlayers", async (req, res) => {
  const { matchId, userTeamId } = req.body;

  try {
    if (!/[^0-9]/g.test(matchId)) {
      let data;
      if (userTeamId && !/[^0-9]/g.test(userTeamId) && userTeamId > 0) {
        [data, matchDetails] = await fetchData("CALL getPlayers(?, ?);", [
          matchId,
          userTeamId,
        ]);
      } else {
        [data, matchDetails] = await fetchData("CALL getPlayers(?, ?);", [
          matchId,
          0,
        ]);
      }
      const serverAddress = `${req.protocol}://${req.headers.host}`;

      data?.forEach((player) => {
        player.roleName = player.roleName.toUpperCase();
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
          matchDetails: matchDetails[0],
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

// get predictors by match id or with no match id and match status
router.post("/getPredictions", async (req, res) => {
  try {
    const { matchId, filter, pageNumber } = req.body;

    let validMatchId = true;
    let totalPredictorsQuery = "";
    let query;
    if (matchId) {
      validMatchId = true;
      if (!/[^0-9]/g.test(matchId)) validMatchId = true;
      else {
        throw { message: "invalid input" };
      }
      totalPredictorsQuery =
        "SELECT COUNT(*) AS totalPredictors FROM userTeamDetails WHERE matchId = ?;";
      query =
        filter === "MOST_VIEWED"
          ? "SELECT userdetails.userId, SUM(userTeamDetails.userTeamViews) AS totalViews, phoneNumber, firstName, lastName, city, registerTime FROM userdetails JOIN userTeamDetails ON userTeamDetails.userId = userdetails.userId JOIN fullmatchdetails ON fullmatchdetails.matchId = userTeamDetails.matchId WHERE userTeamDetails.matchId = ? GROUP BY userdetails.userId ORDER BY totalViews DESC LIMIT ?, 20;"
          : filter === "MOST_LIKED"
          ? "SELECT userdetails.userId, userdetails.imageStamp AS imageStamp, SUM(userTeamDetails.userTeamLikes) AS totalLikes, phoneNumber, firstName, lastName, city, registerTime FROM userdetails JOIN userTeamDetails ON userTeamDetails.userId = userdetails.userId JOIN fullmatchdetails ON fullmatchdetails.matchId = userTeamDetails.matchId WHERE userTeamDetails.matchId = ? GROUP BY userdetails.userId ORDER BY totalLikes DESC LIMIT ?, 20;"
          : "SELECT userdetails.userId, userdetails.imageStamp AS imageStamp, COALESCE(SUM(userTeamDetails.userTeamPoints), 0) AS totalPoints, phoneNumber, firstName, lastName, city, registerTime FROM userdetails JOIN userTeamDetails ON userTeamDetails.userId = userdetails.userId JOIN fullmatchdetails ON fullmatchdetails.matchId = userTeamDetails.matchId WHERE userTeamDetails.matchId = ? GROUP BY userdetails.userId ORDER BY totalPoints DESC LIMIT ?, 20;";
    } else {
      totalPredictorsQuery =
        "SELECT COUNT(*) AS totalPredictors FROM userTeamDetails;";
      query =
        filter === "MOST_VIEWED"
          ? "SELECT userdetails.userId, userdetails.imageStamp AS imageStamp, SUM(userTeamDetails.userTeamViews) AS totalViews, phoneNumber, firstName, lastName, city, registerTime FROM userdetails JOIN userTeamDetails ON userTeamDetails.userId = userdetails.userId JOIN fullmatchdetails ON fullmatchdetails.matchId = userTeamDetails.matchId GROUP BY userdetails.userId ORDER BY totalViews DESC LIMIT ?, 20;"
          : filter === "MOST_LIKED"
          ? "SELECT userdetails.userId, userdetails.imageStamp AS imageStamp, SUM(userTeamDetails.userTeamLikes) AS totalLikes, phoneNumber, firstName, lastName, city, registerTime FROM userdetails JOIN userTeamDetails ON userTeamDetails.userId = userdetails.userId JOIN fullmatchdetails ON fullmatchdetails.matchId = userTeamDetails.matchId GROUP BY userdetails.userId ORDER BY totalLikes DESC LIMIT ?, 20;"
          : "SELECT userdetails.userId, userdetails.imageStamp AS imageStamp, COALESCE(AVG(userTeamDetails.userTeamPoints), 0) AS totalPoints, phoneNumber, firstName, lastName, city, registerTime FROM userdetails JOIN userTeamDetails ON userTeamDetails.userId = userdetails.userId JOIN fullmatchdetails ON fullmatchdetails.matchId = userTeamDetails.matchId WHERE fullmatchdetails.matchStatusString IN ('ended', 'closed') GROUP BY userdetails.userId ORDER BY totalPoints DESC LIMIT ?, 20;";
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

// get best picks by match id
router.post("/getBestPicks", async (req, res) => {
  try {
    const { matchId } = req.body;
    const match = await new MatchStatistics(matchId).getMatchDetails();

    if (
      match &&
      match.matchDetails &&
      match.players.length > 0 &&
      match.competitors.length > 0
    ) {
      const serverAddress = `${req.protocol}://${req.headers.host}`;

      match.competitors.forEach((competitor) => {
        competitor.displayPicture = imageUrl(
          __dirname,
          "../",
          `${process.env.TEAM_IMAGE_URL}${competitor.teamId}.jpg`,
          serverAddress
        );
      });

      let bastMans = match.players.filter((player) => {
        player.URL = imageUrl(
          __dirname,
          "../",
          `${process.env.PLAYER_IMAGE_URL}${player.playerId}.jpg`,
          serverAddress
        );
        return player.roleName === "BATSMAN" && player.selectedBy > 0;
      });
      let wicketKeepers = match.players.filter((player) => {
        player.URL = imageUrl(
          __dirname,
          "../",
          `${process.env.PLAYER_IMAGE_URL}${player.playerId}.jpg`,
          serverAddress
        );
        return player.roleName === "WICKET_KEEPER" && player.selectedBy > 0;
      });
      let allRounders = match.players.filter((player) => {
        player.URL = imageUrl(
          __dirname,
          "../",
          `${process.env.PLAYER_IMAGE_URL}${player.playerId}.jpg`,
          serverAddress
        );
        return player.roleName === "ALL_ROUNDER" && player.selectedBy > 0;
      });
      let bowlers = match.players.filter((player) => {
        player.URL = imageUrl(
          __dirname,
          "../",
          `${process.env.PLAYER_IMAGE_URL}${player.playerId}.jpg`,
          serverAddress
        );
        return player.roleName === "BOWLER" && player.selectedBy > 0;
      });

      const sortPlayer = (a, b) => {
        return a.selectedBy > b.selectedBy
          ? -1
          : a.selectedBy < b.selectedBy
          ? 1
          : 0;
      };

      bastMans = bastMans.sort(sortPlayer).slice(0, 5);
      wicketKeepers = wicketKeepers.sort(sortPlayer).slice(0, 5);
      allRounders = allRounders.sort(sortPlayer).slice(0, 5);
      bowlers = bowlers.sort(sortPlayer).slice(0, 5);

      res.status(200).send({
        status: true,
        message: "success",
        data: {
          matchDetails: match.matchDetails,
          bestPick: {
            bastMans,
            wicketKeepers,
            allRounders,
            bowlers,
          },
          competitors: match.competitors,
        },
      });
    } else {
      res.status(200).send({
        status: true,
        message: "no best picks found",
        data: {},
      });
    }
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage || error.message,
      data: {},
    });
  }
});

// depreicated for now
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
    "SELECT DISTINCT fullmatchdetails.matchId FROM fullmatchdetails JOIN userTeamDetails ON userTeamDetails.matchId = fullmatchdetails.matchId WHERE fullmatchdetails.matchStartDateTime < unix_timestamp(now()) * 1000 AND fullmatchdetails.matchStatus != 'live' ORDER BY matchStartDateTime DESC LIMIT 5;";
  const topPredictorsQuery =
    "SELECT * FROM (SELECT userdetails.userId, userdetails.imageStamp, firstName, lastName, COALESCE(AVG(userTeamDetails.userTeamPoints), 0) AS totalPoints FROM userTeamDetails JOIN userdetails ON userdetails.userId = userTeamDetails.userId GROUP BY userTeamDetails.userId ORDER BY totalPoints DESC LIMIT 10) AS predictors WHERE predictors.totalPoints > 0;";

  try {
    const serverAddress = `${req.protocol}://${req.headers.host}`;
    const recentMatches = await fetchData(recentMatchesQuery);
    const matchIds = recentMatches.map(({ matchId }) => matchId);
    const predictor = await fetchData(topPredictorsQuery, [matchIds.join(",")]);

    // replace server address
    predictor.forEach((trending) => {
      trending.totalPoints = trending.totalPoints.toFixed(1);
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

// match statistics
router.use("/statistics", require("./statistics"));

// comapring teams by match id
router.post("/compareTeams", async (req, res) => {
  try {
    const timeZone = req.headers.timezone;
    const { matchId } = req.body;

    const allPlayersForMatch =
      "SELECT matchId, playerId, fullplayerdetails.name AS playerName, fullplayerdetails.displayName AS playerDisplayName, roleId, roleName, fullplayerdetails.teamId, allteams.name AS teamName, allteams.displayName AS teamDisplayName FROM fullplayerdetails JOIN allteams ON allteams.teamId = fullplayerdetails.teamId WHERE matchId = ?;";
    const matchDetails =
      "SELECT matchId, matchStartDateTime, venue, seriesDname AS seriesDisplayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName FROM fullmatchdetails WHERE matchId = ?;";
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
        // converting time zone
        [responseData[0].matchStartDateTime, responseData[0].matchStartTime] =
          convertTimeZone(responseData[0].matchStartDateTime, timeZone);
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
