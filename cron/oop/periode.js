const { connectToDb, database } = require("../makeRequest");
const { MatchDaily: Match } = require("./match");
const log = require("log-to-file");

const fetchData = async () => {
  try {
    const connection = await connectToDb();
    const matches = await database(
      "SELECT `fullmatchdetails`.`matchTournamentId` AS tournamentId, matchId, matchRadarId, matchTournamentId, matchStartDateTime, matchTyprString, matchStatusString, team1Id, team2Id, team1RadarId, team2RadarId FROM `fullmatchdetails` WHERE matchStatusString IN ('not_started') ORDER BY `fullmatchdetails`.matchStartDateTime DESC;",
      [],
      connection
    );
    connection.release();
    matches.forEach(async (match) => {
      try {
        const now = new Date();
        const matchStartTime = new Date(parseInt(match.matchStartDateTime));
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
            match.matchStartDateTime,
            match.tournamentId
          );
          await newMatch.handleLineUpStore();
          await newMatch.handleMatchStatus();
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

const storeAllData = async () => {
  try {
    const connection = await connectToDb();
    const matches = await database(
      "SELECT `fullmatchdetails`.`matchTournamentId` AS tournamentId, matchId, matchRadarId, matchTournamentId, matchStartDateTime, matchTyprString, matchStatusString, team1Id, team2Id, team1RadarId, team2RadarId FROM `fullmatchdetails` WHERE matchStatusString IN ('ended', 'closed') AND isPointsCalculated = 0 ORDER BY `fullmatchdetails`.matchStartDateTime;",
      [],
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
        } else {
          log(`Finished to store match ${currentMatch}`);
          a(matches[currentMatch]);
        }
      } catch (error) {
        console.log(error);
        currentMatch++;
        if (currentMatch === totalMatches) {
          log(`Finished to store all data`);
        } else {
          log(`Finished to store match ${currentMatch}`);
          a(matches[currentMatch]);
        }
      }
    };

    if (matches.length > 0) {
      a(matches[currentMatch]);
    } else {
      log(`Finished to store all data`);
    }
  } catch (error) {
    console.log(error);
  }
};
storeAllData();

module.exports = {
  fetchData,
};
