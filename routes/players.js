const express = require("express");
const router = express.Router();
const verifyUser = require("../middleware/verifyUser");
const { fetchData, imageUrl } = require("../database/db_connection");

// get players by match id
router.post("/getplayers", async (req, res) => {
  const { matchId, userTeamId } = req.body;

  try {
    if (!/[^0-9]/g.test(matchId)) {
      let data;
      if (userTeamId && !/[^0-9]/g.test(userTeamId) && userTeamId > 0) {
        [data] = await fetchData("CALL get_players(?, ?);", [
          matchId,
          userTeamId,
        ]);
      } else {
        [data] = await fetchData("CALL get_players(?, ?);", [matchId, 0]);
      }
      const serverAddress = `${req.protocol}://${req.headers.host}`;

      data?.forEach((player) => {
        player.captainBy = parseFloat(player.captainBy.toFixed(2));
        player.viceCaptainBy = parseFloat(player.viceCaptainBy.toFixed(2));
        player.selectedBy = parseFloat(player.selectedBy.toFixed(2));
        // changing url address
        player.URL = imageUrl(
          __dirname,
          "../",
          `/public/images/players/profilePicture/${player.playerId}.jpg`,
          serverAddress
        );
      });
      res.status(200).json({
        status: true,
        message: "success",
        data: {
          players: data,
        },
      });
    } else {
      throw { message: "invalid input" };
    }
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage ? error.sqlMessage : error.message,
      data: {},
    });
  }
});

// set team of matchId, userId, teamType
router.post("/setteam", verifyUser, async (req, res) => {
  const {
    userTeamType,
    matchId,
    players,
    captain,
    viceCaptain,
    userId,
    userTeamId,
  } = req.body;

  try {
    const regx = /[^0-9]/g;
    let correctInput = true;
    [userTeamType, matchId, ...players, captain, viceCaptain].forEach((id) => {
      if (regx.test(id)) {
        correctInput = false;
      }
    });
    if (players.length === 11 && correctInput) {
      let data;
      if (userTeamId && !/[^0-9]/g.test(userTeamId) && userTeamId > 0) {
        data = await fetchData("CALL set_team(?, ?, ?, ?, ?, ?,?)", [
          userTeamType,
          matchId,
          userId,
          captain,
          viceCaptain,
          userTeamId,
          [...players],
        ]);
      } else {
        data = await fetchData("CALL set_team(?, ?, ?, ?, ?, ?,?)", [
          userTeamType,
          matchId,
          userId,
          captain,
          viceCaptain,
          0,
          [...players],
        ]);
      }
      if (data[0][0].message === "success") {
        res.status(200).json({
          status: true,
          message: "success",
          data: {},
        });
      }
    } else {
      throw { message: "invalid input" };
    }
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.sqlMessage ? error.sqlMessage : error.message,
      data: {},
    });
  }
});

// exporting module
module.exports = router;
