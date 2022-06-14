const express = require("express");
const router = express.Router();
const Coins = require("../module/Coins");
const verifyUser = require("../middleware/verifyUser");

router.post("/transactionHistory", verifyUser, async (req, res) => {
  try {
    const newCoins = new Coins(req.body.userId);
    await newCoins.getTransitHistory(
      req.body.filterBy,
      req.body.orderBy,
      req.body.orderType
    );

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        transactionHistory: newCoins.transationHistory,
      },
    });
  } catch (error) {
    res.status(200).json({
      status: false,
      message: error.message,
      data: {},
    });
  }
});

router.post("/WithdrawlHistory", verifyUser, async (req, res) => {
  try {
    const newCoins = new Coins(req.body.userId);
    await newCoins.getWithdrawalHistory(req.body.filterBy);

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        withdrawlHistory: newCoins.withdrawalHistory,
      },
    });
  } catch (error) {
    res.status(200).json({
      status: false,
      message: error.message,
      data: {},
    });
  }
});

router.post("/getReedemTokens", verifyUser, async (req, res) => {
  try {
    const newCoins = new Coins(req.body.userId);
    await newCoins.getCoinsToBalanceMapping();

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        tokens: newCoins.coinsToBalanceMapping,
        coins: newCoins.userDetails.coins,
      },
    });
  } catch (error) {
    res.status(200).json({
      status: false,
      message: error.message,
      data: {},
    });
  }
});

router.post("/transitCoins", verifyUser, async (req, res) => {
  try {
    const { coinTransitsource, mappingId, userId } = req.body;

    const newCoins = new Coins(userId);
    await newCoins.transitCoins(coinTransitsource, mappingId);

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        status: "suceess",
      },
    });
  } catch (error) {
    res.status(200).json({
      status: false,
      message: error.message,
      data: {},
    });
  }
});

router.post("/dailyUserCoins", verifyUser, async (req, res) => {
  try {
    const newCoins = new Coins(req.body.userId);
    const dailyRewardSticker = await newCoins.dashBoardCoinData();

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        coins: newCoins.userDetails.coins,
        dailyRewardSticker,
      },
    });
  } catch (error) {
    res.status(200).json({
      status: false,
      message: error.message,
      data: {},
    });
  }
});

module.exports = router;
