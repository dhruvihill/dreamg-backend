const mysql = require("mysql");
require("dotenv/config");
let connectionForCron = null;
const {
  testScore,
  odiScore,
  t20Score,
  t10Score,
} = require("./calculatePoints.js");

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

const calculatePointsOfMatch = async (lineUp, batting, bowling, matchType) => {
  try {
    lineUp.forEach((player) => {
      let totalPoints = 0;

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
          playerBat.dismissalType === "caught"
        );
      });
      const playerRunOuts = batting.filter((playerBat) => {
        return (
          playerBat.dismissalFieldeManId === player.playerId &&
          playerBat.dismissalType === "run_out"
        );
      });
      const playerBowledAndLBW = bowling.filter((playerBat) => {
        return (
          playerBat.dismissalFieldeManId === player.playerId &&
          (playerBat.dismissalType === "bowled" ||
            playerBat.dismissalType === "leg_before_wicket")
        );
      });

      // calculating points for player
      playerBattingStats.forEach(async (batsMan) => {
        try {
          if (matchType.includes("t20")) {
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
            const srBetween150And170 = t20Score.strikeRate["between150.01-170"];
            const srBetween130And150 = t20Score.strikeRate["between130-150"];
            const srBetween60And70 = t20Score.strikeRate["between60-70"];
            const srBetween50And59 = t20Score.strikeRate["between50-59.99"];
            const srBelow50 = t20Score.strikeRate.below50;

            // points for runs and boundaries
            totalPoints += pointsPerRun * batsMan.runs;
            totalPoints += pointsPerFour * batsMan.fours;
            totalPoints += pointsPerSix * batsMan.sixes;

            // conditions for centuries, half centuries, thirties, ducks
            if (batsMan.runs >= 100) {
              totalPoints += pointsPerCentury;
            } else if (batsMan.runs >= 50) {
              totalPoints += pointsPerHalfCentury;
            } else if (batsMan.runs >= 30) {
              totalPoints += pointsPerThirty;
            } else if (batsMan.isDuck) {
              totalPoints += pointsPerDuck;
            }

            // conditions for strike rate
            if (batsMan.strikeRate > 170) {
              totalPoints += srOver170;
            } else if (
              batsMan.strikeRate > 150.01 &&
              batsMan.strikeRate <= 170
            ) {
              totalPoints += srBetween150And170;
            } else if (batsMan.strikeRate > 130 && batsMan.strikeRate <= 150) {
              totalPoints += srBetween130And150;
            } else if (batsMan.strikeRate > 60 && batsMan.strikeRate <= 70) {
              totalPoints += srBetween60And70;
            } else if (batsMan.strikeRate > 50 && batsMan.strikeRate <= 59.99) {
              totalPoints += srBetween50And59;
            } else if (batsMan.strikeRate <= 50) {
              totalPoints += srBelow50;
            }
          } else if (matchType.includes("test")) {
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

            // conditions for centuries, half centuries, ducks
            if (batsMan.runs >= 100) {
              totalPoints += pointsPerCentury;
            } else if (batsMan.runs >= 50) {
              totalPoints += pointsPerHalfCentury;
            } else if (batsMan.isDuck) {
              totalPoints += pointsPerDuck;
            }
          } else if (matchType.includes("odi")) {
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
            const srBetween120And140 = odiScore.strikeRate["between120.01-140"];
            const srBetween100And120 = odiScore.strikeRate["between100-120"];
            const srBetween40And50 = odiScore.strikeRate["between40-50"];
            const srBetween30And40 = odiScore.strikeRate["between30-39.99"];

            // points for runs and boundaries
            totalPoints += pointsPerRun * batsMan.runs;
            totalPoints += pointsPerFour * batsMan.fours;
            totalPoints += pointsPerSix * batsMan.sixes;

            // conditions for centuries, half centuries, ducks
            if (batsMan.runs >= 100) {
              totalPoints += pointsPerCentury;
            } else if (batsMan.runs >= 50) {
              totalPoints += pointsPerHalfCentury;
            } else if (batsMan.isDuck) {
              totalPoints += pointsPerDuck;
            }

            // conditions for strike rate
            if (batsMan.strikeRate > 140) {
              totalPoints += srOver140;
            } else if (
              batsMan.strikeRate > 120.01 &&
              batsMan.strikeRate <= 140
            ) {
              totalPoints += srBetween120And140;
            } else if (batsMan.strikeRate > 100 && batsMan.strikeRate <= 120) {
              totalPoints += srBetween100And120;
            } else if (batsMan.strikeRate >= 40 && batsMan.strikeRate <= 50) {
              totalPoints += srBetween40And50;
            } else if (batsMan.strikeRate > 30 && batsMan.strikeRate <= 39.99) {
              totalPoints += srBetween30And40;
            }
          } else if (matchType.includes("t10")) {
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
            const srBetween170And190 = t10Score.strikeRate["between170.01-190"];
            const srBetween150And170 = t10Score.strikeRate["between150-170"];
            const srBetween70And80 = t10Score.strikeRate["between70-80"];
            const srBetween60And69 = t10Score.strikeRate["between60-69.99"];
            const srBelow60 = t10Score.strikeRate.below60;

            // points for runs and boundaries
            totalPoints += pointsPerRun * batsMan.runs;
            totalPoints += pointsPerFour * batsMan.fours;
            totalPoints += pointsPerSix * batsMan.sixes;

            // conditions for centuries, half centuries, thirties, ducks
            if (batsMan.runs >= 100) {
              totalPoints += pointsPerThirtyRuns;
            } else if (batsMan.runs >= 50) {
              totalPoints += pointsPerHalfCentury;
            } else if (batsMan.runs >= 30) {
              totalPoints += pointsPerThirtyRuns;
            } else if (batsMan.isDuck) {
              totalPoints += pointsPerDuck;
            }

            // conditions for strike rate
            if (batsMan.strikeRate > 190) {
              totalPoints += srOver190;
            } else if (
              batsMan.strikeRate > 170.01 &&
              batsMan.strikeRate <= 190
            ) {
              totalPoints += srBetween170And190;
            } else if (batsMan.strikeRate > 150 && batsMan.strikeRate <= 170) {
              totalPoints += srBetween150And170;
            } else if (batsMan.strikeRate > 70 && batsMan.strikeRate <= 80) {
              totalPoints += srBetween70And80;
            } else if (batsMan.strikeRate > 60 && batsMan.strikeRate <= 69.99) {
              totalPoints += srBetween60And69;
            } else if (batsMan.strikeRate <= 60) {
              totalPoints += srBelow60;
            }
          } else {
            console.log("skip");
          }
        } catch (error) {
          console.log(error.message);
        }
      });
      playerBowlingStats.forEach(async (bowler) => {
        try {
          if (matchType.includes("t20")) {
            // constant for wickets
            const pointsPerWicket = t20Score.bowl.wicket;
            const pointsPerMaiden = t20Score.bowl.maiden;

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

            // conditions for wickets
            if (bowler.wickets >= 5) {
              totalPoints += pointsPerFiveWickets;
            } else if (bowler.wickets >= 4) {
              totalPoints += pointsPerFourWickets;
            } else if (bowler.wickets >= 3) {
              totalPoints += pointsPerThreeWickets;
            }

            // conditions for economy
            if (bowler.economy > 12) {
              totalPoints += eAbove12;
            } else if (bowler.economy > 11 && bowler.economy <= 12) {
              totalPoints += eBetween11And12;
            } else if (bowler.economy > 10 && bowler.economy <= 11) {
              totalPoints += eBetween10And11;
            } else if (bowler.economy > 6 && bowler.economy <= 7) {
              totalPoints += eBetween6And7;
            } else if (bowler.economy > 5 && bowler.economy <= 5.99) {
              totalPoints += eBetween5And6;
            } else if (bowler.economy <= 5) {
              totalPoints += eBelow5;
            }
          } else if (matchType.includes("test")) {
            // constant for wickets
            const pointsPerWicket = testScore.bowling.wicket;

            // constant for hauls
            const pointsPerFourWickets = testScore.bowling.fourWicketBouns;
            const pointsPerFiveWickets = testScore.bowling.fiveWicketBouns;

            // points for wickets
            totalPoints += pointsPerWicket * bowler.wickets;

            // conditions for wickets
            if (bowler.wickets >= 5) {
              totalPoints += pointsPerFiveWickets;
            } else if (bowler.wickets >= 4) {
              totalPoints += pointsPerFourWickets;
            }
          } else if (matchType.includes("odi")) {
            // constant for wickets
            const pointsPerWicket = odiScore.bowling.wicket;
            const pointsPerMaiden = odiScore.bowling.maiden;

            // constant for hauls
            const pointsPerFourWickets = odiScore.bowling.fourWicketBouns;
            const pointsPerFiveWickets = odiScore.bowling.fiveWicketBouns;

            // constant for economy
            const eBelow2_5 = odiScore.economy["below2.5"];
            const eBetween2_5And3_5 = odiScore.economy["between2.5-3.49"];
            const eBetween3_5And4_5 = odiScore.economy["between3.5-4.49"];
            const eBetween7And8 = odiScore.economy["between7-8"];
            const eBetween8And9 = odiScore.economy["between8.01-9"];
            const eAbove9 = odiScore.economy.above9;

            // points for wickets
            totalPoints += pointsPerWicket * bowler.wickets;
            totalPoints += pointsPerMaiden * bowler.maidensOvers;

            // conditions for wickets
            if (bowler.wickets >= 5) {
              totalPoints += pointsPerFiveWickets;
            } else if (bowler.wickets >= 4) {
              totalPoints += pointsPerFourWickets;
            }

            // conditions for economy
            if (bowler.economy > 9) {
              totalPoints += eAbove9;
            } else if (bowler.economy > 8.01 && bowler.economy <= 9) {
              totalPoints += eBetween8And9;
            } else if (bowler.economy > 7 && bowler.economy <= 8) {
              totalPoints += eBetween7And8;
            } else if (bowler.economy > 3.5 && bowler.economy <= 4.49) {
              totalPoints += eBetween3_5And4_5;
            } else if (bowler.economy > 2.5 && bowler.economy <= 3.49) {
              totalPoints += eBetween2_5And3_5;
            } else if (bowler.economy <= 2.5) {
              totalPoints += eBelow2_5;
            }
          } else if (matchType.includes("t10")) {
            // constant for wickets
            const pointsPerWicket = t10Score.bowling.wicket;
            const pointsPerMaiden = t10Score.bowling.maiden;

            // constant for hauls
            const pointsPerTwoWickets = t10Score.bowling.twoWicketBouns;
            const pointsPerThreeWickets = t10Score.bowling.threeWicketBouns;

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

            // conditions for wickets
            if (bowler.wickets >= 3) {
              totalPoints += pointsPerThreeWickets;
            } else if (bowler.wickets >= 2) {
              totalPoints += pointsPerTwoWickets;
            }

            // conditions for economy
            if (bowler.economy > 16) {
              totalPoints += eAbove16;
            } else if (bowler.economy > 15.01 && bowler.economy <= 16) {
              totalPoints += eBetween15And16;
            } else if (bowler.economy > 14 && bowler.economy <= 15) {
              totalPoints += eBetween14And15;
            } else if (bowler.economy > 8 && bowler.economy <= 9) {
              totalPoints += eBetween8And9;
            } else if (bowler.economy > 7 && bowler.economy <= 7.99) {
              totalPoints += eBetween7And8;
            } else if (bowler.economy < 7) {
              totalPoints += eBelow7;
            }
          } else {
            console.log("skip");
          }
        } catch (error) {
          console.log(error.message);
        }
      });
      playerCatches.forEach(() => {
        try {
          if (matchType.includes("test")) {
            totalPoints += testScore.field.catch;
          } else if (matchType.includes("odi")) {
            totalPoints += odiScore.field.catch;
          } else if (matchType.includes("t10")) {
            totalPoints += t10Score.field.catch;
          } else if (matchType.includes("t20")) {
            totalPoints += t20Score.field.catch;
          }
        } catch (error) {
          console.log(error.message);
        }
      });
      playerRunOuts.forEach(() => {
        try {
          if (matchType.includes("test")) {
            totalPoints += testScore.field.runOut;
          } else if (matchType.includes("odi")) {
            totalPoints += odiScore.field.runOut;
          } else if (matchType.includes("t10")) {
            totalPoints += t10Score.field.runOut;
          } else if (matchType.includes("t20")) {
            totalPoints += t20Score.field.runOut;
          }
        } catch (error) {
          console.log(error.message);
        }
      });
      playerBowledAndLBW.forEach(() => {
        try {
          if (matchType.includes("test")) {
            totalPoints += testScore.bowl.lbwOrBowled;
          } else if (matchType.includes("odi")) {
            totalPoints += odiScore.bowl.lbwOrBowled;
          } else if (matchType.includes("t10")) {
            totalPoints += t10Score.bowl.lbwOrBowled;
          } else if (matchType.includes("t20")) {
            totalPoints += t20Score.bowl.lbwOrBowled;
          }
        } catch (error) {
          console.log(error.message);
        }
      });
      console.log(totalPoints, player.playerId);
    });
  } catch (error) {
    console.log(error.message);
  }
};

const fetchData = async () => {
  try {
    const connection = await connectToDb();
    const fetchMatches = await database(
      "SELECT DISTINCT scorcard_details.matchId AS matchId, fullmatchdetails.matchTyprString AS matchType FROM scorcard_details JOIN fullmatchdetails ON fullmatchdetails.matchId = scorcard_details.matchId WHERE fullmatchdetails.matchTyprString NOT IN ('list_a', 'first_class');",
      [],
      connection
    );
    let a = 1;
    fetchMatches.forEach(async (match) => {
      try {
        const [batting, bowling] = await database(
          "SELECT 'batting' AS playerRole, fullmatchdetails.matchTyprString, scorcard_details.`matchId`, UPPER(fullmatchdetails.matchStatusString) AS matchStatusString, fullmatchdetails.matchRadarId, scorcard_innings.scorcardInningId, `inning_batsmans`.`playerId`, `inning_batsmans`.`runs`, `inning_batsmans`.`strikeRate`, `inning_batsmans`.`isNotOut`, `inning_batsmans`.`isDuck`, `inning_batsmans`.`isRetiredHurt`, `inning_batsmans`.`ballFaced`, `inning_batsmans`.`fours`,`inning_batsmans`.`sixes`, `inning_batsmans`.`dismissalBallerId`, `inning_batsmans`.`dismissalFieldeManId`, UPPER(`inning_batsmans`.`dismissalType`) AS dismissalType FROM fullmatchdetails JOIN scorcard_details ON scorcard_details.matchId = fullmatchdetails.matchId JOIN scorcard_innings ON scorcard_innings.scorcardId = scorcard_details.scorcardId JOIN inning_batsmans ON inning_batsmans.scorcardInningId = scorcard_innings.scorcardInningId WHERE fullmatchdetails.matchId = ? ORDER BY `scorcard_details`.`matchId` ASC;SELECT 'bowling' AS playerRole, fullmatchdetails.matchTyprString, UPPER(fullmatchdetails.matchStatusString) AS matchStatusString, scorcard_details.`matchId`, scorcard_innings.scorcardInningId, `inning_bowlers`.`playerId`, `inning_bowlers`.`runsConceded`, `inning_bowlers`.`wickets`, `inning_bowlers`.`overBowled`, `inning_bowlers`.`maidensOvers`, `inning_bowlers`.`dotBalls`, `inning_bowlers`.`fourConceded`, `inning_bowlers`.`sixConceded`, `inning_bowlers`.`noBalls`, `inning_bowlers`.`wides`, `inning_bowlers`.`economyRate` FROM fullmatchdetails JOIN scorcard_details ON scorcard_details.matchId = fullmatchdetails.matchId JOIN scorcard_innings ON scorcard_innings.scorcardId = scorcard_details.scorcardId JOIN inning_bowlers ON inning_bowlers.scorcardInningId = scorcard_innings.scorcardInningId WHERE fullmatchdetails.matchId = ? ORDER BY `scorcard_innings`.`scorcardInningId` ASC;",
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
            calculatePointsOfMatch(lineUp, batting, bowling, match.matchType);
          }
          a++;
        }
      } catch (error) {
        console.log(error.message);
      }
    });
  } catch (error) {
    console.log(error.message, "fetchData");
  }
};

fetchData();

// SELECT scorcard_details.`matchId`, scorcard_innings.scorcardInningId FROM fullmatchdetails JOIN scorcard_details ON scorcard_details.matchId = fullmatchdetails.matchId JOIN scorcard_innings ON scorcard_innings.scorcardId = scorcard_details.scorcardId WHERE fullmatchdetails.matchStatusString NOT IN ('not_started', 'live') ORDER BY `scorcard_innings`.`scorcardInningId` ASC;
// "SELECT scorcard_details.`matchId`, fullmatchdetails.matchRadarId, scorcard_innings.scorcardInningId, `inning_batsmans`.`playerId`, `inning_batsmans`.`runs`, `inning_batsmans`.`strikeRate`, `inning_batsmans`.`isNotOut`, `inning_batsmans`.`isDuck`, `inning_batsmans`.`isRetiredHurt`, `inning_batsmans`.`ballFaced`, `inning_batsmans`.`fours`,`inning_batsmans`.`sixes`, `inning_batsmans`.`dismissalBallerId`, `inning_batsmans`.`dismissalFieldeManId`, UPPER(`inning_batsmans`.`dismissalType`) AS dismissalType FROM fullmatchdetails JOIN scorcard_details ON scorcard_details.matchId = fullmatchdetails.matchId JOIN scorcard_innings ON scorcard_innings.scorcardId = scorcard_details.scorcardId JOIN inning_batsmans ON inning_batsmans.scorcardInningId = scorcard_innings.scorcardInningId WHERE fullmatchdetails.matchStatusString IN ('closed', 'ended') ORDER BY `scorcard_details`.`matchId` ASC;"
// "SELECT scorcard_details.`matchId`, scorcard_innings.scorcardInningId, `inning_bowlers`.`playerId`, `inning_bowlers`.`runsConceded`, `inning_bowlers`.`wickets`, `inning_bowlers`.`overBowled`, `inning_bowlers`.`maidensOvers`, `inning_bowlers`.`dotBalls`, `inning_bowlers`.`fourConceded`, `inning_bowlers`.`sixConceded`, `inning_bowlers`.`noBalls`, `inning_bowlers`.`wides`, `inning_bowlers`.`economyRate` FROM fullmatchdetails JOIN scorcard_details ON scorcard_details.matchId = fullmatchdetails.matchId JOIN scorcard_innings ON scorcard_innings.scorcardId = scorcard_details.scorcardId JOIN inning_bowlers ON inning_bowlers.scorcardInningId = scorcard_innings.scorcardInningId WHERE fullmatchdetails.matchStatusString IN ('ended', 'closed') ORDER BY `scorcard_innings`.`scorcardInningId` ASC;"
