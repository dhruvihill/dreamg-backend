const database = (query, options, connection) => {
  return new Promise(async (resolve, reject) => {
    try {
      connection.query(query, options, (err, reponse) => {
        if (err) {
          if (err.code === "ER_DUP_ENTRY") {
            console.log(err.message);
            resolve(true);
          } else {
            reject(err);
          }
        } else resolve(reponse);
      });
    } catch (error) {
      console.log(error.message, "cron databse function");
    }
  });
};

const storeCompetitor = async (team, connection) => {
  return new Promise(async (resolve) => {
    try {
      let [{ isExists: isTeamExist, competitorId: teamId }] = await database(
        "SELECT COUNT(competitorId) AS isExists, competitorId FROM competitors WHERE competitors.competitorRadarId = ?;",
        [team.id.substr(14)],
        connection
      );
      if (isTeamExist) {
        resolve(teamId);
      } else {
        const storeTournamentCompetitors = await database(
          "INSERT INTO competitors SET ?",
          {
            competitorRadarId: team.id.substr(14),
            competitorName: team.name,
            competitorCountry: team.country,
            competitorCountryCode: team.country_code,
            competitorDisplayName: team.abbreviation,
          },
          connection
        );
        resolve(storeTournamentCompetitors.insertId);
      }
    } catch (error) {}
  });
};

const storeCompetitors = async (tournament, connection) => {
  return new Promise(async (resolve) => {
    let teamsLoopCount = 0;
    tournament.teams.forEach(async (team) => {
      const storeSingleCompetitorRes = await storeCompetitor(team, connection);
      team.insertId = storeSingleCompetitorRes;
      teamsLoopCount++;
      if (teamsLoopCount === tournament.teams.length) {
        resolve(tournament);
      }
    });
  });
};

module.exports = {
  storeCompetitor,
  storeCompetitors,
};
