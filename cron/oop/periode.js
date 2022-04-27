const { connectToDb, database } = require("../makeRequest");
const { MatchDaily: Match } = require("./match");
const log = require("log-to-file");

const fetchData = async () => {
  try {
    const connection = await connectToDb();
    const matches = await database(
      "SELECT matchId, matchRadarId, matchTournamentId, matchStartDateTime, matchStartTimeMilliSeconds, matchTyprString, matchStatusString, team1Id, team2Id, team1RadarId, team2RadarId FROM `fullmatchdetails` WHERE matchStatusString IN ('not_started') ORDER BY `fullmatchdetails`.`matchStartTimeMilliSeconds` DESC;",
      [],
      connection
    );
    connection.release();
    matches.forEach(async (match) => {
      try {
        const now = new Date();
        const matchStartTime = new Date(match.matchStartDateTime);
        if (
          matchStartTime.getTime() > now.getTime() &&
          matchStartTime.getTime() < now.getTime() + 90 * 60 * 1000
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
            match.matchStartDateTime
          );
          await newMatch.handleLineUpStore();
          await newMatch.handleMatchStatus();
          await newMatch.handleScorcardAndPoints();
        }
      } catch (error) {
        console.log(error.message);
      }
    });
  } catch (error) {
    console.log(error);
  }
};

module.exports = {
  fetchData,
};
