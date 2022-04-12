require("dotenv/config");
const { connectToDb, database, makeRequest } = require("./makeRequest");

// store batting style
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

// store bowling style
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

// store player style
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

// store player role
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

const storeTossDetails = async (matchId, matchRadarId, match, connection) => {
  return new Promise(async (resolve) => {
    try {
      const [{ tossWonBy }] = await database(
        "SELECT tossWonBy FROM fullmatchdetails WHERE matchId = ?;",
        [matchId],
        connection
      );
      if (tossWonBy !== null && tossWonBy > 0) {
        const tossDetails = await makeRequest(
          `/matches/sr:match:${matchRadarId}/timeline.json`
        );
        if (tossDetails && tossDetails.sport_event_status) {
          if (tossDetails.sport_event_status.toss_won_by !== null) {
            const tossWonBy =
              parseInt(
                tossDetails.sport_event_status.toss_won_by.substr(14)
              ) === match.team1RadarId
                ? team1Id
                : team2Id;
            const storeTossDetails = await database(
              "UPDATE tournament_matches SET tossWonBy = ?, tossDecision = ? WHERE matchId = ?;",
              {
                tossWonBy,
                tossDecision: tossDetails.sport_event_status.toss_decision,
                matchId,
              },
              connection
            );
            if (storeTossDetails.affectedRows) {
              resolve(true);
            } else {
              resolve(false);
            }
          }
        }
      } else {
        resolve(true);
      }
    } catch (error) {
      resolve(false);
      console.log(error.message);
    }
  });
};

const storeMatchLineup = async (matchId, matchRadarId, match, connection) => {
  return new Promise(async (resolve) => {
    try {
      console.log("lets store match lineup", matchId);

      // getting match lineup from sportsRadar
      const matchLineUp = await makeRequest(
        `/matches/sr:match:${matchRadarId}/lineups.json`
      );

      if (matchLineUp && matchLineUp.sport_event && matchLineUp.lineups) {
        // getting away team as per response of sportsRadar
        const awayCompetitor = matchLineUp?.sport_event.competitors?.filter(
          (competitor) => {
            return competitor.qualifier === "away";
          }
        );

        const storeTossDetailsRes = await storeTossDetails(
          matchId,
          matchRadarId,
          match,
          connection
        );

        // getting home team as per response of sportsRadar
        const homeCompetitor = matchLineUp?.sport_event.competitors?.filter(
          (competitor) => {
            return competitor.qualifier === "home";
          }
        );

        let teamsloopCount = 0;
        matchLineUp?.lineups?.forEach((lineup) => {
          try {
            let playersloopCount = 0;
            const storePlayer = async (player) => {
              try {
                // checking if player is already stored in database table players
                const [{ isExists: isPlayerExists, playerId }] = await database(
                  "SELECT COUNT(playerId) AS isExists, playerId FROM allplayers WHERE playerRadarId = ?",
                  [player.id.substr(10)],
                  connection
                );

                // player exists then store it else store it in players table
                if (isPlayerExists) {
                  const storeMatchPlayersRes = await database(
                    "UPDATE match_players SET isSelected = 1, isCaptain = ?, isWicketKeeper = ? WHERE playerId = ? AND matchId = ?;",
                    [
                      player.is_captain,
                      player.is_wicketkeeper,
                      playerId,
                      matchId,
                    ],
                    connection
                  );

                  // if player stored successfully then go to next player
                  if (storeMatchPlayersRes) {
                    playersloopCount++;
                    if (playersloopCount === lineup.starting_lineup.length) {
                      teamsloopCount++;
                      if (
                        teamsloopCount === matchLineUp.lineups.length &&
                        storeTossDetailsRes
                      ) {
                        resolve(true);
                      }
                    }
                  }
                } else {
                  const storeSinglePlayer = async (playerData) => {
                    try {
                      const roleId = await storePlayerRoleParent(
                        playerData.type,
                        connection
                      );
                      const storePlayers = await database(
                        "INSERT INTO players SET ?",
                        {
                          playerRadarId: playerData.id.substr(10),
                          playerFirstName: playerData.name.split(", ")[1] || "",
                          playerLastName: playerData.name.split(", ")[0] || "",
                          playerCountryCode: playerData.country_code || null,
                          playerRole: roleId || 0,
                          playerDOB: playerData.date_of_birth || null,
                          playerCountry: playerData.nationality || null,
                        },
                        connection
                      );
                      if (storePlayers.insertId) {
                        const updatePlayer = await storePlayerStyle(
                          playerData,
                          connection
                        );
                        const storeRelation = await database(
                          "INSERT INTO tournament_competitor_player SET ?",
                          {
                            tournamentCompetitorId: competitorRadarIdStored,
                            playerId: storePlayers.insertId,
                          },
                          connection
                        );
                        setTimeout(() => {
                          storePlayer(player);
                        }, 0);
                      }
                    } catch (error) {
                      console.log(error.message, "storePlayersOfTeamsParent");
                    }
                  };
                  const { player: playerData } = await makeRequest(
                    `players/${player.id}/profile.json`
                  );
                  storeSinglePlayer(playerData);
                }
              } catch (error) {
                console.log(error.message, "storeMatchLineup1");
              }
            };
            lineup?.starting_lineup?.forEach((player) => {
              // storing single player with matchId and competitor Id
              storePlayer(player);
            });
          } catch (error) {
            console.log(error.message, "storeMatchLineup2");
          }
        });
      } else {
        resolve(false);
      }
    } catch (error) {
      if (error.isAxiosError) {
        if (error.response.data.message === "No lineups.") {
          resolve(false);
        }
      } else {
        console.log(error.message, "storeMatchLineup3");
        resolve(false);
      }
    }
  });
};

// gets matchId from database whose lineup is to be stored
const fetchMatches = async (matchId) => {
  try {
    const connection = await connectToDb();

    // fetching matches which are not stored in database
    let matches;
    if (matchId) {
      matches = await database(
        `SELECT matchId, matchRadarId, team1Id, team2Id, team1RadarId, team2RadarId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?;`,
        [matchId],
        connection
      );
    } else {
      matches = await database(
        `SELECT matchId, matchRadarId, team1Id, team2Id, team1RadarId, team2RadarId FROM fullmatchdetails WHERE fullmatchdetails.matchStatusString IN ('ended', 'closed', 'live') AND matchId NOT IN (SELECT DISTINCT matchId FROM match_lineup) ORDER BY fullmatchdetails.matchRadarId DESC;`,
        [],
        connection
      );
    }

    let currentMatch = 0;
    const totalMatches = matches.length;

    // function to store match lineup
    const processMatch = async (match) => {
      try {
        const newConnection = await connectToDb();

        // calling functio which stores match lineup
        const lineUpRes = await storeMatchLineup(
          match.matchId,
          match.matchRadarId,
          match,
          newConnection
        );

        // lineup stored or not go to next match
        if (lineUpRes) {
          console.log(true);
          currentMatch++;
          if (currentMatch === totalMatches) {
            console.log("All matches processed");
          } else {
            newConnection.release();
            setTimeout(() => {
              processMatch(matches[currentMatch]);
            }, 0);
          }
        } else {
          currentMatch++;
          if (currentMatch === totalMatches) {
            console.log("All matches processed");
          } else {
            newConnection.release();
            setTimeout(() => {
              processMatch(matches[currentMatch]);
            }, 0);
          }
        }
      } catch (error) {
        console.log(error.message, "preocessMatch");
        currentMatch++;
        if (currentMatch === totalMatches) {
          console.log("All matches processed");
        } else {
          setTimeout(() => {
            processMatch(matches[currentMatch]);
          }, 0);
        }
      }
    };

    // calling functio first time
    processMatch(matches[currentMatch]);
  } catch (error) {
    console.log(error.message, "fetchMatches");
  }
};

// exporting the function
module.exports = {
  storeMatchLineup,
  fetchMatches,
};
