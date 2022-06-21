const { fetchData, imageUrl } = require("../database/db_connection");
const { convertTimeZone } = require("../middleware/convertTimeZone");
class FetchMatch {
  Matches = [];
  totalMatches = 0;
  totalPages = 0;

  formatMatches(serverAddress, timeZone) {
    this.Matches.forEach((match) => {
      if (match.matchStatusString === "not_started") {
        match.matchStatusString = "UPCOMING";
      } else if (match.matchStatusString === "live") {
        match.matchStatusString = "LIVE";
      } else if (
        match.matchStatusString === "ended" ||
        match.matchStatusString === "closed"
      ) {
        match.matchStatusString = "RECENT";
      }

      // converting time zone
      [match.matchStartDateTime, match.matchStartTimeMilliSeconds] =
        convertTimeZone(match.matchStartDateTime, timeZone);

      match.remainingMatchStartTime =
        parseInt(match.matchStartTimeMilliSeconds) - Date.now();
      match.remainingMatchStartTime =
        match.remainingMatchStartTime <= 0
          ? "0"
          : match.remainingMatchStartTime.toString();

      match.team1FlagURL = imageUrl(
        __dirname,
        "../../",
        `${process.env.TEAM_IMAGE_URL}${match.team1Id}.jpg`,
        serverAddress
      );
      match.team2FlagURL = imageUrl(
        __dirname,
        "../../",
        `${process.env.TEAM_IMAGE_URL}${match.team2Id}.jpg`,
        serverAddress
      );
    });
  }

  fetchMatches(
    userId,
    numberOfMatchesToBeIgnored = 0,
    matchLimit = 10,
    matchStatus = "UPCOMING",
    serverAddress,
    timeZone
  ) {
    return new Promise(async (resolve, reject) => {
      try {
        let matchQuery = "";

        if (matchStatus === "UPCOMING") {
          matchQuery = `SELECT EXISTS(SELECT * FROM fullmatchdetails AS innerFullMatch WHERE (innerFullMatch.team1Id IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id) OR innerFullMatch.team2Id IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id)) AND innerFullMatch.matchStartDateTime < fullmatchdetails.matchStartDateTime AND innerFullMatch.matchTournamentId IN (fullmatchdetails.matchTournamentId) AND innerFullMatch.matchStatusString IN ('live', 'not_started')) AS isDisabled, fullmatchdetails.isLineUpOut AS isLineUpOut, (SELECT COUNT(DISTINCT userId) FROM userTeamDetails WHERE userTeamDetails.matchId = fullmatchdetails.matchId) AS totalPredictors, seriesName, seriesDname, matchId, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE matchStatusString = 'not_started' AND fullmatchdetails.matchStartDateTime > (UNIX_TIMESTAMP(now()) * 1000) ORDER BY matchStartDateTime LIMIT ?, ?; SELECT COUNT(*) AS totalResult FROM fullmatchdetails WHERE matchStatusString = 'not_started' AND fullmatchdetails.matchStartDateTime > (UNIX_TIMESTAMP(now()) * 1000) ORDER BY fullmatchdetails.matchStartDateTime ASC;`;
        } else if (matchStatus === "LIVE") {
          matchQuery = `SELECT (SELECT COUNT(DISTINCT userId) FROM userTeamDetails WHERE userTeamDetails.matchId = fullmatchdetails.matchId) AS totalPredictors, seriesName, seriesDname, matchId, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE matchStatusString = 'live' AND (UNIX_TIMESTAMP(now()) - 604800) * 1000 < matchStartDateTime ORDER BY matchStartDateTime DESC LIMIT ?, ?; SELECT COUNT(*) AS totalResult FROM fullmatchdetails WHERE matchStatusString = 'live';`;
        } else if (matchStatus === "RECENT") {
          matchQuery = `SELECT (SELECT COUNT(DISTINCT userId) FROM userTeamDetails WHERE userTeamDetails.matchId = fullmatchdetails.matchId) AS totalPredictors, seriesName, seriesDname, fullmatchdetails.matchId, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated,EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated, scorcardDetails.matchResultString AS matchResultString FROM fullmatchdetails JOIN scorcardDetails ON scorcardDetails.matchId = fullmatchdetails.matchId WHERE matchStatusString = 'ended' OR matchStatusString = 'closed' ORDER BY matchStartDateTime DESC LIMIT ?, ?; SELECT COUNT(*) AS totalResult FROM fullmatchdetails WHERE matchStatusString = 'ended' OR matchStatusString = 'closed';`;
        } else if (matchStatus === "CANCELED") {
          matchQuery = `SELECT (SELECT COUNT(DISTINCT userId) FROM userTeamDetails WHERE userTeamDetails.matchId = fullmatchdetails.matchId) AS totalPredictors, seriesName, seriesDname, matchId, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE matchStatusString = 'cancelled' ORDER BY matchStartDateTime DESC LIMIT ?, ?; SELECT COUNT(*) AS totalResult FROM fullmatchdetails WHERE matchStatusString = 'cancelled'`;
        }

        const [matches, [{ totalResult }]] = await fetchData(matchQuery, [
          userId,
          userId,
          numberOfMatchesToBeIgnored,
          matchLimit,
        ]);

        this.Matches = matches;
        this.TotalResult = totalResult;
        this.totalPages = Math.ceil(totalResult / matchLimit);
        this.formatMatches(serverAddress, timeZone);
        resolve();
      } catch (error) {
        reject(error);
      }
    });
  }

  fetchDashboardMatches(
    userId,
    numberOfMatchesToBeIgnored = 0,
    matchLimit = 5,
    serverAddress,
    timeZone
  ) {
    return new Promise(async (resolve, reject) => {
      try {
        const matchesQuery =
          "SELECT * FROM (SELECT EXISTS(SELECT * FROM fullmatchdetails AS innerFullMatch WHERE (innerFullMatch.team1Id IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id) OR innerFullMatch.team2Id IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id)) AND innerFullMatch.matchStartDateTime < fullmatchdetails.matchStartDateTime AND innerFullMatch.matchTournamentId IN (fullmatchdetails.matchTournamentId) AND innerFullMatch.matchStatusString IN ('live', 'not_started')) AS isDisabled, (SELECT COUNT(DISTINCT userId) FROM userTeamDetails WHERE userTeamDetails.matchId = fullmatchdetails.matchId) AS totalPredictors, seriesName, seriesDname, matchId, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE matchStatusString = 'not_started' AND fullmatchdetails.matchStartDateTime > (UNIX_TIMESTAMP(now()) * 1000) ORDER BY matchStartDateTime) AS upcomingMatches WHERE upcomingMatches.isDisabled = 0 LIMIT ?, ?;";
        const matches = await fetchData(matchesQuery, [
          userId,
          userId,
          numberOfMatchesToBeIgnored,
          matchLimit,
        ]);

        this.Matches = matches;

        this.formatMatches(serverAddress, timeZone);

        resolve();
      } catch (error) {
        reject(error);
      }
    });
  }

  userRecentMatches(
    userId,
    numberOfMatchesToBeIgnored = 0,
    matchLimit = 20,
    serverAddress,
    timeZone
  ) {
    return new Promise(async (resolve, reject) => {
      try {
        const matchesQuery =
          "SELECT fullmatchdetails.matchId AS matchId, scorcardDetails.matchResultString, seriesName, seriesDname, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, (SELECT COUNT(DISTINCT userId) FROM userTeamDetails WHERE userTeamDetails.matchId = fullmatchdetails.matchId) AS totalPredictors, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails JOIN scorcardDetails ON scorcardDetails.matchId = fullmatchdetails.matchId WHERE fullmatchdetails.matchStatusString != 'not_started' AND fullmatchdetails.matchId IN (SELECT DISTINCT userTeamDetails.matchId FROM userTeamDetails WHERE userTeamDetails.userId = ? ORDER BY userTeamDetails.creationTime DESC) LIMIT ?, ?;SELECT COUNT(*) AS totalMatches FROM fullmatchdetails WHERE fullmatchdetails.matchStatusString != 'not_started' AND fullmatchdetails.matchId IN (SELECT DISTINCT userTeamDetails.matchId FROM userTeamDetails WHERE userTeamDetails.userId = ? ORDER BY userTeamDetails.creationTime DESC);";

        const [matches, [{ totalMatches }]] = await fetchData(matchesQuery, [
          userId,
          userId,
          userId,
          numberOfMatchesToBeIgnored,
          matchLimit,
          userId,
        ]);

        this.Matches = matches;
        this.TotalResult = totalMatches;
        this.totalPages = Math.ceil(totalMatches / matchLimit);
        this.formatMatches(serverAddress, timeZone);
        resolve();
      } catch (error) {
        reject(error);
      }
    });
  }

  userCurrentMatches(
    userId,
    numberOfMatchesToBeIgnored = 0,
    matchLimit = 20,
    serverAddress,
    timeZone
  ) {
    return new Promise(async (resolve, reject) => {
      try {
        const matchesQuery =
          "SELECT matchId, seriesName, seriesDname, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, (SELECT COUNT(DISTINCT userId) FROM userTeamDetails WHERE userTeamDetails.matchId = fullmatchdetails.matchId) AS totalPredictors, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE fullmatchdetails.matchStatusString = 'not_started' AND fullmatchdetails.matchId IN (SELECT DISTINCT userTeamDetails.matchId FROM userTeamDetails WHERE userTeamDetails.userId = ? ORDER BY userTeamDetails.creationTime DESC) LIMIT ?, ?;SELECT COUNT(*) AS totalMatches FROM fullmatchdetails WHERE fullmatchdetails.matchStatusString = 'not_started' AND fullmatchdetails.matchId IN (SELECT DISTINCT userTeamDetails.matchId FROM userTeamDetails WHERE userTeamDetails.userId = ? ORDER BY userTeamDetails.creationTime DESC);";

        const [matches, [{ totalMatches }]] = await fetchData(matchesQuery, [
          userId,
          userId,
          userId,
          numberOfMatchesToBeIgnored,
          matchLimit,
          userId,
        ]);

        this.Matches = matches;
        this.TotalResult = totalMatches;
        this.totalPages = Math.ceil(totalMatches / matchLimit);
        this.formatMatches(serverAddress, timeZone);
        resolve();
      } catch (error) {
        reject(error);
      }
    });
  }
}

// (async () => {
//   const match = new FetchMatch();
//   await match.userCurrentMatches(
//     1,
//     0,
//     10,
//     "http://localhost:3000",
//     "Asia/Kolkata"
//   );
//   console.log(match.Matches);
// })();

module.exports = FetchMatch;
