const User = require("./User");
const { fetchData } = require("../../database/db_connection");

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

module.exports = UserPan;
