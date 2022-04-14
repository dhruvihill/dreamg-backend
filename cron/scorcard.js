const { storePlayersStatics } = require("./playerStatatics");
const { connectToDb, database, makeRequest } = require("./makeRequest");
/*
player not exists then store it and re execute the function
*/
const storePlayerRoleParent = async (role, connection) => {
  return new Promise(async (resolve) => {
    try {
      if (role) {
        let [{ isExists: isRoleExist, roleId }] = await database(
          "SELECT COUNT(player_roles.roleId) AS isExists, player_roles.roleId AS roleId FROM player_roles WHERE player_roles.roleString = ?;",
          [role],
          connection
        );
        if (!isRoleExist) {
          const storeRole = await database(
            "INSERT INTO player_roles (roleString ) VALUES (?)",
            [role],
            connection
          );
          resolve(storeRole.insertId);
        } else {
          resolve(roleId);
        }
      } else {
        resolve(0);
      }
    } catch (error) {
      console.log(error.message, "storePlayerRoleParent");
    }
  });
};

const storeSinglePlayer = async (player, connection) => {
  return new Promise(async (resolve) => {
    try {
      if (player && player.id) {
        let [{ isExists: isPlayerExist, playerId }] = await database(
          "SELECT COUNT(playerId) AS isExists, playerId FROM players WHERE players.playerRadarId = ?;",
          [player.id.substr(10)],
          connection
        );
        if (isPlayerExist === 1) {
          resolve(playerId);
        } else {
          const playerDetails = await makeRequest(
            `players/${player.id}/profile.json`
          );
          if (playerDetails && playerDetails.player) {
            const roleId = await storePlayerRoleParent(
              playerDetails?.player?.type,
              connection
            );
            const storePlayers = await database(
              "INSERT INTO players SET ?",
              {
                playerRadarId: player.id.substr(10),
                playerFirstName: player.name.split(", ")[1] || "",
                playerLastName: player.name.split(", ")[0] || "",
                playerCountryCode: player.country_code || null,
                playerRole: roleId || 0,
                playerDOB: player.date_of_birth || null,
                playerCountry: player.nationality || null,
              },
              connection
            );
            if (storePlayers.insertId) {
              storePlayersStatics([
                {
                  playerId: storePlayers.insertId,
                  playerRadarId: player.id.substr(10),
                },
              ]);
            }
            resolve(storePlayers.insertId);
          } else {
            resolve(false);
          }
        }
      }
    } catch (error) {
      console.log(error.message, "storesingleplayer");
      resolve(false);
    }
  });
};

const storeBatsMan = (inningId, battingTeam, connection) => {
  return new Promise((resolve) => {
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
          bowler.length > 0 ? (bowler = bowler[0].bowlerId) : (bowler = null);
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
            resolve(true);
          }
        } else {
          const storePlayersId = await storeSinglePlayer(player, connection);
          if (storePlayersId) {
            setTimeout(() => {
              storeSingleBastMan(player);
            }, 0);
          } else {
            resolve(false);
          }
        }
      } catch (error) {
        console.log(error, "storeSingleBastMan");
      }
    };
    try {
      battingTeam?.statistics?.batting?.players?.forEach(async (player) => {
        storeSingleBastMan(player);
      });
    } catch (error) {
      console.log(error.message, "storeBatsMan");
      resolve(false);
    }
  });
};

const storeBowlers = (inningId, bowlingTeam, connection) => {
  return new Promise(async (resolve) => {
    try {
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
              resolve(true);
            }
          } else {
            const storedPlayerId = await storeSinglePlayer(player, connection);
            if (storedPlayerId) {
              setTimeout(() => {
                storeSingleBowler(player);
              }, 0);
            } else {
              resolve(false);
            }
          }
        } catch (error) {
          console.log(error.message, "storeBowlers");
        }
      };
      bowlingTeam?.statistics?.bowling?.players?.forEach(async (player) => {
        storeSingleBowler(player);
      });
    } catch (error) {
      console.log(error.message, "storeBowlers");
      resolve(false);
    }
  });
};

const storeInningBatting = (inningId, battingTeam, connection) => {
  return new Promise(async (resolve) => {
    try {
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
        resolve(true);
      }
    } catch (error) {
      console.log(error.message, "storeInningBatting");
      resolve(false);
    }
  });
};

const storeInningBowling = (inningId, bowlingTeam, connection) => {
  return new Promise(async (resolve) => {
    try {
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
        resolve(true);
      }
    } catch (error) {
      console.log(error.message, "storeInningBowling");
      resolve(false);
    }
  });
};

const storeInnings = (
  scorcardId,
  scorecardDetails,
  storedMatchDetails,
  connection
) => {
  return new Promise(async (resolve) => {
    try {
      let inningLoopCount = 0;
      if (
        scorecardDetails &&
        scorecardDetails.statistics &&
        scorecardDetails.statistics.innings &&
        scorecardDetails.statistics.innings.length > 0 &&
        scorecardDetails.sport_event_status &&
        scorecardDetails.sport_event_status.period_scores
      ) {
        scorecardDetails?.statistics?.innings?.forEach(async (inning) => {
          try {
            const battingTeamId =
              parseInt(inning.batting_team.substr(14)) ===
              parseInt(storedMatchDetails.team1RadarId)
                ? storedMatchDetails.team1Id
                : storedMatchDetails.team2Id;
            const bowlingTeamId =
              parseInt(inning.bowling_team.substr(14)) ===
              parseInt(storedMatchDetails.team1RadarId)
                ? storedMatchDetails.team1Id
                : storedMatchDetails.team2Id;
            const [inningPeriod] =
              scorecardDetails.sport_event_status.period_scores.filter(
                (period) => {
                  return period.number === inning.number;
                }
              );
            const { insertId } = await database(
              "INSERT INTO scorcard_innings SET ?",
              {
                scorcardId,
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
            const [battingTeam] = inning.teams.filter((team) => {
              return team.id === inning.batting_team;
            });
            const [bowlingTeam] = inning.teams.filter((team) => {
              return team.id === inning.bowling_team;
            });
            const storeInningBattingRes = await storeInningBatting(
              insertId,
              battingTeam,
              connection
            );
            const storeInningBowlingRes = await storeInningBowling(
              insertId,
              bowlingTeam,
              connection
            );
            const storeInningBattingPlayerRes = await storeBatsMan(
              insertId,
              battingTeam,
              connection
            );
            const storeInningBowlingPlayersRes = await storeBowlers(
              insertId,
              bowlingTeam,
              connection
            );
            if (
              storeInningBattingRes &&
              storeInningBowlingRes &&
              storeInningBattingPlayerRes &&
              storeInningBowlingPlayersRes
            ) {
              resolve(true);
            } else {
              resolve(false);
            }
            inningLoopCount++;
            if (
              inningLoopCount === scorecardDetails.statistics.innings.length
            ) {
              resolve(true);
            }
          } catch (error) {
            console.log(error.message, "storeInnings");
            resolve(false);
          }
        });
      } else {
        resolve(false);
      }
    } catch (error) {}
  });
};

const storeScorcard = (scoreDetails, storedMatchDetails, connection) => {
  return new Promise(async (resolve, reject) => {
    try {
      if (
        scoreDetails &&
        scoreDetails.sport_event_status &&
        scoreDetails.statistics
      ) {
        const tossWonBy =
          parseInt(
            scoreDetails?.sport_event_status?.toss_won_by?.substr(14)
          ) === parseInt(storedMatchDetails.team1RadarId)
            ? storedMatchDetails.team1Id
            : storedMatchDetails.team2Id;
        const winnerId =
          parseInt(scoreDetails?.sport_event_status?.winner_id?.substr(14)) ===
          parseInt(storedMatchDetails.team1RadarId)
            ? storedMatchDetails.team1Id
            : storedMatchDetails.team2Id;
        const data = await database(
          "SELECT playerId AS manOfMatch FROM allplayers WHERE allplayers.playerRadarId = ?;",
          [
            scoreDetails?.statistics?.man_of_the_match &&
            scoreDetails?.statistics?.man_of_the_match.length > 0
              ? scoreDetails?.statistics?.man_of_the_match[0]?.id?.substr(10)
              : null,
          ],
          connection
        );
        const manOfMatch =
          data && data.length > 0 && data[0].manOfMatch
            ? data[0].manOfMatch
            : null;
        const { insertId } = await database(
          "INSERT scorcard_details SET ?",
          {
            matchId: storedMatchDetails.matchId,
            tossWonBy,
            tossDecision: scoreDetails.sport_event_status.toss_decision,
            winnerId,
            manOfMatch,
            matchResultString: scoreDetails.sport_event_status.match_result,
          },
          connection
        );
        const scorecardInnings = await storeInnings(
          insertId,
          scoreDetails,
          storedMatchDetails,
          connection
        );
        if (scorecardInnings) {
          resolve(true);
        } else {
          resolve(false);
        }
      } else {
        console.log(
          "insufficient data to store innings from radar store scorecard"
        );
        resolve(false);
      }
    } catch (error) {
      console.log(error);
      console.log(error.message, "storeScorcardRes");
      resolve(false);
    }
  });
};

const fetchMatches = async (matchId) => {
  return new Promise(async (resolve) => {
    try {
      const connection = await connectToDb();
      let matches;
      if (matchId) {
        matches = await database(
          `SELECT matchId, matchRadarId, team1Id, team1RadarId, team2Id, team2RadarId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?;`,
          [matchId],
          connection
        );
      } else {
        matches = await database(
          `SELECT matchId, matchRadarId, team1Id, team1RadarId, team2Id, team2RadarId FROM fullmatchdetails WHERE fullmatchdetails.matchStatusString IN ('ended', 'closed') ORDER BY matchId;`,
          [],
          connection
        );
      }
      connection.release();
      let currentMatch = 0;
      const totalMatches = matches.length;

      const processMatch = async (match) => {
        try {
          const newConnection = await connectToDb();
          const [{ isExists }] = await database(
            "SELECT COUNT(matchId) AS isExists FROM `scorcard_details` WHERE scorcard_details.matchId = ?;",
            [match.matchId],
            newConnection
          );
          if (!isExists) {
            const matchScorCard = await makeRequest(
              `matches/sr:match:${match.matchRadarId}/summary.json`
            );
            const storeScorcardRes = await storeScorcard(
              matchScorCard,
              match,
              newConnection
            );
            if (storeScorcardRes) {
              newConnection.release();
              currentMatch++;
              if (currentMatch === totalMatches) {
                resolve(true);
              } else {
                setTimeout(() => {
                  processMatch(matches[currentMatch]);
                }, 0);
              }
            } else {
              newConnection.release();
              currentMatch++;
              if (currentMatch === totalMatches) {
                resolve(false);
              } else {
                setTimeout(() => {
                  processMatch(matches[currentMatch]);
                }, 0);
              }
            }
          } else {
            newConnection.release();
            currentMatch++;
            if (currentMatch === totalMatches) {
              resolve(true);
            } else {
              setTimeout(() => {
                processMatch(matches[currentMatch]);
              }, 0);
            }
          }
        } catch (error) {
          console.log(error.message, "preocessMatch");
          currentMatch++;
          if (currentMatch === totalMatches) {
            resolve(false);
          } else {
            setTimeout(() => {
              processMatch(matches[currentMatch]);
            }, 0);
          }
        }
      };
      processMatch(matches[currentMatch]);
    } catch (error) {
      console.log(error.message, "fetchMatches");
    }
  });
};

module.exports = {
  fetchMatches,
  storeScorcard,
};
