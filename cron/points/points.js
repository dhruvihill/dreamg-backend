const {
  testScore,
  odiScore,
  t20Score,
  t10Score,
} = require("./calculatePoints.js");
const { connectToDb } = require("../makeRequest");

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

const calculatePointsOfMatch = async (
  lineUp,
  batting,
  bowling,
  { matchType, matchId },
  connection
) => {
  return new Promise(async (resolve, reject) => {
    try {
      let currentPlayer = 0;
      const totalPlayers = lineUp.length;
      if (matchType === "test") {
        lineUp.forEach((player) => {
          let totalPoints = 4;
          const points = {
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
              playerBat.dismissalType === "CAUGHT"
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
              } else if (batsMan.isDuck) {
                totalPoints += pointsPerDuck;
                points["duck/50/100Points"] += pointsPerDuck;
              }
            } catch (error) {
              console.log(error.message);
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
              console.log(error.message);
            }
          });
          playerCatches.forEach(() => {
            try {
              totalPoints += testScore.field.catch;
              points.catchesPoints += testScore.field.catch;
            } catch (error) {
              console.log(error.message);
            }
          });
          playerRunOuts.forEach(() => {
            try {
              totalPoints += testScore.field.runOut;
              points.runOutPoints += testScore.field.runOut;
            } catch (error) {
              console.log(error.message);
            }
          });
          playerBowledAndLBW.forEach(() => {
            try {
              totalPoints += testScore.bowl.lbwOrBowled;
              points.lbwOrBowledPoints += testScore.bowl.lbwOrBowled;
            } catch (error) {
              console.log(error.message);
            }
          });
          setTimeout(async () => {
            const storePoints = await database(
              "UPDATE match_lineup SET points = ?, `runsPoints` = ?, `foursPoints` = ?, `sixesPoints` = ?, `numberRunsPoints` = ?, `numberWicketPoints` = ?, `wicketPoints` = ?, `maidenOverPoints` = ?, `lbwOrBowledPoints` = ?, `catchesPoints` = ?, `runOutPoints` = ?, `economyPoints` = ?, `strikeRatePoints` = ? WHERE matchId = ? AND playerId = ?;",
              [
                totalPoints,
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
            const abc = await database(
              "UPDATE `match_players` SET `isSelected` = ?, `points` = ?, `runsPoints` = ?, `foursPoints` = ?, `sixesPoints` = ?, `numberRunsPoints` = ?, `numberWicketPoints` = ?, `wicketPoints` = ?, `maidenOverPoints` = ?, `lbwOrBowledPoints` = ?, `catchesPoints` = ?, `runOutPoints` = ?, `economyPoints` = ?, `strikeRatePoints` = ? WHERE matchId = ? AND playerId = ?;",
              [
                true,
                totalPoints,
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
                resolve(true);
              }
            }
          }, 200);
        });
      } else if (matchType === "odi") {
        lineUp.forEach((player) => {
          let totalPoints = 4;
          const points = {
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
              playerBat.dismissalType === "CAUGHT"
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
              const srBetween100And120 = odiScore.strikeRate["between100-120"];
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
              } else if (batsMan.isDuck) {
                totalPoints += pointsPerDuck;
                points["duck/50/100Points"] += pointsPerDuck;
              }

              // conditions for strike rate
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
              } else if (batsMan.strikeRate >= 40 && batsMan.strikeRate <= 50) {
                totalPoints += srBetween40And50;
                points.strikeRatePoints += srBetween40And50;
              } else if (
                batsMan.strikeRate > 30 &&
                batsMan.strikeRate <= 39.99
              ) {
                totalPoints += srBetween30And40;
                points.strikeRatePoints += srBetween30And40;
              }
            } catch (error) {
              console.log(error.message);
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
              points.maidenOversPoints += pointsPerMaiden * bowler.maidensOvers;

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
              } else if (bowler.economyRate > 8.01 && bowler.economyRate <= 9) {
                totalPoints += eBetween8And9;
                points.economyPoints += eBetween8And9;
              } else if (bowler.economyRate > 7 && bowler.economyRate <= 8) {
                totalPoints += eBetween7And8;
                points.economyPoints += eBetween7And8;
              } else if (
                bowler.economyRate > 3.5 &&
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
              console.log(error.message);
            }
          });
          playerCatches.forEach(() => {
            try {
              totalPoints += odiScore.field.catch;
              points.catchesPoints += odiScore.field.catch;
            } catch (error) {
              console.log(error.message);
            }
          });
          playerRunOuts.forEach(() => {
            try {
              totalPoints += odiScore.field.runOut;
              points.runOutPoints += odiScore.field.runOut;
            } catch (error) {
              console.log(error.message);
            }
          });
          playerBowledAndLBW.forEach(() => {
            try {
              totalPoints += odiScore.bowl.lbwOrBowled;
              points.lbwOrBowledPoints += odiScore.bowl.lbwOrBowled;
            } catch (error) {
              console.log(error.message);
            }
          });
          setTimeout(async () => {
            const storePoints = await database(
              "UPDATE match_lineup SET points = ?, `runsPoints` = ?, `foursPoints` = ?, `sixesPoints` = ?, `numberRunsPoints` = ?, `numberWicketPoints` = ?, `wicketPoints` = ?, `maidenOverPoints` = ?, `lbwOrBowledPoints` = ?, `catchesPoints` = ?, `runOutPoints` = ?, `economyPoints` = ?, `strikeRatePoints` = ? WHERE matchId = ? AND playerId = ?;",
              [
                totalPoints,
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
            const abc = await database(
              "UPDATE `match_players` SET `isSelected` = ?, `points` = ?, `runsPoints` = ?, `foursPoints` = ?, `sixesPoints` = ?, `numberRunsPoints` = ?, `numberWicketPoints` = ?, `wicketPoints` = ?, `maidenOverPoints` = ?, `lbwOrBowledPoints` = ?, `catchesPoints` = ?, `runOutPoints` = ?, `economyPoints` = ?, `strikeRatePoints` = ? WHERE matchId = ? AND playerId = ?;",
              [
                true,
                totalPoints,
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
                resolve(true);
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
              playerBat.dismissalType === "CAUGHT"
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
              const srBetween130And150 = t20Score.strikeRate["between130-150"];
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
              } else if (batsMan.isDuck) {
                totalPoints += pointsPerDuck;
                points["duck/30/50/100Points"] += pointsPerDuck;
              }

              // conditions for strike rate
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
              } else if (batsMan.strikeRate > 60 && batsMan.strikeRate <= 70) {
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
            } catch (error) {
              console.log(error.message);
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
              points.maidenOversPoints += pointsPerMaiden * bowler.maidensOvers;

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
              } else if (bowler.economyRate > 11 && bowler.economyRate <= 12) {
                totalPoints += eBetween11And12;
                points.economyPoints += eBetween11And12;
              } else if (bowler.economyRate > 10 && bowler.economyRate <= 11) {
                totalPoints += eBetween10And11;
                points.economyPoints += eBetween10And11;
              } else if (bowler.economyRate > 6 && bowler.economyRate <= 7) {
                totalPoints += eBetween6And7;
                points.economyPoints += eBetween6And7;
              } else if (bowler.economyRate > 5 && bowler.economyRate <= 5.99) {
                totalPoints += eBetween5And6;
                points.economyPoints += eBetween5And6;
              } else if (bowler.economyRate <= 5) {
                totalPoints += eBelow5;
                points.economyPoints += eBelow5;
              }
            } catch (error) {
              console.log(error.message);
            }
          });
          playerCatches.forEach(() => {
            try {
              totalPoints += t20Score.field.catch;
              points.catchesPoints += t20Score.field.catch;
            } catch (error) {
              console.log(error.message);
            }
          });
          playerRunOuts.forEach(() => {
            try {
              totalPoints += t20Score.field.runOut;
              points.runOutPoints += t20Score.field.runOut;
            } catch (error) {
              console.log(error.message);
            }
          });
          playerBowledAndLBW.forEach(() => {
            try {
              totalPoints += t20Score.bowl.lbwOrBowled;
              points.lbwOrBowledPoints += t20Score.bowl.lbwOrBowled;
            } catch (error) {
              console.log(error.message);
            }
          });
          setTimeout(async () => {
            const storePoints = await database(
              "UPDATE match_lineup SET points = ?, `runsPoints` = ?, `foursPoints` = ?, `sixesPoints` = ?, `numberRunsPoints` = ?, `numberWicketPoints` = ?, `wicketPoints` = ?, `maidenOverPoints` = ?, `lbwOrBowledPoints` = ?, `catchesPoints` = ?, `runOutPoints` = ?, `economyPoints` = ?, `strikeRatePoints` = ? WHERE matchId = ? AND playerId = ?;",
              [
                totalPoints,
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
            const abc = await database(
              "UPDATE `match_players` SET `isSelected` = ?, `points` = ?, `runsPoints` = ?, `foursPoints` = ?, `sixesPoints` = ?, `numberRunsPoints` = ?, `numberWicketPoints` = ?, `wicketPoints` = ?, `maidenOverPoints` = ?, `lbwOrBowledPoints` = ?, `catchesPoints` = ?, `runOutPoints` = ?, `economyPoints` = ?, `strikeRatePoints` = ? WHERE matchId = ? AND playerId = ?;",
              [
                true,
                totalPoints,
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
                resolve(true);
              }
            }
          }, 200);
        });
      } else if (matchType === "t10") {
        lineUp.forEach((player) => {
          let totalPoints = 4;
          const points = {
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
              playerBat.dismissalType === "CAUGHT"
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
              const srBetween150And170 = t10Score.strikeRate["between150-170"];
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
              } else if (batsMan.isDuck) {
                totalPoints += pointsPerDuck;
                points["duck/30/50/100Points"] += pointsPerDuck;
              }

              // conditions for strike rate
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
              } else if (batsMan.strikeRate > 70 && batsMan.strikeRate <= 80) {
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
            } catch (error) {
              console.log(error.message);
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
              points.maidenOversPoints += pointsPerMaiden * bowler.maidensOvers;

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
              } else if (bowler.economyRate > 14 && bowler.economyRate <= 15) {
                totalPoints += eBetween14And15;
                points.economyPoints += eBetween14And15;
              } else if (bowler.economyRate > 8 && bowler.economyRate <= 9) {
                totalPoints += eBetween8And9;
                points.economyPoints += eBetween8And9;
              } else if (bowler.economyRate > 7 && bowler.economyRate <= 7.99) {
                totalPoints += eBetween7And8;
                points.economyPoints += eBetween7And8;
              } else if (bowler.economyRate < 7) {
                totalPoints += eBelow7;
                points.economyPoints += eBelow7;
              }
            } catch (error) {
              console.log(error.message);
            }
          });
          playerCatches.forEach(() => {
            try {
              totalPoints += t10Score.field.catch;
              points.catchesPoints += t10Score.field.catch;
            } catch (error) {
              console.log(error.message);
            }
          });
          playerRunOuts.forEach(() => {
            try {
              totalPoints += t10Score.field.runOut;
              points.runOutPoints += t10Score.field.runOut;
            } catch (error) {
              console.log(error.message);
            }
          });
          playerBowledAndLBW.forEach(() => {
            try {
              totalPoints += t10Score.bowl.lbwOrBowled;
              points.lbwOrBowledPoints += t10Score.bowl.lbwOrBowled;
            } catch (error) {
              console.log(error.message);
            }
          });
          setTimeout(async () => {
            const storePoints = await database(
              "UPDATE match_lineup SET points = ?, `runsPoints` = ?, `foursPoints` = ?, `sixesPoints` = ?, `numberRunsPoints` = ?, `numberWicketPoints` = ?, `wicketPoints` = ?, `maidenOverPoints` = ?, `lbwOrBowledPoints` = ?, `catchesPoints` = ?, `runOutPoints` = ?, `economyPoints` = ?, `strikeRatePoints` = ? WHERE matchId = ? AND playerId = ?;",
              [
                totalPoints,
                points.runsPoints,
                points.foursPoints,
                points.sixesPoints,
                points["duck/50/100Points"],
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
            const abc = await database(
              "UPDATE `match_players` SET `isSelected` = ?, `points` = ?, `runsPoints` = ?, `foursPoints` = ?, `sixesPoints` = ?, `numberRunsPoints` = ?, `numberWicketPoints` = ?, `wicketPoints` = ?, `maidenOverPoints` = ?, `lbwOrBowledPoints` = ?, `catchesPoints` = ?, `runOutPoints` = ?, `economyPoints` = ?, `strikeRatePoints` = ? WHERE matchId = ? AND playerId = ?;",
              [
                true,
                totalPoints,
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
                resolve(true);
              }
            }
          }, 200);
        });
      }
    } catch (error) {
      console.log(error.message);
    }
  });
};

const fetchData = async (matchId) => {
  return new Promise(async (resolve, reject) => {
    try {
      const connection = await connectToDb();
      let fetchMatches;
      if (matchId) {
        fetchMatches = await database(
          "SELECT DISTINCT scorcard_details.matchId AS matchId, fullmatchdetails.matchTyprString AS matchType FROM scorcard_details JOIN fullmatchdetails ON fullmatchdetails.matchId = scorcard_details.matchId WHERE fullmatchdetails.matchId = ?;",
          [matchId],
          connection
        );
      } else {
        fetchMatches = await database(
          "SELECT DISTINCT scorcard_details.matchId AS matchId, fullmatchdetails.matchTyprString AS matchType FROM scorcard_details JOIN fullmatchdetails ON fullmatchdetails.matchId = scorcard_details.matchId;",
          [],
          connection
        );
      }
      let a = 1;
      const pr = async (match) => {
        try {
          const [batting, bowling] = await database(
            "SELECT 'batting' AS playerRole, fullmatchdetails.matchTyprString, scorcard_details.`matchId`, UPPER(fullmatchdetails.matchStatusString) AS matchStatusString, fullmatchdetails.matchRadarId, scorcard_innings.scorcardInningId, `inning_batsmans`.`playerId`, `inning_batsmans`.`battingOrder` AS 'order', `inning_batsmans`.`runs`, `inning_batsmans`.`strikeRate`, `inning_batsmans`.`isNotOut`, `inning_batsmans`.`isDuck`, `inning_batsmans`.`isRetiredHurt`, `inning_batsmans`.`ballFaced`, `inning_batsmans`.`fours`,`inning_batsmans`.`sixes`, `inning_batsmans`.`dismissalBallerId`, `inning_batsmans`.`dismissalFieldeManId`, UPPER(`inning_batsmans`.`dismissalType`) AS dismissalType FROM fullmatchdetails JOIN scorcard_details ON scorcard_details.matchId = fullmatchdetails.matchId JOIN scorcard_innings ON scorcard_innings.scorcardId = scorcard_details.scorcardId JOIN inning_batsmans ON inning_batsmans.scorcardInningId = scorcard_innings.scorcardInningId WHERE fullmatchdetails.matchId = ? ORDER BY `scorcard_details`.`matchId` ASC;SELECT 'bowling' AS playerRole, fullmatchdetails.matchTyprString, UPPER(fullmatchdetails.matchStatusString) AS matchStatusString, scorcard_details.`matchId`, scorcard_innings.scorcardInningId, `inning_bowlers`.`playerId`, `inning_bowlers`.`runsConceded`, `inning_bowlers`.`wickets`, `inning_bowlers`.`overBowled`, `inning_bowlers`.`maidensOvers`, `inning_bowlers`.`dotBalls`, `inning_bowlers`.`fourConceded`, `inning_bowlers`.`sixConceded`, `inning_bowlers`.`noBalls`, `inning_bowlers`.`wides`, `inning_bowlers`.`economyRate` FROM fullmatchdetails JOIN scorcard_details ON scorcard_details.matchId = fullmatchdetails.matchId JOIN scorcard_innings ON scorcard_innings.scorcardId = scorcard_details.scorcardId JOIN inning_bowlers ON inning_bowlers.scorcardInningId = scorcard_innings.scorcardInningId WHERE fullmatchdetails.matchId = ? ORDER BY `scorcard_innings`.`scorcardInningId` ASC;",
            [match.matchId, match.matchId],
            connection
          );
          const lineUp = await database(
            "SELECT matchId, competitorId, playerId, isCaptain, isWicketKeeper FROM `match_lineup` WHERE matchId = ?;",
            [match.matchId],
            connection
          );
          if (batting?.length > 0 && bowling.length > 0 && lineUp.length > 0) {
            if (a === 1) {
              calculatePointsOfMatch(
                lineUp,
                batting,
                bowling,
                match,
                connection
              );
            }
            a++;
          }
        } catch (error) {
          console.log(error.message);
        }
      };
      pr(fetchMatches[0]);
      // fetchMatches.forEach(async (match) => {
      // });
    } catch (error) {
      console.log(error.message, "fetchData");
    }
  });
};

module.exports = {
  fetchData,
  calculatePointsOfMatch,
};
