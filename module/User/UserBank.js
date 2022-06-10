const User = require("./User");
const { fetchData } = require("../../database/db_connection");

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

module.exports = UserBank;
