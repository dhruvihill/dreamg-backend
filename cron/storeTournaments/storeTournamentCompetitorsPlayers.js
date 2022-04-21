const { database } = require("../makeRequest");

// store data in tournament_competitors_players table
const storeTournamentCompetitorsPlayers = async (tournament, connection) => {
  return new Promise(async (resolve) => {
    try {
      let teamsLoopCount = 0;
      const totalTeams = tournament.teams.length;

      const storePlayersOfSingleTeam = async (team) => {
        let playerLoopCount = 0;
        const totalPlayers = team.players.length;

        const storeSinglePlayer = async (player) => {
          try {
            if (player.id && player.name && player.type) {
              const [
                { isExists: isPlayerExists, tournamentCompetitorPlayerId },
              ] = await database(
                "SELECT COUNT(tournament_competitor_player.tournamentCompetitorPlayerId) AS isExists, tournament_competitor_player.tournamentCompetitorPlayerId AS tournamentCompetitorPlayerId FROM `tournament_competitor_player` WHERE tournament_competitor_player.tournamentCompetitorId = ? AND tournament_competitor_player.playerId = ?;",
                [team.tournamentCompetitorId, player.insertId],
                connection
              );
              if (!isPlayerExists) {
                if (player.insertId) {
                  const storeTournamentCompetitorsPlayers = await database(
                    "INSERT INTO tournament_competitor_player SET ?",
                    {
                      tournamentCompetitorId: team.tournamentCompetitorId,
                      playerId: player.insertId,
                    },
                    connection
                  );
                  if (storeTournamentCompetitorsPlayers.insertId) {
                    playerLoopCount++;
                    if (playerLoopCount === totalPlayers) {
                      teamsLoopCount++;
                      if (teamsLoopCount === totalTeams) {
                        resolve(tournament);
                      } else {
                        storePlayersOfSingleTeam(
                          tournament.teams[teamsLoopCount]
                        );
                      }
                    } else {
                      storeSinglePlayer(team.players[playerLoopCount]);
                    }
                  }
                } else {
                  playerLoopCount++;
                  if (playerLoopCount === team.players.length) {
                    teamsLoopCount++;
                    if (teamsLoopCount === tournament.teams.length) {
                      resolve(tournament);
                    }
                  }
                }
              } else {
                playerLoopCount++;
                if (playerLoopCount === team.players.length) {
                  teamsLoopCount++;
                  if (teamsLoopCount === tournament.teams.length) {
                    resolve(tournament);
                  } else {
                    storePlayersOfSingleTeam(tournament.teams[teamsLoopCount]);
                  }
                } else {
                  storeSinglePlayer(team.players[playerLoopCount]);
                }
              }
            } else {
              playerLoopCount++;
              if (playerLoopCount === team.players.length) {
                teamsLoopCount++;
                if (teamsLoopCount === tournament.teams.length) {
                  resolve(tournament);
                } else {
                  storePlayersOfSingleTeam(tournament.teams[teamsLoopCount]);
                }
              } else {
                storeSinglePlayer(team.players[playerLoopCount]);
              }
            }
          } catch (error) {
            console.log(error.message, "storeAllRelations");
          }
        };

        storeSinglePlayer(team.players[playerLoopCount]);
      };
      storePlayersOfSingleTeam(tournament.teams[teamsLoopCount]);
    } catch (error) {
      console.log(error.message, "storeAllRelations");
    }
  });
};

module.exports = {
  storeTournamentCompetitorsPlayers,
};
