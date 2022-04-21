const { storePlayersStatics } = require("../playerStatatics");
const { database } = require("../makeRequest");

// store player role in player_role table
const storePlayerRole = async (role, connection) => {
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
      console.log(error.message, "storePlayerRole");
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
          const roleId = await storePlayerRole(player.type, connection);
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
            storePlayersStatics({
              playerId: storePlayers.insertId,
              playerRadarId: player.id.substr(10),
            });
            resolve(storePlayers.insertId);
          }
        }
      } else {
        resolve(false);
      }
    } catch (error) {
      resolve(false);
    }
  });
};

const storePlayerOfTeams = async (tournament, connection) => {
  return new Promise(async (resolve) => {
    let teamsLoopCount = 0;
    const totalTeams = tournament.teams.length;

    const storePlayersOfSingleTeam = async (team) => {
      let playerLoopCount = 0;
      const totalPlayers = team.players.length;
      const storeSinglePlayerCall = async (player) => {
        try {
          const storeSinglePlayerRes = await storeSinglePlayer(
            player,
            connection
          );
          player.insertId = storeSinglePlayerRes;
          playerLoopCount++;
          if (playerLoopCount === totalPlayers) {
            teamsLoopCount++;
            if (teamsLoopCount === totalTeams) {
              resolve(tournament);
            } else {
              storePlayersOfSingleTeam(tournament.teams[teamsLoopCount]);
            }
          } else {
            setTimeout(() => {
              storeSinglePlayerCall(team.players[playerLoopCount]);
            }, 0);
          }
        } catch (error) {
          console.log(error.message, "storePlayersOfTeamsParent");
          playerLoopCount++;
          if (playerLoopCount === totalPlayers) {
            teamsLoopCount++;
            if (teamsLoopCount === totalTeams) {
              resolve(tournament);
            } else {
              storePlayersOfSingleTeam(tournament.teams[teamsLoopCount]);
            }
          } else {
            setTimeout(() => {
              storeSinglePlayer(team.players[playerLoopCount]);
            }, 0);
          }
        }
      };
      storeSinglePlayerCall(team.players[playerLoopCount]);
    };

    storePlayersOfSingleTeam(tournament.teams[teamsLoopCount]);
  });
};

module.exports = {
  storeSinglePlayer,
  storePlayerOfTeams,
};
