const { fetchData } = require("../database/db_connection");
class User {
  id = null;
  #userDetails = {
    firstName: "",
    imageStamp: "",
    lastName: "",
    phoneNumber: "",
    email: "",
    dateOfBirth: "",
    gender: "",
    address: "",
    city: "",
    pinCode: "",
    state: "",
    country: "",
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
        matchId: "",
        seriesName: "",
        seriesDname: "",
        matchTypeId: "",
        matchTyprString: "",
        matchStartDateTime: "",
        matchStatus: "",
        matchStatusString: "",
        venue: "",
        displayName: "",
        team1Id: "",
        team1Name: "",
        team1DisplayName: "",
        team2Id: "",
        team2Name: "",
        team2DisplayName: "",
        totalPredictors: "",
        isHeadToHeadCreated: "",
        isMegaContestCreated: "",
      },
    ],
    recentMatches: [
      {
        matchId: "",
        seriesName: "",
        seriesDname: "",
        matchTypeId: "",
        matchTyprString: "",
        matchStartDateTime: "",
        matchStatus: "",
        matchStatusString: "",
        venue: "",
        displayName: "",
        team1Id: "",
        team1Name: "",
        team1DisplayName: "",
        team2Id: "",
        team2Name: "",
        team2DisplayName: "",
        totalPredictors: "",
        isHeadToHeadCreated: "",
        isMegaContestCreated: "",
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

  // not working
  async uploadProfileImage(image) {
    return new Promise(async (resolve, reject) => {
      try {
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  // not working
  async updateUserDetails(userDetails) {
    return new Promise(async (resolve, reject) => {
      try {
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

class UserPan extends User {
  #userPanFullName = "";
  #userPanNumber = "";
  #userDateOfBirth = ""; // YYYY-MM-DD format
  #userPanImage = "";

  constructor(id) {
    super(id);
  }

  async InsertUserPanDetails(
    userPanFullName,
    userPanNumber,
    userDateOfBirth,
    userPanImage
  ) {
    return new Promise(async (resolve, reject) => {
      try {
        this.#userDateOfBirth = userDateOfBirth;
        this.#userPanFullName = userPanFullName;
        this.#userPanNumber = userPanNumber;
        this.#userPanImage = userPanImage;

        if (
          this.#userPanFullName === "" ||
          this.#userPanNumber === "" ||
          this.#userDateOfBirth === "" ||
          this.#userPanImage === ""
        ) {
          throw new Error("Invalid Pan Details");
        }

        const insertUserPanDetailsQuery =
          "INSERT INTO `userPanDetails`(`userId`, `panCardNumber`, `panCardName`, `DateOfBirth`, `panCardImage`) VALUES (?, ?, ?, ?, ?);";

        await fetchData(insertUserPanDetailsQuery, [
          this.id,
          this.#userPanNumber,
          this.#userPanFullName,
          this.#userDateOfBirth,
          this.#userPanImage,
        ]);

        resolve();
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  async fetchUserPanDetails() {
    return new Promise(async (resolve, reject) => {
      try {
        const userPanDetailsQuery =
          "SELECT panCardNumber, panCardName, DateOfBirth, panCardImage FROM userPanDetails WHERE userId = ?;";

        const [userPanDetails] = await fetchData(userPanDetailsQuery, [
          this.id,
        ]);

        if (userPanDetails) {
          this.#userPanFullName = userPanDetails.panCardName;
          this.#userPanNumber = userPanDetails.panCardNumber;
          this.#userDateOfBirth = userPanDetails.DateOfBirth;
          this.#userPanImage = userPanDetails.panCardImage;
          resolve();
        }
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }
}

class UserBank extends User {
  #userBankName = "";
  #userBankAccountNumber = "";
  #userBankIFSC = "";
  #userFullName = "";
  #userUPI = ""; //optionak
  #userBankProofImage = "";

  constructor(id) {
    super(id);
  }

  async InsertUserBankDetails(
    userBankName,
    userBankAccountNumber,
    userBankIFSC,
    userFullName,
    userUPI,
    userBankProofImage
  ) {
    return new Promise(async (resolve, reject) => {
      try {
        this.#userBankName = userBankName;
        this.#userBankAccountNumber = userBankAccountNumber;
        this.#userBankIFSC = userBankIFSC;
        this.#userFullName = userFullName;
        this.#userUPI = userUPI;
        this.#userBankProofImage = userBankProofImage;

        if (
          this.#userBankName === "" ||
          this.#userBankAccountNumber === "" ||
          this.#userBankIFSC === "" ||
          this.#userFullName === "" ||
          this.#userBankProofImage === ""
        ) {
          throw new Error("Please fill all the details");
        }

        const insertUserBankDetailsQuery =
          "INSERT INTO `userBankDetails`(`userId`, `bankName`, `AccountNumber`, `IFSCCode`, `UPIId`, `bankProof`) VALUES (?, ?, ?, ?, ?, ?);";

        await fetchData(insertUserBankDetailsQuery, [
          this.id,
          this.#userBankName,
          this.#userBankAccountNumber,
          this.#userBankIFSC,
          this.#userUPI,
          this.#userBankProofImage,
        ]);
        resolve();
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  async fetchUserBankDetails() {
    return new Promise(async (resolve, reject) => {
      try {
        const userBankDetailsQuery =
          "SELECT bankName, AccountNumber, IFSCCode, UPIId, bankProof FROM userBankDetails WHERE userId = ?;";

        const [userBankDetails] = await fetchData(userBankDetailsQuery, [
          this.id,
        ]);

        if (userBankDetails) {
          this.#userBankName = userBankDetails.bankName;
          this.#userBankAccountNumber = userBankDetails.AccountNumber;
          this.#userBankIFSC = userBankDetails.IFSCCode;
          this.#userUPI = userBankDetails.UPI;
          this.#userBankProofImage = userBankDetails.bankProof;
          resolve();
        }
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }
}

module.exports = {
  User,
  UserPan,
  UserBank,
};
