const { connectToDb, database, makeRequest } = require("../makeRequest");
const Player = require("./player");
const Scorcard = require("./scorcard");

class Venue {
  venueId = null;
  name = "";
  radarId = 0;
  capacity = "";
  city = "";
  country = "";
  countryCode = "";
  mapCardinalitties = "";
  end1 = "";
  end2 = "";

  constructor(
    name,
    radarId,
    capacity,
    city,
    country,
    countryCode,
    mapCardinalitties,
    end1,
    end2
  ) {
    this.name = name;
    this.radarId = radarId;
    this.capacity = capacity;
    this.city = city;
    this.country = country;
    this.countryCode = countryCode;
    this.mapCardinalitties = mapCardinalitties;
    this.end1 = end1;
    this.end2 = end2;
  }

  storeVenue() {
    return new Promise(async (resolve) => {
      try {
        const connection = await connectToDb();
        const [{ isExists, id }] = await database(
          "SELECT COUNT(*) AS isExists, venueId AS id FROM venues WHERE venues.venueRadarId = ?;",
          [this.radarId],
          connection
        );

        if (!isExists) {
          const storeVenue = await database(
            "INSERT INTO `venues`(`venueName`, `venueCapacity`, `venueCity`, `venueRadarId`, `venueCountry`, `venueCountryCode`, `venueMapCardinalities`, `venueEnd1`, `venueEnd2`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);",
            [
              this.name,
              this.capacity,
              this.city,
              this.radarId,
              this.country,
              this.countryCode,
              this.mapCardinalitties,
              this.end1,
              this.end2,
            ],
            connection
          );

          if (storeVenue && storeVenue.insertId) {
            connection.release();
            this.venueId = storeVenue.insertId;
            resolve();
          }
        } else {
          connection.release();
          this.venueId = id;
          resolve();
        }
      } catch (error) {
        console.log(error.message);
        this.venueId = null;
        resolve();
      }
    });
  }
}

class Status {
  id = null;
  status = "";

  constructor(status) {
    this.status = status;
  }

  storeStatus() {
    return new Promise(async (resolve) => {
      try {
        const connection = await connectToDb();
        const [{ isExists, id }] = await database(
          "SELECT COUNT(*) AS isExists, statusId AS id FROM match_status WHERE statusString = ?;",
          [this.status],
          connection
        );

        if (!isExists) {
          const storeStatus = await database(
            "INSERT INTO match_status SET match_status.statusString = ?;",
            [this.status],
            connection
          );

          if (storeStatus && storeStatus.insertId) {
            connection.release();
            this.id = storeStatus.insertId;
            resolve();
          }
        } else {
          connection.release();
          this.id = id;
          resolve();
        }
      } catch (error) {
        console.log(error.message);
        this.id = null;
        resolve();
      }
    });
  }

  updateStatus(matchId, status) {
    return new Promise(async (resolve) => {
      try {
        this.status = status;
        await this.storeStatus();

        const updateStatusRes = await database(
          "UPDATE tournament_matches SET tournament_matches.matchStatus = ? WHERE tournament_matches.matchId = ?",
          [this.id, matchId]
        );

        if (updateStatusRes.affectedRows > 0) {
          resolve(true);
        } else {
          resolve(false);
        }
      } catch (error) {
        console.log(error.message);
        resolve(false);
      }
    });
  }
}

class RowMatch extends Venue {
  id = null;
  #radarId = 0;
  #status = "";
  #tournamentId = 0;
  #startTime = "";
  #competitor1 = {};
  #competitor2 = {};

  constructor(
    id,
    status,
    tournamentId,
    startTime,
    competitor1,
    competitor2,
    venueName,
    venueId,
    venueCapacity,
    venueCity,
    venueCountry,
    venueCountryCode,
    end1,
    end2,
    venueMapCardinalities
  ) {
    super(
      venueName,
      venueId,
      venueCapacity,
      venueCity,
      venueCountry,
      venueCountryCode,
      venueMapCardinalities,
      end1,
      end2
    );
    this.#radarId = id;
    this.#status = status;
    this.#tournamentId = tournamentId;
    this.#startTime = startTime;
    this.#competitor1 = competitor1;
    this.#competitor2 = competitor2;
  }

  storeMatch() {
    return new Promise(async (resolve, reject) => {
      try {
        const connection = await connectToDb();
        const [{ isExists, id }] = await database(
          "SELECT COUNT(*) AS isExists, matchRadarId AS id FROM tournament_matches WHERE matchRadarId = ?;",
          [this.#radarId],
          connection
        );

        if (!isExists) {
          // storing venue
          await super.storeVenue();

          // initializing status and store
          const status = new Status(this.#status);
          await status.storeStatus();

          const storeMatch = await database(
            "INSERT INTO `tournament_matches`(`matchRadarId`, `matchTournamentId`, `competitor1`, `competitor2`, `venueId`, `matchStatus`) VALUES (?, ?, ?, ?, ?, ?);",
            [
              this.#radarId,
              this.#tournamentId,
              this.#competitor1.insertId,
              this.#competitor2.insertId,
              this.venueId,
              status.id,
            ],
            connection
          );

          if (storeMatch && storeMatch.insertId) {
            this.id = storeMatch.insertId;
            connection.release();
            resolve();
          }
        } else {
          this.id = id;
          connection.release();
          resolve();
        }
      } catch (error) {
        console.log(error);
        reject();
      }
    });
  }

  storeMatchPlayers() {
    return new Promise(async (resolve, reject) => {
      try {
        const totalPlayers = this.#competitor1.players.length;
        let currentPlayer = 0;

        const connection = await connectToDb();
        [this.#competitor1, this.#competitor2].forEach((competitor) => {
          competitor.players.forEach(async (player) => {
            try {
              const [{ isExists }] = await database(
                "SELECT COUNT(*) AS isExists FROM match_players WHERE matchId = ? AND playerId = ?;",
                [this.id, player.insertId],
                connection
              );

              if (!isExists) {
                const matchPlayerRes = await database(
                  "INSERT INTO match_players SET matchId = ?, playerId = ?, competitorId = ?;",
                  [this.id, player.insertId, competitor.insertId]
                );

                if (matchPlayerRes && matchPlayerRes.insertId) {
                  currentPlayer++;

                  if (currentPlayer >= totalPlayers) {
                    connection.release();
                    resolve();
                  }
                }
              } else {
                connection.release();
                currentPlayer++;

                if (currentPlayer >= totalPlayers) {
                  resolve();
                }
              }
            } catch (error) {
              console.log(error.message);
              reject();
            }
          });
          ß;
        });
      } catch (error) {
        console.log(error.message);
        reject();
      }
    });
  }
}

class MatchDaily extends Status {
  id = 0;
  #radarId = 0;
  #competitors = [];
  #isLineUpStored = false;

  constructor(id, radarId, status, competitors) {
    super(status);
    this.id = id;
    this.#radarId = radarId;
    this.#competitors = competitors;
  }

  updateStatus(status) {
    return new Promise(async (resolve, reject) => {
      try {
        await super.updateStatus(this.id, status);
        resolve();
      } catch (error) {
        console.log(error.message);
        reject();
      }
    });
  }

  storeTossDetails(tossWonBy, tossDecision) {
    return new Promise(async (resolve, reject) => {
      try {
        const connection = await connectToDb();
        const [tossWonByCompetitor] = this.#competitors.filter((competitor) => {
          return competitor.radarId === tossWonBy;
        });

        const updateTossDetails = await database(
          "UPDATE tournament_matches SET tossWonBy = ?, tossDecision = ? WHERE matchId = ?;",
          [tossWonByCompetitor.id, tossDecision, this.id],
          connection
        );

        if (updateTossDetails.affectedRows > 0) {
          connection.release();
          resolve();
        }
      } catch (error) {
        console.log(error.message);
        reject();
      }
    });
  }

  storeLineUp() {
    return new Promise(async (resolve, reject) => {
      try {
        const matchLineUp = await makeRequest(
          `/matches/sr:match:${this.#radarId}/lineups.json`
        );

        if (matchLineUp && matchLineUp.sport_event && matchLineUp.lineups) {
          // store toss details
          const connection = await connectToDb();

          const totalLineUps = matchLineUp.lineups.length;
          let currentLineUp = 0;

          matchLineUp.lineups.forEach(async (lineup) => {
            const totalPlayers = lineup?.starting_lineup?.length;
            let currentPlayer = 0;

            const storePlayer = async (player) => {
              try {
                // checking if player is already stored in database table players
                const [{ isExists: isPlayerExists, playerId }] = await database(
                  "SELECT COUNT(playerId) AS isExists, playerId FROM allplayers WHERE playerRadarId = ?",
                  [player.id.substr(10)],
                  connection
                );

                // player exists then store it else store it in players table
                if (isPlayerExists) {
                  const storeMatchPlayersRes = await database(
                    "UPDATE match_players SET isSelected = 1, isCaptain = ?, isWicketKeeper = ? WHERE playerId = ? AND matchId = ?;",
                    [
                      player.is_captain || 0,
                      player.is_wicketkeeper || 0,
                      playerId,
                      this.id,
                    ],
                    connection
                  );

                  // if player stored successfully then go to next player
                  if (storeMatchPlayersRes) {
                    currentPlayer++;
                    if (currentPlayer === totalPlayers) {
                      currentLineUp++;
                      if (currentLineUp === totalLineUps) {
                        connection.release();
                        this.#isLineUpStored = true;
                        resolve();
                      }
                    }
                  }
                } else {
                  const [playerDetails, statistics] = await makeRequest(
                    `/players/sr:player:${player.id.substr(10)}/profile.json`
                  );
                  if (playerDetails) {
                    const newPlayer = new Player(
                      playerDetails.type,
                      playerDetails.id.substr(10),
                      playerDetails.name.splite(",")[1],
                      playerDetails.name.splite(",")[0],
                      playerDetails.nationality,
                      playerDetails.country_code,
                      playerDetails.date_of_birth,
                      statistics || null,
                      playerDetails.batting_style || null,
                      playerDetails.bowling_style || null
                    );
                    await newPlayer.getPlayerStatesAndStore();
                    storePlayer(player);
                  } else {
                    reject();
                  }
                }
              } catch (error) {
                console.log(error.message, "storeMatchLineup1");
                reject();
              }
            };

            lineup?.starting_lineup?.forEach(async (player) => {
              storePlayer(player);
            });
          });
        }
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  storeScoreCard() {
    return new Promise(async (resolve, reject) => {
      try {
        const newScoreCard = new Scorcard(this.id);
        await newScoreCard.storeScoreCard();
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }
}

module.exports = { MatchDaily, RowMatch };

// list of fearures in MatchDaily

/* 
Update Match Status
store match lineup
store scorcard
calculate and store points
*/
