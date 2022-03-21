const axios = require("axios");
const mysql = require("mysql");
const path = require("path");
require("dotenv/config");
let connectionForCron = null;

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
  return new Promise((resolve, reject) => {
    try {
      if (connectionForCron) {
        connectionForCron.getConnection((err, connection) => {
          try {
            if (err) throw err;
            else {
              console.log("Connected Successfully for cron");
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
        if (err) reject(err);
        else resolve(reponse);
      });
    } catch (error) {
      console.log(error.message, "cron databse function");
    }
  });
};

const axiosInstance = axios.create({
  baseURL: "https://api.sportradar.us/cricket-t2/en/",
  params: {
    api_key: process.env.SPORT_RADAR_API_KEY,
  },
});

// Axios request
const makeRequest = (url) => {
  return new Promise((resolve, reject) => {
    console.log(url);
    axiosInstance
      .get(url)
      .then((data) => {
        resolve(data.data);
      })
      .catch((error) => {
        console.log(error.message, "makeRequest");
        reject(error);
      });
  });
};

const tournamentCompetitorsWithPlayers = async (groups, tournamentId) => {
  return new Promise(async (resolve, reject) => {
    try {
      const storePlayersInTeams = async () => {
        let competitorsCountLoop = 0;
        allCompetitors.forEach((competitor) => {
          const { players } = makeRequest(
            `/tournaments/${tournamentId}/teams/${competitor.id}/squads.json`
          );

          if (players && players.length >= 11) {
            competitor.players = players;
            competitor.isPlayerArrived = true;
          } else {
            competitor.players = [];
            competitor.isPlayerArrived = false;
          }
          competitorsCountLoop++;
          if (competitorsCountLoop === allCompetitors.length) {
            resolve(allCompetitors);
          }
        });
      };
      const allCompetitors = [];

      let groupsCountLoop = 0;
      groups?.forEach((group) => {
        try {
          allCompetitors.push(...group.teams);
          groupsCountLoop++;

          if (groupsCountLoop === groups.length) {
            storePlayersInTeams();
          }
        } catch (error) {
          console.log(error.message, "tournamentCompetitorsWithPlayers");
        }
      });
    } catch (error) {
      console.log(error.message, "tournamentCompetitorsWithPlayers");
      reject([]);
    }
    /*
     try {
          group?.teams?.forEach((team) => {
            try {
              const { players } = makeRequest(
                `/tournaments/${tournament.id}/teams/${team.id}/squads.json`
              );

              if (players && players.length >= 11) {
                team.players = players;
                team.isPlayerArrived = true;
                tournamentTeams.push(team);
              } else {
                team.players = [];
                team.isPlayerArrived = false;
                tournamentTeams.push(team);
              }
            } catch (error) {
              console.log(error.message, "processTournaments");
            }
          });
        } catch (error) {
          console.log(error.message, "processTournaments");
        }
    */
  });
};

const processTournaments = async (tournaments) => {
  try {
    tournaments.forEach(async (tournament) => {
      try {
        const { groups } = await makeRequest(
          `/tournaments/${tournament.id}/info.json`
        );
        // const { sport_events: matches } = await makeRequest(
        //   `/tournaments/${tournament.id}/schedule.json`
        // );

        const tournamentTeams = await tournamentCompetitorsWithPlayers(
          groups,
          tournament.id
        );
        console.log(tournamentTeams);
      } catch (error) {
        console.log(error.message, "processTournaments");
      }
    });
  } catch {}
};

const fetchAndStore = async (url, method, data) => {
  try {
    let connection = await connectToDb();
    // const { tournaments } = await makeRequest("/tournaments.json");

    const tournaments = [
      {
        id: "sr:tournament:2472",
        name: "Indian Premier League",
        sport: {
          id: "sr:sport:21",
          name: "Cricket",
        },
        category: {
          id: "sr:category:497",
          name: "India",
          country_code: "IND",
        },
        current_season: {
          id: "sr:season:91319",
          name: "Indian Premier League 2022",
          start_date: "2022-03-26",
          end_date: "2022-05-29",
          year: "2022",
        },
        type: "t20",
        gender: "men",
      },
    ];
    processTournaments(tournaments);
  } catch (error) {
    console.log(error.message, "fetchAndStore");
  }
};

fetchAndStore();
