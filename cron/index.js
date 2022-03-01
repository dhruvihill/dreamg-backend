const axios = require("axios");
const mysql = require("mysql");
require("dotenv/config");
let connection;

// connectiong to database
connectToDb = () => {
  // connect to database
  connection.connect((err) => {
    try {
      if (err) throw err;
      else console.log("Connected Successfully");
    } catch (error) {
      console.log(error.message);
      if (error.message.includes("ECONNREFUSED")) {
        // some email stuff goes here
      }
      setTimeout(() => {
        initializeConnection();
      }, 3000);
    }
  });

  // error handling to Database
  connection.on("error", (err) => {
    console.log("db error", err.code);
    setTimeout(() => {
      initializeConnection();
    }, 100);
  });
};
// intializing connection
const initializeConnection = () => {
  try {
    connection = mysql.createConnection({
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
    connection.query(query, options, (err, reponse) => {
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

// inserts match, series, teams
const insertMatch = (matches) => {
  [1, 2, 3].forEach((type) => {
    matches[type].forEach(async (match) => {
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
        try {
          await database("INSERT INTO all_series SET ?", {
            seriesId: match.seriesId,
            seriesDisplayName: match.seriesDname,
            seriesName: match.seriesName,
          });
        } catch (error) {
          console.log(error.message);
        }
        try {
          await database("INSERT INTO all_matches SET ?", {
            matchId,
            gameType,
            team1_id,
            team2_id,
            matchStartTimeMilliSeconds,
            matchStatus,
            venue,
            displayName,
            seriesId: match.seriesId,
            seriesDname: match.seriesDname,
            seriesName: match.seriesName,
            matchStartDateTime: matchStartTimeMilliSeconds,
          });
        } catch (error) {
          console.log(error.message);
        }
        try {
          storeTeams = () =>
            new Promise((resolve, reject) => {
              [1, 2].forEach(async (item, index) => {
                try {
                  const storeTeam = await database(
                    "INSERT INTO allteams SET ?",
                    {
                      teamId: match[`team${item}`].id,
                      name: match[`team${item}`].name,
                      displayName: match[`team${item}`].dName,
                      teamFlagUrl: match[`team${item}`].teamFlagURL,
                    }
                  );
                  if (storeTeam && index === 1) {
                    resolve();
                  }
                } catch (error) {
                  reject(error);
                }
              });
            });
          await storeTeams();
        } catch (error) {
          console.log(error.message);
        }
      } catch (error) {
        console.log(error.message);
      }
    });
  });
};

// inserts players, matchplayerrelation
const insertPlayers = (allMatchesIds) => {
  allMatchesIds.forEach((matchIdsByTypes) => {
    matchIdsByTypes.forEach(async (matchId) => {
      try {
        const { players } = await makeRequest(
          "https://www.my11circle.com/api/lobbyApi/matches/v1/getMatchSquad",
          "POST",
          { matchId }
        );
        players?.forEach(async (player) => {
          try {
            await database("INSERT INTO allplayers SET ?", {
              playerId: player.id,
              name: player.name,
              role: player.role,
              displayName: player.dName,
              url: player.imgURL,
            });
          } catch (error) {
            console.log(error.message);
          }
          try {
            await database("INSERT INTO matchplayerrelation SET ?", {
              matchId,
              playerId: player.id,
              teamId: player.teamId,
              credits: player.credits,
              points: player.points,
            });
          } catch (error) {
            console.log(error.message);
          }
        });
      } catch (error) {
        console.log(error.message);
      }
    });
  });
};

// manage to insert all data into database
const fetchAndStore = async () => {
  try {
    initializeConnection();
    const { matches } = await makeRequest(
      "https://www.my11circle.com/api/lobbyApi/v1/getMatches",
      "POST",
      { sportsType: 1 }
    );
    // let allMatchesIds = [1, 2, 3].map((item) =>
    //   matches[item].map((match) => match.matchId)
    // );
    // insertMatch(matches);
    // insertPlayers(allMatchesIds);
  } catch (error) {
    console.log(error);
  }
};

module.exports = fetchAndStore();
