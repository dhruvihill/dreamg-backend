const axios = require("axios");
const mysql = require("mysql");
require("dotenv/config");
let connectionForCron = null;
const data = require("../data2.js");

const tournamentStatistics = {
  proper: [],
  improper: [],
};

const api_tokens = [
  "srsw8sr9pbefe7hr9m7zcfds",
  "gej38ey64cqm4amkvcb8uezb",
  "gtme2pht49kqmnzyp3pacz4t",
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
      setTimeout(() => {
        axiosInstance
          .get(url)
          .then((data) => {
            if (
              data.headers["X-Plan-Quota-Current"] > 1000 ||
              data.headers["X-Plan-Quota-Current"] === 1000
            ) {
              if (currentSelectedToken === api_tokens.length - 1) {
                console.warn("API limit reached");
              } else {
                currentSelectedToken++;
                axiosInstance = createInstance();
              }
            }
            resolve(data.data);
          })
          .catch((error) => {
            console.log(error.response.data, "error");
            console.log(error.message, "makeRequest");
            reject(error);
          });
      }, delay + 1200);
      delay += 1200;
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

const storeVenue = async (venue, connection) => {
  return new Promise(async (resolve, reject) => {
    try {
      if (venue && venue.id) {
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
              venueMapCardinalities: venue.map_coordinates || null,
              venueEnd1: venue?.bowling_ends
                ? venue?.bowling_ends[0]?.name || null
                : null,
              venueEnd2: venue?.bowling_ends
                ? venue?.bowling_ends[1]?.name || null
                : null,
            },
            connection
          );
          if (storeVenue.insertId) {
            resolve(storeVenue.insertId);
          }
        } else {
          resolve(venueId);
        }
      } else {
        resolve(null);
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
    } catch (error) {
      console.log(error.message, "storePlayerRoleParent");
    }
  });
};

// storing value to players, competitors table

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
    });
  });
};

// store players in player table
const storePlayersOfTeamsParent = async (tournament, connection) => {
  return new Promise(async (resolve) => {
    let teamsLoopCount = 0;
    const totalTeams = tournament.teams.length;

    const storePlayersOfSingleTeam = async (team) => {
      let playerLoopCount = 0;
      const totalPlayers = team.players.length;
      const storeSinglePlayer = async (player) => {
        try {
          if (player && player.id) {
            let [{ isExists: isPlayerExist, playerId }] = await database(
              "SELECT COUNT(playerId) AS isExists, playerId FROM players WHERE players.playerRadarId = ?;",
              [player.id.substr(10)],
              connection
            );
            if (isPlayerExist === 1) {
              player.insertId = playerId;
              playerLoopCount++;
              if (playerLoopCount === totalPlayers) {
                teamsLoopCount++;
                if (teamsLoopCount === totalTeams) {
                  resolve(tournament);
                } else {
                  storePlayersOfSingleTeam(tournament.teams[teamsLoopCount]);
                }
              } else {
                storeSinglePlayer(team.players[playerLoopCount]);
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
                    if (playerLoopCount === totalPlayers) {
                      teamsLoopCount++;
                      if (teamsLoopCount === totalTeams) {
                        resolve(tournament);
                      } else {
                        storePlayersOfSingleTeam(
                          tournament.teams[teamsLoopCount]
                        );
                      }
                    } else {
                      storeSinglePlayer(team.players[playerLoopCount]);
                    }
                  }
                } else {
                  playerLoopCount++;
                  if (playerLoopCount === totalPlayers) {
                    teamsLoopCount++;
                    if (teamsLoopCount === totalTeams) {
                      resolve(tournament);
                    } else {
                      storePlayersOfSingleTeam(
                        tournament.teams[teamsLoopCount]
                      );
                    }
                  } else {
                    storeSinglePlayer(team.players[playerLoopCount]);
                  }
                }
              } else {
                playerLoopCount++;
                if (playerLoopCount === totalPlayers) {
                  teamsLoopCount++;
                  if (teamsLoopCount === totalTeams) {
                    resolve(tournament);
                  } else {
                    storePlayersOfSingleTeam(tournament.teams[teamsLoopCount]);
                  }
                } else {
                  storeSinglePlayer(team.players[playerLoopCount]);
                }
              }
            }
          } else {
            playerLoopCount++;
            if (playerLoopCount === totalPlayers) {
              teamsLoopCount++;
              if (teamsLoopCount === totalTeams) {
                resolve(tournament);
              } else {
                storePlayersOfSingleTeam(tournament.teams[teamsLoopCount]);
              }
            } else {
              storeSinglePlayer(team.players[playerLoopCount]);
            }
          }
        } catch (error) {
          console.log(error.message, "storePlayersOfTeamsParent");
          playerLoopCount++;
          if (playerLoopCount === totalPlayers) {
            teamsLoopCount++;
            if (teamsLoopCount === totalTeams) {
              resolve(tournament);
            } else {
              storePlayersOfSingleTeam(tournament.teams[teamsLoopCount]);
            }
          } else {
            storeSinglePlayer(team.players[playerLoopCount]);
          }
        }
      };
      storeSinglePlayer(team.players[playerLoopCount]);
    };

    storePlayersOfSingleTeam(tournament.teams[teamsLoopCount]);
  });
};

// storing relationships

// store data in tournament_competitors table
const storeTournamentCompetitorsRelation = async (tournament, connection) => {
  return new Promise((resolve) => {
    try {
      let teamsLoopCount = 0;
      tournament.teams.forEach(async (team) => {
        try {
          const [{ isExists: isTeamExists, tournamentCompetitorId }] =
            await database(
              "SELECT COUNT(tournament_competitor.tournamentCompetitorId) AS isExists, tournament_competitor.tournamentCompetitorId AS tournamentCompetitorId, isPlayerArrived FROM `tournament_competitor` WHERE tournament_competitor.tournamentId = ? AND tournament_competitor.competitorId = ?;",
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
                resolve(tournament);
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
      const totalTeams = tournament.teams.length;

      const storePlayersOfSingleTeam = async (team) => {
        let playerLoopCount = 0;
        const totalPlayers = team.players.length;

        const storeSinglePlayer = async (player) => {
          try {
            if (player.id && player.name && player.type) {
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
                    playerLoopCount++;
                    if (playerLoopCount === totalPlayers) {
                      teamsLoopCount++;
                      if (teamsLoopCount === totalTeams) {
                        resolve(tournament);
                      } else {
                        storePlayersOfSingleTeam(
                          tournament.teams[teamsLoopCount]
                        );
                      }
                    } else {
                      storeSinglePlayer(team.players[playerLoopCount]);
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
                    resolve(tournament);
                  } else {
                    storePlayersOfSingleTeam(tournament.teams[teamsLoopCount]);
                  }
                } else {
                  storeSinglePlayer(team.players[playerLoopCount]);
                }
              }
            } else {
              playerLoopCount++;
              if (playerLoopCount === team.players.length) {
                teamsLoopCount++;
                if (teamsLoopCount === tournament.teams.length) {
                  resolve(tournament);
                } else {
                  storePlayersOfSingleTeam(tournament.teams[teamsLoopCount]);
                }
              } else {
                storeSinglePlayer(team.players[playerLoopCount]);
              }
            }
          } catch (error) {
            console.log(error.message, "storeAllRelations");
          }
        };

        storeSinglePlayer(team.players[playerLoopCount]);
      };
      storePlayersOfSingleTeam(tournament.teams[teamsLoopCount]);
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
      const totalMatchObject = tournament.matches.length;

      const storeSingleMatch = async (match) => {
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
            const venueId = await storeVenue(match.venue, connection);
            const statusId = await storeMatchStatusParent(
              match.status,
              connection
            );
            if ((venueId || venueId === null) && statusId) {
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
                if (matchLoopCount === totalMatchObject) {
                  resolve(true);
                } else {
                  storeSingleMatch(tournament.matches[matchLoopCount]);
                }
              }
            } else {
              matchLoopCount++;
              if (matchLoopCount === totalMatchObject) {
                resolve(true);
              } else {
                storeSingleMatch(tournament.matches[matchLoopCount]);
              }
            }
          } else {
            matchLoopCount++;
            if (matchLoopCount === totalMatchObject) {
              resolve(true);
            } else {
              storeSingleMatch(tournament.matches[matchLoopCount]);
            }
          }
        } catch (error) {
          console.log(error.message, "storeAllMatches");
        }
      };

      storeSingleMatch(tournament.matches[matchLoopCount]);
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
        // allCompetitors.forEach(async (competitor) => {
        //   try {
        //     const { players } = await makeRequest(
        //       `/tournaments/${tournamentId}/teams/${competitor.id}/squads.json`
        //     );
        //     if (players && players.length >= 11) {
        //       competitor.players = [...players];
        //       competitor.isPlayerArrived = true;
        //     } else {
        //       competitor.players = [];
        //       competitor.isPlayerArrived = false;
        //     }
        //     competitorsCountLoop++;
        //     if (competitorsCountLoop === allCompetitors.length) {
        //       resolve(allCompetitors);
        //     }
        //   } catch (error) {
        //     competitor.isPlayerArrived = false;
        //     competitor.players = [];
        //     competitorsCountLoop++;
        //     if (competitorsCountLoop === allCompetitors.length) {
        //       resolve(allCompetitors);
        //     }
        //     console.log(error.message);
        //   }
        // });
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
          delay = 0;
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
                  if (currentTournament === totalTournaments - 1) {
                    resolve(tournaments);
                  } else {
                    storeTournaments([tournaments[currentTournament]]);
                    currentTournament++;
                    processTournament(tournaments[currentTournament]);
                  }
                } else {
                  tournament.matches = [];
                  tournament.isMatchesArrived = false;
                  if (currentTournament === totalTournaments - 1) {
                    resolve(tournaments);
                  } else {
                    storeTournaments([tournaments[currentTournament]]);
                    currentTournament++;
                    processTournament(tournaments[currentTournament]);
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
                  processTournament(tournaments[currentTournament]);
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
                processTournament(tournaments[currentTournament]);
              }
            }
          } else {
            console.log("stored already");
            if (currentTournament === totalTournaments - 1) {
              resolve(tournaments);
            } else {
              currentTournament++;
              processTournament(tournaments[currentTournament]);
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
    delay = 0;
    const { tournaments } = await makeRequest("/tournaments.json");
    const newTournaments = await processTournaments(tournaments);
  } catch (error) {
    console.log(error.message, "fetchAndStore");
  }
};

fetchAndStore();
