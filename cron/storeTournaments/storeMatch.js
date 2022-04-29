const { database } = require("../makeRequest");

const storeMatchStatus = async (status, connection) => {
  return new Promise(async (resolve, reject) => {
    try {
      if (status === "closed") {
        status = "ended";
      }
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
      console.log(error, "storeMatchStatus");
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
      console.log(error, "storeVenue");
    }
  });
};

const storeSingleMatch = async (match, tournament, connection) => {
  return new Promise(async (resolve, reject) => {
    try {
      const competitors = tournament.teams.filter((competitor) => {
        return (
          competitor.id === match.competitors[0].id ||
          competitor.id === match.competitors[1].id
        );
      });
      const [{ isExists: isMatchExists, tournamentMatchId }] = await database(
        "SELECT COUNT(tournament_matches.matchTournamentId) AS isExists, tournament_matches.matchTournamentId AS matchTournamentId FROM tournament_matches WHERE tournament_matches.matchRadarId = ?;",
        [match.id.substr(9)],
        connection
      );
      if (isMatchExists === 0) {
        const venueId = await storeVenue(match.venue, connection);
        const statusId = await storeMatchStatus(match.status, connection);
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
          if (storeTournamentMatches.insertId) {
            // storing players in match_players table
            competitors?.forEach((competitor) => {
              competitor?.players?.forEach(async (player) => {
                try {
                  if (player.insertId) {
                    const storeMatchPlayers = await database(
                      "INSERT INTO match_players SET ?",
                      {
                        matchId: storeTournamentMatches?.insertId,
                        competitorId: competitor?.insertId,
                        playerId: player?.insertId,
                      },
                      connection
                    );
                  }
                } catch (error) {
                  console.log(error, "storeMatchPlayers");
                }
              });
            });
            resolve(true);
          }
        } else {
          resolve(false);
        }
      } else {
        resolve(true);
      }
    } catch (error) {
      resolve(false);
    }
  });
};

const storeMacthes = async (tournament, connection) => {
  return new Promise(async (resolve, reject) => {
    try {
      let matchLoopCount = 0;
      const totalMatchObject = tournament.matches.length;

      const storeSingleMatchCall = async (match) => {
        try {
          const storeSingleMatchRes = await storeSingleMatch(
            match,
            tournament,
            connection
          );
          if (storeSingleMatchRes) {
            matchLoopCount++;
            if (matchLoopCount === totalMatchObject) {
              resolve(true);
            } else {
              setTimeout(() => {
                storeSingleMatchCall(tournament.matches[matchLoopCount]);
              });
            }
          } else {
            matchLoopCount++;
            if (matchLoopCount === totalMatchObject) {
              resolve(true);
            } else {
              setTimeout(() => {
                storeSingleMatchCall(tournament.matches[matchLoopCount]);
              });
            }
          }
        } catch (error) {
          console.log(error, "storeAllMatches");
          matchLoopCount++;
          if (matchLoopCount === totalMatchObject) {
            resolve(true);
          } else {
            setTimeout(() => {
              storeSingleMatchCall(tournament.matches[matchLoopCount]);
            });
          }
        }
      };

      storeSingleMatchCall(tournament.matches[matchLoopCount]);
    } catch (error) {
      console.log(error, "storeTournamentMatchesRelation");
    }
  });
};

module.exports = {
  storeSingleMatch,
  storeMacthes,
};
