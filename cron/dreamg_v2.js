const axios = require("axios");
const mysql = require("mysql");
const path = require("path");
const { writeFile } = require("fs/promises");
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
      host: process.env.LOCAL_DB.HOST,
      user: process.env.LOCAL_DB.USER,
      password: process.env.LOCAL_DB.PASSWORD,
      database: process.env.LOCAL_DB.NAME,
      multipleStatements: true,
    });
  } catch (error) {
    console.log(error.message, "initializeConnection");
  }
};

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
  timeout: 1000,
  params: {
    api_key: process.env.SPORT_RADAR_API_KEY,
  },
});

// Axios request
const makeRequest = (url) => {
  return new Promise((resolve, reject) => {
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

const processTournaments = async (tournaments) => {
  try {
    tournaments.forEach((tournament) => {
      try {
        const tournamentSchema = {
          id: tournament.id,
          name: tournament.name,
          sport: tournament.sport,
          category: tournament.category,
          current_season: tournament.current_season,
          type: tournament.type,
          gender: tournament.gender,
          tour_id: tournament.tour_id,
        };
      } catch (error) {}
    });
  } catch {}
};

const fetchAndStore = async (url, method, data) => {
  try {
    let connection = await connectToDb();
    let { tournaments } = await makeRequest("/tournaments.json");
  } catch (error) {
    console.log(error.message, "fetchAndStore");
  }
};

// fetchAndStore();
