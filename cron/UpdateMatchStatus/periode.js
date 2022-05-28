const { connectToDb, database } = require("../../middleware/dbSuperUser");
const { MatchDaily: Match } = require("../StoreFromScrach/match");
const log = require("log-to-file");

const fetchData = async () => {
  try {
    const connection = await connectToDb();
    const matches = await database(
      "SELECT `fullmatchdetails`.`matchTournamentId` AS tournamentId, matchId, matchRadarId, matchTournamentId, matchStartDateTime, matchTyprString, matchStatusString, team1Id, team2Id, team1RadarId, team2RadarId, isLineUpOut FROM `fullmatchdetails` WHERE matchStatusString IN ('not_started', 'live') ORDER BY `fullmatchdetails`.matchStartDateTime DESC;",
      [],
      connection
    );
    connection.release();
    matches.forEach(async (match) => {
      try {
        const now = new Date();
        const matchStartTime = new Date(parseInt(match.matchStartDateTime));
        if (
          ((matchStartTime.getTime() > now.getTime() &&
            matchStartTime.getTime() < now.getTime() + 90 * 60 * 1000) ||
          match.matchStatusString === "live") || 
          (matchStartTime.getTime() < now.getTime() && match.matchStatusString === "not_started")
        ) {
          log(
            `Started to proceed match for scorcard, lineups and points for ${match.matchId}`
          );
          const competitor = [
            {
              id: match.team1Id,
              radarId: match.team1RadarId,
            },
            {
              id: match.team2Id,
              radarId: match.team2RadarId,
            },
          ];
          const newMatch = new Match(
            match.matchId,
            match.matchRadarId,
            match.matchStatusString,
            competitor,
            match.matchStartDateTime,
            match.tournamentId,
            match.isLineUpOut
          );
          log(
            "going to store lineups for match" +
              match.matchId +
              "FROM ./cron/oop/periode.js"
          );
          await newMatch.handleLineUpStore();
          log(
            "got response of lineup and going to procedd for matchStatus" +
              match.matchId +
              "FROM ./cron/oop/periode.js"
          );
          await newMatch.handleMatchStatus();
          log(
            "got response of matchStatus and going to procedd for scorcard" +
              match.matchId +
              "FROM ./cron/oop/periode.js"
          );
          await newMatch.handleScorcardAndPoints();
        }
      } catch (error) {
        console.log(error);
      }
    });
  } catch (error) {
    console.log(error);
  }
};

const storeAllScorcardForMatch = async (matchId) => {
  return new Promise(async (resolve, reject) => {
    try {
      const connection = await connectToDb();
      const matches = await database(
        "SELECT `fullmatchdetails`.`matchTournamentId` AS tournamentId, matchId, matchRadarId, matchTournamentId, matchStartDateTime, matchTyprString, matchStatusString, team1Id, team2Id, team1RadarId, team2RadarId FROM `fullmatchdetails` WHERE matchStatusString IN ('ended', 'closed') AND isPointsCalculated = 0 AND matchId = ? ORDER BY `fullmatchdetails`.matchStartDateTime;",
        [matchId],
        connection
      );

      connection.release();
      let currentMatch = 0;
      const totalMatches = matches.length;
      const a = async (match) => {
        try {
          const competitor = [
            {
              id: match.team1Id,
              radarId: match.team1RadarId,
            },
            {
              id: match.team2Id,
              radarId: match.team2RadarId,
            },
          ];
          const newMatch = new Match(
            match.matchId,
            match.matchRadarId,
            match.matchStatusString,
            competitor,
            match.matchStartDateTime,
            match.tournamentId
          );
          await newMatch.handleLineUpStore();
          await newMatch.handleMatchStatus();
          await newMatch.handleScorcardAndPoints();
          currentMatch++;
          if (currentMatch === totalMatches) {
            log(`Finished to store all data`);
            resolve();
          } else {
            log(`Finished to store match ${currentMatch}`);
            a(matches[currentMatch]);
          }
        } catch (error) {
          console.log(error);
          currentMatch++;
          if (currentMatch === totalMatches) {
            log(`Finished to store all data`);
            resolve();
          } else {
            log(`Finished to store match ${currentMatch}`);
            a(matches[currentMatch]);
          }
        }
      };

      if (matches.length > 0) {
        a(matches[currentMatch]);
      } else {
        resolve();
        log(`Finished to store all data`);
      }
    } catch (error) {
      console.log(error);
    }
  });
};

// storeAllScorcardForMatch();

module.exports = {
  fetchData,
  storeAllScorcardForMatch,
};
