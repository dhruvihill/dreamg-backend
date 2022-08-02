const User = require("./User/User");
const { fetchData } = require("../database/db_connection");
const { convertTimeZone } = require("../middleware/convertTimeZone");
const { prisma } = require("../utils");

class Coins extends User {
  coinSources = [];
  withdrawalHistory = [];
  transationHistory = [];
  coinsToBalanceMapping = [];
  isTodaysCoinsRewarded = 0;

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

  async transitCoins(coinTransitsource, mappingId, teamId) {
    return new Promise(async (resolve, reject) => {
      try {
        if (!this.coinSources.length > 0) {
          await this.getCoinSources();
        }
        const source = this.coinSources.find(
          (source) => source.sourceName === coinTransitsource
        );
        if (!source) {
          throw new Error("Invalid Source to transit coins");
        }
        await fetchData(`CALL transitCoins(?, ?, ?, ?);`, [
          this.id,
          mappingId || 0,
          source.sourceName,
          teamId || 0,
        ]);
        await this.getCoins();
        resolve();
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  async getWithdrawalHistory(filterBy) {
    return new Promise(async (resolve, reject) => {
      try {
        const withdrawalHistory = await fetchData(
          "SELECT transactionId, transitedBalance, userId, transitionSource, REPLACE(message, '{{money}}', transitedBalance) AS message, balanceSource.sourceName, logTime FROM balanceHistory JOIN balanceSource ON balanceSource.sourceId = balanceHistory.transitionSource WHERE userId = ? AND operation IN (?) ORDER BY logTime;",
          [
            this.id,
            filterBy
              ? filterBy === "CREDIT"
                ? "+"
                : filterBy === "DEBIT"
                ? "-"
                : ["+", "-"]
              : ["+", "-"],
          ]
        );
        withdrawalHistory.forEach((withdrawal) => {
          withdrawal.credit =
            withdrawal.transitedBalance > 0 ? withdrawal.transitedBalance : 0;
          withdrawal.debit =
            withdrawal.transitedBalance < 0 ? withdrawal.transitedBalance : 0;
          withdrawal.transitedBalance = withdrawal.transitedBalance.toString();
        });
        this.withdrawalHistory = withdrawalHistory;
        resolve();
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  async getTransitHistory(filterBy) {
    return new Promise(async (resolve, reject) => {
      try {
        const transationHistory = await prisma.coinHistory.findMany({
          where: {
            userId: this.id,
            coinTransitSource: {
              operation: {
                in: filterBy
                  ? filterBy === "CREDIT"
                    ? ["+"]
                    : ["-"]
                  : ["+", "-"],
              },
            },
          },
          include: {
            coinTransitSource: true,
          },
          orderBy: {
            timeZone: "desc",
          },
        });

        transationHistory.forEach((transaction) => {
          transaction.credit =
            transaction.spendedCoins > 0 ? transaction.spendedCoins : 0;
          transaction.debit =
            transaction.spendedCoins < 0
              ? Math.abs(transaction.spendedCoins)
              : 0;
          transaction.spendedCoins = transaction.spendedCoins.toString();
          transaction.coinTransitSource.message =
            transaction?.coinTransitSource?.message?.replace(
              "{{coins}}",
              Math.abs(transaction?.spendedCoins)
            );
          [transaction.timeZone, transaction.timeZoneMilliSeconds] =
            convertTimeZone(transaction.timeZone);
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
          "SELECT mappingId, `coins`, `reward` FROM `coinsRewardsMapping`;"
        );
        if (isNaN(this.userDetails.coins)) {
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

  async dashBoardCoinData() {
    return new Promise(async (resolve, reject) => {
      try {
        if (isNaN(this?.userDetails?.coins)) {
          await this.getCoins();
        }
        const [dailyRewardDetails] = await fetchData(
          "SELECT incrementBy, IF(DATEDIFF(coinHistory.timeZone, NOW()) = 0, 1, 0) AS isToday, IF(DATEDIFF(coinHistory.timeZone, NOW()) = -1, 1, 0) AS isYesterday, coinHistory.dayNumber FROM coinTransitSource LEFT JOIN coinHistory ON coinHistory.spendSource = coinTransitSource.sourceId AND coinHistory.userId = ? WHERE sourceName = 'DAILY_APP_OPEN' ORDER BY timeZone DESC LIMIT 1;",
          [this.id]
        );
        const dailyRewardSticker = [];

        for (let index = 1; index <= 7; index++) {
          let isThisDaysCoinCollected = 0;
          let isThisDaysCoinRemainsToCollect = 0;
          let isCoinCollectedToday = 0;
          if (
            dailyRewardDetails.isToday ||
            (dailyRewardDetails.isYesterday &&
              dailyRewardDetails.dayNumber != 7)
          ) {
            if (dailyRewardDetails.isToday) {
              if (index <= dailyRewardDetails.dayNumber) {
                isThisDaysCoinCollected = 1;
                if (index === dailyRewardDetails.dayNumber) {
                  isCoinCollectedToday = 1;
                }
              }
            } else if (dailyRewardDetails.isYesterday) {
              if (index <= dailyRewardDetails.dayNumber) {
                isThisDaysCoinCollected = 1;
              } else if (index === dailyRewardDetails.dayNumber + 1) {
                isThisDaysCoinRemainsToCollect = 1;
              }
            }
          } else {
            if (index === 1) {
              isThisDaysCoinRemainsToCollect = 1;
            }
          }
          dailyRewardSticker.push({
            reward: dailyRewardDetails.incrementBy * index,
            day: index,
            isThisDaysCoinCollected,
            isThisDaysCoinRemainsToCollect,
            isCoinCollectedToday,
          });
        }
        resolve(dailyRewardSticker);
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }
}

// (async () => {
//   const newUser = new Coins(1);
//   await newUser.dashBoardCoinData();
// })();

module.exports = Coins;
