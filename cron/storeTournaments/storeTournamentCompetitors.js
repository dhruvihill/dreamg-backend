const { database } = require("../makeRequest");

const storeTournamentCompetitors = async (tournament, connection) => {
  return new Promise((resolve) => {
    try {
      let teamsLoopCount = 0;
      tournament.teams.forEach(async (team) => {
        try {
          const [{ isExists: isTeamExists, tournamentCompetitorId }] =
            await database(
              "SELECT COUNT(tournament_competitor.tournamentCompetitorId) AS isExists, tournament_competitor.tournamentCompetitorId AS tournamentCompetitorId, isPlayerArrived FROM `tournament_competitor` WHERE tournament_competitor.tournamentId = ? AND tournament_competitor.competitorId = ?;",
              [tournament.insertId, team.insertId],
              connection
            );
          if (!isTeamExists) {
            const storeTournamentCompetitors = await database(
              "INSERT INTO tournament_competitor SET ?",
              {
                tournamentId: tournament.insertId,
                competitorId: team.insertId,
                isPlayerArrived: team.isPlayerArrived,
              },
              connection
            );
            if (storeTournamentCompetitors.insertId) {
              teamsLoopCount++;
              team.tournamentCompetitorId = storeTournamentCompetitors.insertId;
              if (teamsLoopCount === tournament.teams.length) {
                resolve(tournament);
              }
            }
          } else {
            teamsLoopCount++;
            team.tournamentCompetitorId = tournamentCompetitorId;
            if (teamsLoopCount === tournament.teams.length) {
              resolve(tournament);
            }
          }
        } catch (error) {
          console.log(error, "storeAllRelations");
        }
      });
    } catch (error) {
      console.log(error, "storeAllRelations");
    }
  });
};

module.exports = { storeTournamentCompetitors };
