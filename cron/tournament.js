const axios = require("axios");
const mysql = require("mysql");
const { storeCompetitors } = require("./storeTournaments/storeCompetitor");
const { storePlayerOfTeams } = require("./storeTournaments/storePlayer");
const { storeMacthes } = require("./storeTournaments/storeMatch");
const {
  storeTournamentCompetitorsPlayers,
} = require("./storeTournaments/storeTournamentCompetitorsPlayers");
const {
  storeTournamentCompetitors,
} = require("./storeTournaments/storeTournamentCompetitors");
let connectionForCron = null;

const data = require("../data2");
const api_tokens = ["86es3v3uadks3nxj4ts994z4", "gej38ey64cqm4amkvcb8uezb"];
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
                (error.response &&
                  parseInt(error.response.headers["x-plan-quota-current"]) >
                    parseInt(
                      error.response.headers["x-plan-quota-allotted"]
                    )) ||
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
        }, delay);
        delay += 1200;
      };
      makeCall();
    } catch (error) {
      console.log(error.message, "makeRequest");
    }
  });
};

// storing values in parent table in relation (category, role, type, venue)

// store category in tournament_category table
const storeCategoryParent = async (category, connection) => {
  return new Promise(async (resolve) => {
    try {
      let [{ isExists: isCategoryExist, categoryId }] = await database(
        "SELECT COUNT(tournament_category.categoryId ) AS isExists, tournament_category.categoryId AS categoryId FROM tournament_category WHERE tournament_category.categoryRadarId = ?;",
        [category.id.substr(14)],
        connection
      );
      if (!isCategoryExist) {
        const storeCategory = await database(
          "INSERT INTO tournament_category (categoryRadarId, categoryString) VALUES (?,?)",
          [category.id.substr(14), category.name],
          connection
        );
        resolve(storeCategory.insertId);
      } else {
        resolve(categoryId);
      }
    } catch (error) {
      console.log(error.message, "storeCategoryAndTyprParent");
    }
  });
};

// store match type in tournament_type table
const storeTypeParent = async (type, connection) => {
  return new Promise(async (resolve, reject) => {
    try {
      let [{ isExists: isTypeExist, typeId }] = await database(
        "SELECT COUNT(tournament_type.tournamentTypeId) AS isExists, tournament_type.tournamentTypeId AS typeId FROM tournament_type WHERE tournament_type.tournamnetTypeString = ?;",
        [type],
        connection
      );
      if (!isTypeExist) {
        const storeType = await database(
          "INSERT INTO tournament_type (tournamnetTypeString ) VALUES (?);",
          [type],
          connection
        );
        resolve(storeType.insertId);
      } else {
        resolve(typeId);
      }
    } catch (error) {
      console.log(error.message, "storeTypeParent");
    }
  });
};

// will store all relations
const storeAllRelations = (tournament, connection) => {
  return new Promise(async (resolve) => {
    try {
      const storeTournamentCompetitorsRes = await storeTournamentCompetitors(
        tournament,
        connection
      );
      if (storeTournamentCompetitorsRes) {
        const storeTournamentMatchesRes = await storeMacthes(
          tournament,
          connection
        );
        const storeTournamentCompetitorsPlayersRes =
          await storeTournamentCompetitorsPlayers(
            storeTournamentCompetitorsRes,
            connection
          );
        if (storeTournamentCompetitorsPlayersRes && storeTournamentMatchesRes) {
          resolve(true);
        }
      }
    } catch (error) {
      console.log(error.message, "storeAllRelations");
    }
  });
};

// function to manage the data

// store tournament_information
const storeTournaments = async (tournaments) => {
  try {
    let connection = await connectToDb();
    tournaments.forEach(async (tournament) => {
      const categoryId = tournament.category
        ? await storeCategoryParent(tournament.category, connection)
        : null;
      const typeId = tournament.type
        ? await storeTypeParent(tournament.type, connection)
        : null;
      if (categoryId && typeId) {
        let [{ isExists: isTournamentExist, tournamentId }] = await database(
          "SELECT COUNT(tournamentId) AS isExists, tournamentId, isCompetitorsArrived, isMatchesArrived FROM `tournament_information` WHERE tournament_information.tournamentRadarId = ?;",
          [tournament.id.substr(14)],
          connection
        );
        if (!isTournamentExist) {
          const storeTournament = await database(
            "INSERT INTO tournament_information SET ?",
            {
              tournamentRadarId: tournament.id.substr(14),
              currentSeasonRadarId: tournament.current_season.id.substr(10),
              tournamentName: tournament.name,
              currentSeasonName: tournament.current_season.name,
              seasonStartDate: tournament.current_season.start_date,
              seasonEndDate: tournament.current_season.end_date,
              tournamentMatchType: typeId,
              tournamentCategory: categoryId,
              tournamentPlayersGender: tournament.gender,
              tournamentCountry: tournament.category.name || null,
              tournamentCountryCode: tournament.category.country_code || null,
              isCompetitorsArrived: tournament.isCompetitorsArrived,
              isMatchesArrived: tournament.isMatchesArrived,
            },
            connection,
            false
          );
          tournament.insertId = storeTournament.insertId;
          if (storeTournament) {
            const storeTournamentTeamsRes = await storeCompetitors(
              tournament,
              connection
            );
            if (storeTournamentTeamsRes) {
              const storePlayersTournament = await storePlayerOfTeams(
                storeTournamentTeamsRes,
                connection
              );
              if (storePlayersTournament) {
                const res = await storeAllRelations(
                  storePlayersTournament,
                  connection
                );
                if (res) {
                  connection.release();
                }
                console.log(res);
              }
            }
          }
        } else {
          tournament.insertId = tournamentId;
          const storeTournamentTeamsRes = await storeTournamentTeamsParent(
            tournament,
            connection
          );
          if (storeTournamentTeamsRes) {
            const storePlayersTournament = await storePlayersOfTeamsParent(
              storeTournamentTeamsRes,
              connection
            );
            if (storePlayersTournament) {
              const res = await storeAllRelations(
                storePlayersTournament,
                connection
              );
              if (res) {
                connection.release();
              }
              console.log(res);
            }
          }
        }
      } else {
        connection.release();
      }
    });
  } catch (error) {
    console.log(error.message, "storeTournaments");
  }
};

// will make tournament object with player details
const tournamentCompetitorsWithPlayers = async (groups, tournamentId) => {
  return new Promise(async (resolve, reject) => {
    try {
      const allCompetitors = [];

      const storePlayersInTeams = async () => {
        let competitorsCountLoop = 0;

        const storePlayersInTeams = async (competitor) => {
          try {
            const { players } = await makeRequest(
              `/tournaments/${tournamentId}/teams/${competitor.id}/squads.json`
            );
            if (players && players.length >= 11) {
              competitor.players = [...players];
              competitor.isPlayerArrived = true;
            } else {
              competitor.players = [];
              competitor.isPlayerArrived = false;
            }
            competitorsCountLoop++;
            if (competitorsCountLoop === allCompetitors.length) {
              resolve(allCompetitors);
            } else {
              storePlayersInTeams(allCompetitors[competitorsCountLoop]);
            }
          } catch (error) {
            competitor.isPlayerArrived = false;
            competitor.players = [];
            competitorsCountLoop++;
            if (competitorsCountLoop === allCompetitors.length) {
              resolve(allCompetitors);
            } else {
              storePlayersInTeams(allCompetitors[competitorsCountLoop]);
            }
            console.log(error.message);
          }
        };
        storePlayersInTeams(allCompetitors[competitorsCountLoop]);
      };

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
  });
};

// will make tournament object with team details
const processTournaments = async (tournaments) => {
  return new Promise(async (resolve) => {
    try {
      let currentTournament = 0;
      const totalTournaments = tournaments.length;

      const processTournament = async (tournament) => {
        try {
          delay = 1200;
          const connection = await connectToDb();
          const [[tournamentRes]] = await database(
            "SELECT COUNT(tournamentId) AS isExists, tournamentId, fullseriesdetails.tournamentRadarId, fullseriesdetails.isCompetitorsArrived, fullseriesdetails.isMatchesArrived FROM fullseriesdetails WHERE tournamentRadarId = ?;SELECT `tournamentCompetitorId`, `tournamentId`, `competitorId`, `isPlayerArrived` FROM `tournament_competitor` WHERE tournament_competitor.tournamentId = ?;",
            [tournament.id.substr(14), tournament.id.substr(14)],
            connection
          );
          connection.release();
          if (!tournamentRes?.isExists) {
            console.log("lets store tournament", tournament.id);
            const {
              groups,
              tournament: { type: typeRes },
            } = await makeRequest(`/tournaments/${tournament.id}/info.json`);
            if (groups && groups.length > 0) {
              tournament.type = typeRes;
              const tournamentTeams = await tournamentCompetitorsWithPlayers(
                groups,
                tournament.id
              );
              if (tournamentTeams && tournamentTeams.length > 0) {
                tournament.teams = tournamentTeams;
                tournament.isCompetitorsArrived = true;
                const { sport_events: matches } = await makeRequest(
                  `/tournaments/${tournament.id}/schedule.json`
                );
                if (matches && matches.length > 0) {
                  tournament.matches = matches;
                  tournament.isMatchesArrived = true;
                  storeTournaments([tournaments[currentTournament]]);
                  if (currentTournament === totalTournaments - 1) {
                    resolve(tournaments);
                  } else {
                    currentTournament++;
                    setTimeout(() => {
                      processTournament(tournaments[currentTournament]);
                    }, 0);
                  }
                } else {
                  tournament.matches = [];
                  tournament.isMatchesArrived = false;
                  if (currentTournament === totalTournaments - 1) {
                    resolve(tournaments);
                  } else {
                    storeTournaments([tournaments[currentTournament]]);
                    currentTournament++;
                    setTimeout(() => {
                      processTournament(tournaments[currentTournament]);
                    }, 0);
                  }
                }
              } else {
                tournament.teams = [];
                tournament.isCompetitorsArrived = false;
                if (currentTournament === totalTournaments - 1) {
                  resolve(tournaments);
                } else {
                  storeTournaments([tournaments[currentTournament]]);
                  currentTournament++;
                  setTimeout(() => {
                    processTournament(tournaments[currentTournament]);
                  }, 0);
                }
              }
            } else {
              tournament.teams = [];
              tournament.isCompetitorsArrived = false;
              tournament.matches = [];
              tournament.isMatchesArrived = false;
              if (currentTournament === totalTournaments - 1) {
                resolve(tournaments);
              } else {
                storeTournaments([tournaments[currentTournament]]);
                currentTournament++;
                setTimeout(() => {
                  processTournament(tournaments[currentTournament]);
                }, 0);
              }
            }
          } else {
            console.log("stored already");
            if (currentTournament === totalTournaments - 1) {
              resolve(tournaments);
            } else {
              currentTournament++;
              setTimeout(() => {
                processTournament(tournaments[currentTournament]);
              }, 0);
            }
          }
        } catch (error) {
          tournament.matches = [];
          tournament.isMatchesArrived = false;
          if (currentTournament === totalTournaments - 1) {
            resolve(tournaments);
          } else {
            currentTournament++;
            processTournament(tournaments[currentTournament]);
          }
          console.log(error.message, "processTournaments");
        }
      };
      processTournament(tournaments[currentTournament]);
    } catch (error) {
      console.log(error.message, "processTournaments");
    }
  });
};

const fetchAndStore = async () => {
  try {
    // const { tournaments } = await makeRequest("/tournaments.json");
    // const newTournaments = await processTournaments(tournaments);

    const a = await processTournaments([
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
    ]);
  } catch (error) {
    console.log(error.message, "fetchAndStore");
  }
};

fetchAndStore();
