const express = require("express");
const router = express.Router();
const Coins = require("../../module/Coins");
const verifyUser = require("../../middleware/verifyUser");

router.post("/transactionHistory", verifyUser, async (req, res, next) => {
  try {
    const newCoins = new Coins(req.body.userId);
    await newCoins.getTransitHistory(req?.params?.filterBy);

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        transactionHistory: newCoins.transationHistory,
      },
    });
  } catch (error) {
    next(error);
  }
});

router.post("/WithdrawlHistory", verifyUser, async (req, res, next) => {
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
    next(error);
  }
});

router.post("/getRedeemTokens", verifyUser, async (req, res, next) => {
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
    next(error);
  }
});

router.post("/transitCoins", verifyUser, async (req, res, next) => {
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
    next(error);
  }
});

router.post("/dailyUserCoins", verifyUser, async (req, res, next) => {
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
    next(error);
  }
});

module.exports = router;
