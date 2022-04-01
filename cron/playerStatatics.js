const axios = require("axios");
const mysql = require("mysql");
require("dotenv/config");
let connectionForCron = null;

const api_tokens = [
  "2jws2w6zmp4gt8zn3bv56nfy",
  "cg85e68fxv6mzgnbe2sjbsx3",
  "9dn2jbeu4j5ujxrxcgx6ev8k",
  "tmhxaq4w74x7c2xyahuhfq9y",
  "6sh4zwc43b5a8ajszjh7e79d",
  "bme7zzhvyxkw2g2vvkpx8dwe",
  "egb9th552ezx7ddmamtvst7w",
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
                parseInt(error.response.headers["x-plan-quota-current"]) >=
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

const storeSinglePlayerDb = (player, storedPlayerId, connection) => {
  return new Promise(async (resolve) => {
    try {
      let statsCount = 0;
      const totalStats = player.statistics.tournaments.length;
      const storeSingleState = async (statistics) => {
        const storeStatisticsBatting = await database(
          "INSERT INTO player_statistics_batting SET ?;",
          {
            playerId: storedPlayerId,
            type: statistics.type,
            matches: statistics.batting.matches,
            innings: statistics.batting.innings,
            notOuts: statistics.batting.not_outs,
            runs: statistics.batting.runs,
            highestScore: statistics.batting.highest_score,
            average: statistics.batting.average,
            hundreds: statistics.batting.hundreds,
            fifties: statistics.batting.fifties,
            fours: statistics.batting.fours,
            sixes: statistics.batting.sixes,
            strikeRate: statistics.batting.strike_rate,
            ballFaced: statistics.batting.balls_faced,
          },
          connection
        );
        const storeStatisticsBowling = await database(
          "INSERT INTO player_statistics_bowling SET ?;",
          {
            playerId: storedPlayerId,
            type: statistics.type,
            matches: statistics.bowling.matches,
            innings: statistics.bowling.innings,
            overs: statistics.bowling.overs,
            maidens: statistics.bowling.maidens,
            runs: statistics.bowling.runs,
            wickets: statistics.bowling.wickets,
            economy: statistics.bowling.economy,
            average: statistics.bowling.average,
            strikeRate: statistics.bowling.strike_rate,
            bestBowling: statistics.bowling.best_bowling,
            ballsBalled: statistics.bowling.balls_bowled,
            fourWicketHauls: statistics.bowling.four_wicket_hauls,
            fiverWicketHauls: statistics.bowling.five_wicket_hauls,
            tenWicketHauls: statistics.bowling.ten_wicket_hauls,
            catches: statistics.fielding.catches,
            stumping: statistics.fielding.stumpings,
            runOuts: statistics.fielding.runouts,
          },
          connection
        );
        if (
          storeStatisticsBatting.affectedRows &&
          storeStatisticsBowling.affectedRows
        ) {
          statsCount++;
          if (statsCount === totalStats) {
            resolve(true);
          } else {
            setTimeout(() => {
              storeSingleState(player.statistics.tournaments[statsCount]);
            }, 0);
          }
        } else {
          statsCount++;
          if (statsCount === totalStats) {
            resolve(true);
          } else {
            setTimeout(() => {
              storeSingleState(player.statistics.tournaments[statsCount]);
            }, 0);
          }
        }
      };
      storeSingleState(player.statistics.tournaments[statsCount]);
    } catch (error) {
      console.log(error.message, "storeSinglePlayerStatics");
    }
  });
};

const storePlayersStatics = async (players) => {
  return new Promise(async (resolve) => {
    let playerCount = 0;
    const totalPlayers = players.length;

    const storeSinglePlayerStatics = async (player) => {
      try {
        delay = 1200;
        const connection = await connectToDb();
        const [{ isExists: isStateExist }] = await database(
          "SELECT COUNT(player_statistics_batting.playerId) As isExists FROM `player_statistics_batting` WHERE player_statistics_batting.playerId = ?;",
          [player.playerId],
          connection
        );
        if (!isStateExist) {
          const playerData = await makeRequest(
            `players/sr:player:${player.playerRadarId}/profile.json`
          );

          if (playerData && playerData.player && playerData.statistics) {
            console.log("lests store player " + player.playerRadarId);
            const updatePlayer = await storePlayerStyle(
              playerData.player,
              connection
            );
            const storePlayerStaticsRes = await storeSinglePlayerDb(
              playerData,
              player.playerId,
              connection
            );
            if (updatePlayer && storePlayerStaticsRes) {
              connection.release();
              console.log(true);
              playerCount++;
              if (playerCount === totalPlayers) {
                resolve(true);
              } else {
                setTimeout(() => {
                  storeSinglePlayerStatics(players[playerCount]);
                }, 0);
              }
            } else {
              console.log(true);
              playerCount++;
              if (playerCount === totalPlayers) {
                resolve(true);
              } else {
                setTimeout(() => {
                  storeSinglePlayerStatics(players[playerCount]);
                }, 0);
              }
            }
          } else {
            connection.release();
            playerCount++;
            if (playerCount !== totalPlayers) {
              setTimeout(() => {
                storeSinglePlayerStatics(players[playerCount]);
              }, 0);
            } else {
              resolve(true);
            }
          }
        } else {
          connection.release();
          playerCount++;
          if (playerCount === totalPlayers) {
            resolve(true);
          } else {
            setTimeout(() => {
              storeSinglePlayerStatics(players[playerCount]);
            }, 0);
          }
        }
      } catch (error) {
        playerCount++;
        if (!playerCount === totalPlayers) {
          setTimeout(() => {
            storeSinglePlayerStatics(players[playerCount]);
          }, 0);
        } else {
          resolve(true);
        }
      }
    };
    storeSinglePlayerStatics(players[playerCount]);
  });
};

const fetchData = async () => {
  try {
    let connection = await connectToDb();
    const players = await database(
      "SELECT playerRadarId, playerId from allplayers WHERE playerId > 0 ORDER BY playerId;",
      [],
      connection
    );
    storePlayersStatics(players);
  } catch (error) {
    console.log(error.message, "fetchData");
  }
};

module.exports = { storePlayersStatics };
