const User = require("./User/User");
const { fetchData } = require("../database/db_connection");

class Coins extends User {
  coinSources = [];
  withdrawalHistory = [];
  transationHistory = [];
  coinsToBalanceMapping = [];

  constructor(id) {
    super(id);
  }

  async getCoins() {
    return new Promise(async (resolve, reject) => {
      try {
        const coins = await fetchData(
          `SELECT coins FROM userdetails WHERE userId = ?;`,
          [this.id]
        );
        this.userDetails.coins = coins[0].coins;
        resolve();
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  async getCoinSources() {
    return new Promise(async (resolve, reject) => {
      try {
        const sources = await fetchData(
          "SELECT `sourceId`, `sourceName`, `defaulteCoins`, `operation` FROM `coinTransitSource`;"
        );
        this.coinSources = sources;
        resolve();
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  async transitCoins(coins, coinTransitsource) {
    return new Promise(async (resolve, reject) => {
      try {
        const source = this.coinSources.find(
          (source) => source.sourceName === coinTransitsource
        );
        if (source.defaulteCoins) {
          coins = 0;
        }
        const coinsTransit = await fetchData(`CALL transitCoins(?, ?, ?);`, [
          this.id,
          coins,
          source.sourceId,
        ]);
        resolve(coinsTransit);
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  async getWithdrawalHistory() {
    return new Promise(async (resolve, reject) => {
      try {
        const withdrawalHistory = await fetchData(
          "SELECT transactionId, transitedBalance, userId, transitionSource, message, balanceSource.sourceName, logTime FROM balanceHistory JOIN balanceSource ON balanceSource.sourceId = balanceHistory.transitionSource WHERE userId = ?;",
          [this.id]
        );
        withdrawalHistory.forEach((withdrawal) => {
          withdrawal.credit =
            withdrawal.transitedBalance > 0
              ? withdrawal.transitedBalance
              : null;
          withdrawal.debit =
            withdrawal.transitedBalance < 0
              ? withdrawal.transitedBalance
              : null;
          withdrawal.transitedBalance = transitedBalance.toString();
        });
        this.withdrawalHistory = withdrawalHistory;
        resolve();
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  async getTransitHistory() {
    return new Promise(async (resolve, reject) => {
      try {
        const transationHistory = await fetchData(
          "SELECT transactionId, spendedCoints, userId, coinHistory.spendSource, message, coinTransitSource.sourceName, timeZone FROM `coinHistory` JOIN coinTransitSource ON coinTransitSource.sourceId = coinHistory.spendSource WHERE userId = ?;",
          [this.id]
        );
        transationHistory.forEach((transaction) => {
          transaction.credit =
            transaction.spendedCoins > 0 ? transaction.spendedCoins : null;
          transaction.debit =
            transaction.spendedCoins < 0 ? transaction.spendedCoins : null;
          transaction.spendedCoins = spendedCoins.toString();
        });
        this.transationHistory = transationHistory;
        resolve();
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  async getCoinsToBalanceMapping() {
    return new Promise(async (resolve, reject) => {
      try {
        const coinsToBalanceMapping = await fetchData(
          "SELECT `coins`, `reward` FROM `coinsRewardsMapping`;"
        );
        if (!isNaN(this.userDetails.coins)) {
          await this.getCoins();
        }
        coinsToBalanceMapping.forEach((coinBalanceMap) => {
          coinBalanceMap.isDisabled =
            this.userDetails.coins < coinBalanceMap.coins;
        });
        this.coinsToBalanceMapping = coinsToBalanceMapping;
        resolve();
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }
}

module.exports = Coins;
