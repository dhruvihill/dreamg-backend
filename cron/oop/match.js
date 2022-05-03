const { connectToDb, database, makeRequest } = require("../makeRequest");
const Player = require("./player");
const Scorcard = require("./scorcard");
const {
  testScore,
  odiScore,
  t20Score,
  t10Score,
} = require("../points/calculatePoints");

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
    return new Promise(async (resolve, reject) => {
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
        console.log(error);
        this.venueId = null;
        resolve();
      }
    });
  }
}

class Status {
  statusId = null;
  status = "";

  constructor(status) {
    this.status = status;
  }

  storeStatus() {
    return new Promise(async (resolve, reject) => {
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
            this.statusId = storeStatus.insertId;
            resolve();
          }
        } else {
          connection.release();
          this.statusId = id;
          resolve();
        }
      } catch (error) {
        console.log(error);
        this.statusId = null;
        resolve();
      }
    });
  }

  updateStatus(matchId, status) {
    return new Promise(async (resolve, reject) => {
      try {
        this.status = status;
        await this.storeStatus();

        const connection = await connectToDb();
        const updateStatusRes = await database(
          "UPDATE tournament_matches SET tournament_matches.matchStatus = ? WHERE tournament_matches.matchId = ?",
          [this.statusId, matchId],
          connection
        );

        if (updateStatusRes.affectedRows > 0) {
          connection.release();
          resolve(true);
        } else {
          connection.release();
          resolve(false);
        }
      } catch (error) {
        console.log(error);
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
  #startTime = ""; // must be converted to milliseconds before inserting into db
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
          "SELECT COUNT(*) AS isExists, matchId AS id FROM tournament_matches WHERE matchRadarId = ?;",
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
            "INSERT INTO `tournament_matches`(`matchRadarId`, `matchTournamentId`, `matchStartTime`, `competitor1`, `competitor2`, `venueId`, `matchStatus`) VALUES (?, ?, ?, ?, ?, ?, ?);",
            [
              this.#radarId,
              this.#tournamentId,
              new Date(this.#startTime).getTime(),
              this.#competitor1.insertId,
              this.#competitor2.insertId,
              this.venueId,
              status.statusId,
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
        reject(error);
      }
    });
  }

  storeMatchPlayers() {
    return new Promise(async (resolve, reject) => {
      try {
        const totalPlayers =
          this.#competitor1.players.length + this.#competitor2.players.length;
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
                  [this.id, player.insertId, competitor.insertId],
                  connection
                );

                if (matchPlayerRes && matchPlayerRes.affectedRows) {
                  currentPlayer++;

                  if (currentPlayer >= totalPlayers) {
                    connection.release();
                    resolve();
                  }
                }
              } else {
                currentPlayer++;

                console.log(currentPlayer);
                if (currentPlayer >= totalPlayers) {
                  connection.release();
                  resolve();
                }
              }
            } catch (error) {
              console.log(error);
              reject(error);
            }
          });
        });
      } catch (error) {
        console.log(error);
        reject(error);
      }
    });
  }
}

class MatchDaily extends Status {
  id = 0;
  #radarId = 0;
  #tournamentId = 0;
  #competitors = [];
  #isLineUpStored = false;
  #matchStartTime = null;
  #tossWinner = null;
  #tossDecision = null;

  constructor(id, radarId, status, competitors, matchStartTime, tournamentId) {
    super(status);
    this.id = id;
    this.#radarId = radarId;
    this.#competitors = competitors;
    this.#matchStartTime = matchStartTime;
    this.#tournamentId = tournamentId;
  }

  #updateStatus(status) {
    return new Promise(async (resolve, reject) => {
      try {
        await super.updateStatus(this.id, status);
        resolve();
      } catch (error) {
        console.log(error);
        reject(error);
      }
    });
  }

  #storeTossDetails() {
    return new Promise(async (resolve, reject) => {
      try {
        const connection = await connectToDb();

        const updateTossDetails = await database(
          "UPDATE tournament_matches SET tossWonBy = ?, tossDecision = ? WHERE matchId = ?;",
          [this.#tossWinner, this.#tossDecision, this.id],
          connection
        );

        if (updateTossDetails.affectedRows > 0) {
          connection.release();
          resolve();
        }
      } catch (error) {
        console.log(error);
        reject(error);
      }
    });
  }

  #calculatePoints(lineUp, batting, bowling, { matchType, matchId }) {
    return new Promise(async (resolve, reject) => {
      try {
        const connection = await connectToDb();
        let currentPlayer = 0;
        const totalPlayers = lineUp.length;
        if (matchType === "test") {
          lineUp.forEach((player) => {
            let totalPoints = 4;
            const points = {
              order: null,
              runsPoints: 0,
              foursPoints: 0,
              sixesPoints: 0,
              "duck/50/100Points": 0,
              "4/5WicketsPoints": 0,
              wicketsPoints: 0,
              maidenOversPoints: 0,
              lbwOrBowledPoints: 0,
              catchesPoints: 0,
              runOutPoints: 0,
              strikeRatePoints: 0,
            };

            // getting object of player
            const playerBattingStats = batting.filter((playerBat) => {
              return playerBat.playerId === player.playerId;
            });
            const playerBowlingStats = bowling.filter((playerBow) => {
              return playerBow.playerId === player.playerId;
            });
            const playerCatches = batting.filter((playerBat) => {
              return (
                playerBat.dismissalFieldeManId === player.playerId &&
                (playerBat.dismissalType === "CAUGHT" ||
                  playerBat.dismissalType === "STUMPED")
              );
            });
            const playerRunOuts = batting.filter((playerBat) => {
              return (
                playerBat.dismissalFieldeManId === player.playerId &&
                playerBat.dismissalType === "RUN_OUT"
              );
            });
            const playerBowledAndLBW = batting.filter((playerBat) => {
              return (
                playerBat.dismissalBallerId === player.playerId &&
                (playerBat.dismissalType === "BOWLED" ||
                  playerBat.dismissalType === "LEG_BEFORE_WICKET")
              );
            });

            // calculating points for player
            playerBattingStats.forEach(async (batsMan) => {
              try {
                // order of player
                points.order = batsMan.order;

                // constant for runs and bountry
                const pointsPerRun = testScore.bat.run;
                const pointsPerFour = testScore.bat.boundary;
                const pointsPerSix = testScore.bat.six;

                // constant for half century and century
                const pointsPerHalfCentury = testScore.bat.halfCentury;
                const pointsPerCentury = testScore.bat.century;

                // constant for duck
                const pointsPerDuck = testScore.bat.duck;

                // points for runs and boundaries
                totalPoints += pointsPerRun * batsMan.runs;
                totalPoints += pointsPerFour * batsMan.fours;
                totalPoints += pointsPerSix * batsMan.sixes;

                points.runsPoints += pointsPerRun * batsMan.runs;
                points.foursPoints += pointsPerFour * batsMan.fours;
                points.sixesPoints += pointsPerSix * batsMan.sixes;

                // conditions for centuries, half centuries, ducks
                if (batsMan.runs >= 100) {
                  totalPoints += pointsPerCentury;
                  points["duck/50/100Points"] += pointsPerCentury;
                } else if (batsMan.runs >= 50) {
                  totalPoints += pointsPerHalfCentury;
                  points["duck/50/100Points"] += pointsPerHalfCentury;
                } else if (batsMan.isDuck && batsMan.roleName !== "BOWLER") {
                  totalPoints += pointsPerDuck;
                  points["duck/50/100Points"] += pointsPerDuck;
                }
              } catch (error) {
                console.log(error);
              }
            });
            playerBowlingStats.forEach(async (bowler) => {
              try {
                // constant for wickets
                const pointsPerWicket = testScore.bowl.wicket;

                // constant for hauls
                const pointsPerFourWickets = testScore.bowl.fourWicketBouns;
                const pointsPerFiveWickets = testScore.bowl.fiveWicketBouns;

                // points for wickets
                totalPoints += pointsPerWicket * bowler.wickets;

                points.wicketsPoints += pointsPerWicket * bowler.wickets;

                // conditions for wickets
                if (bowler.wickets >= 5) {
                  totalPoints += pointsPerFiveWickets;
                  points["4/5WicketsPoints"] += pointsPerFiveWickets;
                } else if (bowler.wickets >= 4) {
                  totalPoints += pointsPerFourWickets;
                  points["4/5WicketsPoints"] += pointsPerFourWickets;
                }
              } catch (error) {
                console.log(error);
              }
            });
            playerCatches.forEach(() => {
              try {
                totalPoints += testScore.field.catch;
                points.catchesPoints += testScore.field.catch;
              } catch (error) {
                console.log(error);
              }
            });
            playerRunOuts.forEach(() => {
              try {
                totalPoints += testScore.field.runOut;
                points.runOutPoints += testScore.field.runOut;
              } catch (error) {
                console.log(error);
              }
            });
            playerBowledAndLBW.forEach(() => {
              try {
                totalPoints += testScore.bowl.lbwOrBowled;
                points.lbwOrBowledPoints += testScore.bowl.lbwOrBowled;
              } catch (error) {
                console.log(error);
              }
            });
            setTimeout(async () => {
              const storePoints = await database(
                "UPDATE `match_players` SET `isSelected` = ?, `points` = ?, `order` = ?, `runsPoints` = ?, `foursPoints` = ?, `sixesPoints` = ?, `numberRunsPoints` = ?, `numberWicketPoints` = ?, `wicketPoints` = ?, `maidenOverPoints` = ?, `lbwOrBowledPoints` = ?, `catchesPoints` = ?, `runOutPoints` = ?, `economyPoints` = ?, `strikeRatePoints` = ? WHERE matchId = ? AND playerId = ?;",
                [
                  true,
                  totalPoints,
                  points.order,
                  points.runsPoints,
                  points.foursPoints,
                  points.sixesPoints,
                  points["duck/50/100Points"],
                  points["4/5WicketsPoints"],
                  points.wicketsPoints,
                  points.maidenOversPoints,
                  points.lbwOrBowledPoints,
                  points.catchesPoints,
                  points.runOutPoints,
                  null,
                  points.strikeRatePoints,
                  matchId,
                  player.playerId,
                ],
                connection
              );
              if (storePoints) {
                currentPlayer++;
                if (currentPlayer === totalPlayers) {
                  const storeIsPointsCalculatedFlag = await database(
                    "UPDATE tournament_matches SET isPointsCalculated = 1 WHERE matchId = ?;",
                    [matchId],
                    connection
                  );
                  if (storeIsPointsCalculatedFlag) {
                    connection.release();
                    resolve(true);
                  }
                }
              }
            }, 200);
          });
        } else if (matchType === "odi") {
          lineUp.forEach((player) => {
            let totalPoints = 4;
            const points = {
              order: null,
              runsPoints: 0,
              foursPoints: 0,
              sixesPoints: 0,
              "duck/50/100Points": 0,
              "4/5WicketsPoints": 0,
              wicketsPoints: 0,
              maidenOversPoints: 0,
              lbwOrBowledPoints: 0,
              catchesPoints: 0,
              runOutPoints: 0,
              strikeRatePoints: 0,
              economyPoints: 0,
            };

            // getting object of player
            const playerBattingStats = batting.filter((playerBat) => {
              return playerBat.playerId === player.playerId;
            });
            const playerBowlingStats = bowling.filter((playerBow) => {
              return playerBow.playerId === player.playerId;
            });
            const playerCatches = batting.filter((playerBat) => {
              return (
                playerBat.dismissalFieldeManId === player.playerId &&
                (playerBat.dismissalType === "CAUGHT" ||
                  playerBat.dismissalType === "STUMPED")
              );
            });
            const playerRunOuts = batting.filter((playerBat) => {
              return (
                playerBat.dismissalFieldeManId === player.playerId &&
                playerBat.dismissalType === "RUN_OUT"
              );
            });
            const playerBowledAndLBW = batting.filter((playerBat) => {
              return (
                playerBat.dismissalBallerId === player.playerId &&
                (playerBat.dismissalType === "BOWLED" ||
                  playerBat.dismissalType === "LEG_BEFORE_WICKET")
              );
            });

            // calculating points for player
            playerBattingStats.forEach(async (batsMan) => {
              try {
                // order of player
                points.order = batsMan.order;

                // constant for runs and bountry
                const pointsPerRun = odiScore.bat.run;
                const pointsPerFour = odiScore.bat.boundary;
                const pointsPerSix = odiScore.bat.six;

                // constant for half century and century
                const pointsPerHalfCentury = odiScore.bat.halfCentury;
                const pointsPerCentury = odiScore.bat.century;

                // constant for duck
                const pointsPerDuck = odiScore.bat.duck;

                // constant for strike rate
                const srOver140 = odiScore.strikeRate.above140;
                const srBetween120And140 =
                  odiScore.strikeRate["between120.01-140"];
                const srBetween100And120 =
                  odiScore.strikeRate["between100-120"];
                const srBetween40And50 = odiScore.strikeRate["between40-50"];
                const srBetween30And40 = odiScore.strikeRate["between30-39.99"];

                // points for runs and boundaries
                totalPoints += pointsPerRun * batsMan.runs;
                totalPoints += pointsPerFour * batsMan.fours;
                totalPoints += pointsPerSix * batsMan.sixes;

                points.runsPoints += pointsPerRun * batsMan.runs;
                points.foursPoints += pointsPerFour * batsMan.fours;
                points.sixesPoints += pointsPerSix * batsMan.sixes;

                // conditions for centuries, half centuries, ducks
                if (batsMan.runs >= 100) {
                  totalPoints += pointsPerCentury;
                  points["duck/50/100Points"] += pointsPerCentury;
                } else if (batsMan.runs >= 50) {
                  totalPoints += pointsPerHalfCentury;
                  points["duck/50/100Points"] += pointsPerHalfCentury;
                } else if (batsMan.isDuck && batsMan.roleName !== "BOWLER") {
                  totalPoints += pointsPerDuck;
                  points["duck/50/100Points"] += pointsPerDuck;
                }

                // conditions for strike rate
                if (batsMan.ballFaced >= 20) {
                  if (batsMan.strikeRate > 140) {
                    totalPoints += srOver140;
                    points.strikeRatePoints += srOver140;
                  } else if (
                    batsMan.strikeRate > 120.01 &&
                    batsMan.strikeRate <= 140
                  ) {
                    totalPoints += srBetween120And140;
                    points.strikeRatePoints += srBetween120And140;
                  } else if (
                    batsMan.strikeRate > 100 &&
                    batsMan.strikeRate <= 120
                  ) {
                    totalPoints += srBetween100And120;
                    points.strikeRatePoints += srBetween100And120;
                  } else if (
                    batsMan.strikeRate >= 40 &&
                    batsMan.strikeRate <= 50
                  ) {
                    totalPoints += srBetween40And50;
                    points.strikeRatePoints += srBetween40And50;
                  } else if (
                    batsMan.strikeRate > 30 &&
                    batsMan.strikeRate <= 39.99
                  ) {
                    totalPoints += srBetween30And40;
                    points.strikeRatePoints += srBetween30And40;
                  }
                }
              } catch (error) {
                console.log(error);
              }
            });
            playerBowlingStats.forEach(async (bowler) => {
              try {
                // constant for wickets
                const pointsPerWicket = odiScore.bowl.wicket;
                const pointsPerMaiden = odiScore.bowl.maidenOver;

                // constant for hauls
                const pointsPerFourWickets = odiScore.bowl.fourWicketBouns;
                const pointsPerFiveWickets = odiScore.bowl.fiveWicketBouns;

                // constant for economy
                const eBelow2_5 = odiScore.economy["below2.5"];
                const eBetween2_5And3_5 = odiScore.economy["between2.5-3.49"];
                const eBetween3_5And4_5 = odiScore.economy["between3.5-4.5"];
                const eBetween7And8 = odiScore.economy["between7-8"];
                const eBetween8And9 = odiScore.economy["between8.01-9"];
                const eAbove9 = odiScore.economy.above9;

                // points for wickets
                totalPoints += pointsPerWicket * bowler.wickets;
                totalPoints += pointsPerMaiden * bowler.maidensOvers;

                points.wicketsPoints += pointsPerWicket * bowler.wickets;
                points.maidenOversPoints +=
                  pointsPerMaiden * bowler.maidensOvers;

                // conditions for wickets
                if (bowler.wickets >= 5) {
                  totalPoints += pointsPerFiveWickets;
                  points["4/5WicketsPoints"] += pointsPerFiveWickets;
                } else if (bowler.wickets >= 4) {
                  totalPoints += pointsPerFourWickets;
                  points["4/5WicketsPoints"] += pointsPerFourWickets;
                }

                // conditions for economy
                if (bowler.economyRate > 9) {
                  totalPoints += eAbove9;
                  points.economyPoints += eAbove9;
                } else if (
                  bowler.economyRate > 8.01 &&
                  bowler.economyRate <= 9
                ) {
                  totalPoints += eBetween8And9;
                  points.economyPoints += eBetween8And9;
                } else if (bowler.economyRate > 7 && bowler.economyRate <= 8) {
                  totalPoints += eBetween7And8;
                  points.economyPoints += eBetween7And8;
                } else if (
                  bowler.economyRate >= 3.5 &&
                  bowler.economyRate <= 4.49
                ) {
                  totalPoints += eBetween3_5And4_5;
                  points.economyPoints += eBetween3_5And4_5;
                } else if (
                  bowler.economyRate > 2.5 &&
                  bowler.economyRate <= 3.49
                ) {
                  totalPoints += eBetween2_5And3_5;
                  points.economyPoints += eBetween2_5And3_5;
                } else if (bowler.economyRate <= 2.5) {
                  totalPoints += eBelow2_5;
                  points.economyPoints += eBelow2_5;
                }
              } catch (error) {
                console.log(error);
              }
            });
            playerCatches.forEach(() => {
              try {
                totalPoints += odiScore.field.catch;
                points.catchesPoints += odiScore.field.catch;
              } catch (error) {
                console.log(error);
              }
            });
            playerRunOuts.forEach(() => {
              try {
                totalPoints += odiScore.field.runOut;
                points.runOutPoints += odiScore.field.runOut;
              } catch (error) {
                console.log(error);
              }
            });
            playerBowledAndLBW.forEach(() => {
              try {
                totalPoints += odiScore.bowl.lbwOrBowled;
                points.lbwOrBowledPoints += odiScore.bowl.lbwOrBowled;
              } catch (error) {
                console.log(error);
              }
            });
            setTimeout(async () => {
              const storePoints = await database(
                "UPDATE `match_players` SET `isSelected` = ?, `points` = ?, `order` = ?, `runsPoints` = ?, `foursPoints` = ?, `sixesPoints` = ?, `numberRunsPoints` = ?, `numberWicketPoints` = ?, `wicketPoints` = ?, `maidenOverPoints` = ?, `lbwOrBowledPoints` = ?, `catchesPoints` = ?, `runOutPoints` = ?, `economyPoints` = ?, `strikeRatePoints` = ? WHERE matchId = ? AND playerId = ?;",
                [
                  true,
                  totalPoints,
                  points.order || null,
                  points.runsPoints,
                  points.foursPoints,
                  points.sixesPoints,
                  points["duck/50/100Points"],
                  points["4/5WicketsPoints"],
                  points.wicketsPoints,
                  points.maidenOversPoints,
                  points.lbwOrBowledPoints,
                  points.catchesPoints,
                  points.runOutPoints,
                  points.economyPoints,
                  points.strikeRatePoints,
                  matchId,
                  player.playerId,
                ],
                connection
              );
              if (storePoints) {
                currentPlayer++;
                if (currentPlayer === totalPlayers) {
                  const storeIsPointsCalculatedFlag = await database(
                    "UPDATE tournament_matches SET isPointsCalculated = 1 WHERE matchId = ?;",
                    [matchId],
                    connection
                  );
                  if (storeIsPointsCalculatedFlag) {
                    connection.release();
                    resolve(true);
                  }
                }
              }
            }, 200);
          });
        } else if (matchType === "t20") {
          lineUp.forEach((player) => {
            let totalPoints = 4;
            const points = {
              order: null,
              runsPoints: 0,
              foursPoints: 0,
              sixesPoints: 0,
              "duck/30/50/100Points": 0,
              "3/4/5WicketPoints": 0,
              wicketsPoints: 0,
              maidenOversPoints: 0,
              lbwOrBowledPoints: 0,
              catchesPoints: 0,
              runOutPoints: 0,
              strikeRatePoints: 0,
              economyPoints: 0,
            };

            // getting object of player
            const playerBattingStats = batting.filter((playerBat) => {
              return playerBat.playerId === player.playerId;
            });
            const playerBowlingStats = bowling.filter((playerBow) => {
              return playerBow.playerId === player.playerId;
            });
            const playerCatches = batting.filter((playerBat) => {
              return (
                playerBat.dismissalFieldeManId === player.playerId &&
                (playerBat.dismissalType === "CAUGHT" ||
                  playerBat.dismissalType === "STUMPED")
              );
            });
            const playerRunOuts = batting.filter((playerBat) => {
              return (
                playerBat.dismissalFieldeManId === player.playerId &&
                playerBat.dismissalType === "RUN_OUT"
              );
            });
            const playerBowledAndLBW = batting.filter((playerBat) => {
              return (
                playerBat.dismissalBallerId === player.playerId &&
                (playerBat.dismissalType === "BOWLED" ||
                  playerBat.dismissalType === "LEG_BEFORE_WICKET")
              );
            });

            // calculating points for player
            playerBattingStats.forEach(async (batsMan) => {
              try {
                // storing order
                points.order = batsMan.order || null;

                // constant for runs and bountry
                const pointsPerRun = t20Score.bat.run;
                const pointsPerFour = t20Score.bat.boundary;
                const pointsPerSix = t20Score.bat.six;

                // constant for half century and century
                const pointsPerHalfCentury = t20Score.bat.halfCentury;
                const pointsPerCentury = t20Score.bat.century;
                const pointsPerThirty = t20Score.bat.thirtyRuns;

                // constant for duck
                const pointsPerDuck = t20Score.bat.duck;

                // constant for strike rate
                const srOver170 = t20Score.strikeRate.above170;
                const srBetween150And170 =
                  t20Score.strikeRate["between150.01-170"];
                const srBetween130And150 =
                  t20Score.strikeRate["between130-150"];
                const srBetween60And70 = t20Score.strikeRate["between60-70"];
                const srBetween50And59 = t20Score.strikeRate["between50-59.99"];
                const srBelow50 = t20Score.strikeRate.below50;

                // points for runs and boundaries
                totalPoints += pointsPerRun * batsMan.runs;
                totalPoints += pointsPerFour * batsMan.fours;
                totalPoints += pointsPerSix * batsMan.sixes;
                points.runsPoints += pointsPerRun * batsMan.runs;
                points.foursPoints += pointsPerFour * batsMan.fours;
                points.sixesPoints += pointsPerSix * batsMan.sixes;

                // conditions for centuries, half centuries, thirties, ducks
                if (batsMan.runs >= 100) {
                  totalPoints += pointsPerCentury;
                  points["duck/30/50/100Points"] += pointsPerCentury;
                } else if (batsMan.runs >= 50) {
                  totalPoints += pointsPerHalfCentury;
                  points["duck/30/50/100Points"] += pointsPerHalfCentury;
                } else if (batsMan.runs >= 30) {
                  totalPoints += pointsPerThirty;
                  points["duck/30/50/100Points"] += pointsPerThirty;
                } else if (batsMan.isDuck && batsMan.roleName !== "BOWLER") {
                  totalPoints += pointsPerDuck;
                  points["duck/30/50/100Points"] += pointsPerDuck;
                }

                // conditions for strike rate
                if (batsMan.ballFaced >= 10) {
                  if (batsMan.strikeRate > 170) {
                    totalPoints += srOver170;
                    points.strikeRatePoints += srOver170;
                  } else if (
                    batsMan.strikeRate > 150.01 &&
                    batsMan.strikeRate <= 170
                  ) {
                    totalPoints += srBetween150And170;
                    points.strikeRatePoints += srBetween150And170;
                  } else if (
                    batsMan.strikeRate > 130 &&
                    batsMan.strikeRate <= 150
                  ) {
                    totalPoints += srBetween130And150;
                    points.strikeRatePoints += srBetween130And150;
                  } else if (
                    batsMan.strikeRate >= 60 &&
                    batsMan.strikeRate <= 70
                  ) {
                    totalPoints += srBetween60And70;
                    points.strikeRatePoints += srBetween60And70;
                  } else if (
                    batsMan.strikeRate > 50 &&
                    batsMan.strikeRate <= 59.99
                  ) {
                    totalPoints += srBetween50And59;
                    points.strikeRatePoints += srBetween50And59;
                  } else if (batsMan.strikeRate <= 50) {
                    totalPoints += srBelow50;
                    points.strikeRatePoints += srBelow50;
                  }
                }
              } catch (error) {
                console.log(error);
              }
            });
            playerBowlingStats.forEach(async (bowler) => {
              try {
                // constant for wickets
                const pointsPerWicket = t20Score.bowl.wicket;
                const pointsPerMaiden = t20Score.bowl.maidenOver;

                // constant for hauls
                const pointsPerThreeWickets = t20Score.bowl.threeWicketBouns;
                const pointsPerFourWickets = t20Score.bowl.fourWicketBouns;
                const pointsPerFiveWickets = t20Score.bowl.fiveWicketBouns;

                // constant for economy
                const eBelow5 = t20Score.economy.below5;
                const eBetween5And6 = t20Score.economy["between5-5.99"];
                const eBetween6And7 = t20Score.economy["between6-7"];
                const eBetween10And11 = t20Score.economy["between10-11"];
                const eBetween11And12 = t20Score.economy["between11.01-12"];
                const eAbove12 = t20Score.economy.above12;

                // points for wickets
                totalPoints += pointsPerWicket * bowler.wickets;
                totalPoints += pointsPerMaiden * bowler.maidensOvers;
                points.wicketsPoints += pointsPerWicket * bowler.wickets;
                points.maidenOversPoints +=
                  pointsPerMaiden * bowler.maidensOvers;

                // conditions for wickets
                if (bowler.wickets >= 5) {
                  totalPoints += pointsPerFiveWickets;
                  points["3/4/5WicketPoints"] += pointsPerFiveWickets;
                } else if (bowler.wickets >= 4) {
                  totalPoints += pointsPerFourWickets;
                  points["3/4/5WicketPoints"] += pointsPerFourWickets;
                } else if (bowler.wickets >= 3) {
                  totalPoints += pointsPerThreeWickets;
                  points["3/4/5WicketPoints"] += pointsPerThreeWickets;
                }

                // conditions for economy
                if (bowler.economyRate > 12) {
                  totalPoints += eAbove12;
                  points.economyPoints += eAbove12;
                } else if (
                  bowler.economyRate > 11 &&
                  bowler.economyRate <= 12
                ) {
                  totalPoints += eBetween11And12;
                  points.economyPoints += eBetween11And12;
                } else if (
                  bowler.economyRate > 10 &&
                  bowler.economyRate <= 11
                ) {
                  totalPoints += eBetween10And11;
                  points.economyPoints += eBetween10And11;
                } else if (bowler.economyRate >= 6 && bowler.economyRate <= 7) {
                  totalPoints += eBetween6And7;
                  points.economyPoints += eBetween6And7;
                } else if (
                  bowler.economyRate > 5 &&
                  bowler.economyRate <= 5.99
                ) {
                  totalPoints += eBetween5And6;
                  points.economyPoints += eBetween5And6;
                } else if (bowler.economyRate <= 5) {
                  totalPoints += eBelow5;
                  points.economyPoints += eBelow5;
                }
              } catch (error) {
                console.log(error);
              }
            });
            playerCatches.forEach(() => {
              try {
                totalPoints += t20Score.field.catch;
                points.catchesPoints += t20Score.field.catch;
              } catch (error) {
                console.log(error);
              }
            });
            playerRunOuts.forEach(() => {
              try {
                totalPoints += t20Score.field.runOut;
                points.runOutPoints += t20Score.field.runOut;
              } catch (error) {
                console.log(error);
              }
            });
            playerBowledAndLBW.forEach(() => {
              try {
                totalPoints += t20Score.bowl.lbwOrBowled;
                points.lbwOrBowledPoints += t20Score.bowl.lbwOrBowled;
              } catch (error) {
                console.log(error);
              }
            });
            setTimeout(async () => {
              try {
                const storePoints = await database(
                  "UPDATE `match_players` SET `isSelected` = ?, `points` = ?,`order` = ?, `runsPoints` = ?, `foursPoints` = ?, `sixesPoints` = ?, `numberRunsPoints` = ?, `numberWicketPoints` = ?, `wicketPoints` = ?, `maidenOverPoints` = ?, `lbwOrBowledPoints` = ?, `catchesPoints` = ?, `runOutPoints` = ?, `economyPoints` = ?, `strikeRatePoints` = ? WHERE matchId = ? AND playerId = ?;",
                  [
                    true,
                    totalPoints,
                    points.order || null,
                    points.runsPoints,
                    points.foursPoints,
                    points.sixesPoints,
                    points["duck/30/50/100Points"],
                    points["3/4/5WicketPoints"],
                    points.wicketsPoints,
                    points.maidenOversPoints,
                    points.lbwOrBowledPoints,
                    points.catchesPoints,
                    points.runOutPoints,
                    points.economyPoints,
                    points.strikeRatePoints,
                    matchId,
                    player.playerId,
                  ],
                  connection
                );
                if (storePoints) {
                  currentPlayer++;
                  if (currentPlayer === totalPlayers) {
                    const storeIsPointsCalculatedFlag = await database(
                      "UPDATE tournament_matches SET isPointsCalculated = 1 WHERE matchId = ?;",
                      [matchId],
                      connection
                    );
                    if (storeIsPointsCalculatedFlag) {
                      connection.release();
                      resolve(true);
                    }
                  }
                }
              } catch (error) {
                console.log(error);
              }
            }, 200);
          });
        } else if (matchType === "t10") {
          lineUp.forEach((player) => {
            let totalPoints = 4;
            const points = {
              order: null,
              runsPoints: 0,
              foursPoints: 0,
              sixesPoints: 0,
              "duck/30/50/100Points": 0,
              "2/3WicketPoints": 0,
              wicketsPoints: 0,
              maidenOversPoints: 0,
              lbwOrBowledPoints: 0,
              catchesPoints: 0,
              runOutPoints: 0,
              strikeRatePoints: 0,
              economyPoints: 0,
            };

            // getting object of player
            const playerBattingStats = batting.filter((playerBat) => {
              return playerBat.playerId === player.playerId;
            });
            const playerBowlingStats = bowling.filter((playerBow) => {
              return playerBow.playerId === player.playerId;
            });
            const playerCatches = batting.filter((playerBat) => {
              return (
                playerBat.dismissalFieldeManId === player.playerId &&
                (playerBat.dismissalType === "CAUGHT" ||
                  playerBat.dismissalType === "STUMPED")
              );
            });
            const playerRunOuts = batting.filter((playerBat) => {
              return (
                playerBat.dismissalFieldeManId === player.playerId &&
                playerBat.dismissalType === "RUN_OUT"
              );
            });
            const playerBowledAndLBW = batting.filter((playerBat) => {
              return (
                playerBat.dismissalBallerId === player.playerId &&
                (playerBat.dismissalType === "BOWLED" ||
                  playerBat.dismissalType === "LEG_BEFORE_WICKET")
              );
            });

            // calculating points for player
            playerBattingStats.forEach(async (batsMan) => {
              try {
                // order of player
                points.order = batsMan.order;

                // constant for runs and bountry
                const pointsPerRun = t10Score.bat.run;
                const pointsPerFour = t10Score.bat.boundary;
                const pointsPerSix = t10Score.bat.six;

                // constant for half century and century
                const pointsPerHalfCentury = t10Score.bat.halfCentury;
                const pointsPerThirtyRuns = t10Score.bat.thirtyRuns;

                // constant for duck
                const pointsPerDuck = t10Score.bat.duck;

                // constant for strike rate
                const srOver190 = t10Score.strikeRate.above190;
                const srBetween170And190 =
                  t10Score.strikeRate["between170.01-190"];
                const srBetween150And170 =
                  t10Score.strikeRate["between150-170"];
                const srBetween70And80 = t10Score.strikeRate["between70-80"];
                const srBetween60And69 = t10Score.strikeRate["between60-69.99"];
                const srBelow60 = t10Score.strikeRate.below60;

                // points for runs and boundaries
                totalPoints += pointsPerRun * batsMan.runs;
                totalPoints += pointsPerFour * batsMan.fours;
                totalPoints += pointsPerSix * batsMan.sixes;
                points.runsPoints += pointsPerRun * batsMan.runs;
                points.foursPoints += pointsPerFour * batsMan.fours;
                points.sixesPoints += pointsPerSix * batsMan.sixes;

                // conditions for centuries, half centuries, thirties, ducks
                if (batsMan.runs >= 100) {
                  totalPoints += pointsPerThirtyRuns;
                  points["duck/30/50/100Points"] += pointsPerThirtyRuns;
                } else if (batsMan.runs >= 50) {
                  totalPoints += pointsPerHalfCentury;
                  points["duck/30/50/100Points"] += pointsPerHalfCentury;
                } else if (batsMan.runs >= 30) {
                  totalPoints += pointsPerThirtyRuns;
                  points["duck/30/50/100Points"] += pointsPerThirtyRuns;
                } else if (batsMan.isDuck && batsMan.roleName !== "BOWLER") {
                  totalPoints += pointsPerDuck;
                  points["duck/30/50/100Points"] += pointsPerDuck;
                }

                // conditions for strike rate
                if (batsMan.ballFaced >= 5) {
                  if (batsMan.strikeRate > 190) {
                    totalPoints += srOver190;
                    points.strikeRatePoints += srOver190;
                  } else if (
                    batsMan.strikeRate > 170.01 &&
                    batsMan.strikeRate <= 190
                  ) {
                    totalPoints += srBetween170And190;
                    points.strikeRatePoints += srBetween170And190;
                  } else if (
                    batsMan.strikeRate > 150 &&
                    batsMan.strikeRate <= 170
                  ) {
                    totalPoints += srBetween150And170;
                    points.strikeRatePoints += srBetween150And170;
                  } else if (
                    batsMan.strikeRate >= 70 &&
                    batsMan.strikeRate <= 80
                  ) {
                    totalPoints += srBetween70And80;
                    points.strikeRatePoints += srBetween70And80;
                  } else if (
                    batsMan.strikeRate > 60 &&
                    batsMan.strikeRate <= 69.99
                  ) {
                    totalPoints += srBetween60And69;
                    points.strikeRatePoints += srBetween60And69;
                  } else if (batsMan.strikeRate <= 60) {
                    totalPoints += srBelow60;
                    points.strikeRatePoints += srBelow60;
                  }
                }
              } catch (error) {
                console.log(error);
              }
            });
            playerBowlingStats.forEach(async (bowler) => {
              try {
                // constant for wickets
                const pointsPerWicket = t10Score.bowl.wicket;
                const pointsPerMaiden = t10Score.bowl.maidenOver;

                // constant for hauls
                const pointsPerTwoWickets = t10Score.bowl.twoWicketBouns;
                const pointsPerThreeWickets = t10Score.bowl.threeWicketBouns;

                // constant for economy
                const eBelow7 = t10Score.economy.below7;
                const eBetween7And8 = t10Score.economy["between7-7.99"];
                const eBetween8And9 = t10Score.economy["between8-9"];
                const eBetween14And15 = t10Score.economy["between14-15"];
                const eBetween15And16 = t10Score.economy["between15.01-16"];
                const eAbove16 = t10Score.economy.above16;

                // points for wickets
                totalPoints += pointsPerWicket * bowler.wickets;
                totalPoints += pointsPerMaiden * bowler.maidensOvers;
                points.wicketsPoints += pointsPerWicket * bowler.wickets;
                points.maidenOversPoints +=
                  pointsPerMaiden * bowler.maidensOvers;

                // conditions for wickets
                if (bowler.wickets >= 3) {
                  totalPoints += pointsPerThreeWickets;
                  points["2/3WicketPoints"] += pointsPerThreeWickets;
                } else if (bowler.wickets >= 2) {
                  totalPoints += pointsPerTwoWickets;
                  points["2/3WicketPoints"] += pointsPerTwoWickets;
                }

                // conditions for economy
                if (bowler.economyRate > 16) {
                  totalPoints += eAbove16;
                  points.economyPoints += eAbove16;
                } else if (
                  bowler.economyRate > 15.01 &&
                  bowler.economyRate <= 16
                ) {
                  totalPoints += eBetween15And16;
                  points.economyPoints += eBetween15And16;
                } else if (
                  bowler.economyRate > 14 &&
                  bowler.economyRate <= 15
                ) {
                  totalPoints += eBetween14And15;
                  points.economyPoints += eBetween14And15;
                } else if (bowler.economyRate >= 8 && bowler.economyRate <= 9) {
                  totalPoints += eBetween8And9;
                  points.economyPoints += eBetween8And9;
                } else if (
                  bowler.economyRate > 7 &&
                  bowler.economyRate <= 7.99
                ) {
                  totalPoints += eBetween7And8;
                  points.economyPoints += eBetween7And8;
                } else if (bowler.economyRate <= 7) {
                  totalPoints += eBelow7;
                  points.economyPoints += eBelow7;
                }
              } catch (error) {
                console.log(error);
              }
            });
            playerCatches.forEach(() => {
              try {
                totalPoints += t10Score.field.catch;
                points.catchesPoints += t10Score.field.catch;
              } catch (error) {
                console.log(error);
              }
            });
            playerRunOuts.forEach(() => {
              try {
                totalPoints += t10Score.field.runOut;
                points.runOutPoints += t10Score.field.runOut;
              } catch (error) {
                console.log(error);
              }
            });
            playerBowledAndLBW.forEach(() => {
              try {
                totalPoints += t10Score.bowl.lbwOrBowled;
                points.lbwOrBowledPoints += t10Score.bowl.lbwOrBowled;
              } catch (error) {
                console.log(error);
              }
            });
            setTimeout(async () => {
              const storePoints = await database(
                "UPDATE `match_players` SET `isSelected` = ?, `points` = ?, `order` = ?, `runsPoints` = ?, `foursPoints` = ?, `sixesPoints` = ?, `numberRunsPoints` = ?, `numberWicketPoints` = ?, `wicketPoints` = ?, `maidenOverPoints` = ?, `lbwOrBowledPoints` = ?, `catchesPoints` = ?, `runOutPoints` = ?, `economyPoints` = ?, `strikeRatePoints` = ? WHERE matchId = ? AND playerId = ?;",
                [
                  true,
                  totalPoints,
                  points.order || null,
                  points.runsPoints,
                  points.foursPoints,
                  points.sixesPoints,
                  points["duck/30/50/100Points"],
                  points["2/3WicketPoints"],
                  points.wicketsPoints,
                  points.maidenOversPoints,
                  points.lbwOrBowledPoints,
                  points.catchesPoints,
                  points.runOutPoints,
                  points.economyPoints,
                  points.strikeRatePoints,
                  matchId,
                  player.playerId,
                ],
                connection
              );
              if (storePoints) {
                currentPlayer++;
                if (currentPlayer === totalPlayers) {
                  const storeIsPointsCalculatedFlag = await database(
                    "UPDATE tournament_matches SET isPointsCalculated = 1 WHERE matchId = ?;",
                    [matchId],
                    connection
                  );
                  if (storeIsPointsCalculatedFlag) {
                    connection.release();
                    resolve(true);
                  }
                }
              }
            }, 200);
          });
        }
      } catch (error) {
        console.log(error);
        reject(error);
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
                // used when player does not exists in database and then to store player details in database and to store player in tournament_competitions_players table and to store player in matches_players table
                const storePlayerAndMatchPlayer = async ({
                  isPlayerExists,
                }) => {
                  return new Promise(async (resolve, reject) => {
                    try {
                      const { player: playerDetails, statistics } =
                        await makeRequest(
                          `/players/sr:player:${player.id.substr(
                            10
                          )}/profile.json`
                        );
                      if (playerDetails) {
                        const newPlayer = new Player(
                          playerDetails.type,
                          playerDetails.id.substr(10),
                          playerDetails.name.split(", ")[1],
                          playerDetails.name.split(", ")[0],
                          playerDetails.nationality,
                          playerDetails.country_code,
                          playerDetails.date_of_birth,
                          statistics || null,
                          playerDetails.batting_style || null,
                          playerDetails.bowling_style || null
                        );
                        await newPlayer.getPlayerStatesAndStore();

                        // storing player in tournament_competitors_player table
                        const team = lineup.team;
                        const competitor =
                          matchLineUp.sport_event.competitors.find(
                            (competitor) => competitor.qualifier === team
                          );
                        const tournamentCompetitorIdRes = await database(
                          "SELECT tournamentCompetitorId, competitorId FROM allteams2 WHERE allteams2.tournamentId = ? AND allteams2.competitorRadarId = ?;",
                          [this.#tournamentId, competitor.id.substr(14)],
                          connection
                        );
                        if (
                          tournamentCompetitorIdRes.length > 0 &&
                          tournamentCompetitorIdRes[0].tournamentCompetitorId
                        ) {
                          await newPlayer.storePlayerRelation(
                            tournamentCompetitorIdRes[0].tournamentCompetitorId
                          );
                          // storing player in match_players table
                          const storeMatchPlayersRes = await database(
                            "INSERT INTO match_players (matchId, competitorId, playerId, isSelected, isCaptain, isWicketKeeper) VALUES (?, ?, ?, ?, ?, ?);",
                            [
                              this.id,
                              tournamentCompetitorIdRes[0].competitorId,
                              newPlayer.id,
                              true,
                              player.is_captain || 0,
                              player.is_wicketkeeper || 0,
                            ],
                            connection
                          );
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
                          } else {
                            connection.release();
                            throw new Error("Error while storing lineup");
                          }
                        }
                      } else {
                        connection.release();
                        throw new Error("Player not found");
                      }
                    } catch (error) {
                      console.log(error.message);
                      reject(error);
                    }
                  });
                };

                // checking if player is already stored in database table players
                const [{ isExists: isPlayerExists, playerId }] = await database(
                  "SELECT COUNT(playerId) AS isExists, playerId FROM allplayers WHERE playerRadarId = ?;",
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
                  if (
                    storeMatchPlayersRes &&
                    storeMatchPlayersRes.affectedRows > 0
                  ) {
                    currentPlayer++;
                    if (currentPlayer === totalPlayers) {
                      currentLineUp++;
                      if (currentLineUp === totalLineUps) {
                        connection.release();
                        this.#isLineUpStored = true;
                        resolve();
                      }
                    }
                  } else {
                    storePlayerAndMatchPlayer({ isPlayerExists: 1 });
                  }
                } else {
                  storePlayerAndMatchPlayer({ isPlayerExists: 1 });
                }
              } catch (error) {
                console.log(error, "storeMatchLineup1");
                reject(error);
              }
            };

            lineup?.starting_lineup?.forEach(async (player) => {
              storePlayer(player);
            });
          });
        }
      } catch (error) {
        console.log(error);
        reject(error);
      }
    });
  }

  storeScoreCard() {
    return new Promise(async (resolve, reject) => {
      try {
        const newScoreCard = new Scorcard(
          this.id,
          this.#radarId,
          this.#competitors
        );
        await newScoreCard.storeScorcard();
        resolve();
      } catch (error) {
        console.log(error);
        reject(error);
      }
    });
  }

  storePoints() {
    return new Promise(async (resolve, reject) => {
      try {
        const connection = await connectToDb();
        const match = await database(
          "SELECT DISTINCT scorcard_details.matchId AS matchId, fullmatchdetails.matchTyprString AS matchType FROM scorcard_details JOIN fullmatchdetails ON fullmatchdetails.matchId = scorcard_details.matchId WHERE fullmatchdetails.matchId = ?;",
          [this.id],
          connection
        );
        const [batting, bowling] = await database(
          "SELECT 'batting' AS playerRole, fullmatchdetails.matchTyprString, scorcard_details.`matchId`, UPPER(fullmatchdetails.matchStatusString) AS matchStatusString, fullmatchdetails.matchRadarId, scorcard_innings.scorcardInningId, `inning_batsmans`.`playerId`, allplayers.roleName, `inning_batsmans`.`battingOrder` AS 'order', `inning_batsmans`.`runs`, `inning_batsmans`.`strikeRate`, `inning_batsmans`.`isNotOut`, `inning_batsmans`.`isDuck`, `inning_batsmans`.`isRetiredHurt`, `inning_batsmans`.`ballFaced`, `inning_batsmans`.`fours`,`inning_batsmans`.`sixes`, `inning_batsmans`.`dismissalBallerId`, `inning_batsmans`.`dismissalFieldeManId`, UPPER(`inning_batsmans`.`dismissalType`) AS dismissalType FROM fullmatchdetails JOIN scorcard_details ON scorcard_details.matchId = fullmatchdetails.matchId JOIN scorcard_innings ON scorcard_innings.scorcardId = scorcard_details.scorcardId JOIN inning_batsmans ON inning_batsmans.scorcardInningId = scorcard_innings.scorcardInningId JOIN allplayers ON allplayers.playerId = inning_batsmans.playerId WHERE fullmatchdetails.matchId = ? ORDER BY `scorcard_details`.`matchId` ASC;SELECT 'bowling' AS playerRole, fullmatchdetails.matchTyprString, UPPER(fullmatchdetails.matchStatusString) AS matchStatusString, scorcard_details.`matchId`, scorcard_innings.scorcardInningId, `inning_bowlers`.`playerId`, `inning_bowlers`.`runsConceded`, `inning_bowlers`.`wickets`, `inning_bowlers`.`overBowled`, `inning_bowlers`.`maidensOvers`, `inning_bowlers`.`dotBalls`, `inning_bowlers`.`fourConceded`, `inning_bowlers`.`sixConceded`, `inning_bowlers`.`noBalls`, `inning_bowlers`.`wides`, `inning_bowlers`.`economyRate` FROM fullmatchdetails JOIN scorcard_details ON scorcard_details.matchId = fullmatchdetails.matchId JOIN scorcard_innings ON scorcard_innings.scorcardId = scorcard_details.scorcardId JOIN inning_bowlers ON inning_bowlers.scorcardInningId = scorcard_innings.scorcardInningId WHERE fullmatchdetails.matchId = ? ORDER BY `scorcard_innings`.`scorcardInningId` ASC;",
          [this.id, this.id],
          connection
        );
        const lineUp = await database(
          "SELECT matchId, competitorId, playerId, isCaptain, isWicketKeeper FROM `match_players` WHERE matchId = ? AND isSelected = 1;",
          [this.id],
          connection
        );
        if (batting?.length > 0 && bowling.length > 0 && lineUp.length > 0) {
          const calculatePointsRes = await this.#calculatePoints(
            lineUp,
            batting,
            bowling,
            match[0]
          );
          if (calculatePointsRes) {
            connection.release();
            resolve();
          } else {
            connection.release();
            throw new Error("can't calculate points");
          }
        } else {
          connection.release();
          throw new Error("can't calculate points");
        }
      } catch (error) {
        console.log(error);
        reject(error);
      }
    });
  }

  #handleToss() {
    return new Promise(async (resolve, reject) => {
      try {
        const matchTimeLine = await makeRequest(
          `/matches/sr:match:${this.#radarId}/timeline.json`
        );
        if (matchTimeLine && matchTimeLine.sport_event_status) {
          const tossWonBy = this.#competitors.find((competitor) => {
            return (
              competitor.radarId ==
              matchTimeLine.sport_event_status.toss_won_by.substr(14)
            );
          });
          this.#tossDecision = matchTimeLine.sport_event_status.toss_decision;
          this.#tossWinner = tossWonBy.id;

          await this.#storeTossDetails();
          resolve();
        } else {
          throw new Error("can't get match toss details");
        }
      } catch (error) {
        console.log(error);
        reject(error);
      }
    });
  }

  handleLineUpStore() {
    return new Promise(async (resolve, reject) => {
      try {
        const matchStartTime = new Date(parseInt(this.#matchStartTime));
        const now = new Date();

        setTimeout(async () => {
          try {
            await this.storeLineUp();
            await this.#handleToss();
            resolve();
          } catch (error) {
            reject(error);
          }
        }, matchStartTime.getTime() - now.getTime() - 25 * 60 * 1000);
      } catch (error) {
        console.log(error);
        reject(error);
      }
    });
  }

  handleScorcardAndPoints() {
    return new Promise(async (resolve, reject) => {
      try {
        const handleStore = () => {
          return new Promise(async (resolve, reject) => {
            try {
              if (this.#isLineUpStored) {
                await this.storeScoreCard();
                await this.#updateStatus("ended");
                await this.storePoints();
                resolve(true);
              } else {
                await this.handleLineUpStore();
                await this.storeScoreCard();
                await this.#updateStatus("ended");
                await this.storePoints();
                resolve(true);
              }
            } catch (error) {
              console.log(error);
              if (!error.message === "Match is not ended") {
                reject(error);
              } else {
                resolve(false);
              }
            }
          });
        };
        if (this.status === "ended" || this.status === "closed") {
          await handleStore();
          resolve();
        } else {
          const intervalId = setInterval(async () => {
            const res = await handleStore();
            if (res) {
              resolveInterval();
              resolve();
            }
          }, 30 * 60 * 1000);
          const resolveInterval = () => {
            clearInterval(intervalId);
            resolve();
          };
        }
      } catch (error) {
        console.log(error);
        reject(error);
      }
    });
  }

  handleMatchStatus() {
    return new Promise(async (resolve, reject) => {
      try {
        setTimeout(async () => {
          const matchTimeLine = await makeRequest(
            `/matches/sr:match:${this.#radarId}/timeline.json`
          );
          if (matchTimeLine && matchTimeLine.sport_event_status) {
            const matchStatus = matchTimeLine.sport_event_status.status;

            if (matchStatus !== "not_started") {
              if (matchStatus === "closed") {
                await this.#updateStatus("ended");
                resolve();
              } else {
                await this.#updateStatus(matchStatus);
                resolve();
              }
            } else {
              setTimeout(async () => {
                await this.handleMatchStatus();
                resolve();
              }, 3 * 60 * 1000);
            }
          } else {
            throw new Error("can't update status");
          }
        }, parseInt(this.#matchStartTime) - new Date().getTime() + 2 * 60 * 1000);
      } catch (error) {
        console.log(error);
        reject(error);
      }
    });
  }
}

module.exports = { MatchDaily, RowMatch };
