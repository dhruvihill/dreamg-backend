const axios = require("axios");
require("dotenv/config");
const { connectToDb, database, makeRequest } = require("./makeRequest");

const storeBattingStyle = async (battingStyle, connection) => {
  return new Promise(async (resolve) => {
    try {
      if (battingStyle) {
        let [{ isExists: isStyleExist, styleId }] = await database(
          "SELECT COUNT(player_batting_style.playerBattingStyleId) As isExists, player_batting_style.playerBattingStyleId AS styleId FROM `player_batting_style` WHERE player_batting_style.battingStyleString = ?;",
          [battingStyle],
          connection
        );
        if (!isStyleExist) {
          const storeStyle = await database(
            "INSERT INTO player_batting_style SET ?;",
            { battingStyleString: battingStyle },
            connection
          );
          resolve(storeStyle.insertId);
        } else {
          resolve(styleId);
        }
      } else {
        resolve(null);
      }
    } catch (error) {
      console.log(error.message, "storeBattingStyle");
    }
  });
};

const storeBowlingStyle = async (bowlingStyle, connection) => {
  return new Promise(async (resolve) => {
    try {
      if (bowlingStyle) {
        let [{ isExists: isStyleExist, styleId }] = await database(
          "SELECT COUNT(player_bowling_style.playerBowlingStyleId) As isExists, player_bowling_style.playerBowlingStyleId AS styleId FROM `player_bowling_style` WHERE player_bowling_style.playerBowlingStyleString = ?;",
          [bowlingStyle],
          connection
        );
        if (!isStyleExist) {
          const storeStyle = await database(
            "INSERT INTO player_bowling_style SET ?;",
            { playerBowlingStyleString: bowlingStyle },
            connection
          );
          resolve(storeStyle.insertId);
        } else {
          resolve(styleId);
        }
      } else {
        resolve(null);
      }
    } catch (error) {
      console.log(error.message, "storeBattingStyle");
    }
  });
};

const storePlayerStyle = async (player, connection) => {
  return new Promise(async (resolve) => {
    try {
      const battingStyleId = await storeBattingStyle(
        player.batting_style,
        connection
      );
      const bowlingStyleId = await storeBowlingStyle(
        player.bowling_style,
        connection
      );

      const updatePlayer = await database(
        "UPDATE players SET playerBattingStyleId = ?, playerBowlingStyleId = ? WHERE playerRadarId = ?;",
        [battingStyleId, bowlingStyleId, player.id.substr(10)],
        connection
      );
      if (updatePlayer.affectedRows) {
        resolve(true);
      } else {
        resolve(false);
      }
    } catch (error) {
      console.log(error.message, "storePlayerStyle");
    }
  });
};

const storeSinglePlayerDb = (player, storedPlayerId, connection) => {
  return new Promise(async (resolve) => {
    try {
      let statsCount = 0;
      const totalStats = player.statistics.tournaments.length;
      const storeSingleState = async (statistics) => {
        const storeStatisticsBatting = await database(
          "INSERT INTO player_statistics_batting SET ?;",
          {
            playerId: storedPlayerId,
            type: statistics.type,
            matches: statistics.batting.matches,
            innings: statistics.batting.innings,
            notOuts: statistics.batting.not_outs,
            runs: statistics.batting.runs,
            highestScore: statistics.batting.highest_score,
            average: statistics.batting.average,
            hundreds: statistics.batting.hundreds,
            fifties: statistics.batting.fifties,
            fours: statistics.batting.fours,
            sixes: statistics.batting.sixes,
            strikeRate: statistics.batting.strike_rate,
            ballFaced: statistics.batting.balls_faced,
          },
          connection
        );
        const storeStatisticsBowling = await database(
          "INSERT INTO player_statistics_bowling SET ?;",
          {
            playerId: storedPlayerId,
            type: statistics.type,
            matches: statistics.bowling.matches,
            innings: statistics.bowling.innings,
            overs: statistics.bowling.overs,
            maidens: statistics.bowling.maidens,
            runs: statistics.bowling.runs,
            wickets: statistics.bowling.wickets,
            economy: statistics.bowling.economy,
            average: statistics.bowling.average,
            strikeRate: statistics.bowling.strike_rate,
            bestBowling: statistics.bowling.best_bowling,
            ballsBalled: statistics.bowling.balls_bowled,
            fourWicketHauls: statistics.bowling.four_wicket_hauls,
            fiverWicketHauls: statistics.bowling.five_wicket_hauls,
            tenWicketHauls: statistics.bowling.ten_wicket_hauls,
            catches: statistics.fielding.catches,
            stumping: statistics.fielding.stumpings,
            runOuts: statistics.fielding.runouts,
          },
          connection
        );
        if (
          storeStatisticsBatting.affectedRows &&
          storeStatisticsBowling.affectedRows
        ) {
          statsCount++;
          if (statsCount === totalStats) {
            resolve(true);
          } else {
            setTimeout(() => {
              storeSingleState(player.statistics.tournaments[statsCount]);
            }, 0);
          }
        } else {
          statsCount++;
          if (statsCount === totalStats) {
            resolve(true);
          } else {
            setTimeout(() => {
              storeSingleState(player.statistics.tournaments[statsCount]);
            }, 0);
          }
        }
      };
      storeSingleState(player.statistics.tournaments[statsCount]);
    } catch (error) {
      console.log(error.message, "storeSinglePlayerStatics");
    }
  });
};

const storePlayersStatics = async (players) => {
  return new Promise(async (resolve) => {
    let playerCount = 0;
    const totalPlayers = players.length;

    const storeSinglePlayerStatics = async (player) => {
      try {
        const connection = await connectToDb();
        const [{ isExists: isStateExist }] = await database(
          "SELECT COUNT(player_statistics_batting.playerId) As isExists FROM `player_statistics_batting` WHERE player_statistics_batting.playerId = ?;",
          [player.playerId],
          connection
        );
        if (!isStateExist) {
          const playerData = await makeRequest(
            `players/sr:player:${player.playerRadarId}/profile.json`
          );

          if (playerData && playerData.player && playerData.statistics) {
            console.log("lests store player " + player.playerRadarId);
            const updatePlayer = await storePlayerStyle(
              playerData.player,
              connection
            );
            const storePlayerStaticsRes = await storeSinglePlayerDb(
              playerData,
              player.playerId,
              connection
            );
            if (updatePlayer && storePlayerStaticsRes) {
              connection.release();
              console.log(true);
              playerCount++;
              if (playerCount === totalPlayers) {
                resolve(true);
              } else {
                setTimeout(() => {
                  storeSinglePlayerStatics(players[playerCount]);
                }, 0);
              }
            } else {
              console.log(true);
              playerCount++;
              if (playerCount === totalPlayers) {
                resolve(true);
              } else {
                setTimeout(() => {
                  storeSinglePlayerStatics(players[playerCount]);
                }, 0);
              }
            }
          } else {
            connection.release();
            playerCount++;
            if (playerCount !== totalPlayers) {
              setTimeout(() => {
                storeSinglePlayerStatics(players[playerCount]);
              }, 0);
            } else {
              resolve(true);
            }
          }
        } else {
          connection.release();
          playerCount++;
          if (playerCount === totalPlayers) {
            resolve(true);
          } else {
            setTimeout(() => {
              storeSinglePlayerStatics(players[playerCount]);
            }, 0);
          }
        }
      } catch (error) {
        playerCount++;
        if (!playerCount === totalPlayers) {
          setTimeout(() => {
            storeSinglePlayerStatics(players[playerCount]);
          }, 0);
        } else {
          resolve(true);
        }
      }
    };
    storeSinglePlayerStatics(players[playerCount]);
  });
};

const fetchData = async () => {
  try {
    let connection = await connectToDb();
    const players = await database(
      "SELECT playerRadarId, playerId from allplayers WHERE playerId > 0 ORDER BY playerId;",
      [],
      connection
    );
    storePlayersStatics(players);
  } catch (error) {
    console.log(error.message, "fetchData");
  }
};

module.exports = { storePlayersStatics, fetchData };
