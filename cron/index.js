const axios = require("axios");
const { request } = require("https");
const mysql = require("mysql");
const path = require("path");
const fs = require("fs");
require("dotenv/config");
let connectionForCron;

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
    console.log(error.message);
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
    const teamsStatistics = {
      insertedTeamIds: [],
      duplicateTeamIds: [],
    };
    [1, 2].forEach(async (item, index) => {
      try {
        const storeTeam = await database("INSERT INTO teams SET ?", {
          teamId: match[`team${item}`].id,
          name: match[`team${item}`].name,
          displayName: match[`team${item}`].dName,
          teamFlagUrl: match[`team${item}`].teamFlagURL,
        });

        if (storeTeam && index === 1) {
          teamsStatistics.insertedTeamIds.push(match[`team${item}`].id);
          resolve(teamsStatistics);
        }
      } catch (error) {
        if (error.sqlMessage && error.sqlMessage.includes("Duplicate")) {
          teamsStatistics.duplicateTeamIds.push(match[`team${item}`].id);
          if (index === 1) {
            resolve(teamsStatistics);
          }
        } else {
          console.log(error.message);
        }
      } finally {
        const teamId = match[`team${item}`].id;
        downloadImage(
          match[`team${item}`].teamFlagURL,
          path.join(__dirname, `../public/images/teamflag/${teamId}.jpg`)
        );
      }
    });
  });
};

const insertSingleSeries = async (match) => {
  return new Promise(async (resolve) => {
    const seriesStatistics = {
      insertedSeriesIds: [],
      duplicateSeriesIds: [],
    };

    try {
      const series = await database("INSERT INTO all_series SET ?", {
        seriesId: match.seriesId,
        seriesDisplayName: match.seriesDname,
        seriesName: match.seriesName,
      });
      if (series) {
        seriesStatistics.insertedSeriesIds.push(match.seriesId);
        resolve(seriesStatistics);
      }
    } catch (error) {
      if (error.sqlMessage && error.sqlMessage.includes("Duplicate entry")) {
        seriesStatistics.duplicateSeriesIds.push(match.seriesId);
        resolve(seriesStatistics);
      } else {
        console.log(error.message);
      }
    }
  });
};

const insertSingleMatch = async (match) => {
  return new Promise(async (resolve) => {
    const matchStatistics = {
      insertedMatchIds: [],
      duplicateMatchIds: [],
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
        matchStatistics.duplicateMatchIds.push(matchId);
        resolve(matchStatistics);
      }
    } catch (error) {
      if (error.sqlMessage && error.sqlMessage.includes("Duplicate entry")) {
        matchStatistics.duplicateMatchIds.push(match.matchId);
        resolve(matchStatistics);
      } else {
        console.log(error.message);
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

      const playersStatistics = {
        insertedPlayers: [],
        duplicatePlayers: [],
      };
      const relationStatistics = {
        insertedRelation: [],
        duplicateRelation: [],
      };

      if (!players || (players && players.length === 0)) {
        deleteMatch(matchId);
        resolve({ playersStatistics, relationStatistics });
      }
      let loopCount = 0;
      players?.forEach(async (player, index) => {
        try {
          insertSinglePlayer(player, matchId).then((singlePlayerStatistics) => {
            playersStatistics.insertedPlayers.push(
              ...singlePlayerStatistics.playersStatistics.insertedPlayerIds
            );
            playersStatistics.duplicatePlayers.push(
              ...singlePlayerStatistics.playersStatistics.duplicatePlayerIds
            );
            relationStatistics.insertedRelation.push(
              ...singlePlayerStatistics.relationStatistics.insertedRelation
            );
            relationStatistics.duplicateRelation.push(
              ...singlePlayerStatistics.relationStatistics.duplicateRelation
            );

            loopCount++;

            if (loopCount === players.length) {
              resolve({ playersStatistics, relationStatistics });
            }
          });
        } catch (error) {
          console.log(error.message);
        }
      });
    } catch (error) {
      console.log(error.message);
    }
  });
};

const insertSinglePlayer = async (player, matchId) => {
  return new Promise(async (resolve) => {
    const singlePlayerStatistics = {
      playersStatistics: {
        insertedPlayerIds: [],
        duplicatePlayerIds: [],
      },
      relationStatistics: {
        insertedRelation: [],
        duplicateRelation: [],
      },
    };

    try {
      const singlePlayerInserted = await database("INSERT INTO players SET ?", {
        playerId: player.id,
        name: player.name,
        role: player.role,
        displayName: player.dName,
        url: player.imgURL,
      });

      if (singlePlayerInserted) {
        singlePlayerStatistics.playersStatistics.insertedPlayerIds.push(
          player.id
        );
        insertSingleMatchPlayerRelation(player, matchId).then(
          (relationStatistics) => {
            singlePlayerStatistics.relationStatistics.insertedRelation.push(
              ...relationStatistics.insertedRelation
            );
            singlePlayerStatistics.relationStatistics.duplicateRelation.push(
              ...relationStatistics.duplicateRelation
            );
            resolve(singlePlayerStatistics);
          }
        );
      }
    } catch (error) {
      if (error.sqlMessage && error.sqlMessage.includes("Duplicate entry")) {
        singlePlayerStatistics.playersStatistics.duplicatePlayerIds.push(
          player.id
        );
        insertSingleMatchPlayerRelation(player, matchId).then(
          (relationStatistics) => {
            singlePlayerStatistics.relationStatistics.insertedRelation.push(
              ...relationStatistics.insertedRelation
            );
            singlePlayerStatistics.relationStatistics.duplicateRelation.push(
              ...relationStatistics.duplicateRelation
            );
            resolve(singlePlayerStatistics);
          }
        );
      } else {
        console.log(error.message, "single player error");
      }
    } finally {
      downloadImage(
        player.imgURL,
        path.join(
          __dirname,
          `../public/images/players/profilePicture/${player.id}.jpg`
        )
      );
    }
  });
};

const insertSingleMatchPlayerRelation = async (player, matchId) => {
  return new Promise(async (resolve) => {
    const matchPlayerRelationStatistics = {
      insertedRelation: [],
      duplicateRelation: [],
    };

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
        matchPlayerRelationStatistics.insertedRelation.push(player.id);
        resolve(matchPlayerRelationStatistics);
      }
    } catch (error) {
      if (error.sqlMessage && error.sqlMessage.includes("Duplicate entry")) {
        matchPlayerRelationStatistics.duplicateRelation.push(player.id);
        resolve(matchPlayerRelationStatistics);
      } else {
        console.log(error.message);
      }
    }
  });
};

const downloadImage = (url, filePath) => {
  return new Promise(async (resolve) => {
    try {
      const { data } = await axios.get(url, { responseType: "arraybuffer" });
      fs.writeFile(filePath, data, (err) => {
        if (err) {
          console.log(err.message);
          resolve(false);
        } else {
          resolve(true);
        }
      });
    } catch (error) {
      resolve(false);
    }
  });
};

const deleteMatch = (matchId) => {
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
        resolve(true);
      }
    } catch (error) {
      console.log(error.message);
    }
  });
};

// manage to insert all data into database
const fetchAndStore = async () => {
  try {
    const statistics = {
      teamsStatistics: {
        insertedTeamIds: [],
        duplicateTeamIds: [],
      },
      seriesStatistics: {
        insertedSeriesIds: [],
        duplicateSeriesIds: [],
      },
      matchesStatistics: {
        insertedMatchIds: [],
        duplicateMatchIds: [],
      },
      playersStatistics: {
        insertedPlayerIds: [],
        duplicatePlayerIds: [],
      },
      relationStatistics: {
        insertedRelation: [],
        duplicateRelation: [],
      },
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
                    .then((teamsStatistics) => {
                      statistics.teamsStatistics.insertedTeamIds.push(
                        ...teamsStatistics.insertedTeamIds
                      );
                      statistics.teamsStatistics.duplicateTeamIds.push(
                        ...teamsStatistics.duplicateTeamIds
                      );

                      // inserting series
                      insertSingleSeries(match)
                        .then((seriesStatistics) => {
                          statistics.seriesStatistics.insertedSeriesIds.push(
                            ...seriesStatistics.insertedSeriesIds
                          );
                          statistics.seriesStatistics.duplicateSeriesIds.push(
                            ...seriesStatistics.duplicateSeriesIds
                          );

                          // inserting matches
                          insertSingleMatch(match)
                            .then((matchStatistics) => {
                              statistics.matchesStatistics.insertedMatchIds.push(
                                ...matchStatistics.insertedMatchIds
                              );
                              statistics.matchesStatistics.duplicateMatchIds.push(
                                ...matchStatistics.duplicateMatchIds
                              );

                              // if (
                              //   !(
                              //     matchStatistics.duplicateMatchIds.length >
                              //       0 &&
                              //     matchStatistics.insertedMatchIds.length === 0
                              //   )
                              // ) {
                              // inserting match players
                              insertPlayersOfMatch(match.matchId)
                                .then(
                                  ({
                                    playersStatistics,
                                    relationStatistics,
                                  }) => {
                                    statistics.playersStatistics.insertedPlayerIds.push(
                                      ...playersStatistics.insertedPlayers
                                    );
                                    statistics.playersStatistics.duplicatePlayerIds.push(
                                      ...playersStatistics.duplicatePlayers
                                    );
                                    statistics.relationStatistics.insertedRelation.push(
                                      ...relationStatistics.insertedRelation
                                    );
                                    statistics.relationStatistics.duplicateRelation.push(
                                      ...relationStatistics.duplicateRelation
                                    );

                                    loopCount++;
                                    if (loopCount === totalMatchObjects) {
                                      resolve();
                                    }
                                  }
                                )
                                .catch((error) => {
                                  console.log(error.message, "here");
                                });
                              // } else {
                              //   loopCount++;
                              //   if (loopCount === totalMatchObjects) {
                              //     resolve();
                              //   }
                              // }
                            })
                            .catch((error) => {
                              console.log(error.message);
                            });
                        })
                        .catch((error) => {
                          console.log(error.message);
                        });
                    })
                    .catch((error) => {
                      console.log(error.message);
                    });
                } catch (error) {
                  console.log(error.message);
                }
              });
            } catch (error) {
              console.log(error.message);
            }
          });
        } catch (error) {
          console.log(error.message);
        }
      });
    };
    storeData()
      .then(() => {
        const insertedTeamIds = new Set(
          statistics.teamsStatistics.insertedTeamIds
        );
        const duplicateTeamIds = new Set(
          statistics.teamsStatistics.duplicateTeamIds
        );
        const insertedSeriesIds = new Set(
          statistics.seriesStatistics.insertedSeriesIds
        );
        const duplicateSeriesIds = new Set(
          statistics.seriesStatistics.duplicateSeriesIds
        );
        const insertedMatchIds = new Set(
          statistics.matchesStatistics.insertedMatchIds
        );
        const duplicateMatchIds = new Set(
          statistics.matchesStatistics.duplicateMatchIds
        );
        const insertedPlayerIds = new Set(
          statistics.playersStatistics.insertedPlayerIds
        );
        const duplicatePlayerIds = new Set(
          statistics.playersStatistics.duplicatePlayerIds
        );
        const insertedRelations = new Set(
          statistics.relationStatistics.insertedRelation
        );
        const duplicateRelations = new Set(
          statistics.relationStatistics.duplicateRelation
        );
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

        connectionForCron.end((err) => {
          if (err) console.log(err.sqlMessage);
          else console.log("connection ended");
        });
      })
      .catch((error) => {
        console.log(error.message);
      });
  } catch (error) {
    console.log(error.message);
  }
};

module.exports = fetchAndStore();
