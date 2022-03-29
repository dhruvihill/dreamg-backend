const axios = require("axios");
const mysql = require("mysql");
require("dotenv/config");
let connectionForCron = null;

const api_tokens = [
  "3frs3xa587s9uhfwa2wnkufu",
  "q7te6md2rf9ez7aju72bm4gz",
  "fmpwthupf2fr479np2r6dauy",
];
let currentSelectedToken = 0;

let delay = 0;

// connectiong to database
const connectToDb = () => {
  // connect to database
  return new Promise((resolve, reject) => {
    try {
      if (connectionForCron) {
        connectionForCron.getConnection((err, connection) => {
          try {
            if (err) throw err;
            else {
              // console.log("Connected Successfully for cron");
              resolve(connection);
            }
          } catch (error) {
            if (error.message.includes("ECONNREFUSED")) {
              // some email stuff goes here
            }
            reject(error);
            initializeConnection();
          }
        });
      } else {
        initializeConnection();
        connectToDb()
          .then((connection) => {
            resolve(connection);
          })
          .catch((error) => {
            console.log(error.message, "connectToDb");
          });
      }
    } catch (error) {
      console.log(error, "connectToDb");
    }

    // error handling to Database
    connectionForCron.on("error", (err) => {
      console.log("db error", err.code);
      setTimeout(() => {
        initializeConnection();
      }, 1000);
    });
  });
};
// intializing connection
const initializeConnection = () => {
  try {
    connectionForCron = mysql.createPool({
      connectionLimit: 0,
      host: process.env.LOCAL_DB_HOST,
      user: process.env.LOCAL_DB_USER,
      password: process.env.LOCAL_DB_PASSWORD,
      database: process.env.LOCAL_DB_NAME,
      multipleStatements: true,
    });
  } catch (error) {
    console.log(error.message, "initializeConnection");
  }
};
initializeConnection();

// query to fetch, insert data
const database = (query, options, connection) => {
  return new Promise(async (resolve, reject) => {
    try {
      connection.query(query, options, (err, reponse) => {
        if (err) {
          if (err.code === "ER_DUP_ENTRY") {
            console.log(err.message);
            resolve(true);
          } else {
            reject(err);
          }
        } else resolve(reponse);
      });
    } catch (error) {
      console.log(error.message, "cron databse function");
    }
  });
};

const createInstance = () => {
  return axios.create({
    baseURL: "https://api.sportradar.us/cricket-t2/en/",
    params: {
      api_key: api_tokens[currentSelectedToken],
    },
  });
};
let axiosInstance = createInstance();

// Axios request
const makeRequest = (url) => {
  return new Promise((resolve, reject) => {
    try {
      const makeCall = () => {
        setTimeout(() => {
          axiosInstance
            .get(url)
            .then((data) => {
              resolve(data.data);
            })
            .catch((error) => {
              if (
                parseInt(error.response.headers["x-plan-quota-current"]) >
                  parseInt(error.response.headers["x-plan-quota-allotted"]) ||
                parseInt(error.response.headers["x-plan-quota-current"]) ===
                  parseInt(error.response.headers["x-plan-quota-allotted"])
              ) {
                currentSelectedToken++;
                if (currentSelectedToken === api_tokens.length) {
                  console.warn("API limit reached");
                } else {
                  axiosInstance = createInstance();
                  makeCall();
                }
              } else {
                console.log(error.response.data, "error");
                console.log(error.message, "makeRequest");
                reject(error);
              }
            });
        }, delay + 1200);
        delay += 1200;
      };
      makeCall();
    } catch (error) {
      console.log(error.message, "makeRequest");
    }
  });
};

const storeBattingStyle = async (battingStyle, connection) => {
  return new Promise(async (resolve) => {
    try {
      if (battingStyle) {
        let [{ isExists: isStyleExist, styleId }] = await database(
          "SELECT COUNT(player_batting_style.playerBattingStyleId) As isExists, player_batting_style.playerBattingStyleId AS styleId FROM `player_batting_style` WHERE player_batting_style.battingStyleString = ?;",
          [battingStyle],
          connection
        );
        if (!isStyleExist) {
          const storeStyle = await database(
            "INSERT INTO player_batting_style SET ?;",
            { battingStyleString: battingStyle },
            connection
          );
          resolve(storeStyle.insertId);
        } else {
          resolve(styleId);
        }
      } else {
        resolve(null);
      }
    } catch (error) {
      console.log(error.message, "storeBattingStyle");
    }
  });
};

const storeBowlingStyle = async (bowlingStyle, connection) => {
  return new Promise(async (resolve) => {
    try {
      if (bowlingStyle) {
        let [{ isExists: isStyleExist, styleId }] = await database(
          "SELECT COUNT(player_bowling_style.playerBowlingStyleId) As isExists, player_bowling_style.playerBowlingStyleId AS styleId FROM `player_bowling_style` WHERE player_bowling_style.playerBowlingStyleString = ?;",
          [bowlingStyle],
          connection
        );
        if (!isStyleExist) {
          const storeStyle = await database(
            "INSERT INTO player_bowling_style SET ?;",
            { playerBowlingStyleString: bowlingStyle },
            connection
          );
          resolve(storeStyle.insertId);
        } else {
          resolve(styleId);
        }
      } else {
        resolve(null);
      }
    } catch (error) {
      console.log(error.message, "storeBattingStyle");
    }
  });
};

const storePlayerStyle = async (player, connection) => {
  return new Promise(async (resolve) => {
    try {
      const battingStyleId = await storeBattingStyle(
        player.batting_style,
        connection
      );
      const bowlingStyleId = await storeBowlingStyle(
        player.bowling_style,
        connection
      );

      const updatePlayer = await database(
        "UPDATE players SET playerBattingStyleId = ?, playerBowlingStyleId = ? WHERE playerRadarId = ?;",
        [battingStyleId, bowlingStyleId, player.id.substr(10)],
        connection
      );
      if (updatePlayer.affectedRows) {
        resolve(true);
      } else {
        resolve(false);
      }
    } catch (error) {
      console.log(error.message, "storePlayerStyle");
    }
  });
};

const storePlayerRoleParent = async (role, connection) => {
  return new Promise(async (resolve) => {
    try {
      if (role) {
        let [{ isExists: isRoleExist, roleId }] = await database(
          "SELECT COUNT(player_roles.roleId) AS isExists, player_roles.roleId AS roleId FROM player_roles WHERE player_roles.roleString = ?;",
          [role],
          connection
        );
        if (!isRoleExist) {
          const storeRole = await database(
            "INSERT INTO player_roles (roleString ) VALUES (?)",
            [role],
            connection
          );
          resolve(storeRole.insertId);
        } else {
          resolve(roleId);
        }
      } else {
        resolve(0);
      }
    } catch (error) {
      console.log(error.message, "storePlayerRoleParent");
    }
  });
};

const storeMatchLineup = async (matchId, matchRadarId, connection) => {
  return new Promise(async (resolve, reject) => {
    try {
      console.log("lets store match lineup", matchId);
      const matchLineUp = await makeRequest(
        `/matches/sr:match:${matchRadarId}/lineups.json`
      );
      const awayCompetitor = matchLineUp?.sport_event.competitors?.filter(
        (competitor) => {
          return competitor.qualifier === "away";
        }
      );
      const homeCompetitor = matchLineUp?.sport_event.competitors?.filter(
        (competitor) => {
          return competitor.qualifier === "home";
        }
      );

      let teamsloopCount = 0;
      matchLineUp?.lineups?.forEach((lineup) => {
        try {
          const team = lineup.team === "home" ? "home" : "away";
          const competitorId =
            team === "home" ? homeCompetitor[0].id : awayCompetitor[0].id;

          let playersloopCount = 0;
          const storePlayer = async (player) => {
            try {
              const [{ isExists: isPlayerExists, playerId }] = await database(
                "SELECT COUNT(playerId) AS isExists, playerId FROM allplayers WHERE playerRadarId = ?",
                [player.id.substr(10)],
                connection
              );

              const [{ competitorIdStored, competitorRadarIdStored }] =
                await database(
                  "SELECT teamId AS competitorIdStored, teamRadarId AS competitorRadarIdStored FROM allteams WHERE teamRadarId = ?",
                  [competitorId.substr(14)],
                  connection
                );
              if (isPlayerExists) {
                const storePlayer = await database(
                  "INSERT INTO match_lineup SET ?",
                  {
                    matchId,
                    playerId: playerId,
                    competitorId: competitorIdStored,
                    order: player.order,
                    isCaptain: player.is_captain ? 1 : 0,
                    isWicketKeeper: player.is_wicketkeeper ? 1 : 0,
                  },
                  connection
                );

                if (storePlayer) {
                  playersloopCount++;
                  if (playersloopCount === lineup.starting_lineup.length) {
                    teamsloopCount++;
                    if (teamsloopCount === matchLineUp.lineups.length) {
                      resolve(true);
                    }
                  }
                }
              } else {
                const storeSinglePlayer = async (playerData) => {
                  try {
                    const roleId = await storePlayerRoleParent(
                      playerData.type,
                      connection
                    );
                    const storePlayers = await database(
                      "INSERT INTO players SET ?",
                      {
                        playerRadarId: playerData.id.substr(10),
                        playerFirstName: playerData.name.split(", ")[1] || "",
                        playerLastName: playerData.name.split(", ")[0] || "",
                        playerCountryCode: playerData.country_code || null,
                        playerRole: roleId || 0,
                        playerDOB: playerData.date_of_birth || null,
                        playerCountry: playerData.nationality || null,
                      },
                      connection
                    );
                    if (storePlayers.insertId) {
                      const updatePlayer = await storePlayerStyle(
                        playerData,
                        connection
                      );
                      const storeRelation = await database(
                        "INSERT INTO tournament_competitor_player SET ?",
                        {
                          tournamentCompetitorId: competitorRadarIdStored,
                          playerId: storePlayers.insertId,
                        },
                        connection
                      );
                      setTimeout(() => {
                        storePlayer(player);
                      }, 0);
                    }
                  } catch (error) {
                    console.log(error.message, "storePlayersOfTeamsParent");
                  }
                };
                const { player: playerData } = await makeRequest(
                  `players/${player.id}/profile.json`
                );
                storeSinglePlayer(playerData);
              }
            } catch (error) {
              console.log(error.message, "storeMatchLineup1");
            }
          };
          lineup?.starting_lineup?.forEach((player) => {
            storePlayer(player);
          });
        } catch (error) {
          console.log(error.message, "storeMatchLineup2");
        }
      });
    } catch (error) {
      resolve(false);
      console.log(error.message, "storeMatchLineup3");
    }
  });
};

const fetchMatches = async () => {
  try {
    const connection = await connectToDb();
    const matches = await database(
      `SELECT matchId, matchRadarId FROM fullmatchdetails WHERE fullmatchdetails.matchStatusString IN ('ended', 'closed', 'abandoned', 'cancelled', 'live') AND matchId > 0 ORDER BY matchId;`,
      [],
      connection
    );

    let currentMatch = 0;
    const totalMatches = matches.length;

    const processMatch = async (match) => {
      try {
        delay = 1200;
        const newConnection = await connectToDb();
        const [{ isExists }] = await database(
          "SELECT COUNT(matchId) AS isExists FROM `match_lineup` WHERE match_lineup.matchId = ?;",
          [match.matchId],
          newConnection
        );
        if (!isExists) {
          const lineUpRes = await storeMatchLineup(
            match.matchId,
            match.matchRadarId,
            newConnection
          );
          if (lineUpRes) {
            console.log(true);
            currentMatch++;
            if (currentMatch === totalMatches) {
              console.log("All matches processed");
            } else {
              newConnection.release();
              setTimeout(() => {
                processMatch(matches[currentMatch]);
              }, 0);
            }
          } else {
            currentMatch++;
            if (currentMatch === totalMatches) {
              console.log("All matches processed");
            } else {
              newConnection.release();
              setTimeout(() => {
                processMatch(matches[currentMatch]);
              }, 0);
            }
          }
        } else {
          currentMatch++;
          if (currentMatch === totalMatches) {
            console.log("All matches processed");
          } else {
            newConnection.release();
            setTimeout(() => {
              processMatch(matches[currentMatch]);
            }, 0);
          }
        }
      } catch (error) {
        console.log(error.message, "preocessMatch");
        currentMatch++;
        if (currentMatch === totalMatches) {
          console.log("All matches processed");
        } else {
          newConnection.release();
          setTimeout(() => {
            processMatch(matches[currentMatch]);
          }, 0);
        }
      }
    };
    processMatch(matches[currentMatch]);
  } catch (error) {
    console.log(error.message, "fetchMatches");
  }
};

fetchMatches();
