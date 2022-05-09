const express = require("express");
const router = express.Router({ mergeParams: true });
const MatchStatistics = require("../module/MatchStatistics");

router.post("/pitchReport", async (req, res) => {
  try {
    const { matchId } = req.body;

    const regx = /[^0-9]/g;

    if (!matchId || regx.test(matchId)) {
      throw new Error("invalid input");
    }

    const MatchStatisticsObject = await new MatchStatistics(
      matchId
    ).getMatchDetails();
    await MatchStatisticsObject.getPitchReport();

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        pitchReport: MatchStatisticsObject.pitchReport,
        competitors: MatchStatisticsObject.competitors,
        players: MatchStatisticsObject.players,
        venue: MatchStatisticsObject.venue,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage || error.message,
      data: {},
    });
  }
});

router.post("/teamComparison", async (req, res) => {
  try {
    const { matchId } = req.body;

    const regx = /[^0-9]/g;

    if (!matchId || regx.test(matchId)) {
      throw new Error("invalid input");
    }

    const MatchStatisticsObject = await new MatchStatistics(
      matchId
    ).getMatchDetails();
    await MatchStatisticsObject.getTeamComparison();

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        teamComparison: MatchStatisticsObject.teamComparison,
        competitors: MatchStatisticsObject.competitors,
        players: MatchStatisticsObject.players,
        venue: MatchStatisticsObject.venue,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage || error.message,
      data: {},
    });
  }
});

router.post("/fantasyPoints", async (req, res) => {
  try {
    const { matchId } = req.body;

    const regx = /[^0-9]/g;

    if (!matchId || regx.test(matchId)) {
      throw new Error("invalid input");
    }

    const MatchStatisticsObject = await new MatchStatistics(
      matchId
    ).getMatchDetails();
    await MatchStatisticsObject.getFantacyPoints();

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        fantasyPoints: MatchStatisticsObject.fantasyPoints,
        competitors: MatchStatisticsObject.competitors,
        players: MatchStatisticsObject.players,
        venue: MatchStatisticsObject.venue,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage || error.message,
      data: {},
    });
  }
});

router.post("/playerPerformance", async (req, res) => {
  try {
    const { matchId } = req.body;

    const regx = /[^0-9]/g;

    if (!matchId || regx.test(matchId)) {
      throw new Error("invalid input");
    }

    const MatchStatisticsObject = await new MatchStatistics(
      matchId
    ).getMatchDetails();
    await MatchStatisticsObject.getPlayerPerformance();

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        playerPerformance: MatchStatisticsObject.playerPerformance,
        competitors: MatchStatisticsObject.competitors,
        players: MatchStatisticsObject.players,
        venue: MatchStatisticsObject.venue,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage || error.message,
      data: {},
    });
  }
});

router.post("/statistics", async (req, res) => {
  try {
    const { matchId } = req.body;

    const regx = /[^0-9]/g;

    if (!matchId || regx.test(matchId)) {
      throw new Error("invalid input");
    }

    const MatchStatisticsObject = await new MatchStatistics(
      matchId
    ).getMatchDetails();
    await MatchStatisticsObject.getStatistics();

    res.status(200).json({
      status: true,

      message: "success",
      data: {
        statistics: MatchStatisticsObject.statistics,
        competitors: MatchStatisticsObject.competitors,
        players: MatchStatisticsObject.players,
        venue: MatchStatisticsObject.venue,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage || error.message,
      data: {},
    });
  }
});

router.post("/lineup", async (req, res) => {
  try {
    const { matchId } = req.body;

    const regx = /[^0-9]/g;

    if (!matchId || regx.test(matchId)) {
      throw new Error("invalid input");
    }

    const MatchStatisticsObject = await new MatchStatistics(
      matchId
    ).getMatchDetails();

    let lineUp = [];
    if (MatchStatisticsObject.matchDetails.isLineUpOut == 1) {
      lineUp = MatchStatisticsObject.players.filter((player) => {
        return player.isLineUpSelected == 1;
      });
    }
    res.status(200).json({
      status: true,
      message: "success",
      data: {
        lineUp,
        competitors: MatchStatisticsObject.competitors,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage || error.message,
      data: {},
    });
  }
});

module.exports = router;
