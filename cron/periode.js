const mysql = require("mysql");
const { storeMatchLineup } = require("./matchLineUp");

let connectionForCron = null;

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

const storeScorcardAndPoints = async (match) => {
  return new Promise(async (resolve) => {
    try {
    } catch (error) {
      console.log(error.message);
    }
  });
};

const storeMatchLineUpAndStatus = async (match) => {
  try {
    const connection = await connectToDb();
    const res = await storeMatchLineup(
      match.matchId,
      match.matchRadarId,
      connection
    );
    if (res) {
      // calling function for scorcard and points
      const date = new Date(match.matchStartTime).getTime();
      setTimeout(storeScorcardAndPoints, date + 5 * 60 * 1000);

      console.log("match lineup stored");
      // updating match status
      let matchStatus = await database(
        "SELECT statusId FROM `match_status` WHERE statusString = ?",
        ["live"],
        connection
      );
      if (matchStatus && matchStatus.length > 0) {
        const updateMatchStatus = await database(
          "UPDATE tournament_matches SET matchStatus = ? WHERE matchId = ?",
          [matchStatus[0].statusId, match.matchId],
          connection
        );
        if (updateMatchStatus && updateMatchStatus.affectedRows === 1) {
          connection.release();
          console.log("match status updated");
        } else {
          connection.release();
          console.log("match status not updated");
        }
      } else {
        connection.release();
        console.log("match status not found");
      }
    } else {
      connection.release();
      console.log("not updated");
      // email stuff goes here
    }
  } catch (error) {
    if (error.isAxiosError) {
      if (error.response.data.message === "No lineups.") {
        setTimeout(() => {
          storeMatchLineUpAndStatus(match);
        }, 2 * 60 * 1000);
      }
    } else {
      console.log(error);
    }
  }
};

const fetchData = async () => {
  try {
    const connection = await connectToDb();
    const matches = await database(
      "SELECT matchId, matchRadarId, matchTournamentId, matchStartDateTime, matchStartTimeMilliSeconds, matchTyprString, matchStatusString, team1Id, team2Id, team1RadarId, team2RadarId FROM `fullmatchdetails` WHERE matchStatusString IN ('live', 'not_started') ORDER BY `fullmatchdetails`.`matchStartTimeMilliSeconds` DESC;",
      [],
      connection
    );
    connection.release();
    if (matches.length > 0) {
      const totalMatches = matches.length;
      let currentMatch = 0;

      const setTimeoutForMatches = async (match) => {
        try {
          // const connection = await connectToDb();
          const matchStartTime = new Date(
            match.matchStartTimeMilliSeconds + 330 * 60 * 1000
          ); // adding 5:30 hours to make it equal time zone
          const now = new Date();
          if (matchStartTime.getTime() > now.getTime()) {
            if (matchStartTime.getTime() < now.getTime() + 90 * 60 * 1000) {
              setTimeout(() => {
                storeMatchLineUpAndStatus(match);
              }, matchStartTime.getTime() - now.getTime() - 25 * 60 * 1000);

              currentMatch++;
              if (currentMatch !== totalMatches) {
                setTimeout(() => {
                  setTimeoutForMatches(matches[currentMatch]);
                }, 0);
              } else {
                console.log("done");
              }
            } else {
              currentMatch++;
              if (currentMatch !== totalMatches) {
                setTimeout(() => {
                  setTimeoutForMatches(matches[currentMatch]);
                }, 0);
              } else {
                console.log("done");
              }
            }
          } else {
            // do it right now
            currentMatch++;
            if (currentMatch !== totalMatches) {
              setTimeout(() => {
                setTimeoutForMatches(matches[currentMatch]);
              }, 0);
            } else {
              console.log("done");
            }
          }
        } catch (error) {
          console.log(error.message, "processMatch");
        }
      };
      setTimeoutForMatches(matches[currentMatch]);
      //   console.log(matches);
    } else {
      console.log("No matches to fetch");
    }
  } catch (error) {
    console.log(error.message, "fetchData");
  }
};

module.exports = {
  fetchData,
};
