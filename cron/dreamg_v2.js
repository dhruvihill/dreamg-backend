const axios = require("axios");
const mysql = require("mysql");
require("dotenv/config");
let connectionForCron = null;
const data = require("../data2.js");

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
        if (err) {
          if (err.code === "ER_DUP_ENTRY") {
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

const axiosInstance = axios.create({
  baseURL: "https://api.sportradar.us/cricket-t2/en/",
  params: {
    api_key: process.env.SPORT_RADAR_API_KEY,
  },
});

// Axios request
const makeRequest = (url) => {
  return new Promise((resolve, reject) => {
    try {
      setTimeout(() => {
        axiosInstance
          .get(url)
          .then((data) => {
            resolve(data.data);
          })
          .catch((error) => {
            console.log(error.message, "makeRequest");
            reject(error);
          });
      }, delay);
      delay += 1200;
    } catch (error) {
      console.log(error.message, "makeRequest");
    }
  });
};

// store category in tournament_category table
const storeCategoryParent = async (category, connection) => {
  return new Promise(async (resolve, reject) => {
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

const storeVenue = async (venue, connection) => {
  return new Promise(async (resolve, reject) => {
    try {
      let [{ isExists: isVenueExist, venueId }] = await database(
        "SELECT COUNT(venueId) AS isExists, venues.venueId AS venueId FROM venues WHERE venues.venueRadarId = ?;",
        [venue.id.substr(9)],
        connection
      );
      if (!isVenueExist) {
        const storeVenue = await database(
          "INSERT INTO venues SET ?;",
          {
            venueRadarId: venue.id.substr(9),
            venueName: venue.name,
            venueCity: venue.city_name,
            venueCountry: venue.country,
            venueCapacity: venue.capacity,
            venueCountry: venue.country_name,
            venueCountryCode: venue.country_code,
            venueMapCardinalities: venue.map_coordinates,
            venueEnd1: venue.bowling_ends[0].name,
            venueEnd2: venue.bowling_ends[1].name,
          },
          connection
        );
        if (storeVenue.insertId) {
          resolve(storeVenue.insertId);
        }
      } else {
        resolve(venueId);
      }
    } catch (error) {
      console.log(error.message, "storeVenue");
    }
  });
};

const storeMatchStatusParent = async (status, connection) => {
  return new Promise(async (resolve, reject) => {
    try {
      let [{ isExists: isStatusExist, statusId }] = await database(
        "SELECT COUNT(match_status.statusId) AS isExists, match_status.statusId AS statusId FROM match_status WHERE match_status.statusString = ?;",
        [status],
        connection
      );
      if (!isStatusExist) {
        const storeStatus = await database(
          "INSERT INTO match_status (statusString ) VALUES (?);",
          [status],
          connection
        );
        resolve(storeStatus.insertId);
      } else {
        resolve(statusId);
      }
    } catch (error) {
      console.log(error.message, "storeMatchStatusParent");
    }
  });
};

// store player role in player_role table
const storePlayerRoleParent = async (role, connection) => {
  return new Promise(async (resolve) => {
    try {
      if (role && role !== "") {
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

// store competitors in competitiors table
const storeTournamentTeamsParent = async (tournament, connection) => {
  return new Promise(async (resolve) => {
    let teamsLoopCount = 0;
    tournament.teams.forEach(async (team) => {
      let [{ isExists: isTeamExist, competitorId: teamId }] = await database(
        "SELECT COUNT(competitorId) AS isExists, competitorId FROM competitors WHERE competitors.competitorRadarId = ?;",
        [team.id.substr(14)],
        connection
      );
      if (isTeamExist) {
        team.insertId = teamId;
        teamsLoopCount++;
        if (teamsLoopCount === tournament.teams.length) {
          resolve(tournament);
        }
      } else {
        const storeTournamentCompetitors = await database(
          "INSERT INTO competitors SET ?",
          {
            competitorRadarId: team.id.substr(14),
            competitorName: team.name,
            competitorCountry: team.country,
            competitorCountryCode: team.country_code,
            competitorDisplayName: team.abbreviation,
          },
          connection
        );
        team.insertId = storeTournamentCompetitors.insertId;
        if (storeTournamentCompetitors.insertId) {
          teamsLoopCount++;
          if (teamsLoopCount === tournament.teams.length) {
            resolve(tournament);
          }
        }
      }
      // team.players.forEach((player) => {
      //   const storePlayers = await database(
      //     "INSERT INTO players SET ?",
      //     {
      //       playerRadarId,
      //       playerFirstName,
      //       playerLastName,
      //       playerCountryCode,
      //       playerRole,
      //       playerDOB,
      //       playerCountry,
      //     },
      //     connection
      //   );
      // });
    });
  });
};

// store players in player table
const storePlayersOfTeamsParent = async (tournament, connection) => {
  return new Promise(async (resolve) => {
    let teamsLoopCount = 0;
    tournament.teams.forEach(async (team) => {
      let playerLoopCount = 0;
      team.players.forEach(async (player) => {
        try {
          let [{ isExists: isPlayerExist, playerId }] = await database(
            "SELECT COUNT(playerId) AS isExists, playerId FROM players WHERE players.playerRadarId = ?;",
            [player.id.substr(10)],
            connection
          );
          if (isPlayerExist === 1) {
            player.insertId = playerId;
            playerLoopCount++;
            if (playerLoopCount === team.players.length) {
              teamsLoopCount++;
              if (teamsLoopCount === tournament.teams.length) {
                resolve(tournament);
              }
            }
          } else {
            if (player.type && player.type !== "") {
              const roleId = await storePlayerRoleParent(
                player.type,
                connection
              );
              if (roleId !== 0) {
                const storePlayers = await database(
                  "INSERT INTO players SET ?",
                  {
                    playerRadarId: player.id.substr(10),
                    playerFirstName: player.name.split(", ")[1] || "",
                    playerLastName: player.name.split(", ")[0] || "",
                    playerCountryCode: player.country_code || null,
                    playerRole: roleId,
                    playerDOB: player.date_of_birth || null,
                    playerCountry: player.nationality || null,
                  },
                  connection
                );
                player.insertId = storePlayers.insertId;
                if (storePlayers.insertId) {
                  playerLoopCount++;
                  if (playerLoopCount === team.players.length) {
                    teamsLoopCount++;
                    if (teamsLoopCount === tournament.teams.length) {
                      resolve(tournament);
                    }
                  }
                }
              } else {
                playerLoopCount++;
                if (playerLoopCount === team.players.length) {
                  teamsLoopCount++;
                  if (teamsLoopCount === tournament.teams.length) {
                    resolve(tournament);
                  }
                }
              }
            } else {
              playerLoopCount++;
              if (playerLoopCount === team.players.length) {
                teamsLoopCount++;
                if (teamsLoopCount === tournament.teams.length) {
                  console.log(tournament.teams[0].players);
                  resolve(tournament);
                }
              }
            }
          }
        } catch (error) {
          playerLoopCount++;
          console.log(error.message, "storePlayersOfTeamsParent");
        }
      });
    });
  });
};

// store data in tournament_competitors table
const storeTournamentCompetitorsRelation = async (tournament, connection) => {
  return new Promise((resolve) => {
    try {
      let teamsLoopCount = 0;
      tournament.teams.forEach(async (team) => {
        try {
          const [{ isExists: isTeamExists, tournamentCompetitorId }] =
            await database(
              "SELECT COUNT(tournament_competitor.tournamentCompetitorId) AS isExists, tournament_competitor.tournamentCompetitorId AS tournamentCompetitorId FROM `tournament_competitor` WHERE tournament_competitor.tournamentId = ? AND tournament_competitor.competitorId = ?;",
              [tournament.insertId, team.insertId],
              connection
            );
          if (!isTeamExists) {
            const storeTournamentCompetitors = await database(
              "INSERT INTO tournament_competitor SET ?",
              {
                tournamentId: tournament.insertId,
                competitorId: team.insertId,
                isPlayerArrived: team.isPlayerArrived,
              },
              connection
            );
            if (storeTournamentCompetitors.insertId) {
              teamsLoopCount++;
              team.tournamentCompetitorId = storeTournamentCompetitors.insertId;
              if (teamsLoopCount === tournament.teams.length) {
              }
            }
          } else {
            teamsLoopCount++;
            team.tournamentCompetitorId = tournamentCompetitorId;
            if (teamsLoopCount === tournament.teams.length) {
              resolve(tournament);
            }
          }
        } catch (error) {
          console.log(error.message, "storeAllRelations");
        }
      });
    } catch (error) {
      console.log(error.message, "storeAllRelations");
    }
  });
};

// store data in tournament_competitors_players table
const storeTournamentCompetitorsPlayersRelation = async (
  tournament,
  connection
) => {
  return new Promise(async (resolve) => {
    try {
      let teamsLoopCount = 0;
      tournament.teams.forEach(async (team) => {
        try {
          let playersLoopCount = 0;
          team.players.forEach(async (player) => {
            try {
              const [
                { isExists: isPlayerExists, tournamentCompetitorPlayerId },
              ] = await database(
                "SELECT COUNT(tournament_competitor_player.tournamentCompetitorPlayerId) AS isExists, tournament_competitor_player.tournamentCompetitorPlayerId AS tournamentCompetitorPlayerId FROM `tournament_competitor_player` WHERE tournament_competitor_player.tournamentCompetitorId = ? AND tournament_competitor_player.playerId = ?;",
                [team.tournamentCompetitorId, player.insertId],
                connection
              );
              if (!isPlayerExists) {
                if (player.insertId) {
                  const storeTournamentCompetitorsPlayers = await database(
                    "INSERT INTO tournament_competitor_player SET ?",
                    {
                      tournamentCompetitorId: team.tournamentCompetitorId,
                      playerId: player.insertId,
                    },
                    connection
                  );
                  if (storeTournamentCompetitorsPlayers.insertId) {
                    playersLoopCount++;
                    if (playersLoopCount === team.players.length) {
                      teamsLoopCount++;
                      if (teamsLoopCount === tournament.teams.length) {
                        resolve(tournament);
                      }
                    }
                  }
                } else {
                  playersLoopCount++;
                  if (playersLoopCount === team.players.length) {
                    teamsLoopCount++;
                    if (teamsLoopCount === tournament.teams.length) {
                      resolve(tournament);
                    }
                  }
                }
              } else {
                playersLoopCount++;
                if (playersLoopCount === team.players.length) {
                  teamsLoopCount++;
                  if (teamsLoopCount === tournament.teams.length) {
                    resolve(tournament);
                  }
                }
              }
            } catch (error) {
              console.log(error.message, "storeAllRelations");
            }
          });
        } catch (error) {
          console.log(error.message, "storeAllRelations");
        }
      });
    } catch (error) {
      console.log(error.message, "storeAllRelations");
    }
  });
};

// store data in tournament_matches table
const storeTournamentMatchesRelation = async (tournament, connection) => {
  return new Promise(async (resolve) => {
    try {
      let matchLoopCount = 0;
      tournament.matches.forEach(async (match, index) => {
        try {
          const competitors = tournament.teams.filter((competitor) => {
            return (
              competitor.id === match.competitors[0].id ||
              competitor.id === match.competitors[1].id
            );
          });
          const [{ isExists: isMatchExists, tournamentMatchId }] =
            await database(
              "SELECT COUNT(tournament_matches.matchTournamentId) AS isExists, tournament_matches.matchTournamentId AS matchTournamentId FROM tournament_matches WHERE tournament_matches.matchRadarId = ?;",
              [match.id.substr(9)],
              connection
            );
          if (isMatchExists === 0) {
            setTimeout(async () => {
              const venueId = await storeVenue(match.venue, connection);
              const statusId = await storeMatchStatusParent(
                match.status,
                connection
              );
              if (venueId && statusId) {
                const storeTournamentMatches = await database(
                  "INSERT INTO tournament_matches SET ?",
                  {
                    matchRadarId: match.id.substr(9),
                    matchTournamentId: tournament.insertId,
                    matchStartTime: match.scheduled,
                    competitor1: competitors[0].insertId,
                    competitor2: competitors[1].insertId,
                    venueId: venueId,
                    matchStatus: statusId,
                  },
                  connection
                );
                if (storeTournamentMatches) {
                  matchLoopCount++;
                  if (matchLoopCount === tournament.matches.length) {
                    resolve(true);
                  }
                }
              } else {
                matchLoopCount++;
                if (matchLoopCount === tournament.matches.length) {
                  resolve(true);
                }
              }
            }, index * 100);
          } else {
            matchLoopCount++;
            if (matchLoopCount === tournament.matches.length) {
              resolve(true);
            }
          }
        } catch (error) {
          console.log(error.message, "storeAllMatches");
        }
      });
    } catch (error) {
      console.log(error.message, "storeTournamentMatchesRelation");
    }
  });
};

// will store all relations
const storeAllRelations = (tournament, connection) => {
  return new Promise(async (resolve) => {
    try {
      const storeTournamentCompetitorsRes =
        await storeTournamentCompetitorsRelation(tournament, connection);
      if (storeTournamentCompetitorsRes) {
        const storeTournamentMatchesRes = await storeTournamentMatchesRelation(
          tournament,
          connection
        );
        const storeTournamentCompetitorsPlayersRes =
          await storeTournamentCompetitorsPlayersRelation(
            storeTournamentCompetitorsRes,
            connection
          );
        if (storeTournamentCompetitorsPlayersRes) {
          resolve(true);
        }
      }
    } catch (error) {
      console.log(error.message, "storeAllRelations");
    }
  });
};

// store tournament_information
const storeTournaments = async (tournaments) => {
  try {
    let connection = await connectToDb();
    tournaments.forEach(async (tournament) => {
      const categoryId = await storeCategoryParent(
        tournament.category,
        connection
      );
      const typeId = await storeTypeParent(tournament.type, connection);
      if (categoryId && typeId) {
        let [{ isExists: isTournamentExist, tournamentId }] = await database(
          "SELECT COUNT(tournamentId) AS isExists, tournamentId FROM `tournament_information` WHERE tournament_information.tournamentRadarId = ?;",
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
              tournamentCountry: tournament.current_season.name,
              tournamentCountryCode: tournament.category.country_code || null,
              isCompetitorsArrived: tournament.isCompetitorsArrived,
              isMatchesArrived: tournament.isMatchesArrived,
            },
            connection,
            false
          );
          tournament.insertId = storeTournament.insertId;
        } else {
          tournament.insertId = tournamentId;
        }
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
            storeAllRelations(storePlayersTournament, connection);
          }
        }
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
        allCompetitors.forEach(async (competitor, index) => {
          try {
            setTimeout(async () => {
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
              }
            }, (index + 1) * 1200);
          } catch (error) {
            console.log(error.message);
          }
        });
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

// will make tournament object with team details
const processTournaments = async (tournaments) => {
  return new Promise(async (resolve, reject) => {
    try {
      let tournamentsCountLoop = 0;
      tournaments.forEach(async (tournament) => {
        try {
          const { groups } = await makeRequest(
            `/tournaments/${tournament.id}/info.json`
          );

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
              tournamentsCountLoop++;
              if (tournamentsCountLoop === tournaments.length) {
                resolve(tournaments);
              }
            } else {
              tournament.matches = [];
              tournament.isMatchesArrived = false;
              tournamentsCountLoop++;
              if (tournamentsCountLoop === tournaments.length) {
                resolve(tournaments);
              }
            }
          } else {
            tournament.teams = [];
            tournament.isCompetitorsArrived = false;
            tournamentsCountLoop++;
            if (tournamentsCountLoop === tournaments.length) {
              resolve(tournaments);
            }
          }
        } catch (error) {
          console.log(error.message, "processTournaments");
        }
      });
    } catch (error) {
      console.log(error.message, "processTournaments");
    }
  });
};

const fetchAndStore = async (url, method, data) => {
  try {
    delay = 0;
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
    const newTournaments = await processTournaments(tournaments);
    storeTournaments(newTournaments);
  } catch (error) {
    console.log(error.message, "fetchAndStore");
  }
};

// fetchAndStore();

const a = async () => {
  try {
    const connection = await connectToDb();
    const res = await storeAllRelations(data, connection);
    console.log(res);
  } catch (error) {
    console.log(error.message, "a");
  }
};
a();
