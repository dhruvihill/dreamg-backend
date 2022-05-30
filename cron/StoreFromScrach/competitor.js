const { makeRequest } = require("../../middleware/makeRequest");
const { connectToDb, database } = require("../../middleware/dbSuperUser");
const Player = require("./player");

class Competitor {
  id = null;
  tournamentCompetitorId = null;
  #radarId = 0;
  #name = "";
  #country = "";
  #countryCode = "";
  #displayName = "";
  #isPlayersArrived = 0;
  players = [];

  constructor(id, name, country, countryCode, displayName) {
    this.#radarId = id;
    this.#name = name;
    this.#country = country;
    this.#countryCode = countryCode;
    this.#displayName = displayName;
  }

  #fetchPlayers(tournamentRadarId) {
    return new Promise(async (resolve, reject) => {
      const { players } = await makeRequest(
        `/tournaments/sr:tournament:${tournamentRadarId}/teams/sr:competitor:${this.#radarId
        }/squads.json`
      );

      if (players && players.length > 0) {
        this.isPlayersArrived = 1;
        const totalPlayers = players.length;
        let currentPlayer = 0;

        players.forEach((player) => {
          this.players.push(player);
          currentPlayer++;
          if (currentPlayer >= totalPlayers) {
            this.#isPlayersArrived = 1;
            resolve();
          }
        });
      } else {
        const connection = await connectToDb();

        const updateIsPlayersArrivedFalg = await database("UPDATE tournament_competitor SET isPlayerArrived = 0 WHERE tournamentCompetitorId = ?;", [this.tournamentCompetitorId], connection);

        connection.release();
        this.players = [];
        this.#isPlayersArrived = 0;
        resolve();
      }
    });
  }

  storeCompetitor() {
    return new Promise(async (resolve, reject) => {
      try {
        const connection = await connectToDb();
        let [{ isExists: isTeamExist, competitorId: teamId }] = await database(
          "SELECT COUNT(competitorId) AS isExists, competitorId FROM competitors WHERE competitors.competitorRadarId = ?;",
          [this.#radarId],
          connection
        );
        if (isTeamExist) {
          connection.release();
          this.id = teamId;
          resolve();
        } else {
          const storeTournamentCompetitors = await database(
            "INSERT INTO competitors SET ?",
            {
              competitorRadarId: this.#radarId,
              competitorName: this.#name,
              competitorCountry: this.#country,
              competitorCountryCode: this.#countryCode,
              competitorDisplayName: this.#displayName,
            },
            connection
          );
          connection.release();
          this.id = storeTournamentCompetitors.insertId;
          resolve();
        }
      } catch (error) {
        error.sqlMessage ? (this.id = null) : null;
        console.log(error);
        reject(error);
      }
    });
  }

  storeCompetitorRelation(tournamentStoredId) {
    return new Promise(async (resolve, reject) => {
      try {
        const connection = await connectToDb();
        const [{ isExists, id }] = await database(
          "SELECT COUNT(*) AS isExists, tournament_competitor.tournamentCompetitorId FROM tournament_competitor WHERE tournament_competitor.tournamentId = ? AND tournament_competitor.competitorId = ?;; ",
          [tournamentStoredId, this.id],
          connection
        );
        

        if (!isExists) {
          const tournamentCompetitorRes = await database(
            "INSERT INTO tournament_competitor SET tournament_competitor.tournamentId = ?, tournament_competitor.competitorId = ?;",
            [tournamentStoredId, this.id],
            connection
          );
          if (tournamentCompetitorRes) {
            connection.release();
            this.tournamentCompetitorId = tournamentCompetitorRes.insertId;
            resolve();
          }
        } else {
          connection.release();
          this.tournamentCompetitorId = id;
          resolve();
        }
      } catch (error) {
        console.log(error);
        if (error.sqlMessage) {
          this.tournamentCompetitorId = null;
        }
        resolve();
      }
    });
  }

  storePlayers(tournamentRadarId) {
    return new Promise(async (resolve, reject) => {
      try {
        await this.#fetchPlayers(tournamentRadarId);

        const totalPlayers = this.players.length;
        let currentPlayer = 0;

        const storeSinglePlayer = async (player) => {
          try {
            const newPlayer = new Player(
              player.type,
              player.id.substr(10),
              player.name.split(", ")[1],
              player.name.split(", ")[0],
              player.nationality,
              player.country_code,
              player.date_of_birth
            );

            await newPlayer.storePlayer();
            await newPlayer.storePlayerRelation(this.tournamentCompetitorId);
            await newPlayer.getPlayerStatesAndStore();
            player.insertId = newPlayer.id;

            currentPlayer++;
            if (currentPlayer >= totalPlayers) {
              resolve();
            } else {
              storeSinglePlayer(this.players[currentPlayer]);
            }
          } catch (error) {
            console.log(error);
            reject(error);
          }
        };
        if (totalPlayers > 0) {
          storeSinglePlayer(this.players[currentPlayer]);
        } else {
          resolve();
        }
      } catch (error) {
        console.log(error);
        resolve(false);
      }
    });
  }
}

module.exports = Competitor;
