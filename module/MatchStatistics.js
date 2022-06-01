const { fetchData } = require("../database/db_connection");

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
      basedOnYears: "2",
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
      basedOnYears: "2",
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
  fantasyPoints = {
    thisSeason: [],
    lastFiveMatches: [],
  };
  playerPerformance = {
    players: [
      {
        playerId: 0,
        avgPoints: 0,
        totalMatches: 0,
        playerPerformance: "",
      },
    ],
    basedOnYears: "2",
    playerPerformance: {
      Prime: "100+",
      InForm: "50-100",
      Good: "30-50",
      Average: "20-30",
      Poor: "10-20",
      Weak: "0-10",
    },
  };
  statistics = {
    players: {
      topBatsMan: [
        {
          playerId: 0,
          averageStrikeRate: 0,
          totalMatches: 0,
          runsPerMatch: 0,
          totalRuns: 0,
        },
      ],
      topBowlers: [
        {
          playerId: 0,
          economy: 0,
          totalMatches: 0,
          totalWickets: 0,
        },
      ],
    },
    basedOnYears: "2",
  };

  constructor(id) {
    this.id = id;
  }

  #getMatchPlayers() {
    return new Promise(async (resolve, reject) => {
      try {
        const [lineUp] = await fetchData("CALL getPlayers(?, 0)", [this.id]);

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

  getMatchDetails() {
    return new Promise(async (resolve, reject) => {
      try {
        await this.#getMatchPlayers();

        const [[matchDetails], competitors, [venue]] = await fetchData(
          "SELECT `matchRadarId`, `matchTournamentId`, `matchStartDateTime`, `isPointsCalculated`, `tossWonBy`, `tossDecision`, `matchTypeId`, `matchTyprString`, `matchStatus`, `matchStatusString`, `seriesName`, `seriesDname`, `isLineUpOut`, `displayName` FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?; SELECT allteams.teamId, allteams.teamRadarId, allteams.name, allteams.countryName, allteams.countryCode, allteams.displayName FROM `fullmatchdetails` JOIN allteams ON allteams.teamId IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id) WHERE fullmatchdetails.matchId = ?; SELECT fullmatchdetails.venueId, fullmatchdetails.venue AS venueName, fullmatchdetails.venueCity, fullmatchdetails.venueCapacity, fullmatchdetails.venuesCountry, fullmatchdetails.end2, fullmatchdetails.end1 FROM `fullmatchdetails` WHERE matchId = ?;",
          [this.id, this.id, this.id]
        );

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

  getPitchReport() {
    return new Promise(async (resolve, reject) => {
      try {
        const winStatsQuery =
          "SELECT COUNT(*) AS totalMatches, COALESCE((SUM((scorcardDetails.tossWonBy = scorcardDetails.winnerId AND scorcardDetails.tossDecision = 'bat') OR (scorcardDetails.tossWonBy != scorcardDetails.winnerId AND scorcardDetails.tossDecision = 'bowl')) / COUNT(*)) * 100, 0) AS winsBattingFirst, COALESCE((SUM((scorcardDetails.tossWonBy = scorcardDetails.winnerId AND scorcardDetails.tossDecision = 'bowl') OR (scorcardDetails.tossWonBy != scorcardDetails.winnerId AND scorcardDetails.tossDecision = 'bat')) / COUNT(*)) * 100, 0) AS winsBowlingFirst FROM fullmatchdetails JOIN scorcardDetails ON scorcardDetails.matchId =fullmatchdetails.matchId WHERE fullmatchdetails.venueId IN (SELECT fullmatchdetails.venueId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchStatusString IN ('ended', 'closed') AND fullmatchdetails.matchStartDateTime < (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?);";

        const pointsStatsQuery =
          "SELECT COUNT(*) AS totalTeamsCreated, COALESCE(AVG(userTeamDetails.userTeamPoints),0) AS averagePoints FROM userTeamDetails WHERE userTeamDetails.matchId IN (SELECT fullmatchdetails.matchId FROM fullmatchdetails WHERE fullmatchdetails.venueId IN (SELECT fullmatchdetails.venueId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchStatusString IN ('ended', 'closed') AND fullmatchdetails.matchStartDateTime < (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?));";

        const avgScoreQuery =
          "SELECT COALESCE(AVG(IF(scorcardInning.inningNumber = 1, scorcardInning.runs, null)), 0) AS averageFirstinningScore, COALESCE((AVG(scorcardInning.runs)), 0) AS averageTotalScore FROM fullmatchdetails JOIN scorcardDetails ON scorcardDetails.matchId = fullmatchdetails.matchId JOIN scorcardInning ON scorcardInning.scorcardId = scorcardDetails.scorcardId WHERE fullmatchdetails.matchId IN (SELECT fullmatchdetails.matchId FROM fullmatchdetails WHERE fullmatchdetails.venueId IN (SELECT fullmatchdetails.venueId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchStartDateTime < (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchStatusString IN ('ended', 'closed'));";

        const tossWinnerStatsQuery =
          "SELECT COALESCE((SUM(IF(scorcardDetails.tossDecision = 'bowl', 1, 0)) / COUNT(*)) * 100, 0) AS tossWinnerOptToBowl, COALESCE((SUM(IF(scorcardDetails.tossWonBy = scorcardDetails.winnerId AND scorcardDetails.tossDecision = 'bowl', 1, 0)) / COUNT(*)) * 100, 0) AS teamBowlingFirstWins FROM fullmatchdetails JOIN scorcardDetails ON scorcardDetails.matchId = fullmatchdetails.matchId WHERE fullmatchdetails.venueId IN (SELECT fullmatchdetails.venueId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchStatusString IN ('ended', 'closed') AND fullmatchdetails.matchStartDateTime < (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?);";

        const topBatsManQuery =
          "SELECT inningBatsmans.playerId, COALESCE(SUM(inningBatsmans.runs), 0) AS totalRuns, COALESCE(SUM(inningBatsmans.runs), 0) / COUNT(*) AS runsPerMatch, COUNT(*) AS totalMatches, AVG(inningBatsmans.strikeRate) AS averageStrikeRate FROM fullmatchdetails JOIN scorcardDetails ON scorcardDetails.matchId = fullmatchdetails.matchId JOIN scorcardInning ON scorcardInning.scorcardId = scorcardDetails.scorcardId JOIN inningBatsmans ON inningBatsmans.scorcardInningId = scorcardInning.scorcardInningId WHERE fullmatchdetails.matchId IN (SELECT fullmatchdetails.matchId FROM fullmatchdetails WHERE fullmatchdetails.venueId IN (SELECT fullmatchdetails.venueId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchStatusString IN ('ended', 'closed') AND (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) - fullmatchdetails.matchStartDateTime < (? * 365 * 24 * 60 * 60 * 1000)) AND (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) > fullmatchdetails.matchStartDateTime AND inningBatsmans.playerId IN (SELECT fullplayerdetails.playerId FROM fullplayerdetails WHERE fullplayerdetails.matchId = ?) GROUP BY inningBatsmans.playerId ORDER BY totalRuns DESC, runsPerMatch DESC, averageStrikeRate DESC LIMIT 5;";

        const topBowlerQuery =
          "SELECT inningBowlers.playerId, COALESCE(SUM(inningBowlers.wickets), 0) AS totalWickets, COUNT(*) AS totalMatches, AVG(inningBowlers.economyRate) AS averageEconomy FROM fullmatchdetails JOIN scorcardDetails ON scorcardDetails.matchId = fullmatchdetails.matchId JOIN scorcardInning ON scorcardInning.scorcardId = scorcardDetails.scorcardId JOIN inningBowlers ON inningBowlers.scorcardInningId = scorcardInning.scorcardInningId WHERE fullmatchdetails.matchId IN (SELECT fullmatchdetails.matchId FROM fullmatchdetails WHERE fullmatchdetails.venueId IN (SELECT fullmatchdetails.venueId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchStatusString IN ('ended', 'closed') AND (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) - fullmatchdetails.matchStartDateTime < (? * 365 * 24 * 60 * 60 * 1000)) AND (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) > fullmatchdetails.matchStartDateTime AND inningBowlers.playerId IN (SELECT fullplayerdetails.playerId FROM fullplayerdetails WHERE fullplayerdetails.matchId = ?) GROUP BY inningBowlers.playerId ORDER BY totalWickets DESC, averageEconomy DESC LIMIT 5;";

        const [
          [{ winsBattingFirst, winsBowlingFirst, totalMatches }],
          [{ averagePoints, totalTeamsCreated }],
          [{ averageFirstinningScore, averageTotalScore }],
          [{ tossWinnerOptToBowl, teamBowlingFirstWins }],
          topBatsMan,
          topBowler,
        ] = await fetchData(
          `${winStatsQuery}${pointsStatsQuery}${avgScoreQuery}${tossWinnerStatsQuery}${topBatsManQuery}${topBowlerQuery}`,
          [
            ...Array(15).fill(this.id),
            this.pitchReport.topPlayersAtVenue.basedOnYears,
            ...Array(5).fill(this.id),
            this.pitchReport.topPlayersAtVenue.basedOnYears,
            ...Array(2).fill(this.id),
          ]
        );

        this.pitchReport.totalPlayedMatch = totalMatches;
        this.pitchReport.pitchWinningStats.winsBattingFirst =
          winsBattingFirst.toFixed(2);
        this.pitchReport.pitchWinningStats.winsBowlingFirst =
          winsBowlingFirst.toFixed(2);
        this.pitchReport.totalTeamsCreated = totalTeamsCreated;
        this.pitchReport.averageFantacyPoints = averagePoints.toFixed(2);
        this.pitchReport.pitchScoreStats.avgFirstinningScore =
          averageFirstinningScore.toFixed(2);
        this.pitchReport.pitchScoreStats.avgTotalScore =
          averageTotalScore.toFixed(2);
        this.pitchReport.pitchScoreStats.avgTossWinnerOptToBowl =
          tossWinnerOptToBowl.toFixed(2);
        this.pitchReport.pitchScoreStats.avgTeamBowlingFirstWins =
          teamBowlingFirstWins.toFixed(2);
        this.pitchReport.topPlayersAtVenue.batsman = topBatsMan.map(
          (batsman) => {
            batsman.runsPerMatch = batsman.runsPerMatch.toFixed(2);
            batsman.averageStrikeRate = batsman.averageStrikeRate.toFixed(2);
            return batsman;
          }
        );
        this.pitchReport.topPlayersAtVenue.bowler = topBowler.map((bowler) => {
          bowler.averageEconomy = bowler.averageEconomy.toFixed(2);
          return bowler;
        });

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
          "SELECT (SELECT COUNT(*) FROM fullmatchdetails AS inner2FullmatchDetails JOIN scorcardDetails ON scorcardDetails.matchId = inner2FullmatchDetails.matchId JOIN scorcardInning ON scorcardInning.scorcardId = scorcardDetails.scorcardId WHERE (inner2FullmatchDetails.team1Id IN (allteams.teamId) OR inner2FullmatchDetails.team2Id IN (allteams.teamId)) AND inner2FullmatchDetails.matchTypeId = fullmatchdetails.matchTypeId AND inner2FullmatchDetails.matchStatusString IN ('ended', 'closed') AND scorcardInning.inningNumber = 1 AND scorcardInning.battingTeam = allteams.teamId AND scorcardDetails.winnerId = allteams.teamId AND (fullmatchdetails.matchStartDateTime > inner2FullmatchDetails.matchStartDateTime) AND (inner2FullmatchDetails.matchStartDateTime - fullmatchdetails.matchStartDateTime) < (? * 365 * 24 * 60 * 60 * 1000)) AS battingFirstWins, (SELECT COUNT(*) FROM fullmatchdetails AS inner2FullmatchDetails JOIN scorcardDetails ON scorcardDetails.matchId = inner2FullmatchDetails.matchId JOIN scorcardInning ON scorcardInning.scorcardId = scorcardDetails.scorcardId WHERE (inner2FullmatchDetails.team1Id IN (allteams.teamId) OR inner2FullmatchDetails.team2Id IN (allteams.teamId)) AND inner2FullmatchDetails.matchTypeId = fullmatchdetails.matchTypeId AND inner2FullmatchDetails.matchStatusString IN ('ended', 'closed') AND scorcardInning.inningNumber = 2 AND scorcardInning.battingTeam = allteams.teamId AND scorcardDetails.winnerId = allteams.teamId AND (fullmatchdetails.matchStartDateTime > inner2FullmatchDetails.matchStartDateTime) AND (inner2FullmatchDetails.matchStartDateTime - fullmatchdetails.matchStartDateTime) < (? * 365 * 24 * 60 * 60 * 1000)) AS battingSecondWins, (SELECT COUNT(*) FROM fullmatchdetails AS inner2FullmatchDetails JOIN scorcardDetails ON scorcardDetails.matchId = inner2FullmatchDetails.matchId WHERE (inner2FullmatchDetails.team1Id IN (allteams.teamId) OR inner2FullmatchDetails.team2Id IN (allteams.teamId)) AND inner2FullmatchDetails.matchTypeId = fullmatchdetails.matchTypeId AND inner2FullmatchDetails.matchStatusString IN ('ended', 'closed') AND (fullmatchdetails.matchStartDateTime > inner2FullmatchDetails.matchStartDateTime) AND (inner2FullmatchDetails.matchStartDateTime - fullmatchdetails.matchStartDateTime) < (? * 365 * 24 * 60 * 60 * 1000)) AS totalMatchesPlayed, allteams.teamId FROM fullmatchdetails JOIN allteams ON allteams.teamId IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id) WHERE matchId = ?;";

        const matchesPlayedRecentlyQuery =
          "SELECT scorcardDetails.winnerId AS winnerId, IF(scorcardDetails.winnerId = team1Id, team2Id, IF(scorcardDetails.winnerId = team2Id, team1Id, null)) AS looserId FROM fullmatchdetails JOIN scorcardDetails ON scorcardDetails.matchId = fullmatchdetails.matchId WHERE fullmatchdetails.team1Id IN (SELECT allteams.teamId FROM fullmatchdetails JOIN allteams ON allteams.teamId IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id) WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.team2Id IN (SELECT allteams.teamId FROM fullmatchdetails JOIN allteams ON allteams.teamId IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id) WHERE fullmatchdetails.matchId = ?) AND (fullmatchdetails.matchStartDateTime < (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?)) ORDER BY fullmatchdetails.matchStartDateTime DESC LIMIT 5;";

        const [competitorwins, [{ totalMatches }], teams, recentMatches] =
          await fetchData(
            `${matchAgainstEachOtherQuery}${competitorStrengthQuery}${matchesPlayedRecentlyQuery}`,
            [
              ...Array(2).fill(this.id),
              ...Array(3).fill(this.teamComparison.teamStrengths.basedOnYears),
              ...Array(7).fill(this.id),
            ]
          );

        this.teamComparison.winProbability = [
          {
            teamId: competitorwins[0].teamId,
            winProbability: "50.00",
          },
          {
            teamId: competitorwins[1].teamId,
            winProbability: "50.00",
          },
        ];

        this.teamComparison.totalMatches = totalMatches;
        this.teamComparison.matchesAgainstEachOther.matchWithDecision =
          competitorwins;
        this.teamComparison.matchesAgainstEachOther.matchWithoutDecision =
          totalMatches -
          (competitorwins[0].totalWins + competitorwins[1].totalWins);
        this.teamComparison.teamStrengths.teams = teams;
        this.teamComparison.matchesRecent = recentMatches;

        resolve();
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  getFantacyPoints() {
    return new Promise(async (resolve, reject) => {
      try {
        const thisSeasonStatsQuery =
          "SELECT COALESCE(SUM(fullplayerdetails.points), 0) AS points, fullplayerdetails.playerId FROM fullplayerdetails JOIN fullmatchdetails ON fullmatchdetails.matchId = fullplayerdetails.matchId WHERE fullplayerdetails.playerId IN (SELECT fullplayerdetails.playerId FROM fullplayerdetails WHERE fullplayerdetails.matchId = ?) AND fullmatchdetails.matchTournamentId IN (SELECT fullmatchdetails.matchTournamentId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchStartDateTime < (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) GROUP BY playerId ORDER BY `points` DESC;";

        const lastFiveMatchStatsQuery =
          "SELECT COALESCE(SUM(fiveMatchState.points)) AS points, fiveMatchState.playerId FROM (SELECT COALESCE(points, 0) AS points, fullplayerdetails.playerId, ROW_NUMBER() OVER (PARTITION BY fullplayerdetails.playerId ORDER BY fullmatchdetails.matchStartDateTime DESC) AS rowId FROM fullplayerdetails JOIN fullmatchdetails ON fullmatchdetails.matchId = fullplayerdetails.matchId WHERE fullmatchdetails.matchStatusString IN ('ended', 'closed') AND fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchStartDateTime < (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullplayerdetails.playerId IN (SELECT fullplayerdetails.playerId FROM fullplayerdetails WHERE fullplayerdetails.matchId = ?) ORDER BY `points` DESC) AS fiveMatchState WHERE fiveMatchState.rowId <= 5 GROUP BY fiveMatchState.playerId ORDER BY points DESC;";

        const [thisSeason, lastFiveMatches] = await fetchData(
          `${thisSeasonStatsQuery}${lastFiveMatchStatsQuery}`,
          [...Array(8).fill(this.id)]
        );

        this.fantasyPoints = {
          thisSeason: thisSeason,
          lastFiveMatches: lastFiveMatches,
        };
        resolve();
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  getPlayerPerformance() {
    return new Promise(async (resolve, reject) => {
      try {
        const playerPerformanceQuery =
          "SELECT fullplayerdetails.playerId, COALESCE(AVG(fullplayerdetails.points), 0) AS avgPoints, COUNT(*) AS totalMatches FROM fullplayerdetails JOIN fullmatchdetails ON fullmatchdetails.matchId = fullplayerdetails.matchId WHERE fullplayerdetails.playerId IN (SELECT fullplayerdetails.playerId FROM fullplayerdetails WHERE fullplayerdetails.matchId = ?) AND fullmatchdetails.matchStatusString IN ('ended', 'closed') AND fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) - fullmatchdetails.matchStartDateTime < ? * 365 * 24 * 60 * 60 * 1000 AND fullplayerdetails.isSelected = 1 GROUP BY fullplayerdetails.playerId ORDER BY avgPoints DESC;";

        const playerPerformance = await fetchData(playerPerformanceQuery, [
          ...Array(3).fill(this.id),
          this.playerPerformance.basedOnYears,
        ]);

        playerPerformance.forEach((player) => {
          player.avgPoints = player.avgPoints.toFixed(2);
          let playerPerformance = "";
          if (player.avgPoints > 100) {
            playerPerformance = "Prime";
          } else if (player.avgPoints > 50 && player.avgPoints <= 100) {
            playerPerformance = "InForm";
          } else if (player.avgPoints > 30 && player.avgPoints <= 50) {
            playerPerformance = "Good";
          } else if (player.avgPoints > 20 && player.avgPoints <= 30) {
            playerPerformance = "Average";
          } else if (player.avgPoints > 10 && player.avgPoints <= 20) {
            playerPerformance = "Poor";
          } else {
            playerPerformance = "weak";
          }
          player.playerPerformance = playerPerformance;
        });
        this.playerPerformance.players = playerPerformance;
        resolve();
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  getStatistics() {
    return new Promise(async (resolve, reject) => {
      try {
        const topBatsManQuery =
          "SELECT inningBatsmans.playerId, COALESCE(SUM(inningBatsmans.runs), 0) AS totalRuns, COALESCE(SUM(inningBatsmans.runs), 0) / COUNT(*) AS runsPerMatch, COUNT(*) AS totalMatches, AVG(inningBatsmans.strikeRate) AS averageStrikeRate FROM fullmatchdetails JOIN scorcardDetails ON scorcardDetails.matchId = fullmatchdetails.matchId JOIN scorcardInning ON scorcardInning.scorcardId = scorcardDetails.scorcardId JOIN inningBatsmans ON inningBatsmans.scorcardInningId = scorcardInning.scorcardInningId WHERE fullmatchdetails.matchId IN (SELECT fullmatchdetails.matchId FROM fullmatchdetails WHERE fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchStatusString IN ('ended', 'closed') AND (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) - fullmatchdetails.matchStartDateTime < (? * 365 * 24 * 60 * 60 * 1000)) AND (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) > fullmatchdetails.matchStartDateTime AND inningBatsmans.playerId IN (SELECT fullplayerdetails.playerId FROM fullplayerdetails WHERE fullplayerdetails.matchId = ?) GROUP BY inningBatsmans.playerId ORDER BY totalRuns DESC, runsPerMatch DESC, averageStrikeRate DESC LIMIT 5;";

        const topBowlerQuery =
          "SELECT inningBowlers.playerId, COALESCE(SUM(inningBowlers.wickets), 0) AS totalWickets, COUNT(*) AS totalMatches, AVG(inningBowlers.economyRate) AS averageEconomy FROM fullmatchdetails JOIN scorcardDetails ON scorcardDetails.matchId = fullmatchdetails.matchId JOIN scorcardInning ON scorcardInning.scorcardId = scorcardDetails.scorcardId JOIN inningBowlers ON inningBowlers.scorcardInningId = scorcardInning.scorcardInningId WHERE fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) AND fullmatchdetails.matchStatusString IN ('ended', 'closed') AND (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) - fullmatchdetails.matchStartDateTime < (? * 365 * 24 * 60 * 60 * 1000) AND (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = ?) > fullmatchdetails.matchStartDateTime AND inningBowlers.playerId IN (SELECT fullplayerdetails.playerId FROM fullplayerdetails WHERE fullplayerdetails.matchId = ?) GROUP BY inningBowlers.playerId ORDER BY totalWickets DESC, averageEconomy DESC LIMIT 5;";

        const [topBatsMan, topBowler] = await fetchData(
          `${topBatsManQuery}${topBowlerQuery}`,
          [
            ...Array(2).fill(this.id),
            this.statistics.basedOnYears,
            ...Array(4).fill(this.id),
            this.statistics.basedOnYears,
            ...Array(2).fill(this.id),
          ]
        );

        this.statistics.players.topBatsMan = topBatsMan.map((batsman) => {
          batsman.runsPerMatch = batsman.runsPerMatch.toFixed(2);
          batsman.averageStrikeRate = batsman.averageStrikeRate.toFixed(2);
          return batsman;
        });
        this.statistics.players.topBowlers = topBowler.map((bowler) => {
          bowler.averageEconomy = bowler.averageEconomy.toFixed(2);
          return bowler;
        });
        resolve();
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }
}

module.exports = MatchStatistics;
