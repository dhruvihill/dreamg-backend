const axios = require("axios");
const mysql = require("mysql");
require("dotenv/config");
let connectionForCron = null;
const data = require("../data2.js");

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
          lineup?.starting_lineup?.forEach(async (player) => {
            try {
              const [{ playerId }] = await database(
                "SELECT playerId FROM allplayers WHERE playerRadarId = ?",
                [player.id.substr(10)],
                connection
              );
              const [{ competitorIdStored }] = await database(
                "SELECT teamId AS competitorIdStored FROM allteams WHERE teamRadarId = ?",
                [competitorId.substr(14)],
                connection
              );
              const storePlayer = await database(
                "INSERT INTO match_lineup SET ?",
                {
                  matchId,
                  playerId: playerId,
                  competitorId: competitorIdStored,
                  order: player.order,
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
            } catch (error) {
              console.log(error.message, "storeMatchLineup");
            }
          });
        } catch (error) {
          console.log(error.message, "storeMatchLineup");
        }
      });
    } catch (error) {
      resolve(false);
      console.log(error.message, "storeMatchLineup");
    }
  });
};

const fetchMatches = async () => {
  try {
    const connection = await connectToDb();
    const matches = await database(
      `SELECT matchId, matchRadarId FROM fullmatchdetails WHERE fullmatchdetails.matchStatusString IN ('ended', 'closed', 'abandoned', 'cancelled', 'live') ORDER BY matchId;`,
      [],
      connection
    );

    let currentMatch = 0;
    const totalMatches = matches.length;

    const preocessMatch = async (match) => {
      try {
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
              setTimeout(() => {
                preocessMatch(matches[currentMatch]);
              }, 0);
            }
          } else {
            currentMatch++;
            if (currentMatch === totalMatches) {
              console.log("All matches processed");
            } else {
              setTimeout(() => {
                preocessMatch(matches[currentMatch]);
              }, 0);
            }
          }
        } else {
          currentMatch++;
          if (currentMatch === totalMatches) {
            console.log("All matches processed");
          } else {
            setTimeout(() => {
              preocessMatch(matches[currentMatch]);
            }, 0);
          }
        }
      } catch (error) {
        console.log(error.message, "preocessMatch");
        currentMatch++;
        if (currentMatch === totalMatches) {
          console.log("All matches processed");
        } else {
          setTimeout(() => {
            preocessMatch(matches[currentMatch]);
          }, 0);
        }
      }
    };
    preocessMatch(matches[currentMatch]);
  } catch (error) {
    console.log(error.message, "fetchMatches");
  }
};

fetchMatches();
