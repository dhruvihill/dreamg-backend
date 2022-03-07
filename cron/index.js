const axios = require("axios");
const mysql = require("mysql");
const path = require("path");
const { writeFile } = require("fs/promises");
require("dotenv/config");
let connectionForCron;

let allStatistics = {
  teamsStatistics: {
    insertedIds: [],
    duplicatedIds: [],
  },
  seriesStatistics: {
    insertedIds: [],
    duplicatedIds: [],
  },
  matchesStatistics: {
    insertedIds: [],
    duplicatedIds: [],
  },
  playersStatistics: {
    insertedIds: [],
    duplicatedIds: [],
  },
  relationStatistics: {
    insertedIds: [],
    duplicatedIds: [],
  },
  playerPerformanceStatistics: {
    insertedIds: [],
    duplicatedIds: [],
  },
  playerImagesStatistics: {
    insertedIds: [],
  },
  teamsImageStatistics: {
    insertedIds: [],
  },
  deleteMatchStatistics: [],
};

// connectiong to database
const connectToDb = () => {
  // connect to database
  connectionForCron.connect((err) => {
    try {
      if (err) throw err;
      else console.log("Connected Successfully for cron");
    } catch (error) {
      if (error.message.includes("ECONNREFUSED")) {
        // some email stuff goes here
      }
      setTimeout(() => {
        initializeConnection();
      }, 1000);
    }
  });

  // error handling to Database
  connectionForCron.on("error", (err) => {
    console.log("db error", err.code);
    setTimeout(() => {
      initializeConnection();
    }, 1000);
  });
};
// intializing connection
const initializeConnection = () => {
  try {
    connectionForCron = mysql.createConnection({
      host: process.env.CLEVER_CLOUD_HOST,
      user: process.env.CLEVER_CLOUD_USER,
      password: process.env.CLEVER_CLOUD_PASSWORD,
      database: process.env.CLEVER_CLOUD_DATABASE_NAME,
      multipleStatements: true,
    });
    connectToDb();
  } catch (error) {
    console.log(error.message, "initializeConnection");
  }
};

// query to fetch, insert data
const database = (query, options) =>
  new Promise((resolve, reject) => {
    connectionForCron.query(query, options, (err, reponse) => {
      if (err) reject(err);
      else resolve(reponse);
    });
  });

// Axios request
const makeRequest = (url, method, data) => {
  return new Promise((resolve, reject) => {
    axios({
      url,
      method: method,
      headers: {
        Cookie:
          process.env.SSID || "SSID=SSID9101099d-3d6c-455f-934a-24da0276d04d",
      },
      data,
    })
      .then((data) => {
        resolve(data.data);
      })
      .catch((error) => {
        reject(error);
      });
  });
};

const insertTeamsOfMatch = async (match) => {
  return new Promise((resolve) => {
    [1, 2].forEach(async (item, index) => {
      const teamId = match[`team${item}`].id;
      try {
        const storeTeam = await database("INSERT INTO teams SET ?", {
          teamId: match[`team${item}`].id,
          name: match[`team${item}`].name,
          displayName: match[`team${item}`].dName,
          teamFlagUrl: match[`team${item}`].teamFlagURL,
        });
        downloadImage(
          match[`team${item}`].teamFlagURL,
          path.join(__dirname, `../public/images/teamflag/${teamId}.jpg`),
          teamId,
          true
        );
        if (storeTeam && index === 1) {
          allStatistics.teamsStatistics.insertedIds.push(teamId);
          resolve();
        }
      } catch (error) {
        if (error.sqlMessage && error.sqlMessage.includes("Duplicate")) {
          allStatistics.teamsStatistics.duplicatedIds.push(teamId);
          if (index === 1) {
            resolve();
          }
        } else {
          console.log(error.message, "insertTeamsOfMatch");
        }
      }
    });
  });
};

const insertSingleSeries = async (match) => {
  return new Promise(async (resolve) => {
    try {
      const series = await database("INSERT INTO all_series SET ?", {
        seriesId: match.seriesId,
        seriesDisplayName: match.seriesDname,
        seriesName: match.seriesName,
      });
      if (series) {
        allStatistics.seriesStatistics.insertedIds.push(match.seriesId);
        resolve();
      }
    } catch (error) {
      if (error.sqlMessage && error.sqlMessage.includes("Duplicate entry")) {
        allStatistics.seriesStatistics.duplicatedIds.push(match.seriesId);
        resolve();
      } else {
        console.log(error.message, "insertSingleSeries");
      }
    }
  });
};

const insertSingleMatch = async (match) => {
  return new Promise(async (resolve) => {
    const matchStatistics = {
      insertedIds: [],
      duplicateIds: [],
    };

    const {
      matchId,
      gameType,
      team1: { id: team1Id },
      team2: { id: team2Id },
      matchStartTime: matchStartTimeMilliSeconds,
      matchStatus,
      venue,
      displayName,
      seriesId,
    } = match;
    try {
      const matchSetted = await database("INSERT INTO all_matches SET ?", {
        matchId,
        gameType,
        team1Id,
        team2Id,
        matchStartTimeMilliSeconds,
        matchStatus,
        venue,
        displayName,
        seriesId: match.seriesId,
        matchStartDateTime: matchStartTimeMilliSeconds,
        seriesId,
      });
      if (matchSetted) {
        matchStatistics.insertedIds.push(match.matchId);
        allStatistics.matchesStatistics.insertedIds.push(matchId);
        resolve(matchStatistics);
      }
    } catch (error) {
      if (error.sqlMessage && error.sqlMessage.includes("Duplicate entry")) {
        matchStatistics.duplicateIds.push(match.matchId);
        allStatistics.matchesStatistics.duplicatedIds.push(match.matchId);
        resolve(matchStatistics);
      } else {
        console.log(error.message, "insertSingleMatch");
      }
    }
  });
};

const insertPlayersOfMatch = async (matchId) => {
  return new Promise(async (resolve) => {
    try {
      const { players } = await makeRequest(
        "https://www.my11circle.com/api/lobbyApi/matches/v1/getMatchSquad",
        "POST",
        { matchId }
      );
      if (!players || (players && players.length === 0)) {
        deleteMatch(matchId);
        resolve();
      }
      let loopCount = 0;
      players?.forEach(async (player) => {
        try {
          insertSinglePlayer(player, matchId)
            .then(() => {
              loopCount++;

              if (loopCount === players.length) {
                resolve();
              }
            })
            .catch((error) => {
              console.log(error.message, "insertPlayersOfMatch");
            });
        } catch (error) {
          console.log(error.message, "insertPlayersOfMatch");
        }
      });
    } catch (error) {
      console.log(error.message, "insertPlayersOfMatch");
    }
  });
};

const insertSinglePlayer = async (player, matchId) => {
  return new Promise(async (resolve) => {
    try {
      const singlePlayerInserted = await database("INSERT INTO players SET ?", {
        playerId: player.id,
        name: player.name,
        role: player.role,
        displayName: player.dName,
        url: player.imgURL,
      });
      downloadImage(
        player.imgURL,
        path.join(
          __dirname,
          `../public/images/players/profilePicture/${player.id}.jpg`
        ),
        player.id
      );

      if (singlePlayerInserted) {
        allStatistics.playersStatistics.insertedIds.push(player.id);
        insertSingleMatchPlayerRelation(player, matchId).then(() => {
          resolve();
        });
      }
    } catch (error) {
      if (error.sqlMessage && error.sqlMessage.includes("Duplicate entry")) {
        allStatistics.playersStatistics.duplicatedIds.push(player.id);
        insertSingleMatchPlayerRelation(player, matchId).then(() => {
          resolve();
        });
      } else {
        console.log(error.message, "single player error");
      }
    }
  });
};

const insertSingleMatchPlayerRelation = async (player, matchId) => {
  return new Promise(async (resolve) => {
    try {
      const insertedRelation = await database(
        "INSERT INTO match_player_relation SET ?",
        {
          matchId,
          playerId: player.id,
          teamId: player.teamId,
          credits: player.credits,
          points: player.points,
        }
      );
      if (insertedRelation) {
        allStatistics.relationStatistics.insertedIds.push(player.id);
        await insertPlayerStatistics(
          player.lastNMatchStatistics,
          insertedRelation.insertId,
          player.id
        );
        resolve();
      }
    } catch (error) {
      if (error.sqlMessage && error.sqlMessage.includes("Duplicate entry")) {
        allStatistics.relationStatistics.duplicatedIds.push(player.id);
        resolve();
      } else {
        console.log(error.message, "insertSingleMatchPlayerRelation");
      }
    }
  });
};

const insertPlayerStatistics = async (
  playersStatistics,
  insertId,
  playerId
) => {
  return new Promise(async (resolve) => {
    try {
      const insertedStatistics = await database(
        "INSERT INTO playerlastnmatchstatistics SET ?",
        {
          relationId: insertId,
          gameType: playersStatistics.gameType,
          runs: playersStatistics.runs,
          centuries: playersStatistics["num100s"],
          fifties: playersStatistics["num50s"],
          strikeRate: playersStatistics.strikeRate,
          wickets: playersStatistics.wickets,
          economy: playersStatistics.economy,
          highestScore: playersStatistics.highestScore,
          bestBowling: playersStatistics.bestBowling,
          average: playersStatistics.average,
          balls: playersStatistics.balls,
          innings: playersStatistics.innings,
        }
      );
      if (insertedStatistics) {
        allStatistics.playerPerformanceStatistics.insertedIds.push(playerId);
        resolve(true);
      }
    } catch (error) {
      allStatistics.playerPerformanceStatistics.duplicatedIds.push(playerId);
      resolve(false);
      console.log(error.message, "insertPlayerStatistics");
    }
  });
};

const downloadImage = async (url, filePath, id, isTeam = false) => {
  try {
    const { data } = await axios.get(url, { responseType: "arraybuffer" });
    const res = writeFile(filePath, data);
    if (res) {
      if (isTeam) {
        allStatistics.teamsImageStatistics.insertedIds.push(id);
        return;
      }
      allStatistics.playerImagesStatistics.insertedIds.push(id);
    }
  } catch (error) {
    console.log(error.message, "downloadImage");
  }
};

const deleteMatch = async (matchId) => {
  return new Promise(async (resolve) => {
    try {
      const deleted = await database(
        "DELETE FROM all_matches WHERE matchId = ?",
        matchId
      );
      const deleteRelation = await database(
        "DELETE FROM match_player_relation WHERE matchId = ?",
        matchId
      );
      if (deleted && deleteRelation) {
        allStatistics.deleteMatchStatistics.push(matchId);
        resolve();
      }
    } catch (error) {
      console.log(error.message, "deleteMatch");
    }
  });
};

// manage to insert all data into database
const fetchAndStore = async () => {
  try {
    allStatistics = {
      teamsStatistics: {
        insertedIds: [],
        duplicatedIds: [],
      },
      seriesStatistics: {
        insertedIds: [],
        duplicatedIds: [],
      },
      matchesStatistics: {
        insertedIds: [],
        duplicatedIds: [],
      },
      playersStatistics: {
        insertedIds: [],
        duplicatedIds: [],
      },
      relationStatistics: {
        insertedIds: [],
        duplicatedIds: [],
      },
      playerPerformanceStatistics: {
        insertedIds: [],
        duplicatedIds: [],
      },
      playerImagesStatistics: {
        insertedIds: [],
      },
      teamsImageStatistics: {
        insertedIds: [],
      },
      deleteMatchStatistics: [],
    };
    initializeConnection();
    const { matches } = await makeRequest(
      "https://www.my11circle.com/api/lobbyApi/v1/getMatches",
      "POST",
      { sportsType: 1 }
    );
    const storeData = () => {
      return new Promise(async (resolve) => {
        try {
          const totalMatchObjects =
            matches["1"].length + matches["2"].length + matches["3"].length;

          let loopCount = 0;
          [1, 2, 3].forEach((type) => {
            try {
              matches[type].forEach(async (match) => {
                try {
                  // inserting match teams
                  insertTeamsOfMatch(match)
                    .then(() => {
                      // inserting series
                      insertSingleSeries(match)
                        .then(() => {
                          // inserting matches
                          insertSingleMatch(match)
                            .then((matchStatistics) => {
                              if (
                                !(
                                  matchStatistics.duplicateIds.length > 0 &&
                                  matchStatistics.insertedIds.length === 0
                                )
                              ) {
                                // inserting match players
                                insertPlayersOfMatch(match.matchId)
                                  .then(() => {
                                    loopCount++;
                                    if (loopCount === totalMatchObjects) {
                                      resolve();
                                    }
                                  })
                                  .catch((error) => {
                                    console.log(
                                      error.message,
                                      "calling insertPlayersOfMatch"
                                    );
                                  });
                              } else {
                                loopCount++;
                                if (loopCount === totalMatchObjects) {
                                  resolve();
                                }
                              }
                            })
                            .catch((error) => {
                              console.log(
                                error.message,
                                "calling insertSingleMatch"
                              );
                            });
                        })
                        .catch((error) => {
                          console.log(
                            error.message,
                            "calling insertSingleSeries"
                          );
                        });
                    })
                    .catch((error) => {
                      console.log(error.message, "calling insertTeamsOfMatch");
                    });
                } catch (error) {
                  console.log(error.message, "calling loop");
                }
              });
            } catch (error) {
              console.log(error.message, "calling loop2");
            }
          });
        } catch (error) {
          console.log(error.message, "calling");
        }
      });
    };
    storeData()
      .then(() => {
        const insertedTeamIds = new Set(
          allStatistics.teamsStatistics.insertedIds
        );
        const duplicateTeamIds = new Set(
          allStatistics.teamsStatistics.duplicatedIds
        );
        const insertedSeriesIds = new Set(
          allStatistics.seriesStatistics.insertedIds
        );
        const duplicateSeriesIds = new Set(
          allStatistics.seriesStatistics.duplicatedIds
        );
        const insertedMatchIds = new Set(
          allStatistics.matchesStatistics.insertedIds
        );
        const duplicateMatchIds = new Set(
          allStatistics.matchesStatistics.duplicatedIds
        );
        const insertedPlayerIds = new Set(
          allStatistics.playersStatistics.insertedIds
        );
        const duplicatePlayerIds = new Set(
          allStatistics.playersStatistics.duplicatedIds
        );
        const insertedRelations = new Set(
          allStatistics.relationStatistics.insertedIds
        );
        const duplicateRelations = new Set(
          allStatistics.relationStatistics.duplicatedIds
        );
        const insertedStatistics = new Set(
          allStatistics.playerPerformanceStatistics.insertedIds
        );
        const duplicateStatistics = new Set(
          allStatistics.playerPerformanceStatistics.duplicatedIds
        );
        const insertedPlayerImage = new Set(
          allStatistics.playerImagesStatistics.insertedIds
        );
        const insertedTeamsImage = new Set(
          allStatistics.teamsImageStatistics.insertedIds
        );
        const deleteMatch = new Set(allStatistics.deleteMatchStatistics);

        console.table({
          insertedTeamIds: insertedTeamIds.size,
          duplicateTeamIds: duplicateTeamIds.size,
          insertedSeriesIds: insertedSeriesIds.size,
          duplicateSeriesIds: duplicateSeriesIds.size,
          insertedMatchIds: insertedMatchIds.size,
          duplicateMatchIds: duplicateMatchIds.size,
          insertedPlayerIds: insertedPlayerIds.size,
          duplicatePlayerIds: duplicatePlayerIds.size,
          insertedRelations: insertedRelations.size,
          duplicateRelations: duplicateRelations.size,
          insertedStatistics: insertedStatistics.size,
          duplicateStatistics: duplicateStatistics.size,
          playerImage: insertedPlayerImage.size,
          teamsImage: insertedTeamsImage.size,
          deleteMatch: deleteMatch.size,
        });

        console.log({
          insertedTeamIds: Array.from(insertedTeamIds),
          duplicateTeamIds: Array.from(duplicateTeamIds),
        });
        console.log({
          insertedSeriesIds: Array.from(insertedSeriesIds),
          duplicateSeriesIds: Array.from(duplicateSeriesIds),
        });
        console.log({
          insertedMatchIds: Array.from(insertedMatchIds),
          duplicateMatchIds: Array.from(duplicateMatchIds),
        });
        console.log({
          insertedPlayerIds: Array.from(insertedPlayerIds),
          duplicatePlayerIds: Array.from(duplicatePlayerIds),
        });
        console.log({
          insertedRelation: Array.from(insertedRelations),
          duplicateRelation: Array.from(duplicateRelations),
        });
        console.log({
          insertedStatistics: Array.from(insertedStatistics),
          duplicateStatistics: Array.from(duplicateStatistics),
        });
        console.log({
          playerImage: Array.from(insertedPlayerImage),
          teamsImage: Array.from(insertedTeamsImage),
        });
        console.log({
          deleteMatch: Array.from(deleteMatch),
        });

        connectionForCron.end((err) => {
          if (err) console.log(err.sqlMessage);
          else console.log("connection ended");
        });
      })
      .catch((error) => {
        console.log(error.message, "calling storeData");
      });
  } catch (error) {
    console.log(error.message);
  }
};

module.exports = fetchAndStore;
