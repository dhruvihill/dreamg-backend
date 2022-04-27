const { connectToDb, database, makeRequest } = require("../makeRequest");
const Player = require("./player");

class Scorcard {
  id = 0;
  #radarId = 0;
  #scorcardDetails = {
    sportEvent: {},
    sportEventStatus: {},
    statistics: {},
    tossWonBy: null,
    manOfMatch: null,
    winner: null,
  };
  #competitors = [];
  #scorcardId = null;

  constructor(id, radarId, competitors) {
    this.id = id;
    this.#radarId = radarId;
    this.#competitors = competitors;
  }

  #fetchScorcard = () => {
    return new Promise(async (resolve, reject) => {
      try {
        const {
          sport_event: sportEvent,
          sport_event_status: sportEventStatus,
          statistics,
        } = await makeRequest(
          `/matches/sr:match:${this.#radarId}/summary.json`
        );

        if (sportEvent && sportEventStatus && statistics) {
          if (
            sportEventStatus.match_status === "ended" ||
            sportEventStatus.match_status === "closed"
          ) {
            this.#scorcardDetails.sportEvent = sportEvent;
            this.#scorcardDetails.sportEventStatus = sportEventStatus;
            this.#scorcardDetails.statistics = statistics;
          } else {
            throw new Error("Match is not ended");
          }

          resolve();
        } else {
          throw new Error("Scorcard details not found");
        }
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  };

  #fetchWinnerManOfMatch = () => {
    return new Promise(async (resolve, reject) => {
      try {
        const connection = await connectToDb();
        const [{ playerId }] = await database(
          "SELECT playerId FROM allplayers WHERE playerRadarId = ?;",
          [this.#scorcardDetails.statistics.man_of_the_match[0].id.substr(10)],
          connection
        );

        const [winner] = this.#competitors.filter((competitor) => {
          return (
            competitor.radarId ==
            this.#scorcardDetails.sportEventStatus.winner_id.substr(14)
          );
        });

        const [tossWonBy] = this.#competitors.filter((competitor) => {
          return (
            competitor.radarId ==
            this.#scorcardDetails.sportEventStatus.toss_won_by.substr(14)
          );
        });

        this.#scorcardDetails.manOfMatch = playerId;
        this.#scorcardDetails.winner = winner.id;
        this.#scorcardDetails.tossWonBy = tossWonBy.id;
        resolve();
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  };

  #storeInningBatting = (battingTeam, inningId) => {
    return new Promise(async (resolve, reject) => {
      try {
        const connection = await connectToDb();
        const store = await database(
          "INSERT INTO inning_batting SET ?;",
          {
            scorcardInningId: inningId,
            runs: battingTeam.statistics?.batting?.runs || 0,
            fours: battingTeam.statistics?.batting?.fours || 0,
            sixes: battingTeam.statistics?.batting?.sixes || 0,
            runRate: battingTeam.statistics?.batting?.run_rate || 0,
            ballFaced: battingTeam.statistics?.batting?.balls_faced || 0,
          },
          connection
        );
        if (store) {
          connection.release();
          resolve(true);
        }
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  };

  #storeInningBowling = (bowlingTeam, inningId) => {
    return new Promise(async (resolve, reject) => {
      try {
        const connection = await connectToDb();
        const store = await database(
          "INSERT INTO inning_bowling SET ?;",
          {
            scorcardInningId: inningId,
            overs: bowlingTeam?.statistics?.bowling?.overs || 0,
            wickets: bowlingTeam?.statistics?.bowling?.wickets || 0,
            maidens: bowlingTeam?.statistics?.bowling?.maidens || 0,
            extras: bowlingTeam?.statistics?.bowling?.extras || 0,
            noBalls: bowlingTeam?.statistics?.bowling?.no_balls || 0,
            byes: bowlingTeam?.statistics?.bowling?.byes || 0,
            legByes: bowlingTeam?.statistics?.bowling?.leg_byes || 0,
            dotBalls: bowlingTeam?.statistics?.bowlin?.dot_balls || 0,
          },
          connection
        );
        if (store) {
          connection.release();
          resolve(true);
        }
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  };

  #storeInningBatsmen = (battingTeam, inningId) => {
    return new Promise(async (resolve, reject) => {
      try {
        const totalBatsman = battingTeam?.statistics?.batting?.players?.length;
        let currentBatsman = 0;

        const connection = await connectToDb();
        const storeSingleBastMan = async (player) => {
          try {
            let [
              [{ isExists: isPlayerExists, playerInsertedId }],
              bowler,
              fielder,
            ] = await database(
              "SELECT COUNT(playerId) AS isExists, playerId AS playerInsertedId FROM allplayers WHERE playerRadarId = ?; SELECT playerId AS bowlerId FROM allplayers WHERE playerRadarId = ?; SELECT playerId AS fielderId FROM allplayers WHERE playerRadarId = ?;",
              [
                player?.id?.substr(10),
                player?.statistics?.dismissal?.bowler_id?.substr(10),
                player?.statistics?.dismissal?.fieldsman_id?.substr(10),
              ],
              connection
            );
            if (isPlayerExists) {
              bowler.length > 0
                ? (bowler = bowler[0].bowlerId)
                : (bowler = null);
              fielder.length > 0
                ? (fielder = fielder[0].fielderId)
                : (fielder = null);
              const store = await database(
                "INSERT INTO inning_batsmans SET ?;",
                {
                  scorcardInningId: inningId,
                  playerId: playerInsertedId,
                  battingOrder: player?.order || null,
                  runs: player?.statistics?.runs || 0,
                  strikeRate: player?.statistics?.strike_rate || 0.0,
                  isNotOut: player?.statistics?.not_out || 0,
                  isDuck: player?.statistics?.duck || 0,
                  isRetiredHurt: player?.statistics?.retired_hurt || 0,
                  ballFaced: player?.statistics?.balls_faced || 0,
                  fours: player?.statistics?.fours || 0,
                  sixes: player?.statistics?.sixes || 0,
                  attackIngShot: player?.statistics?.attacking_shots || 0,
                  semiAttackingShot: player?.statistics?.semi_attacking || 0,
                  defendingShot: player?.statistics?.defending_shots || 0,
                  leaves: player?.statistics?.left_alone || 0,
                  onSideShot: player?.statistics?.onside_shots || 0,
                  offSideShot: player?.statistics?.offside_shots || 0,
                  squreLegShot: player?.statistics?.square_leg_shots || 0,
                  fineLegShot: player?.statistics?.fine_leg_shots || 0,
                  thirdManShot: player?.statistics?.third_man_shots || 0,
                  coverShot: player?.statistics?.cover_shots || 0,
                  pointsShot: player?.statistics?.point_shots || 0,
                  midOnShot: player?.statistics?.mid_on_shots || 0,
                  midOffShot: player?.statistics?.mid_off_shots || 0,
                  midWicketShot: player?.statistics?.mid_wicket_shots || 0,
                  dismissalOverBallNumber:
                    player?.statistics?.dismissal?.ball_number || null,
                  dismissalOverNumber:
                    player?.statistics?.dismissal?.over_number || null,
                  dismissalBallerId: bowler || null,
                  dismissalDiliveryType:
                    player?.statistics?.dismissal?.delivery_type || null,
                  dismissalFieldeManId: fielder || null,
                  dismissalIsOnStrike:
                    player?.statistics?.dismissal?.on_strike | null,
                  dismissalShotType:
                    player?.statistics?.dismissal?.shot_type || null,
                  dismissalType: player?.statistics?.dismissal?.type || null,
                },
                connection
              );
              if (store) {
                currentBatsman++;
                if (currentBatsman === totalBatsman) {
                  resolve(true);
                }
              }
            } else {
              const newPlayer = new Player(player);
              await newPlayer.getPlayerStatesAndStore();
              setTimeout(() => {
                storeSingleBowler(player);
              }, 0);
            }
          } catch (error) {
            console.log(error, "storeSingleBastMan");
            reject(error);
          }
        };
        battingTeam?.statistics?.batting?.players?.forEach(async (player) => {
          storeSingleBastMan(player);
        });
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  };

  #storeInningBowlers = (bowlingTeam, inningId) => {
    return new Promise(async (resolve, reject) => {
      try {
        const totalBowlers = bowlingTeam?.statistics?.bowling?.players?.length;
        let currentBowler = 0;

        const connection = await connectToDb();
        const storeSingleBowler = async (player) => {
          try {
            const [{ isExists: isPlayerExists, playerInsertedId }] =
              await database(
                "SELECT COUNT(playerId) AS isExists, playerId AS playerInsertedId FROM allplayers WHERE playerRadarId = ?;",
                [player.id.substr(10)],
                connection
              );
            if (isPlayerExists) {
              const store = await database(
                "INSERT INTO inning_bowlers SET ?;",
                {
                  scorcardInningId: inningId,
                  playerId: playerInsertedId,
                  runsConceded: player?.statistics?.runs_conceded || 0,
                  wickets: player?.statistics?.wickets || 0,
                  overBowled: player?.statistics?.overs_bowled || 0,
                  maidensOvers: player?.statistics?.maidens || 0,
                  dotBalls: player?.statistics?.dot_balls || 0,
                  fourConceded: player?.statistics?.fours_conceded || 0,
                  sixConceded: player?.statistics?.sixes_conceded || 0,
                  noBalls: player?.statistics?.no_balls || 0,
                  wides: player?.statistics?.wides || 0,
                  slowerDeliveries: player?.statistics?.slower_deliveries || 0,
                  yorkers: player?.statistics?.yorkers || 0,
                  economyRate: player?.statistics?.economy_rate || 0.0,
                  fastestBall: player?.statistics?.fastest_delivery || 0,
                  slowestBall: player?.statistics?.slowest_delivery || 0,
                  averageSpeed: player?.statistics?.average_speed || 0.0,
                  overTheWicketBalls: player?.statistics?.over_the_wicket || 0,
                  aroundTheWicketBalls:
                    player?.statistics?.around_the_wicket || 0,
                  bouncers: player?.statistics?.bouncers || 0,
                  beatBats: player?.statistics?.beat_bats || 0,
                  edge: player?.statistics?.edges || 0,
                },
                connection
              );
              if (store) {
                currentBowler++;
                if (currentBowler === totalBowlers) {
                  connection.release();
                  resolve(true);
                }
              }
            } else {
              connection.release();
              const newPlayer = new Player(player);
              await newPlayer.getPlayerStatesAndStore();
              setTimeout(() => {
                storeSingleBowler(player);
              }, 0);
            }
          } catch (error) {
            console.log(error.message, "storeBowlers");
          }
        };
        bowlingTeam?.statistics?.bowling?.players?.forEach(async (player) => {
          storeSingleBowler(player);
        });
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  };

  #storeInning = () => {
    return new Promise(async (resolve, reject) => {
      try {
        if (
          this.#scorcardDetails &&
          this.#scorcardDetails.statistics &&
          this.#scorcardDetails.statistics.innings &&
          this.#scorcardDetails.statistics.innings.length > 0 &&
          this.#scorcardDetails.sportEventStatus &&
          this.#scorcardDetails.sportEventStatus.period_scores
        ) {
          const connection = await connectToDb();
          this.#scorcardDetails.statistics.innings.forEach(async (inning) => {
            try {
              const battingTeamId = this.#competitors.filter((competitor) => {
                return competitor.radarId == inning.batting_team.substr(14);
              })[0].id;
              const bowlingTeamId = this.#competitors.filter((competitor) => {
                return competitor.radarId == inning.bowling_team.substr(14);
              })[0].id;
              const [inningPeriod] =
                this.#scorcardDetails.sportEventStatus.period_scores.filter(
                  (period) => {
                    return period.number === inning.number;
                  }
                );

              const storeInningScoreRes = await database(
                "INSERT INTO scorcard_innings SET ?",
                {
                  scorcardId: this.#scorcardId,
                  inningNumber: inning.number,
                  battingTeam: battingTeamId,
                  bowlingTeam: bowlingTeamId,
                  runs: inningPeriod?.home_score
                    ? inningPeriod.home_score
                    : inningPeriod.away_score || 0,
                  wickets: inningPeriod?.home_wickets
                    ? inningPeriod.home_wickets
                    : inningPeriod.away_wickets || 0,
                  oversPlayed: inning.overs_completed,
                },
                connection
              );

              if (storeInningScoreRes && storeInningScoreRes.insertId) {
                const [battingTeam] = inning.teams.filter((team) => {
                  return team.id === inning.batting_team;
                });
                const [bowlingTeam] = inning.teams.filter((team) => {
                  return team.id === inning.bowling_team;
                });

                const storeInningBattingRes = await this.#storeInningBatting(
                  battingTeam,
                  storeInningScoreRes.insertId
                );
                const storeInningBowlingRes = await this.#storeInningBowling(
                  bowlingTeam,
                  storeInningScoreRes.insertId
                );
                const storeInningBattingPlayerRes =
                  await this.#storeInningBatsmen(
                    battingTeam,
                    storeInningScoreRes.insertId
                  );
                const storeInningBowlingPlayersRes =
                  await this.#storeInningBowlers(
                    bowlingTeam,
                    storeInningScoreRes.insertId
                  );

                if (
                  storeInningBattingRes &&
                  storeInningBowlingRes &&
                  storeInningBattingPlayerRes &&
                  storeInningBowlingPlayersRes
                ) {
                  resolve();
                } else {
                  reject();
                }
              } else {
                reject();
              }
            } catch (error) {
              console.log(error.message);
              reject(error);
            }
          });
        } else {
          reject();
        }
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  };

  storeScorcard = () => {
    return new Promise(async (resolve, reject) => {
      try {
        const connection = await connectToDb();
        const [{ isExist }] = await database(
          "SELECT COUNT(*) FROM scorcard_details WHERE matchId = ?;",
          [this.id],
          connection
        );
        if (!isExist) {
          await this.#fetchScorcard();
          await this.#fetchWinnerManOfMatch();

          const storeScorcardDetailsRes = await database(
            "INSERT INTO `scorcard_details`(`matchId`, `tossWonBy`, `tossDecision`, `winnerId`, `manOfMatch`, `isPointsCalculated`, `matchResultString`) VALUES (?, ?, ?, ?, ?, ?, ?);",
            [
              this.id,
              this.#scorcardDetails.tossWonBy || null,
              this.#scorcardDetails.sportEventStatus.toss_decision || null,
              this.#scorcardDetails.winner || null,
              this.#scorcardDetails.manOfMatch || null,
              0,
              this.#scorcardDetails.sportEventStatus.match_result || null,
            ],
            connection
          );

          if (storeScorcardDetailsRes.insertId) {
            connection.release();
            this.#scorcardId = storeScorcardDetailsRes.insertId;

            await this.#storeInning();

            resolve();
          } else {
            connection.release();
            reject();
          }
        } else {
          connection.release();
          resolve();
        }
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  };
}

module.exports = Scorcard;
