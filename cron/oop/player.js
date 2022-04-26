const { connectToDb, database, makeRequest } = require("../makeRequest");

class Role {
  roleId = null;
  #roleName = "";

  constructor(name) {
    this.#roleName = name;
  }

  storeRole() {
    return new Promise(async (resolve) => {
      try {
        if (this.#roleName) {
          const connection = await connectToDb();
          let [{ isExists: isRoleExist, roleId }] = await database(
            "SELECT COUNT(player_roles.roleId) AS isExists, player_roles.roleId AS roleId FROM player_roles WHERE player_roles.roleString = ?;",
            [this.#roleName],
            connection
          );
          if (!isRoleExist) {
            const storeRole = await database(
              "INSERT INTO player_roles (roleString ) VALUES (?)",
              [this.#roleName],
              connection
            );
            connection.release();
            this.roleId = storeRole.insertId;
            resolve(storeRole.insertId);
          } else {
            connection.release();
            this.roleId = roleId;
            resolve(roleId);
          }
        } else {
          this.roleId = null;
          resolve(null);
        }
      } catch (error) {
        this.roleId = null;
        console.log(error.message, "storePlayerRole");
        resolve(null);
      }
    });
  }
}

class Player extends Role {
  id = null;
  radarId = 0;
  #firstName = "";
  #lastName = "";
  #country = "";
  #countryCode = "";
  #dateOfBirth = "";

  constructor(
    roleName,
    id,
    firstName,
    lastName,
    country,
    countryCode,
    dateOfBirth
  ) {
    super(roleName);
    this.radarId = id;
    this.#firstName = firstName;
    this.#lastName = lastName;
    this.#country = country;
    this.#countryCode = countryCode;
    this.#dateOfBirth = dateOfBirth;
  }

  storePlayer() {
    return new Promise(async (resolve) => {
      try {
        if (this.radarId) {
          const connection = await connectToDb();
          await super.storeRole();
          let [{ isExists: isPlayerExist, playerId }] = await database(
            "SELECT COUNT(playerId) AS isExists, playerId FROM players WHERE players.playerRadarId = ?;",
            [this.radarId],
            connection
          );
          if (isPlayerExist === 1) {
            connection.release();
            this.id = playerId;
            resolve(this.id);
          } else {
            const storePlayers = await database(
              "INSERT INTO players SET ?",
              {
                playerRadarId: this.radarId,
                playerFirstName: this.#firstName || "",
                playerLastName: this.#lastName || "",
                playerCountryCode: this.#countryCode || null,
                playerRole: this.roleId || 0,
                playerDOB: this.#dateOfBirth || null,
                playerCountry: this.#country || null,
              },
              connection
            );
            if (storePlayers.insertId) {
              connection.release();
              this.id = storePlayers.insertId;
              resolve(this.id);
              /*
                            storePlayersStatics({
                                playerId: storePlayers.insertId,
                                playerRadarId: player.id.substr(10),
                            });
                            resolve(storePlayers.insertId);
                            */
            }
          }
        } else {
          this.id = null;
          resolve(null);
        }
      } catch (error) {
        this.id = null;
        resolve(null);
      }
    });
  }

  storePlayerRelation(tournamentCompetitorId) {
    return new Promise(async (resolve) => {
      try {
        const connection = await connectToDb();
        const [{ isExists, tournamentCompetitorPlayerId }] = await database(
          "SELECT COUNT(*) AS isExists, tournamentCompetitorPlayerId FROM tournament_competitor_player WHERE tournament_competitor_player.playerId = ? AND tournament_competitor_player.tournamentCompetitorId = ?;",
          [this.id, tournamentCompetitorId],
          connection
        );

        if (!isExists) {
          const tournamentCompetitorPlayerRes = await database(
            "INSERT INTO tournament_competitor_player SET tournament_competitor_player.playerId = ?, tournament_competitor_player.tournamentCompetitorId = ?;",
            [this.id, tournamentCompetitorId],
            connection
          );

          if (
            tournamentCompetitorPlayerRes &&
            tournamentCompetitorPlayerRes.insertId
          ) {
            connection.release();
            resolve();
          }
        } else {
          connection.release();
          resolve();
        }
      } catch (error) {
        console.log(error.message);
        resolve();
      }
    });
  }
}

class PlayerStatistics extends Player {
  #battingStyleId = null;
  #bowlingStyleId = null;
  #battingStyle = "";
  #bowlingStyle = "";
  #playerStatistics = [];

  constructor(
    roleName,
    id,
    firstName,
    lastName,
    country,
    countryCode,
    dateOfBirth,
    PlayerStatistics,
    battingStyle,
    bowlingStyle
  ) {
    super(roleName, id, firstName, lastName, country, countryCode, dateOfBirth);
    if (PlayerStatistics) {
      this.#playerStatistics = playerStatistics;
    }
    if (battingStyle) {
      this.#battingStyle = battingStyle;
    }
    if (bowlingStyle) {
      this.#bowlingStyle = bowlingStyle;
    }
  }

  async #storeBattingStyle() {
    return new Promise(async (resolve) => {
      try {
        if (this.#battingStyle) {
          const connection = await connectToDb();
          let [{ isExists: isStyleExist, styleId }] = await database(
            "SELECT COUNT(player_batting_style.playerBattingStyleId) As isExists, player_batting_style.playerBattingStyleId AS styleId FROM `player_batting_style` WHERE player_batting_style.battingStyleString = ?;",
            [this.#battingStyle],
            connection
          );
          if (!isStyleExist) {
            const storeStyle = await database(
              "INSERT INTO player_batting_style SET ?;",
              { battingStyleString: this.#battingStyle },
              connection
            );
            this.#battingStyleId = storeStyle.insertId;
            connection.release();
            resolve(storeStyle.insertId);
          } else {
            this.#battingStyleId = styleId;
            connection.release();
            resolve(styleId);
          }
        } else {
          this.#battingStyleId = null;
          resolve(null);
        }
      } catch (error) {
        console.log(error.message, "storeBattingStyle");
        resolve(null);
      }
    });
  }

  async #storeBowlingStyle() {
    return new Promise(async (resolve) => {
      try {
        if (this.#bowlingStyle) {
          const connection = await connectToDb();
          let [{ isExists: isStyleExist, styleId }] = await database(
            "SELECT COUNT(player_bowling_style.playerBowlingStyleId) As isExists, player_bowling_style.playerBowlingStyleId AS styleId FROM `player_bowling_style` WHERE player_bowling_style.playerBowlingStyleString = ?;",
            [this.#bowlingStyle],
            connection
          );
          if (!isStyleExist) {
            const storeStyle = await database(
              "INSERT INTO player_bowling_style SET ?;",
              { playerBowlingStyleString: this.#bowlingStyle },
              connection
            );
            connection.release();
            this.#bowlingStyleId = storeStyle.insertId;
            resolve(storeStyle.insertId);
          } else {
            this.#bowlingStyleId = styleId;
            connection.release();
            resolve(styleId);
          }
        } else {
          resolve(null);
        }
      } catch (error) {
        console.log(error.message, "storeBattingStyle");
        this.#bowlingStyleId = null;
      }
    });
  }

  async #storePlayerStyle() {
    return new Promise(async (resolve) => {
      try {
        const connection = await connectToDb();
        await this.#storeBattingStyle(this.#battingStyle, connection);
        await this.#storeBowlingStyle(this.#bowlingStyle, connection);

        const updatePlayer = await database(
          "UPDATE players SET playerBattingStyleId = ?, playerBowlingStyleId = ? WHERE playerRadarId = ?;",
          [this.#battingStyleId, this.#bowlingStyleId, super.id],
          connection
        );
        if (updatePlayer.affectedRows) {
          connection.release();
          resolve(true);
        } else {
          connection.release();
          resolve(false);
        }
      } catch (error) {
        console.log(error.message, "storePlayerStyle");
      }
    });
  }

  async #storePlayerStatistics() {
    return new Promise(async (resolve) => {
      try {
        const connection = await connectToDb();
        let statsCount = 0;
        const totalStats = this.#playerStatistics.length;
        const storeSingleState = async (statistics) => {
          const storeStatisticsBatting = await database(
            "INSERT INTO player_statistics_batting SET ?;",
            {
              playerId: super.id,
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
              playerId: super.id,
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
              connection.release();
              resolve(true);
            } else {
              setTimeout(() => {
                storeSingleState(this.#playerStatistics[statsCount]);
              }, 0);
            }
          } else {
            statsCount++;
            if (statsCount === totalStats) {
              connection.release();
              resolve(true);
            } else {
              setTimeout(() => {
                storeSingleState(this.#playerStatistics[statsCount]);
              }, 0);
            }
          }
        };
        storeSingleState(this.#playerStatistics[statsCount]);
      } catch (error) {
        console.log(error.message, "storeSinglePlayerStatics");
        resolve(false);
      }
    });
  }

  async getPlayerStatesAndStore() {
    return new Promise(async (resolve, reject) => {
      try {
        const connection = await connectToDb();
        await super.storePlayer();
        const [{ isExists: isStateExist }] = await database(
          "SELECT COUNT(player_statistics_batting.playerId) As isExists FROM `player_statistics_batting` WHERE player_statistics_batting.playerId = ?;",
          [super.id],
          connection
        );
        if (!isStateExist) {
          const playerData = await makeRequest(
            `players/sr:player:${this.radarId}/profile.json`
          );
          if (playerData && playerData.player && playerData.statistics) {
            this.#battingStyle = playerData.player.batting_style;
            this.#bowlingStyle = playerData.player.bowling_style;
            this.#playerStatistics = playerData.statistics.tournaments;

            const updatePlayer = await this.#storePlayerStyle();
            const storePlayerStaticsRes = await this.#storePlayerStatistics();
            if (updatePlayer && storePlayerStaticsRes) {
              connection.release();
              resolve();
            } else {
              connection.release();
              resolve();
            }
          } else {
            connection.release();
            resolve();
          }
        } else {
          connection.release();
          resolve();
        }
      } catch (error) {
        console.log(error.message);
        reject();
      }
    });
  }
}

module.exports = PlayerStatistics;
