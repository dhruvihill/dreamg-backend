const { fetchData, imageUrl } = require("../../database/db_connection");
const { rename, writeFile } = require("fs/promises");
const { existsSync, mkdirSync } = require("fs");
const { convertTimeZone } = require("../../middleware/convertTimeZone");
const path = require("path");
const jwt = require("jsonwebtoken");
const { NotFoundError } = require("../Exception/index");
const { prisma } = require("../../utils/index");

class User {
  id = null;
  userDetails = {
    firstName: "",
    imageStamp: "",
    lastName: "",
    phoneNumber: "",
    email: "",
    dateOfBirth: 0, // milliseconds
    gender: "",
    address: "",
    city: "",
    pinCode: "",
    state: "",
    country: "",
    displayPicture: "",
  };
  userApplications = {};
  applicationStatus = [];
  userPointsDetails = {
    totalMatches: 0,
    totalTeams: 0,
    mega_contest_totalPoints: 0,
    head_to_head_totalPoints: 0,
  };
  userMatchDetails = {
    currentMatch: [],
    recentMatches: [],
  };

  constructor(id) {
    this.id = id;
  }

  // AUTHENTICATION
  async LoginUser(phoneNumber) {
    return new Promise(async (resolve, reject) => {
      try {
        const user = await prisma.users.findUnique({
          where: {
            phoneNumber,
          },
          select: {
            userId: true,
            phoneNumber: true,
            firstName: true,
            lastName: true,
          },
        });

        if (!user) {
          throw new NotFoundError("User not found");
        }

        this.id = user.userId;
        // creating auth token
        const jwtData = {
          user: {
            userId: this.id,
          },
        };
        const token = await jwt.sign(jwtData, process.env.JWT_SECRET_KEY);
        this.userDetails = { ...this.userDetails, ...user };

        user.authToken = token;
        resolve(user);
      } catch (error) {
        reject(error);
      }
    });
  }

  async RegisterUser(phoneNumber) {
    return new Promise(async (resolve, reject) => {
      try {
        const user = await prisma.users.create({
          data: {
            phoneNumber,
          },
        });

        // creating auth token
        const jwtData = { user: { userId: user.userId } };
        const token = await jwt.sign(jwtData, process.env.JWT_SECRET_KEY);

        this.id = user.userId;
        resolve({
          userId: user.userId,
          token,
        });
      } catch (error) {
        reject(error);
      }
    });
  }

  async CheckUser(phoneNumber) {
    return new Promise(async (resolve, reject) => {
      try {
        const user = await prisma.users.findUnique({
          where: {
            phoneNumber,
          },
          select: {
            userId: true,
          },
        });

        if (!user) {
          throw new NotFoundError("User not found");
        }

        this.id = user.userId;
        resolve();
      } catch (error) {
        reject(error);
      }
    });
  }

  // USER DETAILS
  async fetchUserDetails(serverAddress) {
    return new Promise(async (resolve, reject) => {
      try {
        const userDetailsQuery = `SELECT userdetails.firstName, userdetails.balance, userdetails.imageStamp, userdetails.lastName, userdetails.phoneNumber, userdetails.email, userdetails.dateOfBirth, userdetails.gender, userdetails.address, userdetails.city, userdetails.pinCode, userdetails.state, userdetails.country, userdetails.coins FROM userdetails WHERE userdetails.userId = ?;`;

        const [userDetails] = await fetchData(userDetailsQuery, [this.id]);

        if (userDetails) {
          // userDetails.dateOfBirth
          const dateArray = userDetails.dateOfBirth.split("/");
          if (dateArray.length === 3) {
            userDetails.dateOfBirth = new Date(
              dateArray[0],
              dateArray[1],
              dateArray[2]
            ).getTime();
          } else {
            userDetails.dateOfBirth = 0;
          }
          this.userDetails = userDetails;
          this.userDetails.displayPicture = imageUrl(
            __dirname,
            "../",
            `${process.env.USER_IMAGE_URL}${this.userDetails.imageStamp}.jpg`,
            serverAddress
          );
          resolve();
        } else {
          throw { message: "user does not exists" };
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
        const user = {
          userId: this.id,
          time: new Date().getTime(),
        };
        const newImageStamp = btoa(JSON.stringify(user));

        const [[{ imageStamp }], imageStampSet] = await fetchData(
          "SELECT imageStamp FROM userdetails WHERE userdetails.userId = ?;UPDATE users SET imageStamp = ? WHERE users.userId = ?;",
          [this.id, newImageStamp, this.id]
        );

        if (
          !existsSync(
            path.join(__dirname, "../../", `${process.env.USER_IMAGE_URL}`)
          )
        ) {
          mkdirSync(
            path.join(__dirname, "../../", `${process.env.USER_IMAGE_URL}`)
          );
        }

        if (
          !existsSync(
            path.join(__dirname, "../../", `${process.env.OLD_USER_IMAGE_URL}`)
          )
        ) {
          mkdirSync(
            path.join(__dirname, "../../", `${process.env.OLD_USER_IMAGE_URL}`)
          );
        }

        if (
          imageStamp &&
          existsSync(
            path.join(
              __dirname,
              "../../",
              process.env.USER_IMAGE_URL + imageStamp + ".jpg"
            )
          )
        ) {
          rename(
            path.join(
              __dirname,
              "../../",
              process.env.USER_IMAGE_URL + imageStamp + ".jpg"
            ),
            path.join(
              __dirname,
              "../../",
              process.env.OLD_USER_IMAGE_URL + imageStamp + ".jpg"
            )
          );
        }

        if (imageStampSet.affectedRows > 0) {
          await writeFile(
            path.join(
              __dirname,
              "../",
              `..${process.env.USER_IMAGE_URL}${newImageStamp}.jpg`
            ),
            image
          );
          this.userDetails.imageStamp = newImageStamp;
          resolve();
        } else {
          throw { message: "some error occured" };
        }
      } catch (error) {
        console.log(error.message);
        reject(new Error("some error occured"));
      }
    });
  }

  async updateUserDetails(userDetails) {
    return new Promise(async (resolve, reject) => {
      try {
        let keys = [],
          values = [];
        for (const key in userDetails) {
          if (key !== "userId") {
            keys.push(`${key} = ?`);
            values.push(userDetails[key]);
          }
        }
        const updateUserQuery = `UPDATE users SET ${keys.join(
          ","
        )} WHERE userId = ?;`;
        const updateUserResponse = await fetchData(updateUserQuery, [
          ...values,
          this.id,
        ]);
        if (updateUserResponse.affectedRows > 0) {
          this.userDetails = {
            ...this.userDetails,
            ...userDetails,
          };
          this.fetchUserPointDetails();
          resolve(this.userPointsDetails, this.userDetails);
        } else {
          throw { message: "user does not exists" };
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
          this.userPointsDetails = userPointsDetails;
          resolve();
        }
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  async fetchUserApplications() {
    return new Promise(async (resolve, reject) => {
      try {
        const userApplicationsQuery =
          'SELECT * FROM userApplicationStatus; SELECT COALESCE(userPanDetails.status, 0) AS panStatus, COALESCE(userPanDetails.panCardNumber, "") AS userPanCardNumber, COALESCE(userPanDetails.message, "") AS panErrorMessage, COALESCE(userBankDetails.status, 0) AS bankStatus, COALESCE(userBankDetails.AccountNumber, "") AS userBankAccountNumber, COALESCE(userBankDetails.message, "") AS bankErrorMessage, COALESCE(userEmailDetails.status, 0) AS emailStatus, COALESCE(userdetails.email, "") AS userEmail, COALESCE(userEmailDetails.message, "") AS emailErrorMessage FROM `userdetails` LEFT JOIN userPanDetails ON userPanDetails.userId = userdetails.userId LEFT JOIN userBankDetails ON userBankDetails.userId = userdetails.userId LEFT JOIN userEmailDetails ON userEmailDetails.userId = userdetails.userId WHERE userdetails.userId = ?;';
        const [userApplicationStatus, [userApplications]] = await fetchData(
          userApplicationsQuery,
          [this.id]
        );
        if (userApplications && userApplicationStatus) {
          userApplications.panStatus =
            userApplications.panStatus == 0
              ? "NOT_APPLIED"
              : userApplicationStatus.find(
                  (uap) => uap.id == userApplications.panStatus
                ).string;
          userApplications.bankStatus =
            userApplications.bankStatus == 0
              ? "NOT_APPLIED"
              : userApplicationStatus.find(
                  (uap) => uap.id == userApplications.bankStatus
                ).string;
          userApplications.emailStatus =
            userApplications.emailStatus == 0
              ? "NOT_APPLIED"
              : userApplicationStatus.find(
                  (uap) => uap.id == userApplications.emailStatus
                ).string;
          this.userApplications = userApplications;
          this.applicationStatus = userApplicationStatus;
          resolve();
        } else {
          throw { message: "user does not exists" };
        }
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  async fetchUserMatchesDetails(
    serverAddress,
    timeZone,
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
            ...Array(3).fill(this.id),
            matchesToBeIgnored,
            numberOfMatchesToBeFetched,
            ...Array(3).fill(this.id),
            matchesToBeIgnored,
            numberOfMatchesToBeFetched,
          ]
        );

        if (recentMatches && currentMatch) {
          recentMatches.forEach(async (match) => {
            if (match.matchStatusString === "not_started") {
              match.matchStatusString = "UPCOMING";
            } else if (match.matchStatusString === "live") {
              match.matchStatusString = "LIVE";
            } else if (
              match.matchStatusString === "ended" ||
              match.matchStatusString === "closed"
            ) {
              match.matchStatusString = "RECENT";
            } else if (match.matchStatusString === "cancelled") {
              match.matchStatusString = "CANCELED";
            }
            match.remainingMatchStartTime = (
              parseInt(match.matchStartTimeMilliSeconds) - Date.now()
            ).toString();
            // converting time zone
            [match.matchStartDateTime, match.matchStartTimeMilliSeconds] =
              convertTimeZone(match.matchStartDateTime, timeZone);

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
          currentMatch.forEach((match) => {
            if (match.matchStatusString === "not_started") {
              match.matchStatusString = "UPCOMING";
            } else if (match.matchStatusString === "live") {
              match.matchStatusString = "LIVE";
            } else if (
              match.matchStatusString === "ended" ||
              match.matchStatusString === "closed"
            ) {
              match.matchStatusString = "RECENT";
            } else if (match.matchStatusString === "cancelled") {
              match.matchStatusString = "CANCELED";
            }
            match.remainingMatchStartTime = (
              parseInt(match.matchStartTimeMilliSeconds) - Date.now()
            ).toString();
            // converting time zone
            [match.matchStartDateTime, match.matchStartTimeMilliSeconds] =
              convertTimeZone(match.matchStartDateTime, timeZone);

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
          this.userMatchDetails.currentMatch = currentMatch;
          this.userMatchDetails.recentMatches = recentMatches;
          resolve();
        }
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }
}

module.exports = User;
