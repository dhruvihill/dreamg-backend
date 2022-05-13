const Competitor = require("./competitor");
const { RowMatch: Match } = require("./match");
const { makeRequest } = require("../../middleware/makeRequest");
const { connectToDb, database } = require("../../middleware/dbSuperUser");

class Category {
  categoryId = null;
  #radarId = 0;
  #name = "";

  constructor(id, name) {
    this.#radarId = id;
    this.#name = name;
  }

  storeCategory() {
    return new Promise(async (resolve, reject) => {
      try {
        const connection = await connectToDb();
        let [{ isExists: isCategoryExist, categoryId }] = await database(
          "SELECT COUNT(tournament_category.categoryId ) AS isExists, tournament_category.categoryId AS categoryId FROM tournament_category WHERE tournament_category.categoryRadarId = ?;",
          [this.#radarId],
          connection
        );
        if (!isCategoryExist) {
          const storeCategoryRes = await database(
            "INSERT INTO tournament_category (categoryRadarId, categoryString) VALUES (?,?)",
            [this.#radarId, this.#name],
            connection
          );
          connection.release();
          this.categoryId = storeCategoryRes.insertId;
          resolve();
        } else {
          connection.release();
          this.categoryId = categoryId;
          resolve();
        }
      } catch (error) {
        this.categoryId = null;
        console.log(error, "storeCategoryAndTyprParent");
      }
    });
  }
}

class Type {
  typeId = null;
  #type = "";

  constructor(tournamentType) {
    this.#type = tournamentType;
  }

  storeType() {
    return new Promise(async (resolve, reject) => {
      try {
        const connection = await connectToDb();
        let [{ isExists: isTypeExist, typeId }] = await database(
          "SELECT COUNT(tournament_type.tournamentTypeId) AS isExists, tournament_type.tournamentTypeId AS typeId FROM tournament_type WHERE tournament_type.tournamnetTypeString = ?;",
          [this.#type],
          connection
        );
        if (!isTypeExist) {
          const storeType = await database(
            "INSERT INTO tournament_type (tournamnetTypeString ) VALUES (?);",
            [this.#type],
            connection
          );
          connection.release();
          this.typeId = storeType.insertId;
          resolve();
        } else {
          connection.release();
          this.typeId = typeId;
          resolve();
        }
      } catch (error) {
        this.typeId = null;
        console.log(error, "storeTypeParent");
        resolve();
      }
    });
  }
}

class Tournament {
  id = null;
  #radarId = 0; // tournament id of sports radar
  #competitors = [];
  #matches = [];
  #tournamentDetails = {
    type: "",
    gender: "",
    categoryId: 0,
    categoryName: "",
    name: "",
    seasonId: 0,
    seasonName: "",
    seasonStartDate: "",
    seasonEndDate: "",
    country: "",
    countryCode: "",
    isCompetitorArrived: 0,
    isMatchesArrived: 0,
    year: 0,
  };

  constructor(id) {
    this.#radarId = id;
  }

  #fetchTournamentDetails() {
    return new Promise(async (resolve, reject) => {
      try {
        const { tournament, groups } = await makeRequest(
          `tournaments/sr:tournament:${this.#radarId}/info.json`
        );
        const { sport_events: matches } = await makeRequest(
          `/tournaments/sr:tournament:${this.#radarId}/schedule.json`
        );

        if (tournament) {
          this.#tournamentDetails.type = tournament.type;
          this.#tournamentDetails.gender = tournament.gender;
          this.#tournamentDetails.categoryId =
            tournament.category.id.substr(12);
          this.#tournamentDetails.categoryName = tournament.category.name;
          this.#tournamentDetails.name = tournament.name;
          this.#tournamentDetails.seasonId =
            tournament.current_season.id.substr(10);
          this.#tournamentDetails.seasonName = tournament.current_season.name;
          this.#tournamentDetails.seasonStartDate =
            tournament.current_season.start_date;
          this.#tournamentDetails.seasonEndDate =
            tournament.current_season.end_date;
          this.#tournamentDetails.country = tournament.category.name;
          this.#tournamentDetails.countryCode =
            tournament.category.country_code;
          this.#tournamentDetails.year = parseInt(
            tournament.current_season.year || 0
          );
          if (groups && groups.length > 0) {
            this.#tournamentDetails.isCompetitorArrived = 1;

            const totalGroups = groups.length;
            let currentGroup = 0;

            groups.forEach((group) => {
              const totalTeams = group.teams.length;
              let currentTeam = 0;

              group.teams.forEach((team) => {
                this.#competitors.push(team);
                currentTeam++;
                if (currentTeam === totalTeams) {
                  currentGroup++;
                  if (currentGroup === totalGroups) {
                    this.#tournamentDetails.isMatchesArrived = 1;
                    if (matches && matches.length) {
                      const totalMatches = matches.length;
                      let currentMatch = 0;

                      this.#tournamentDetails.isMatchesArrived = 1;
                      matches.forEach((match) => {
                        this.#matches.push(match);

                        currentMatch++;
                        if (currentMatch === totalMatches) {
                          this.#tournamentDetails.isMatchesArrived = 1;
                          resolve();
                        }
                      });
                    } else {
                      this.#tournamentDetails.isMatchesArrived = 0;
                      resolve();
                    }
                  }
                }
              });
            });
          } else {
            this.#tournamentDetails.isCompetitorArrived = 0;
            resolve();
          }
        } else {
          throw new Error("tournament is null");
        }
      } catch (error) {
        console.log(error);
        reject(error);
      }
    });
  }

  storeTournament() {
    return new Promise(async (resolve, reject) => {
      try {
        const connection = await connectToDb();
        const [{ isExists, id: tournamentStoredId }] = await database(
          "SELECT COUNT(*) AS isExists, tournamentId AS id FROM fullseriesdetails WHERE fullseriesdetails.tournamentRadarId = ?;",
          [this.#radarId],
          connection
        );

        if (!isExists) {
          await this.#fetchTournamentDetails();

          const tournamentType = new Type(this.#tournamentDetails.type);
          const tournamentCategory = new Category(
            this.#tournamentDetails.categoryId,
            this.#tournamentDetails.categoryName
          );
          await tournamentType.storeType();
          await tournamentCategory.storeCategory();

          const storeTournamentRes = await database(
            "INSERT INTO `tournament_information`(`tournamentRadarId`, `currentSeasonRadarId`, `tournamentName`, `currentSeasonName`, `seasonStartDate`, `seasonEndDate`, `tournamentMatchType`, `tournamentCategory`, `tournamentPlayersGender`, `tournamentCountry`, `tournamentCountryCode`, `isCompetitorsArrived`, `isMatchesArrived`) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",
            [
              this.#radarId,
              this.#tournamentDetails.seasonId,
              this.#tournamentDetails.name,
              this.#tournamentDetails.seasonName,
              this.#tournamentDetails.seasonStartDate,
              this.#tournamentDetails.seasonEndDate,
              tournamentType.typeId,
              tournamentCategory.categoryId,
              this.#tournamentDetails.gender,
              this.#tournamentDetails.country,
              this.#tournamentDetails.countryCode,
              this.#tournamentDetails.isCompetitorArrived,
              this.#tournamentDetails.isMatchesArrived,
            ],
            connection
          );
          if (storeTournamentRes && storeTournamentRes.insertId > 0) {
            connection.release();
            this.id = storeTournamentRes.insertId;
            resolve();
          }
        } else {
          connection.release();
          this.id = tournamentStoredId;
          resolve();
        }
      } catch (error) {
        if (error.sqlMessage) {
          this.id = null;
        }
        console.log(error);
        resolve();
      }
    });
  }

  storeCompetitors() {
    return new Promise(async (resolve, reject) => {
      try {
        const totalCompetitors = this.#competitors.length;
        let currentCompetitor = 0;

        const storeSingleCompetitor = async (competitor) => {
          try {
            const newCompetitor = new Competitor(
              competitor.id.substr(14),
              competitor.name,
              competitor.country,
              competitor.country_code,
              competitor.abbreviation
            );

            await newCompetitor.storeCompetitor();
            await newCompetitor.storeCompetitorRelation(this.id);
            await newCompetitor.storePlayers(this.#radarId);
            competitor.insertId = newCompetitor.id;
            competitor.players = newCompetitor.players;

            currentCompetitor++;
            if (currentCompetitor >= totalCompetitors) {
              resolve(true);
            } else {
              storeSingleCompetitor(this.#competitors[currentCompetitor]);
            }
          } catch (error) {
            console.log(error);
            reject(error);
          }
        };
        storeSingleCompetitor(this.#competitors[currentCompetitor]);
      } catch (error) {
        console.log(error);
        reject(error);
      }
    });
  }

  storeMatches() {
    return new Promise(async (resolve, reject) => {
      try {
        const totalMatches = this.#matches.length;
        let currentMatch = 0;

        const storeSingleMatch = async (match) => {
          try {
            const competitor1 = this.#competitors.find(
              (competitor) => competitor.id === match.competitors[0].id
            );
            const competitor2 = this.#competitors.find(
              (competitor) => competitor.id === match.competitors[1].id
            );
            const newMatch = new Match(
              match.id.substr(9),
              match.status,
              this.id,
              match.scheduled,
              competitor1,
              competitor2,
              match.venue.name,
              match.venue.id.substr(9),
              match.venue.capacity,
              match.venue.city_name,
              match.venue.country_name,
              match.venue.country_code,
              match.venue.bowling_ends[0].name,
              match.venue.bowling_ends[1].name,
              match.venue.map_coordinates
            );
            await newMatch.storeMatch();
            await newMatch.storeMatchPlayers();

            currentMatch++;
            if (currentMatch >= totalMatches) {
              resolve();
            } else {
              storeSingleMatch(this.#matches[currentMatch]);
            }
          } catch (error) {
            console.log(error);
            reject(error);
          }
        };

        storeSingleMatch(this.#matches[currentMatch]);
      } catch (error) {
        console.log(error);
        reject(error);
      }
    });
  }
}

const a = async () => {
  try {
    const tournament = new Tournament("2472");
    await tournament.storeTournament();
    await tournament.storeCompetitors();
    await tournament.storeMatches();
    console.log("stored success");
  } catch (error) {
    console.log(error);
  }
};
a();

// module.exports = Tournament;
