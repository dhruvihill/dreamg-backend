const { fetchData } = require("../database/db_connection");

class User {
  id = 0;
  #userDetails = {
    firstName,
    imageStamp,
    lastName,
    phoneNumber,
    email,
    dateOfBirth,
    gender,
    address,
    city,
    pinCode,
    state,
    country,
  };
  #userPointsDetails = {
    totalMatches: 0,
    totalTeams: 0,
    mega_contest_totalPoints: 0,
    head_to_head_totalPoints: 0,
  };
  #userMatchDetails = {
    currentMatch: [
      {
        matchId,
        seriesName,
        seriesDname,
        matchTypeId,
        matchTyprString,
        matchStartDateTime,
        matchStatus,
        matchStatusString,
        venue,
        displayName,
        team1Id,
        team1Name,
        team1DisplayName,
        team2Id,
        team2Name,
        team2DisplayName,
        totalPredictors,
        isHeadToHeadCreated,
        isMegaContestCreated,
      },
    ],
    recentMatches: [
      {
        matchId,
        seriesName,
        seriesDname,
        matchTypeId,
        matchTyprString,
        matchStartDateTime,
        matchStatus,
        matchStatusString,
        venue,
        displayName,
        team1Id,
        team1Name,
        team1DisplayName,
        team2Id,
        team2Name,
        team2DisplayName,
        totalPredictors,
        isHeadToHeadCreated,
        isMegaContestCreated,
      },
    ],
  };

  constructor(id) {
    this.id = id;
  }

  async fetchUserDetails() {
    return new Promise(async (resolve, reject) => {
      try {
        const userDetailsQuery = `SELECT userdetails.firstName, userdetails.imageStamp, userdetails.lastName, userdetails.phoneNumber, userdetails.email, userdetails.dateOfBirth, userdetails.gender, userdetails.address, userdetails.city, userdetails.pinCode, userdetails.state, userdetails.country FROM userdetails WHERE userdetails.userId = ?;`;

        const [userDetails] = await fetchData(userDetailsQuery, [this.id]);

        if (userDetails) {
          this.#userDetails = userDetails;
          resolve();
        }
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  async fetchUserPointDetails() {
    return new Promise(async (resolve, reject) => {
      try {
        const userPointsDetailsQuery = `SELECT COUNT(DISTINCT matchId) AS totalMatches, COUNT(DISTINCT userTeamId) AS totalTeams, COALESCE(SUM(IF(userTeamDetails.teamTypeString = "MEGA_CONTEST" ,userTeamDetails.userTeamPoints, 0)), 0) AS mega_contest_totalPoints,COALESCE(SUM(IF(userTeamDetails.teamTypeString = "HEAD_TO_HEAD", userTeamDetails.userTeamPoints, 0)), 0) AS head_to_head_totalPoints FROM userTeamDetails WHERE userTeamDetails.userId = ?;`;

        const [userPointsDetails] = await fetchData(userPointsDetailsQuery, [
          this.id,
        ]);

        if (userPointsDetails) {
          this.#userPointsDetails = userPointsDetails;
          resolve();
        }
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  async uploadProfileImage(image) {
    return new Promise(async (resolve, reject) => {
      try {
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  async updateUserDetails(userDetails) {
    return new Promise(async (resolve, reject) => {
      try {
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  async fetchUserPanDetails() {
    return new Promise(async (resolve, reject) => {
      try {
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  async fetchUserBankDetails() {
    return new Promise(async (resolve, reject) => {
      try {
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  async fetchUserMatchesDetails(
    matchesToBeIgnored = 0,
    numberOfMatchesToBeFetched = 5
  ) {
    return new Promise(async (resolve, reject) => {
      try {
        const recentMatchesQuery =
          "SELECT matchId, seriesName, seriesDname, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, (SELECT COUNT(DISTINCT userId) FROM userTeamDetails WHERE userTeamDetails.matchId = fullmatchdetails.matchId) AS totalPredictors, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE fullmatchdetails.matchStatusString != 'not_started' AND fullmatchdetails.matchId IN (SELECT DISTINCT userTeamDetails.matchId FROM userTeamDetails WHERE userTeamDetails.userId = ? ORDER BY userTeamDetails.creationTime DESC) LIMIT ?, ?;";

        const currentMatchQuery =
          "SELECT matchId, seriesName, seriesDname, matchTypeId, UPPER(matchTyprString) AS matchTyprString, matchStartDateTime, matchStatus, matchStatusString, venue, displayName, team1Id, team1Name, team1DisplayName, team2Id, team2Name, team2DisplayName, (SELECT COUNT(DISTINCT userId) FROM userTeamDetails WHERE userTeamDetails.matchId = fullmatchdetails.matchId) AS totalPredictors, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'HEAD_TO_HEAD') AS isHeadToHeadCreated, EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userId = ? AND userTeamDetails.matchId = fullmatchdetails.matchId AND userTeamDetails.teamTypeString = 'MEGA_CONTEST') AS isMegaContestCreated FROM fullmatchdetails WHERE fullmatchdetails.matchStatusString = 'not_started' AND fullmatchdetails.matchId IN (SELECT DISTINCT userTeamDetails.matchId FROM userTeamDetails WHERE userTeamDetails.userId = ? ORDER BY userTeamDetails.creationTime DESC) LIMIT ?, ?;";

        const [recentMatches, currentMatch] = await fetchData(
          `${recentMatchesQuery}${currentMatchQuery}`,
          [
            Array(3).fill(this.id),
            matchesToBeIgnored,
            numberOfMatchesToBeFetched,
            Array(3).fill(this.id),
            matchesToBeIgnored,
            numberOfMatchesToBeFetched,
          ]
        );

        if (recentMatches && currentMatch) {
          this.#userMatchDetails.currentMatch = currentMatch;
          this.#userMatchDetails.recentMatches = recentMatches;
          resolve();
        }
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }
}
