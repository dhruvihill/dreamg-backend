const { connectToDb, database } = require("../cron/makeRequest");

class MatchStatistics {
  id = 0;
  matchDetails = {
    matchRadarId: 0,
    matchTournamentId: 0,
    matchStartDateTime: "",
    isPointsCalculated: 0,
    tossWonBy: 0,
    tossDecision: 0,
    matchTypeId: 0,
    matchTyprString: "",
    matchStatus: 0,
    matchStatusString: "",
    seriesName: "",
    seriesDname: "",
    isLineUpOut: 0,
    displayName: "",
  };
  competitors = [
    {
      teamId: 0,
      name: "",
      countryName: "",
      countryCode: "",
      displayName: "",
      teamRadarId: 0,
    },
  ];
  venue = {
    venueId: 0,
    venueName: "",
    venueCity: "",
    venueCapacity: 0,
    venueCountry: "",
    end1: "",
    end2: "",
  };
  players = [
    {
      playerId: 0,
      teamId: 0,
      credits: 0,
      isSelected: 0,
      points: 0,
      playerName: "",
      playerDisplayName: "",
      roleId: 0,
      roleName: "",
    },
  ];
  pitchReport = {
    totalPlayedMatch: 0,
    pitchWinningStats: {
      winsBattingFirst: 0,
      winsBowlingFirst: 0,
    },
    averageFantacyPoints: 0,
    totalTeamsCreated: 0,
    pitchScoreStats: {
      avgFirstinningScore: 0,
      avgTotalScore: 0,
      avgTossWinnerOptToBowl: 0,
      avgTeamBowlingFirstWins: 0,
    },
    topPlayersAtVenue: {
      batsman: [
        {
          playerId: 0,
          totalRuns: 0,
          runsPerMatch: 0,
          totalMatches: 0,
          averageStrikeRate: 0,
        },
      ],
      bowler: [
        {
          playerId: 0,
          totalWickets: 0,
          totalMatches: 0,
          averageEconomy: 0,
        },
      ],
    },
  };
  teamComparison = {
    totalMatches: 0,
    winProbability: [
      {
        teamId: 0,
        winPercentage: 49.5,
      },
      {
        teamId: 0,
        winPercentage: 50.5,
      },
    ],
    matchesAgainstEachOther: {
      matchWithDecision: [
        {
          teamId: 0,
          totalWins: 0,
        },
      ],
      matchWithoutDecision: 0,
    },
    teamStrengths: {
      teams: [
        {
          battingFirstWins: 0,
          battingSecondWins: 0,
          teamId: 0,
          totalMatches: 0,
        },
      ],
    },
    matchesRecent: [
      {
        winnerId: 0,
        looserId: 0,
      },
    ],
  };

  constructor(id) {
    this.id = id;
  }

  getMatchDetails() {
    return new Promise(async (resolve, reject) => {
      try {
        const connection = await connectToDb();
        const [[matchDetails], competitors, [venue]] = await database(
          "SELECT `matchRadarId`, `matchTournamentId`, `matchStartDateTime`, `isPointsCalculated`, `tossWonBy`, `tossDecision`, `matchTypeId`, `matchTyprString`, `matchStatus`, `matchStatusString`, `seriesName`, `seriesDname`, `isLineUpOut`, `displayName` FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?; SELECT allteams.teamId, allteams.teamRadarId, allteams.name, allteams.countryName, allteams.countryCode, allteams.displayName FROM `fullmatchdetails` JOIN allteams ON allteams.teamId IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id) WHERE fullmatchdetails.matchId = ?; SELECT fullmatchdetails.venueId, fullmatchdetails.venue AS venueName, fullmatchdetails.venueCity, fullmatchdetails.venueCapacity, fullmatchdetails.venuesCountry, fullmatchdetails.end2, fullmatchdetails.end1 FROM `fullmatchdetails` WHERE matchId = ?;",
          [this.id, this.id, this.id],
          connection
        );
        connection.release();
        this.matchDetails = matchDetails;
        this.competitors = [...competitors];
        this.venue = venue;
        resolve(this);
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  getMatchPlayers() {
    return new Promise(async (resolve, reject) => {
      try {
        const connection = await connectToDb();
        const [lineUp] = await database(
          "CALL getPlayers(?, 0)",
          [this.id],
          connection
        );
        connection.release();
        this.players = lineUp;
        if (this.matchDetails.isLineUpOut === 1) {
          const lineUpOut = this.players.filter(
            (player) => player.isSelected === 1
          );
          resolve(this.matchDetails.isLineUpOut, lineUpOut);
        } else {
          resolve(this.matchDetails.isLineUpOut);
        }
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  getPitchReport() {
    return new Promise(async (resolve, reject) => {
      try {
        const winStatsQuery =
          "SELECT COUNT(*) AS totalMatches, COALESCE((SUM((scorcardDetails.tossWonBy = scorcardDetails.winnerId AND scorcardDetails.tossDecision = 'bat') OR (scorcardDetails.tossWonBy != scorcardDetails.winnerId AND scorcardDetails.tossDecision = 'bowl')) / COUNT(*)) * 100, 0) AS winsBattingFirst, COALESCE((SUM((scorcardDetails.tossWonBy = scorcardDetails.winnerId AND scorcardDetails.tossDecision = 'bowl') OR (scorcardDetails.tossWonBy != scorcardDetails.winnerId AND scorcardDetails.tossDecision = 'bat')) / COUNT(*)) * 100, 0) AS winsBowlingFirst FROM fullmatchdetails JOIN scorcardDetails ON scorcardDetails.matchId =fullmatchdetails.matchId WHERE fullmatchdetails.venueId IN (SELECT fullmatchdetails.venueId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchStatusString IN ('ended', 'closed') AND fullmatchdetails.matchStartDateTime < (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?);";

        const pointsStatsQuery =
          "SELECT COUNT(*) AS totalTeamsCreated, COALESCE(AVG(userTeamDetails.userTeamPoints),0) AS averagePoints FROM userTeamDetails WHERE userTeamDetails.matchId IN (SELECT fullmatchdetails.matchId FROM fullmatchdetails WHERE fullmatchdetails.venueId IN (SELECT fullmatchdetails.venueId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchStatusString IN ('ended', 'closed') AND fullmatchdetails.matchStartDateTime < (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?));";

        const avgScoreQuery =
          "SELECT COALESCE(AVG(IF(scorcardInning.inningNumber = 1, scorcardInning.runs, null)), 0) AS averageFirstinningScore, COALESCE((AVG(scorcardInning.runs) * 2), 0) AS averageTotalScore FROM fullmatchdetails JOIN scorcardDetails ON scorcardDetails.matchId = fullmatchdetails.matchId JOIN scorcardInning ON scorcardInning.scorcardId = scorcardDetails.scorcardId WHERE fullmatchdetails.matchId IN (SELECT fullmatchdetails.matchId FROM fullmatchdetails WHERE fullmatchdetails.venueId IN (SELECT fullmatchdetails.venueId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchStartDateTime < (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchStatusString IN ('ended', 'closed'));";

        const tossWinnerStatsQuery =
          "SELECT COALESCE((SUM(IF(scorcardDetails.tossDecision = 'bowl', 1, 0)) / COUNT(*)) * 100, 0) AS tossWinnerOptToBowl, COALESCE((SUM(IF(scorcardDetails.tossWonBy = scorcardDetails.winnerId AND scorcardDetails.tossDecision = 'bowl', 1, 0)) / COUNT(*)) * 100, 0) AS teamBowlingFirstWins FROM fullmatchdetails JOIN scorcardDetails ON scorcardDetails.matchId = fullmatchdetails.matchId WHERE fullmatchdetails.venueId IN (SELECT fullmatchdetails.venueId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchStatusString IN ('ended', 'closed') AND fullmatchdetails.matchStartDateTime < (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?);";

        const topBatsManQuery =
          "SELECT inningBatsmans.playerId, SUM(inningBatsmans.runs) AS totalRuns, SUM(inningBatsmans.runs) / COUNT(*) AS runsPerMatch, COUNT(*) AS totalMatches, AVG(inningBatsmans.strikeRate) AS averageStrikeRate FROM fullmatchdetails JOIN scorcardDetails ON scorcardDetails.matchId = fullmatchdetails.matchId JOIN scorcardInning ON scorcardInning.scorcardId = scorcardDetails.scorcardId JOIN inningBatsmans ON inningBatsmans.scorcardInningId = scorcardInning.scorcardInningId WHERE fullmatchdetails.matchId IN (SELECT fullmatchdetails.matchId FROM fullmatchdetails WHERE fullmatchdetails.venueId IN (SELECT fullmatchdetails.venueId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchStatusString IN ('ended', 'closed') AND (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) - fullmatchdetails.matchStartDateTime < (2 * 365 * 24 * 60 * 60 * 1000)) AND (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) > fullmatchdetails.matchStartDateTime AND inningBatsmans.playerId IN (SELECT fullplayerdetails.playerId FROM fullplayerdetails WHERE fullplayerdetails.matchId = ?) GROUP BY inningBatsmans.playerId ORDER BY totalRuns DESC, runsPerMatch DESC, averageStrikeRate DESC LIMIT 5;";

        const topBowlerQuery =
          "SELECT inningBowlers.playerId, SUM(inningBowlers.wickets) AS totalWickets, COUNT(*) AS totalMatches, AVG(inningBowlers.economyRate) AS averageEconomy FROM fullmatchdetails JOIN scorcardDetails ON scorcardDetails.matchId = fullmatchdetails.matchId JOIN scorcardInning ON scorcardInning.scorcardId = scorcardDetails.scorcardId JOIN inningBowlers ON inningBowlers.scorcardInningId = scorcardInning.scorcardInningId WHERE fullmatchdetails.matchId IN (SELECT fullmatchdetails.matchId FROM fullmatchdetails WHERE fullmatchdetails.venueId IN (SELECT fullmatchdetails.venueId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchStatusString IN ('ended', 'closed') AND (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) - fullmatchdetails.matchStartDateTime < (2 * 365 * 24 * 60 * 60 * 1000)) AND (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) > fullmatchdetails.matchStartDateTime AND inningBowlers.playerId IN (SELECT fullplayerdetails.playerId FROM fullplayerdetails WHERE fullplayerdetails.matchId = ?) GROUP BY inningBowlers.playerId ORDER BY totalWickets DESC, averageEconomy DESC LIMIT 5;";

        const connection = await connectToDb();
        const [
          [{ winsBattingFirst, winsBowlingFirst, totalMatches }],
          [{ averagePoints, totalTeamsCreated }],
          [{ averageFirstinningScore, averageTotalScore }],
          [{ tossWinnerOptToBowl, teamBowlingFirstWins }],
          topBatsMan,
          topBowler,
        ] = await database(
          `${winStatsQuery}${pointsStatsQuery}${avgScoreQuery}${tossWinnerStatsQuery}${topBatsManQuery}${topBowlerQuery}`,
          [...Array(22).fill(this.id)],
          connection
        );
        connection.release();
        this.pitchReport.totalPlayedMatch = totalMatches;
        this.pitchReport.pitchWinningStats.winsBattingFirst = winsBattingFirst;
        this.pitchReport.pitchWinningStats.winsBowlingFirst = winsBowlingFirst;
        this.pitchReport.totalTeamsCreated = totalTeamsCreated;
        this.pitchReport.averageFantacyPoints = averagePoints;
        this.pitchReport.pitchScoreStats.avgFirstinningScore =
          averageFirstinningScore;
        this.pitchReport.pitchScoreStats.avgTotalScore = averageTotalScore;
        this.pitchReport.pitchScoreStats.avgTossWinnerOptToBowl =
          tossWinnerOptToBowl;
        this.pitchReport.pitchScoreStats.avgTeamBowlingFirstWins =
          teamBowlingFirstWins;
        this.pitchReport.topPlayersAtVenue.batsman = topBatsMan;
        this.pitchReport.topPlayersAtVenue.bowler = topBowler;

        // this.pitchReport.topPlayersAtVenue.batsman =
        //   this.pitchReport.topPlayersAtVenue.batsman.map((batsman) => {
        //     const player = this.players.find((player) => {
        //       return player.playerId === batsman.playerId;
        //     });
        //     batsman = { ...batsman, ...player };
        //     return batsman;
        //   });
        // this.pitchReport.topPlayersAtVenue.bowler =
        //   this.pitchReport.topPlayersAtVenue.bowler.map((bowler) => {
        //     const player = this.players.find((player) => {
        //       return player.playerId === bowler.playerId;
        //     });
        //     bowler = { ...bowler, ...player };
        //     return bowler;
        //   });

        resolve();
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  getTeamComparison() {
    return new Promise(async (resolve, reject) => {
      try {
        const matchAgainstEachOtherQuery =
          "SELECT (SELECT COUNT(*) FROM fullmatchdetails AS inner2FullmatchDetails JOIN scorcardDetails ON scorcardDetails.matchId = inner2FullmatchDetails.matchId WHERE inner2FullmatchDetails.team1Id IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id) AND inner2FullmatchDetails.team2Id IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id) AND scorcardDetails.winnerId = allteams.teamId AND fullmatchdetails.matchStartDateTime > inner2FullmatchDetails.matchStartDateTime ) AS totalWins, allteams.teamId FROM fullmatchdetails JOIN allteams ON allteams.teamId IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id) WHERE fullmatchdetails.matchId = ?;SELECT (SELECT COUNT(*) FROM fullmatchdetails AS innnerFullMatchDetails WHERE innnerFullMatchDetails.team1Id IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id) AND innnerFullMatchDetails.team2Id IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id) AND innnerFullMatchDetails.matchStartDateTime < fullmatchdetails.matchStartDateTime) AS totalMatches FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?;";

        const competitorStrengthQuery =
          "SELECT (SELECT COUNT(*) FROM fullmatchdetails AS inner2FullmatchDetails JOIN scorcardDetails ON scorcardDetails.matchId = inner2FullmatchDetails.matchId JOIN scorcardInning ON scorcardInning.scorcardId = scorcardDetails.scorcardId WHERE (inner2FullmatchDetails.team1Id IN (allteams.teamId) OR inner2FullmatchDetails.team2Id IN (allteams.teamId)) AND inner2FullmatchDetails.matchTypeId = fullmatchdetails.matchTypeId AND inner2FullmatchDetails.matchStatusString IN ('ended', 'closed') AND scorcardInning.inningNumber = 1 AND scorcardInning.battingTeam = allteams.teamId AND scorcardDetails.winnerId = allteams.teamId AND (fullmatchdetails.matchStartDateTime > inner2FullmatchDetails.matchStartDateTime) AND (inner2FullmatchDetails.matchStartDateTime - fullmatchdetails.matchStartDateTime) < (2 * 365 * 24 * 60 * 60 * 1000)) AS battingFirstWins, (SELECT COUNT(*) FROM fullmatchdetails AS inner2FullmatchDetails JOIN scorcardDetails ON scorcardDetails.matchId = inner2FullmatchDetails.matchId JOIN scorcardInning ON scorcardInning.scorcardId = scorcardDetails.scorcardId WHERE (inner2FullmatchDetails.team1Id IN (allteams.teamId) OR inner2FullmatchDetails.team2Id IN (allteams.teamId)) AND inner2FullmatchDetails.matchTypeId = fullmatchdetails.matchTypeId AND inner2FullmatchDetails.matchStatusString IN ('ended', 'closed') AND scorcardInning.inningNumber = 2 AND scorcardInning.battingTeam = allteams.teamId AND scorcardDetails.winnerId = allteams.teamId AND (fullmatchdetails.matchStartDateTime > inner2FullmatchDetails.matchStartDateTime) AND (inner2FullmatchDetails.matchStartDateTime - fullmatchdetails.matchStartDateTime) < (2 * 365 * 24 * 60 * 60 * 1000)) AS battingSecondWins, (SELECT COUNT(*) FROM fullmatchdetails AS inner2FullmatchDetails JOIN scorcardDetails ON scorcardDetails.matchId = inner2FullmatchDetails.matchId WHERE (inner2FullmatchDetails.team1Id IN (allteams.teamId) OR inner2FullmatchDetails.team2Id IN (allteams.teamId)) AND inner2FullmatchDetails.matchTypeId = fullmatchdetails.matchTypeId AND inner2FullmatchDetails.matchStatusString IN ('ended', 'closed') AND scorcardDetails.winnerId = allteams.teamId AND (fullmatchdetails.matchStartDateTime > inner2FullmatchDetails.matchStartDateTime) AND (inner2FullmatchDetails.matchStartDateTime - fullmatchdetails.matchStartDateTime) < (2 * 365 * 24 * 60 * 60 * 1000)) AS totalMatches, allteams.teamId FROM fullmatchdetails JOIN allteams ON allteams.teamId IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id) WHERE matchId = ?;";

        const matchesPlayedRecentlyQuery =
          "SELECT scorcardDetails.winnerId AS winnerId, IF(scorcardDetails.winnerId = team1Id, team2Id, IF(scorcardDetails.winnerId = team2Id, team1Id, null)) AS looserId FROM fullmatchdetails JOIN scorcardDetails ON scorcardDetails.matchId = fullmatchdetails.matchId WHERE fullmatchdetails.team1Id IN (SELECT allteams.teamId FROM fullmatchdetails JOIN allteams ON allteams.teamId IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id) WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.team2Id IN (SELECT allteams.teamId FROM fullmatchdetails JOIN allteams ON allteams.teamId IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id) WHERE fullmatchdetails.matchId = ?) AND (fullmatchdetails.matchStartDateTime < (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?)) ORDER BY fullmatchdetails.matchStartDateTime DESC LIMIT 5;";

        const connection = await connectToDb();
        const [competitorwins, [{ totalMatches }], teams, recentMatches] =
          await database(
            `${matchAgainstEachOtherQuery}${competitorStrengthQuery}${matchesPlayedRecentlyQuery}`,
            [...Array(9).fill(this.id)],
            connection
          );
        connection.release();

        this.teamComparison.winProbability = [
          {
            teamId: competitorwins[0].teamId,
            winProbability: 50,
          },
          {
            teamId: competitorwins[1].teamId,
            winProbability: 50,
          },
        ];

        this.teamComparison.totalMatches = totalMatches;
        this.teamComparison.matchesAgainstEachOther.matchWithDecision =
          competitorwins;
        this.teamComparison.matchesAgainstEachOther.matchWithoutDecision =
          totalMatches -
          (competitorwins[0].totalWins, competitorwins[1].totalWins);
        this.teamComparison.teamStrengths.teams = teams;
        this.teamComparison.matchesRecent = recentMatches;

        resolve();
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }
}

const a = async () => {
  const match = await new MatchStatistics(26).getMatchDetails();
  await match.getMatchPlayers();
  await match.getPitchReport();
  await match.getTeamComparison();
};
// a();

module.exports = MatchStatistics;
