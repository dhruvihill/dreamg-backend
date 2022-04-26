-- phpMyAdmin SQL Dump
-- version 5.1.3
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Apr 26, 2022 at 05:53 PM
-- Server version: 10.4.24-MariaDB
-- PHP Version: 8.1.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

--
-- Database: `dreamg-test-cron`
--

-- --------------------------------------------------------

--
-- Stand-in structure for view `allplayers`
-- (See below for the actual view)
--
CREATE TABLE `allplayers` (
`playerId` int(11)
,`playerRadarId` int(11)
,`playerFirstName` varchar(200)
,`playerLastName` varchar(200)
,`playerCountryCode` varchar(30)
,`playerRole` int(2)
,`roleName` tinytext
,`playerDOB` date
,`playerCountry` varchar(50)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `allteams`
-- (See below for the actual view)
--
CREATE TABLE `allteams` (
`teamId` int(10)
,`teamRadarId` int(10)
,`name` varchar(50)
,`countryName` varchar(30)
,`countryCode` varchar(20)
,`displayName` tinytext
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `allteams2`
-- (See below for the actual view)
--
CREATE TABLE `allteams2` (
`tournamentCompetitorId` int(11)
,`tournamentId` int(11)
,`competitorId` int(10)
,`competitorRadarId` int(10)
,`competitorName` varchar(50)
,`competitorCountry` varchar(30)
,`competitorCountryCode` varchar(20)
,`competitorDisplayName` tinytext
,`isPlayerArrived` tinyint(1)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `allviews`
-- (See below for the actual view)
--
CREATE TABLE `allviews` (
`userTeamId` int(11)
,`userId` int(11)
,`viewCount` int(9)
);

-- --------------------------------------------------------

--
-- Table structure for table `competitors`
--

CREATE TABLE `competitors` (
  `competitorId` int(10) NOT NULL,
  `competitorRadarId` int(10) NOT NULL,
  `competitorName` varchar(50) NOT NULL,
  `competitorCountry` varchar(30) DEFAULT NULL,
  `competitorCountryCode` varchar(20) DEFAULT NULL,
  `competitorDisplayName` tinytext DEFAULT NULL,
  `logTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `discussion`
--

CREATE TABLE `discussion` (
  `discussionId` int(11) NOT NULL,
  `matchId` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `messengerId` int(11) NOT NULL,
  `message` varchar(5000) NOT NULL,
  `messageTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Stand-in structure for view `fulldiscussion`
-- (See below for the actual view)
--
CREATE TABLE `fulldiscussion` (
`discussionId` int(11)
,`matchId` int(11)
,`userId` int(11)
,`messengerId` int(11)
,`message` varchar(5000)
,`messageTime` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `fulllikesdetails`
-- (See below for the actual view)
--
CREATE TABLE `fulllikesdetails` (
`userTeamId` int(11)
,`userId` int(11)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `fullmatchdetails`
-- (See below for the actual view)
--
CREATE TABLE `fullmatchdetails` (
`matchId` int(11)
,`matchRadarId` int(11)
,`matchTournamentId` int(11)
,`matchStartDateTime` timestamp
,`matchStartTimeMilliSeconds` varchar(21)
,`team1Id` int(11)
,`team2Id` int(11)
,`tossWonBy` int(11)
,`tossDecision` tinytext
,`venueId` int(11)
,`venue` varchar(500)
,`matchTypeId` int(2)
,`matchTyprString` varchar(50)
,`venueCity` tinytext
,`venueCapacity` int(8)
,`venuesCountry` varchar(50)
,`end2` varchar(100)
,`end1` varchar(100)
,`matchStatus` int(2)
,`matchStatusString` tinytext
,`seriesName` varchar(500)
,`seriesDname` varchar(500)
,`team1Name` varchar(50)
,`team1RadarId` int(10)
,`team1Country` varchar(30)
,`team1CountryCode` varchar(20)
,`team1DisplayName` tinytext
,`team2Name` varchar(50)
,`team2RadarId` int(10)
,`team2Country` varchar(30)
,`team2CountryName` varchar(20)
,`team2DisplayName` tinytext
,`displayName` text
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `fullnotification`
-- (See below for the actual view)
--
CREATE TABLE `fullnotification` (
`notificationId` int(11)
,`userId` int(11)
,`notificationType` int(11)
,`notificationTypeString` varchar(30)
,`notificationMessage` varchar(2000)
,`creationTime` timestamp
,`haveReaded` tinyint(1)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `fullplayerdetails`
-- (See below for the actual view)
--
CREATE TABLE `fullplayerdetails` (
`matchId` int(11)
,`matchRadarId` int(11)
,`playerId` int(11)
,`teamId` int(11)
,`credits` int(1)
,`isSelected` tinyint(1)
,`points` int(6)
,`name` varchar(401)
,`displayName` varchar(401)
,`roleId` int(2)
,`roleName` varchar(255)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `fullseriesdetails`
-- (See below for the actual view)
--
CREATE TABLE `fullseriesdetails` (
`tournamentId` int(10)
,`tournamentRadarId` int(10)
,`currentSeasonRadarId` int(10)
,`tournamentName` varchar(500)
,`currentSeasonName` varchar(500)
,`seasonStartDate` date
,`seasonEndDate` date
,`tournamentMatchType` int(2)
,`tournamentCategory` int(2)
,`tournamentPlayersGender` tinytext
,`tournamentCountry` varchar(30)
,`tournamentCountryCode` varchar(20)
,`isCompetitorsArrived` tinyint(1)
,`isMatchesArrived` tinyint(1)
,`categoryString` varchar(50)
,`tournamentTypeString` varchar(50)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `fullteamdetails`
-- (See below for the actual view)
--
CREATE TABLE `fullteamdetails` (
`matchId` int(11)
,`userId` int(11)
,`userTeamId` int(11)
,`userTeamType` int(11)
,`teamTypeString` tinytext
,`userTeamPoints` int(6)
,`userTeamViews` int(11)
,`userTeamLikes` int(11)
,`captain` int(11)
,`viceCaptain` int(11)
,`player1` int(11)
,`player2` int(11)
,`player3` int(11)
,`player4` int(11)
,`player5` int(11)
,`player6` int(11)
,`player7` int(11)
,`player8` int(11)
,`player9` int(11)
,`player10` int(11)
,`player11` int(11)
,`creationTime` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `inningBatsmans`
-- (See below for the actual view)
--
CREATE TABLE `inningBatsmans` (
`scorcardInningId` int(11)
,`playerId` int(11)
,`battingOrder` int(2)
,`runs` int(4)
,`strikeRate` float
,`isNotOut` tinyint(1)
,`isDuck` tinyint(1)
,`isRetiredHurt` tinyint(1)
,`ballFaced` int(4)
,`fours` int(3)
,`sixes` int(3)
,`attackIngShot` int(4)
,`semiAttackingShot` int(4)
,`defendingShot` int(4)
,`leaves` int(4)
,`onSideShot` int(4)
,`offSideShot` int(4)
,`squreLegShot` int(4)
,`fineLegShot` int(4)
,`thirdManShot` int(4)
,`coverShot` int(4)
,`pointsShot` int(4)
,`midOnShot` int(4)
,`midOffShot` int(4)
,`midWicketShot` int(4)
,`dismissalOverBallNumber` tinyint(1)
,`dismissalOverNumber` smallint(4)
,`dismissalBallerId` int(11)
,`dismissalDiliveryType` tinytext
,`dismissalFieldeManId` int(11)
,`dismissalIsOnStrike` tinyint(1)
,`dismissalShotType` tinytext
,`dismissalType` tinytext
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `inningBatting`
-- (See below for the actual view)
--
CREATE TABLE `inningBatting` (
`scorcardInningId` int(11)
,`runs` int(4)
,`fours` int(3)
,`sixes` int(3)
,`runRate` float
,`ballFaced` int(5)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `inningBowlers`
-- (See below for the actual view)
--
CREATE TABLE `inningBowlers` (
`scorcardInningId` int(11)
,`playerId` int(11)
,`runsConceded` int(4)
,`wickets` int(2)
,`overBowled` int(4)
,`maidensOvers` int(4)
,`dotBalls` int(4)
,`fourConceded` int(3)
,`sixConceded` int(3)
,`noBalls` int(3)
,`wides` int(3)
,`slowerDeliveries` int(4)
,`yorkers` int(4)
,`economyRate` float
,`fastestBall` int(3)
,`slowestBall` int(3)
,`averageSpeed` int(3)
,`overTheWicketBalls` int(4)
,`aroundTheWicketBalls` int(4)
,`bouncers` int(4)
,`beatBats` int(4)
,`edge` int(4)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `inningBowling`
-- (See below for the actual view)
--
CREATE TABLE `inningBowling` (
`scorcardInningId` int(11)
,`overs` float
,`wickets` int(2)
,`maidens` int(3)
,`extras` int(4)
,`noBalls` int(3)
,`byes` int(3)
,`legByes` int(3)
,`dotBalls` int(4)
);

-- --------------------------------------------------------

--
-- Table structure for table `inning_batsmans`
--

CREATE TABLE `inning_batsmans` (
  `scorcardInningId` int(11) NOT NULL,
  `playerId` int(11) NOT NULL,
  `battingOrder` int(2) DEFAULT NULL,
  `runs` int(4) NOT NULL DEFAULT 0,
  `strikeRate` float DEFAULT 0,
  `isNotOut` tinyint(1) NOT NULL DEFAULT 0,
  `isDuck` tinyint(1) NOT NULL DEFAULT 0,
  `isRetiredHurt` tinyint(1) NOT NULL DEFAULT 0,
  `ballFaced` int(4) NOT NULL DEFAULT 0,
  `fours` int(3) NOT NULL DEFAULT 0,
  `sixes` int(3) NOT NULL DEFAULT 0,
  `attackIngShot` int(4) NOT NULL DEFAULT 0,
  `semiAttackingShot` int(4) NOT NULL DEFAULT 0,
  `defendingShot` int(4) NOT NULL DEFAULT 0,
  `leaves` int(4) NOT NULL DEFAULT 0,
  `onSideShot` int(4) NOT NULL DEFAULT 0,
  `offSideShot` int(4) NOT NULL DEFAULT 0,
  `squreLegShot` int(4) NOT NULL DEFAULT 0,
  `fineLegShot` int(4) NOT NULL DEFAULT 0,
  `thirdManShot` int(4) NOT NULL DEFAULT 0,
  `coverShot` int(4) NOT NULL DEFAULT 0,
  `pointsShot` int(4) NOT NULL DEFAULT 0,
  `midOnShot` int(4) NOT NULL DEFAULT 0,
  `midOffShot` int(4) NOT NULL DEFAULT 0,
  `midWicketShot` int(4) NOT NULL DEFAULT 0,
  `dismissalOverBallNumber` tinyint(1) DEFAULT NULL,
  `dismissalOverNumber` smallint(4) DEFAULT NULL,
  `dismissalBallerId` int(11) DEFAULT NULL,
  `dismissalDiliveryType` tinytext DEFAULT NULL,
  `dismissalFieldeManId` int(11) DEFAULT NULL,
  `dismissalIsOnStrike` tinyint(1) DEFAULT NULL,
  `dismissalShotType` tinytext DEFAULT NULL,
  `dismissalType` tinytext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `inning_batting`
--

CREATE TABLE `inning_batting` (
  `scorcardInningId` int(11) NOT NULL,
  `runs` int(4) NOT NULL,
  `fours` int(3) NOT NULL,
  `sixes` int(3) NOT NULL,
  `runRate` float NOT NULL,
  `ballFaced` int(5) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `inning_bowlers`
--

CREATE TABLE `inning_bowlers` (
  `scorcardInningId` int(11) NOT NULL,
  `playerId` int(11) NOT NULL,
  `runsConceded` int(4) NOT NULL DEFAULT 0,
  `wickets` int(2) NOT NULL DEFAULT 0,
  `overBowled` int(4) NOT NULL DEFAULT 0,
  `maidensOvers` int(4) NOT NULL DEFAULT 0,
  `dotBalls` int(4) NOT NULL DEFAULT 0,
  `fourConceded` int(3) NOT NULL DEFAULT 0,
  `sixConceded` int(3) NOT NULL DEFAULT 0,
  `noBalls` int(3) NOT NULL DEFAULT 0,
  `wides` int(3) NOT NULL DEFAULT 0,
  `slowerDeliveries` int(4) NOT NULL DEFAULT 0,
  `yorkers` int(4) NOT NULL DEFAULT 0,
  `economyRate` float NOT NULL DEFAULT 0,
  `fastestBall` int(3) NOT NULL DEFAULT 0,
  `slowestBall` int(3) NOT NULL DEFAULT 0,
  `averageSpeed` int(3) NOT NULL,
  `overTheWicketBalls` int(4) NOT NULL DEFAULT 0,
  `aroundTheWicketBalls` int(4) NOT NULL DEFAULT 0,
  `bouncers` int(4) NOT NULL DEFAULT 0,
  `beatBats` int(4) NOT NULL DEFAULT 0,
  `edge` int(4) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `inning_bowling`
--

CREATE TABLE `inning_bowling` (
  `scorcardInningId` int(11) NOT NULL,
  `overs` float NOT NULL,
  `wickets` int(2) NOT NULL,
  `maidens` int(3) NOT NULL,
  `extras` int(4) NOT NULL,
  `noBalls` int(3) NOT NULL,
  `byes` int(3) NOT NULL,
  `legByes` int(3) NOT NULL,
  `dotBalls` int(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `match_lineup`
--

CREATE TABLE `match_lineup` (
  `matchId` int(11) NOT NULL,
  `competitorId` int(11) NOT NULL,
  `playerId` int(11) NOT NULL,
  `isCaptain` tinyint(1) NOT NULL DEFAULT 0,
  `isWicketKeeper` tinyint(1) NOT NULL DEFAULT 0,
  `order` tinyint(2) NOT NULL,
  `points` int(4) DEFAULT 0,
  `runsPoints` int(4) NOT NULL DEFAULT 0,
  `foursPoints` int(4) NOT NULL DEFAULT 0,
  `sixesPoints` int(4) NOT NULL DEFAULT 0,
  `numberRunsPoints` int(4) NOT NULL DEFAULT 0,
  `numberWicketPoints` int(4) NOT NULL DEFAULT 0,
  `wicketPoints` int(4) NOT NULL DEFAULT 0,
  `maidenOverPoints` int(4) NOT NULL DEFAULT 0,
  `lbwOrBowledPoints` int(4) NOT NULL DEFAULT 0,
  `catchesPoints` int(4) NOT NULL DEFAULT 0,
  `runOutPoints` int(4) NOT NULL DEFAULT 0,
  `economyPoints` int(3) DEFAULT NULL,
  `strikeRatePoints` int(3) NOT NULL,
  `logTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `match_players`
--

CREATE TABLE `match_players` (
  `matchId` int(11) NOT NULL,
  `competitorId` int(11) NOT NULL,
  `playerId` int(11) NOT NULL,
  `isSelected` tinyint(1) NOT NULL DEFAULT 0,
  `isCaptain` tinyint(1) NOT NULL DEFAULT 0,
  `isWicketKeeper` tinyint(1) NOT NULL DEFAULT 0,
  `order` int(2) DEFAULT NULL,
  `points` int(6) DEFAULT NULL,
  `runsPoints` int(4) NOT NULL DEFAULT 0,
  `foursPoints` int(4) NOT NULL DEFAULT 0,
  `sixesPoints` int(4) NOT NULL DEFAULT 0,
  `numberRunsPoints` int(4) NOT NULL DEFAULT 0,
  `numberWicketPoints` int(4) NOT NULL DEFAULT 0,
  `wicketPoints` int(4) NOT NULL DEFAULT 0,
  `maidenOverPoints` int(4) NOT NULL DEFAULT 0,
  `lbwOrBowledPoints` int(4) NOT NULL DEFAULT 0,
  `catchesPoints` int(4) NOT NULL DEFAULT 0,
  `runOutPoints` int(4) NOT NULL DEFAULT 0,
  `economyPoints` int(3) DEFAULT NULL,
  `strikeRatePoints` int(3) NOT NULL,
  `logTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `match_status`
--

CREATE TABLE `match_status` (
  `statusId` int(11) NOT NULL,
  `statusString` tinytext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `notificationId` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `isReaded` tinyint(1) NOT NULL DEFAULT 0,
  `notificationType` int(11) NOT NULL,
  `notificationMessage` varchar(2000) NOT NULL,
  `creationTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `notification_type`
--

CREATE TABLE `notification_type` (
  `notificationType` int(11) NOT NULL,
  `notificationTypeString` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `players`
--

CREATE TABLE `players` (
  `playerId` int(11) NOT NULL,
  `playerRadarId` int(11) NOT NULL,
  `playerFirstName` varchar(200) NOT NULL,
  `playerLastName` varchar(200) NOT NULL,
  `playerCountryCode` varchar(30) DEFAULT NULL,
  `playerRole` int(2) NOT NULL DEFAULT 0,
  `playerDOB` date DEFAULT NULL,
  `playerBattingStyleId` int(11) DEFAULT NULL,
  `playerBowlingStyleId` int(11) DEFAULT NULL,
  `playerCountry` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `player_batting_style`
--

CREATE TABLE `player_batting_style` (
  `playerBattingStyleId` int(11) NOT NULL,
  `battingStyleString` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `player_bowling_style`
--

CREATE TABLE `player_bowling_style` (
  `playerBowlingStyleId` int(11) NOT NULL,
  `playerBowlingStyleString` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `player_roles`
--

CREATE TABLE `player_roles` (
  `roleId` int(11) NOT NULL,
  `roleString` tinytext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `player_statistics_batting`
--

CREATE TABLE `player_statistics_batting` (
  `playerId` int(11) NOT NULL,
  `type` varchar(30) NOT NULL,
  `matches` int(6) DEFAULT NULL,
  `innings` int(6) DEFAULT NULL,
  `ballFaced` int(8) DEFAULT NULL,
  `notOuts` int(4) DEFAULT NULL,
  `runs` int(8) DEFAULT NULL,
  `average` float DEFAULT NULL,
  `strikeRate` float DEFAULT NULL,
  `highestScore` int(5) DEFAULT NULL,
  `hundreds` int(4) DEFAULT NULL,
  `fifties` int(5) DEFAULT NULL,
  `fours` int(5) DEFAULT NULL,
  `sixes` int(5) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `player_statistics_bowling`
--

CREATE TABLE `player_statistics_bowling` (
  `playerId` int(11) NOT NULL,
  `type` varchar(30) NOT NULL,
  `matches` int(7) DEFAULT NULL,
  `innings` int(7) DEFAULT NULL,
  `overs` float DEFAULT NULL,
  `ballsBalled` int(9) DEFAULT NULL,
  `maidens` int(5) DEFAULT NULL,
  `runs` int(9) DEFAULT NULL,
  `wickets` int(6) DEFAULT NULL,
  `average` float DEFAULT NULL,
  `strikeRate` float DEFAULT NULL,
  `economy` float DEFAULT NULL,
  `bestBowling` int(5) DEFAULT NULL,
  `fourWicketHauls` int(5) DEFAULT NULL,
  `fiverWicketHauls` int(5) DEFAULT NULL,
  `tenWicketHauls` int(5) DEFAULT NULL,
  `catches` int(7) DEFAULT NULL,
  `stumping` int(6) DEFAULT NULL,
  `runOuts` int(5) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Stand-in structure for view `scorcardDetails`
-- (See below for the actual view)
--
CREATE TABLE `scorcardDetails` (
`scorcardId` int(11)
,`matchId` int(11)
,`tossWonBy` int(11)
,`tossDecision` varchar(20)
,`winnerId` int(11)
,`manOfMatch` int(11)
,`isPointsCalculated` tinyint(1)
,`matchResultString` varchar(1000)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `scorcardInning`
-- (See below for the actual view)
--
CREATE TABLE `scorcardInning` (
`scorcardInningId` int(11)
,`scorcardId` int(11)
,`inningNumber` int(11)
,`battingTeam` int(11)
,`bowlingTeam` int(11)
,`runs` int(11)
,`wickets` int(11)
,`oversPlayed` decimal(10,0)
);

-- --------------------------------------------------------

--
-- Table structure for table `scorcard_details`
--

CREATE TABLE `scorcard_details` (
  `scorcardId` int(11) NOT NULL,
  `matchId` int(11) NOT NULL,
  `tossWonBy` int(11) DEFAULT NULL,
  `tossDecision` varchar(20) DEFAULT NULL,
  `winnerId` int(11) DEFAULT NULL,
  `manOfMatch` int(11) DEFAULT NULL,
  `isPointsCalculated` tinyint(1) NOT NULL DEFAULT 0,
  `matchResultString` varchar(1000) DEFAULT NULL,
  `logTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `scorcard_innings`
--

CREATE TABLE `scorcard_innings` (
  `scorcardInningId` int(11) NOT NULL,
  `scorcardId` int(11) NOT NULL,
  `inningNumber` int(11) NOT NULL,
  `battingTeam` int(11) NOT NULL,
  `bowlingTeam` int(11) NOT NULL,
  `runs` int(11) NOT NULL,
  `wickets` int(11) NOT NULL,
  `oversPlayed` decimal(10,0) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `team_type`
--

CREATE TABLE `team_type` (
  `teamType` int(11) NOT NULL,
  `teamTypeString` tinytext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Stand-in structure for view `testView`
-- (See below for the actual view)
--
CREATE TABLE `testView` (
`matchId` int(11)
,`matchRadarId` int(11)
,`playerId` int(11)
,`teamId` int(11)
,`credits` int(1)
,`isSelected` tinyint(1)
,`points` int(6)
,`name` varchar(401)
,`displayName` varchar(401)
,`roleId` int(2)
,`roleName` varchar(255)
);

-- --------------------------------------------------------

--
-- Table structure for table `tournament_category`
--

CREATE TABLE `tournament_category` (
  `categoryId` int(2) NOT NULL,
  `categoryRadarId` int(5) NOT NULL,
  `categoryString` varchar(50) NOT NULL,
  `logTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `tournament_competitor`
--

CREATE TABLE `tournament_competitor` (
  `tournamentCompetitorId` int(11) NOT NULL,
  `tournamentId` int(11) NOT NULL,
  `competitorId` int(11) NOT NULL,
  `isPlayerArrived` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `tournament_competitor_player`
--

CREATE TABLE `tournament_competitor_player` (
  `tournamentCompetitorPlayerId` int(11) NOT NULL,
  `tournamentCompetitorId` int(11) NOT NULL,
  `playerId` int(11) NOT NULL,
  `credit` decimal(40,1) NOT NULL DEFAULT 0.0
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `tournament_information`
--

CREATE TABLE `tournament_information` (
  `tournamentId` int(10) NOT NULL,
  `tournamentRadarId` int(10) NOT NULL,
  `currentSeasonRadarId` int(10) NOT NULL,
  `tournamentName` varchar(500) NOT NULL,
  `currentSeasonName` varchar(500) NOT NULL,
  `seasonStartDate` date NOT NULL,
  `seasonEndDate` date NOT NULL,
  `tournamentMatchType` int(2) NOT NULL,
  `tournamentCategory` int(2) NOT NULL,
  `tournamentPlayersGender` tinytext DEFAULT NULL,
  `tournamentCountry` varchar(30) DEFAULT NULL,
  `tournamentCountryCode` varchar(20) DEFAULT NULL,
  `isCompetitorsArrived` tinyint(1) NOT NULL DEFAULT 0,
  `isMatchesArrived` tinyint(1) NOT NULL DEFAULT 0,
  `logTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `tournament_matches`
--

CREATE TABLE `tournament_matches` (
  `matchId` int(11) NOT NULL,
  `matchRadarId` int(11) NOT NULL,
  `matchTournamentId` int(11) NOT NULL,
  `matchStartTime` timestamp NOT NULL DEFAULT current_timestamp(),
  `isPointsCalculated` tinyint(1) NOT NULL DEFAULT 0,
  `competitor1` int(11) NOT NULL,
  `competitor2` int(11) NOT NULL,
  `tossWonBy` int(11) DEFAULT NULL,
  `tossDecision` tinytext DEFAULT NULL,
  `venueId` int(11) DEFAULT NULL,
  `matchStatus` int(2) NOT NULL,
  `logTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Table structure for table `tournament_type`
--

CREATE TABLE `tournament_type` (
  `tournamentTypeId` int(2) NOT NULL,
  `tournamnetTypeString` varchar(50) NOT NULL,
  `logTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Stand-in structure for view `userdetails`
-- (See below for the actual view)
--
CREATE TABLE `userdetails` (
`userId` int(11)
,`userType` int(11)
,`userTypeString` varchar(30)
,`phoneNumber` varchar(10)
,`email` varchar(500)
,`dateOfBirth` varchar(50)
,`gender` varchar(20)
,`firstName` varchar(30)
,`lastName` varchar(30)
,`address` varchar(1000)
,`city` varchar(50)
,`pinCode` varchar(10)
,`state` varchar(50)
,`country` varchar(50)
,`isVerified` tinyint(1)
,`imageStamp` varchar(100)
,`registerTime` timestamp
);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `userId` int(11) NOT NULL,
  `userType` int(11) NOT NULL DEFAULT 1,
  `phoneNumber` varchar(10) NOT NULL,
  `email` varchar(500) NOT NULL DEFAULT '',
  `dateOfBirth` varchar(50) NOT NULL DEFAULT '',
  `gender` varchar(20) NOT NULL DEFAULT '',
  `displayPicture` varchar(1000) DEFAULT '',
  `firstName` varchar(30) NOT NULL DEFAULT '',
  `lastName` varchar(30) NOT NULL DEFAULT '',
  `address` varchar(1000) DEFAULT '',
  `city` varchar(50) NOT NULL DEFAULT '',
  `pinCode` varchar(10) DEFAULT NULL,
  `state` varchar(50) NOT NULL DEFAULT '',
  `country` varchar(50) NOT NULL DEFAULT '',
  `imageStamp` varchar(100) DEFAULT NULL,
  `isVerified` tinyint(1) NOT NULL DEFAULT 0,
  `registerTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Stand-in structure for view `userTeamDetails`
-- (See below for the actual view)
--
CREATE TABLE `userTeamDetails` (
`userTeamId` int(11)
,`matchId` int(11)
,`userId` int(11)
,`userTeamType` int(11)
,`teamTypeString` tinytext
,`userTeamPoints` int(6)
,`userTeamViews` int(8)
,`userTeamLikes` int(8)
,`creationTime` timestamp
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `userTeamPlayersDetails`
-- (See below for the actual view)
--
CREATE TABLE `userTeamPlayersDetails` (
`userTeamId` int(11)
,`playerId` int(11)
,`isCaptain` int(11)
,`isViceCaptain` int(11)
);

-- --------------------------------------------------------

--
-- Table structure for table `user_team`
--

CREATE TABLE `user_team` (
  `number` int(11) NOT NULL,
  `matchId` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `userTeamId` int(11) NOT NULL,
  `userTeamType` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `user_team_data`
--

CREATE TABLE `user_team_data` (
  `userTeamId` int(11) NOT NULL,
  `userTeamPoints` int(6) NOT NULL DEFAULT 0,
  `userTeamViews` int(11) NOT NULL DEFAULT 0,
  `userTeamLikes` int(11) NOT NULL DEFAULT 0,
  `captain` int(11) NOT NULL,
  `viceCaptain` int(11) NOT NULL,
  `player1` int(11) NOT NULL,
  `player2` int(11) NOT NULL,
  `player3` int(11) NOT NULL,
  `player4` int(11) NOT NULL,
  `player5` int(11) NOT NULL,
  `player6` int(11) NOT NULL,
  `player7` int(11) NOT NULL,
  `player8` int(11) NOT NULL,
  `player9` int(11) NOT NULL,
  `player10` int(11) NOT NULL,
  `player11` int(11) NOT NULL,
  `creationTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `user_team_data_new`
--

CREATE TABLE `user_team_data_new` (
  `userTeamId` int(11) NOT NULL,
  `playerId` int(11) NOT NULL,
  `isCaptain` int(11) NOT NULL DEFAULT 0,
  `isViceCaptain` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `user_team_likes`
--

CREATE TABLE `user_team_likes` (
  `userTeamId` int(11) NOT NULL,
  `userId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `user_team_new`
--

CREATE TABLE `user_team_new` (
  `userTeamId` int(11) NOT NULL,
  `matchId` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `userTeamType` int(11) NOT NULL,
  `userTeamPoints` int(6) DEFAULT NULL,
  `userTeamViews` int(8) NOT NULL DEFAULT 0,
  `userTeamLikes` int(8) NOT NULL DEFAULT 0,
  `creationTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `user_team_views`
--

CREATE TABLE `user_team_views` (
  `userTeamId` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `viewCount` int(9) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `user_type`
--

CREATE TABLE `user_type` (
  `userType` int(11) NOT NULL,
  `userTypeString` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- Table structure for table `venues`
--

CREATE TABLE `venues` (
  `venueId` int(11) NOT NULL,
  `venueName` varchar(500) DEFAULT NULL,
  `venueCapacity` int(8) DEFAULT NULL,
  `venueCity` tinytext DEFAULT NULL,
  `venueRadarId` int(11) NOT NULL,
  `venueCountry` varchar(50) DEFAULT NULL,
  `venueCountryCode` varchar(20) DEFAULT NULL,
  `venueMapCardinalities` varchar(100) DEFAULT NULL,
  `venueEnd1` varchar(100) DEFAULT NULL,
  `venueEnd2` varchar(100) DEFAULT NULL,
  `logTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- --------------------------------------------------------

--
-- Structure for view `allplayers`
--
DROP TABLE IF EXISTS `allplayers`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `allplayers`  AS SELECT `players`.`playerId` AS `playerId`, `players`.`playerRadarId` AS `playerRadarId`, `players`.`playerFirstName` AS `playerFirstName`, `players`.`playerLastName` AS `playerLastName`, `players`.`playerCountryCode` AS `playerCountryCode`, `players`.`playerRole` AS `playerRole`, `player_roles`.`roleString` AS `roleName`, `players`.`playerDOB` AS `playerDOB`, `players`.`playerCountry` AS `playerCountry` FROM (`players` join `player_roles` on(`player_roles`.`roleId` = `players`.`playerRole`))  ;

-- --------------------------------------------------------

--
-- Structure for view `allteams`
--
DROP TABLE IF EXISTS `allteams`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `allteams`  AS SELECT `competitors`.`competitorId` AS `teamId`, `competitors`.`competitorRadarId` AS `teamRadarId`, `competitors`.`competitorName` AS `name`, `competitors`.`competitorCountry` AS `countryName`, `competitors`.`competitorCountryCode` AS `countryCode`, `competitors`.`competitorDisplayName` AS `displayName` FROM `competitors``competitors`  ;

-- --------------------------------------------------------

--
-- Structure for view `allteams2`
--
DROP TABLE IF EXISTS `allteams2`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `allteams2`  AS SELECT `tournament_competitor`.`tournamentCompetitorId` AS `tournamentCompetitorId`, `tournament_competitor`.`tournamentId` AS `tournamentId`, `competitors`.`competitorId` AS `competitorId`, `competitors`.`competitorRadarId` AS `competitorRadarId`, `competitors`.`competitorName` AS `competitorName`, `competitors`.`competitorCountry` AS `competitorCountry`, `competitors`.`competitorCountryCode` AS `competitorCountryCode`, `competitors`.`competitorDisplayName` AS `competitorDisplayName`, `tournament_competitor`.`isPlayerArrived` AS `isPlayerArrived` FROM (`competitors` join `tournament_competitor` on(`tournament_competitor`.`competitorId` = `competitors`.`competitorId`))  ;

-- --------------------------------------------------------

--
-- Structure for view `allviews`
--
DROP TABLE IF EXISTS `allviews`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `allviews`  AS SELECT `user_team_views`.`userTeamId` AS `userTeamId`, `user_team_views`.`userId` AS `userId`, `user_team_views`.`viewCount` AS `viewCount` FROM `user_team_views``user_team_views`  ;

-- --------------------------------------------------------

--
-- Structure for view `fulldiscussion`
--
DROP TABLE IF EXISTS `fulldiscussion`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `fulldiscussion`  AS SELECT `discussion`.`discussionId` AS `discussionId`, `discussion`.`matchId` AS `matchId`, `discussion`.`userId` AS `userId`, `discussion`.`messengerId` AS `messengerId`, `discussion`.`message` AS `message`, `discussion`.`messageTime` AS `messageTime` FROM `discussion``discussion`  ;

-- --------------------------------------------------------

--
-- Structure for view `fulllikesdetails`
--
DROP TABLE IF EXISTS `fulllikesdetails`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `fulllikesdetails`  AS SELECT `user_team_likes`.`userTeamId` AS `userTeamId`, `user_team_likes`.`userId` AS `userId` FROM `user_team_likes``user_team_likes`  ;

-- --------------------------------------------------------

--
-- Structure for view `fullmatchdetails`
--
DROP TABLE IF EXISTS `fullmatchdetails`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `fullmatchdetails`  AS SELECT `tournament_matches`.`matchId` AS `matchId`, `tournament_matches`.`matchRadarId` AS `matchRadarId`, `tournament_matches`.`matchTournamentId` AS `matchTournamentId`, `tournament_matches`.`matchStartTime` AS `matchStartDateTime`, cast(unix_timestamp(`tournament_matches`.`matchStartTime`) * 1000 as char charset utf8mb4) AS `matchStartTimeMilliSeconds`, `tournament_matches`.`competitor1` AS `team1Id`, `tournament_matches`.`competitor2` AS `team2Id`, `tournament_matches`.`tossWonBy` AS `tossWonBy`, `tournament_matches`.`tossDecision` AS `tossDecision`, `tournament_matches`.`venueId` AS `venueId`, `venues`.`venueName` AS `venue`, `fullseriesdetails`.`tournamentMatchType` AS `matchTypeId`, `fullseriesdetails`.`tournamentTypeString` AS `matchTyprString`, `venues`.`venueCity` AS `venueCity`, `venues`.`venueCapacity` AS `venueCapacity`, `venues`.`venueCountry` AS `venuesCountry`, `venues`.`venueEnd1` AS `end2`, `venues`.`venueEnd2` AS `end1`, `tournament_matches`.`matchStatus` AS `matchStatus`, `match_status`.`statusString` AS `matchStatusString`, `fullseriesdetails`.`tournamentName` AS `seriesName`, `fullseriesdetails`.`currentSeasonName` AS `seriesDname`, `comp1`.`competitorName` AS `team1Name`, `comp1`.`competitorRadarId` AS `team1RadarId`, `comp1`.`competitorCountry` AS `team1Country`, `comp1`.`competitorCountryCode` AS `team1CountryCode`, `comp1`.`competitorDisplayName` AS `team1DisplayName`, `comp2`.`competitorName` AS `team2Name`, `comp2`.`competitorRadarId` AS `team2RadarId`, `comp2`.`competitorCountry` AS `team2Country`, `comp2`.`competitorCountryCode` AS `team2CountryName`, `comp2`.`competitorDisplayName` AS `team2DisplayName`, concat(`comp1`.`competitorDisplayName`,' vs ',`comp2`.`competitorDisplayName`) AS `displayName` FROM (((((`tournament_matches` join `competitors` `comp1` on(`tournament_matches`.`competitor1` = `comp1`.`competitorId`)) join `competitors` `comp2` on(`tournament_matches`.`competitor2` = `comp2`.`competitorId`)) join `fullseriesdetails` on(`fullseriesdetails`.`tournamentId` = `tournament_matches`.`matchTournamentId`)) join `match_status` on(`tournament_matches`.`matchStatus` = `match_status`.`statusId`)) join `venues` on(`tournament_matches`.`venueId` = `venues`.`venueId`))  ;

-- --------------------------------------------------------

--
-- Structure for view `fullnotification`
--
DROP TABLE IF EXISTS `fullnotification`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `fullnotification`  AS SELECT `notifications`.`notificationId` AS `notificationId`, `notifications`.`userId` AS `userId`, `notifications`.`notificationType` AS `notificationType`, `notification_type`.`notificationTypeString` AS `notificationTypeString`, `notifications`.`notificationMessage` AS `notificationMessage`, `notifications`.`creationTime` AS `creationTime`, `notifications`.`isReaded` AS `haveReaded` FROM (`notifications` join `notification_type` on(`notification_type`.`notificationType` = `notifications`.`notificationType`))  ;

-- --------------------------------------------------------

--
-- Structure for view `fullplayerdetails`
--
DROP TABLE IF EXISTS `fullplayerdetails`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `fullplayerdetails`  AS SELECT `tournament_matches`.`matchId` AS `matchId`, `tournament_matches`.`matchRadarId` AS `matchRadarId`, `match_players`.`playerId` AS `playerId`, `match_players`.`competitorId` AS `teamId`, 8 AS `credits`, `match_players`.`isSelected` AS `isSelected`, `match_players`.`points` AS `points`, concat(`allplayers`.`playerFirstName`,' ',`allplayers`.`playerLastName`) AS `name`, concat(`allplayers`.`playerFirstName`,' ',`allplayers`.`playerLastName`) AS `displayName`, `allplayers`.`playerRole` AS `roleId`, ucase(`allplayers`.`roleName`) AS `roleName` FROM ((`tournament_matches` join `match_players` on(`match_players`.`matchId` = `tournament_matches`.`matchId`)) join `allplayers` on(`allplayers`.`playerId` = `match_players`.`playerId`))  ;

-- --------------------------------------------------------

--
-- Structure for view `fullseriesdetails`
--
DROP TABLE IF EXISTS `fullseriesdetails`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `fullseriesdetails`  AS SELECT `tournament_information`.`tournamentId` AS `tournamentId`, `tournament_information`.`tournamentRadarId` AS `tournamentRadarId`, `tournament_information`.`currentSeasonRadarId` AS `currentSeasonRadarId`, `tournament_information`.`tournamentName` AS `tournamentName`, `tournament_information`.`currentSeasonName` AS `currentSeasonName`, `tournament_information`.`seasonStartDate` AS `seasonStartDate`, `tournament_information`.`seasonEndDate` AS `seasonEndDate`, `tournament_information`.`tournamentMatchType` AS `tournamentMatchType`, `tournament_information`.`tournamentCategory` AS `tournamentCategory`, `tournament_information`.`tournamentPlayersGender` AS `tournamentPlayersGender`, `tournament_information`.`tournamentCountry` AS `tournamentCountry`, `tournament_information`.`tournamentCountryCode` AS `tournamentCountryCode`, `tournament_information`.`isCompetitorsArrived` AS `isCompetitorsArrived`, `tournament_information`.`isMatchesArrived` AS `isMatchesArrived`, `tournament_category`.`categoryString` AS `categoryString`, `tournament_type`.`tournamnetTypeString` AS `tournamentTypeString` FROM ((`tournament_information` join `tournament_type` on(`tournament_type`.`tournamentTypeId` = `tournament_information`.`tournamentMatchType`)) join `tournament_category` on(`tournament_category`.`categoryId` = `tournament_information`.`tournamentCategory`))  ;

-- --------------------------------------------------------

--
-- Structure for view `fullteamdetails`
--
DROP TABLE IF EXISTS `fullteamdetails`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `fullteamdetails`  AS SELECT `user_team`.`matchId` AS `matchId`, `user_team`.`userId` AS `userId`, `user_team`.`userTeamId` AS `userTeamId`, `user_team`.`userTeamType` AS `userTeamType`, `team_type`.`teamTypeString` AS `teamTypeString`, `user_team_data`.`userTeamPoints` AS `userTeamPoints`, `user_team_data`.`userTeamViews` AS `userTeamViews`, `user_team_data`.`userTeamLikes` AS `userTeamLikes`, `user_team_data`.`captain` AS `captain`, `user_team_data`.`viceCaptain` AS `viceCaptain`, `user_team_data`.`player1` AS `player1`, `user_team_data`.`player2` AS `player2`, `user_team_data`.`player3` AS `player3`, `user_team_data`.`player4` AS `player4`, `user_team_data`.`player5` AS `player5`, `user_team_data`.`player6` AS `player6`, `user_team_data`.`player7` AS `player7`, `user_team_data`.`player8` AS `player8`, `user_team_data`.`player9` AS `player9`, `user_team_data`.`player10` AS `player10`, `user_team_data`.`player11` AS `player11`, `user_team_data`.`creationTime` AS `creationTime` FROM ((`user_team` join `user_team_data` on(`user_team_data`.`userTeamId` = `user_team`.`userTeamId`)) join `team_type` on(`team_type`.`teamType` = `user_team`.`userTeamType`))  ;

-- --------------------------------------------------------

--
-- Structure for view `inningBatsmans`
--
DROP TABLE IF EXISTS `inningBatsmans`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `inningBatsmans`  AS SELECT `inning_batsmans`.`scorcardInningId` AS `scorcardInningId`, `inning_batsmans`.`playerId` AS `playerId`, `inning_batsmans`.`battingOrder` AS `battingOrder`, `inning_batsmans`.`runs` AS `runs`, `inning_batsmans`.`strikeRate` AS `strikeRate`, `inning_batsmans`.`isNotOut` AS `isNotOut`, `inning_batsmans`.`isDuck` AS `isDuck`, `inning_batsmans`.`isRetiredHurt` AS `isRetiredHurt`, `inning_batsmans`.`ballFaced` AS `ballFaced`, `inning_batsmans`.`fours` AS `fours`, `inning_batsmans`.`sixes` AS `sixes`, `inning_batsmans`.`attackIngShot` AS `attackIngShot`, `inning_batsmans`.`semiAttackingShot` AS `semiAttackingShot`, `inning_batsmans`.`defendingShot` AS `defendingShot`, `inning_batsmans`.`leaves` AS `leaves`, `inning_batsmans`.`onSideShot` AS `onSideShot`, `inning_batsmans`.`offSideShot` AS `offSideShot`, `inning_batsmans`.`squreLegShot` AS `squreLegShot`, `inning_batsmans`.`fineLegShot` AS `fineLegShot`, `inning_batsmans`.`thirdManShot` AS `thirdManShot`, `inning_batsmans`.`coverShot` AS `coverShot`, `inning_batsmans`.`pointsShot` AS `pointsShot`, `inning_batsmans`.`midOnShot` AS `midOnShot`, `inning_batsmans`.`midOffShot` AS `midOffShot`, `inning_batsmans`.`midWicketShot` AS `midWicketShot`, `inning_batsmans`.`dismissalOverBallNumber` AS `dismissalOverBallNumber`, `inning_batsmans`.`dismissalOverNumber` AS `dismissalOverNumber`, `inning_batsmans`.`dismissalBallerId` AS `dismissalBallerId`, `inning_batsmans`.`dismissalDiliveryType` AS `dismissalDiliveryType`, `inning_batsmans`.`dismissalFieldeManId` AS `dismissalFieldeManId`, `inning_batsmans`.`dismissalIsOnStrike` AS `dismissalIsOnStrike`, `inning_batsmans`.`dismissalShotType` AS `dismissalShotType`, `inning_batsmans`.`dismissalType` AS `dismissalType` FROM `inning_batsmans``inning_batsmans`  ;

-- --------------------------------------------------------

--
-- Structure for view `inningBatting`
--
DROP TABLE IF EXISTS `inningBatting`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `inningBatting`  AS SELECT `inning_batting`.`scorcardInningId` AS `scorcardInningId`, `inning_batting`.`runs` AS `runs`, `inning_batting`.`fours` AS `fours`, `inning_batting`.`sixes` AS `sixes`, `inning_batting`.`runRate` AS `runRate`, `inning_batting`.`ballFaced` AS `ballFaced` FROM `inning_batting``inning_batting`  ;

-- --------------------------------------------------------

--
-- Structure for view `inningBowlers`
--
DROP TABLE IF EXISTS `inningBowlers`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `inningBowlers`  AS SELECT `inning_bowlers`.`scorcardInningId` AS `scorcardInningId`, `inning_bowlers`.`playerId` AS `playerId`, `inning_bowlers`.`runsConceded` AS `runsConceded`, `inning_bowlers`.`wickets` AS `wickets`, `inning_bowlers`.`overBowled` AS `overBowled`, `inning_bowlers`.`maidensOvers` AS `maidensOvers`, `inning_bowlers`.`dotBalls` AS `dotBalls`, `inning_bowlers`.`fourConceded` AS `fourConceded`, `inning_bowlers`.`sixConceded` AS `sixConceded`, `inning_bowlers`.`noBalls` AS `noBalls`, `inning_bowlers`.`wides` AS `wides`, `inning_bowlers`.`slowerDeliveries` AS `slowerDeliveries`, `inning_bowlers`.`yorkers` AS `yorkers`, `inning_bowlers`.`economyRate` AS `economyRate`, `inning_bowlers`.`fastestBall` AS `fastestBall`, `inning_bowlers`.`slowestBall` AS `slowestBall`, `inning_bowlers`.`averageSpeed` AS `averageSpeed`, `inning_bowlers`.`overTheWicketBalls` AS `overTheWicketBalls`, `inning_bowlers`.`aroundTheWicketBalls` AS `aroundTheWicketBalls`, `inning_bowlers`.`bouncers` AS `bouncers`, `inning_bowlers`.`beatBats` AS `beatBats`, `inning_bowlers`.`edge` AS `edge` FROM `inning_bowlers``inning_bowlers`  ;

-- --------------------------------------------------------

--
-- Structure for view `inningBowling`
--
DROP TABLE IF EXISTS `inningBowling`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `inningBowling`  AS SELECT `inning_bowling`.`scorcardInningId` AS `scorcardInningId`, `inning_bowling`.`overs` AS `overs`, `inning_bowling`.`wickets` AS `wickets`, `inning_bowling`.`maidens` AS `maidens`, `inning_bowling`.`extras` AS `extras`, `inning_bowling`.`noBalls` AS `noBalls`, `inning_bowling`.`byes` AS `byes`, `inning_bowling`.`legByes` AS `legByes`, `inning_bowling`.`dotBalls` AS `dotBalls` FROM `inning_bowling``inning_bowling`  ;

-- --------------------------------------------------------

--
-- Structure for view `scorcardDetails`
--
DROP TABLE IF EXISTS `scorcardDetails`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `scorcardDetails`  AS SELECT `scorcard_details`.`scorcardId` AS `scorcardId`, `scorcard_details`.`matchId` AS `matchId`, `scorcard_details`.`tossWonBy` AS `tossWonBy`, `scorcard_details`.`tossDecision` AS `tossDecision`, `scorcard_details`.`winnerId` AS `winnerId`, `scorcard_details`.`manOfMatch` AS `manOfMatch`, `scorcard_details`.`isPointsCalculated` AS `isPointsCalculated`, `scorcard_details`.`matchResultString` AS `matchResultString` FROM `scorcard_details``scorcard_details`  ;

-- --------------------------------------------------------

--
-- Structure for view `scorcardInning`
--
DROP TABLE IF EXISTS `scorcardInning`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `scorcardInning`  AS SELECT `scorcard_innings`.`scorcardInningId` AS `scorcardInningId`, `scorcard_innings`.`scorcardId` AS `scorcardId`, `scorcard_innings`.`inningNumber` AS `inningNumber`, `scorcard_innings`.`battingTeam` AS `battingTeam`, `scorcard_innings`.`bowlingTeam` AS `bowlingTeam`, `scorcard_innings`.`runs` AS `runs`, `scorcard_innings`.`wickets` AS `wickets`, `scorcard_innings`.`oversPlayed` AS `oversPlayed` FROM `scorcard_innings``scorcard_innings`  ;

-- --------------------------------------------------------

--
-- Structure for view `testView`
--
DROP TABLE IF EXISTS `testView`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `testView`  AS SELECT `tournament_matches`.`matchId` AS `matchId`, `tournament_matches`.`matchRadarId` AS `matchRadarId`, `match_players`.`playerId` AS `playerId`, `match_players`.`competitorId` AS `teamId`, 0 AS `credits`, `match_players`.`isSelected` AS `isSelected`, `match_players`.`points` AS `points`, concat(`allplayers`.`playerFirstName`,' ',`allplayers`.`playerLastName`) AS `name`, concat(`allplayers`.`playerFirstName`,' ',`allplayers`.`playerLastName`) AS `displayName`, `allplayers`.`playerRole` AS `roleId`, ucase(`allplayers`.`roleName`) AS `roleName` FROM ((`tournament_matches` join `match_players` on(`match_players`.`matchId` = `tournament_matches`.`matchId`)) join `allplayers` on(`allplayers`.`playerId` = `match_players`.`playerId`))  ;

-- --------------------------------------------------------

--
-- Structure for view `userdetails`
--
DROP TABLE IF EXISTS `userdetails`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `userdetails`  AS SELECT `users`.`userId` AS `userId`, `users`.`userType` AS `userType`, `user_type`.`userTypeString` AS `userTypeString`, `users`.`phoneNumber` AS `phoneNumber`, `users`.`email` AS `email`, `users`.`dateOfBirth` AS `dateOfBirth`, `users`.`gender` AS `gender`, `users`.`firstName` AS `firstName`, `users`.`lastName` AS `lastName`, `users`.`address` AS `address`, `users`.`city` AS `city`, `users`.`pinCode` AS `pinCode`, `users`.`state` AS `state`, `users`.`country` AS `country`, `users`.`isVerified` AS `isVerified`, `users`.`imageStamp` AS `imageStamp`, `users`.`registerTime` AS `registerTime` FROM (`users` join `user_type` on(`user_type`.`userType` = `users`.`userType`))  ;

-- --------------------------------------------------------

--
-- Structure for view `userTeamDetails`
--
DROP TABLE IF EXISTS `userTeamDetails`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `userTeamDetails`  AS SELECT `user_team_new`.`userTeamId` AS `userTeamId`, `user_team_new`.`matchId` AS `matchId`, `user_team_new`.`userId` AS `userId`, `user_team_new`.`userTeamType` AS `userTeamType`, `team_type`.`teamTypeString` AS `teamTypeString`, `user_team_new`.`userTeamPoints` AS `userTeamPoints`, `user_team_new`.`userTeamViews` AS `userTeamViews`, `user_team_new`.`userTeamLikes` AS `userTeamLikes`, `user_team_new`.`creationTime` AS `creationTime` FROM (`user_team_new` join `team_type` on(`team_type`.`teamType` = `user_team_new`.`userTeamType`))  ;

-- --------------------------------------------------------

--
-- Structure for view `userTeamPlayersDetails`
--
DROP TABLE IF EXISTS `userTeamPlayersDetails`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `userTeamPlayersDetails`  AS SELECT `user_team_data_new`.`userTeamId` AS `userTeamId`, `user_team_data_new`.`playerId` AS `playerId`, `user_team_data_new`.`isCaptain` AS `isCaptain`, `user_team_data_new`.`isViceCaptain` AS `isViceCaptain` FROM `user_team_data_new``user_team_data_new`  ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `competitors`
--
ALTER TABLE `competitors`
  ADD PRIMARY KEY (`competitorId`),
  ADD UNIQUE KEY `competitorRadarId` (`competitorRadarId`);

--
-- Indexes for table `discussion`
--
ALTER TABLE `discussion`
  ADD PRIMARY KEY (`discussionId`),
  ADD KEY `match` (`matchId`),
  ADD KEY `messenger` (`messengerId`),
  ADD KEY `teamCreater` (`userId`);

--
-- Indexes for table `inning_batsmans`
--
ALTER TABLE `inning_batsmans`
  ADD UNIQUE KEY `scorcardInningId` (`scorcardInningId`,`playerId`),
  ADD KEY `relation_scorcardInning_player` (`playerId`);

--
-- Indexes for table `inning_batting`
--
ALTER TABLE `inning_batting`
  ADD PRIMARY KEY (`scorcardInningId`);

--
-- Indexes for table `inning_bowlers`
--
ALTER TABLE `inning_bowlers`
  ADD UNIQUE KEY `scorcardInningId_2` (`scorcardInningId`,`playerId`),
  ADD KEY `scorcardInningId` (`scorcardInningId`);

--
-- Indexes for table `inning_bowling`
--
ALTER TABLE `inning_bowling`
  ADD PRIMARY KEY (`scorcardInningId`);

--
-- Indexes for table `match_lineup`
--
ALTER TABLE `match_lineup`
  ADD UNIQUE KEY `matchId` (`matchId`,`competitorId`,`playerId`),
  ADD KEY `match_lineup_competitor` (`competitorId`),
  ADD KEY `match_lineup_playerId` (`playerId`);

--
-- Indexes for table `match_players`
--
ALTER TABLE `match_players`
  ADD UNIQUE KEY `matchId` (`matchId`,`competitorId`,`playerId`),
  ADD KEY `competitorId` (`competitorId`),
  ADD KEY `playerId` (`playerId`);

--
-- Indexes for table `match_status`
--
ALTER TABLE `match_status`
  ADD PRIMARY KEY (`statusId`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`notificationId`),
  ADD KEY `userNotification` (`userId`),
  ADD KEY `notificationType` (`notificationType`);

--
-- Indexes for table `notification_type`
--
ALTER TABLE `notification_type`
  ADD PRIMARY KEY (`notificationType`);

--
-- Indexes for table `players`
--
ALTER TABLE `players`
  ADD PRIMARY KEY (`playerId`),
  ADD UNIQUE KEY `playerRadarId` (`playerRadarId`),
  ADD KEY `relation_player_role` (`playerRole`),
  ADD KEY `relation_batting_style` (`playerBattingStyleId`),
  ADD KEY `relation_bowling_style` (`playerBowlingStyleId`);

--
-- Indexes for table `player_batting_style`
--
ALTER TABLE `player_batting_style`
  ADD PRIMARY KEY (`playerBattingStyleId`),
  ADD UNIQUE KEY `battingStyleString` (`battingStyleString`);

--
-- Indexes for table `player_bowling_style`
--
ALTER TABLE `player_bowling_style`
  ADD PRIMARY KEY (`playerBowlingStyleId`),
  ADD UNIQUE KEY `playerBowlingStyleString` (`playerBowlingStyleString`);

--
-- Indexes for table `player_roles`
--
ALTER TABLE `player_roles`
  ADD PRIMARY KEY (`roleId`);

--
-- Indexes for table `player_statistics_batting`
--
ALTER TABLE `player_statistics_batting`
  ADD UNIQUE KEY `playerId` (`playerId`,`type`);

--
-- Indexes for table `player_statistics_bowling`
--
ALTER TABLE `player_statistics_bowling`
  ADD UNIQUE KEY `playerId` (`playerId`,`type`);

--
-- Indexes for table `scorcard_details`
--
ALTER TABLE `scorcard_details`
  ADD PRIMARY KEY (`scorcardId`),
  ADD UNIQUE KEY `matchId` (`matchId`),
  ADD KEY `manOfMatch` (`manOfMatch`),
  ADD KEY `tossWonBy` (`tossWonBy`);

--
-- Indexes for table `scorcard_innings`
--
ALTER TABLE `scorcard_innings`
  ADD PRIMARY KEY (`scorcardInningId`),
  ADD UNIQUE KEY `scorcardId` (`scorcardId`,`inningNumber`);

--
-- Indexes for table `team_type`
--
ALTER TABLE `team_type`
  ADD PRIMARY KEY (`teamType`);

--
-- Indexes for table `tournament_category`
--
ALTER TABLE `tournament_category`
  ADD PRIMARY KEY (`categoryId`),
  ADD UNIQUE KEY `categoryRadarId` (`categoryRadarId`),
  ADD UNIQUE KEY `categoryString` (`categoryString`);

--
-- Indexes for table `tournament_competitor`
--
ALTER TABLE `tournament_competitor`
  ADD PRIMARY KEY (`tournamentCompetitorId`),
  ADD UNIQUE KEY `UNIQUE_TOURNAMENT_COMPETITOR` (`competitorId`,`tournamentId`),
  ADD KEY `relation_tournament` (`tournamentId`);

--
-- Indexes for table `tournament_competitor_player`
--
ALTER TABLE `tournament_competitor_player`
  ADD PRIMARY KEY (`tournamentCompetitorPlayerId`),
  ADD UNIQUE KEY `UNIQUE_COMPETITOR_PLAYER` (`tournamentCompetitorId`,`playerId`),
  ADD KEY `relation_player_playersTable` (`playerId`);

--
-- Indexes for table `tournament_information`
--
ALTER TABLE `tournament_information`
  ADD PRIMARY KEY (`tournamentId`),
  ADD UNIQUE KEY `tournamentRadarId` (`tournamentRadarId`),
  ADD UNIQUE KEY `currentSeasonRadarId` (`currentSeasonRadarId`),
  ADD UNIQUE KEY `UNIQUE_TOURNAMENT_SEASON` (`currentSeasonRadarId`,`tournamentRadarId`),
  ADD KEY `relation_tournament_category` (`tournamentCategory`),
  ADD KEY `relation_tournament_type` (`tournamentMatchType`);

--
-- Indexes for table `tournament_matches`
--
ALTER TABLE `tournament_matches`
  ADD PRIMARY KEY (`matchId`),
  ADD UNIQUE KEY `matchRadarId` (`matchRadarId`),
  ADD KEY `relation_match_status` (`matchStatus`),
  ADD KEY `relation_match_competitor1` (`competitor1`),
  ADD KEY `relation_match_competitor2` (`competitor2`),
  ADD KEY `relation_match_venue` (`venueId`),
  ADD KEY `relation_match_tournament` (`matchTournamentId`),
  ADD KEY `tossWonBy` (`tossWonBy`);

--
-- Indexes for table `tournament_type`
--
ALTER TABLE `tournament_type`
  ADD PRIMARY KEY (`tournamentTypeId`),
  ADD UNIQUE KEY `tournamnetTypeString` (`tournamnetTypeString`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`userId`,`phoneNumber`),
  ADD UNIQUE KEY `phone_number` (`phoneNumber`),
  ADD KEY `user_type` (`userType`);

--
-- Indexes for table `user_team`
--
ALTER TABLE `user_team`
  ADD PRIMARY KEY (`number`),
  ADD UNIQUE KEY `matchId` (`matchId`,`userId`,`userTeamId`),
  ADD KEY `relation_userId_userTable` (`userId`),
  ADD KEY `relation_teamType_teamTypeTable` (`userTeamId`);

--
-- Indexes for table `user_team_data`
--
ALTER TABLE `user_team_data`
  ADD PRIMARY KEY (`userTeamId`),
  ADD KEY `relation_player1_players` (`player1`),
  ADD KEY `relation_player2_players` (`player2`),
  ADD KEY `relation_player3_players` (`player3`),
  ADD KEY `relation_player4_players` (`player4`),
  ADD KEY `relation_player5_players` (`player5`),
  ADD KEY `relation_player6_players` (`player6`),
  ADD KEY `relation_player7_players` (`player7`),
  ADD KEY `relation_player8_players` (`player8`),
  ADD KEY `relation_player9_players` (`player9`),
  ADD KEY `relation_player10_players` (`player10`),
  ADD KEY `relation_player11_players` (`player11`),
  ADD KEY `relation_captain_players` (`captain`),
  ADD KEY `relation_viceCaptain_players` (`viceCaptain`);

--
-- Indexes for table `user_team_data_new`
--
ALTER TABLE `user_team_data_new`
  ADD UNIQUE KEY `userTeamId` (`userTeamId`,`playerId`),
  ADD KEY `playerId` (`playerId`);

--
-- Indexes for table `user_team_likes`
--
ALTER TABLE `user_team_likes`
  ADD UNIQUE KEY `userTeamId` (`userTeamId`,`userId`),
  ADD KEY `relation_userTeamLikes_usersTable` (`userId`);

--
-- Indexes for table `user_team_new`
--
ALTER TABLE `user_team_new`
  ADD PRIMARY KEY (`userTeamId`),
  ADD UNIQUE KEY `matchId` (`matchId`,`userId`,`userTeamType`),
  ADD KEY `userId` (`userId`),
  ADD KEY `userTeamType` (`userTeamType`);

--
-- Indexes for table `user_team_views`
--
ALTER TABLE `user_team_views`
  ADD UNIQUE KEY `userTeamId` (`userTeamId`,`userId`),
  ADD KEY `relation_userId_usersTbale` (`userId`);

--
-- Indexes for table `user_type`
--
ALTER TABLE `user_type`
  ADD PRIMARY KEY (`userType`),
  ADD UNIQUE KEY `userTypeString` (`userTypeString`),
  ADD UNIQUE KEY `userTypeString_2` (`userTypeString`);

--
-- Indexes for table `venues`
--
ALTER TABLE `venues`
  ADD PRIMARY KEY (`venueId`),
  ADD UNIQUE KEY `venueRadarId` (`venueRadarId`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `competitors`
--
ALTER TABLE `competitors`
  MODIFY `competitorId` int(10) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `discussion`
--
ALTER TABLE `discussion`
  MODIFY `discussionId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `match_status`
--
ALTER TABLE `match_status`
  MODIFY `statusId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `players`
--
ALTER TABLE `players`
  MODIFY `playerId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `player_batting_style`
--
ALTER TABLE `player_batting_style`
  MODIFY `playerBattingStyleId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `player_bowling_style`
--
ALTER TABLE `player_bowling_style`
  MODIFY `playerBowlingStyleId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `player_roles`
--
ALTER TABLE `player_roles`
  MODIFY `roleId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scorcard_details`
--
ALTER TABLE `scorcard_details`
  MODIFY `scorcardId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `scorcard_innings`
--
ALTER TABLE `scorcard_innings`
  MODIFY `scorcardInningId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `team_type`
--
ALTER TABLE `team_type`
  MODIFY `teamType` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tournament_category`
--
ALTER TABLE `tournament_category`
  MODIFY `categoryId` int(2) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tournament_competitor`
--
ALTER TABLE `tournament_competitor`
  MODIFY `tournamentCompetitorId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tournament_competitor_player`
--
ALTER TABLE `tournament_competitor_player`
  MODIFY `tournamentCompetitorPlayerId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tournament_information`
--
ALTER TABLE `tournament_information`
  MODIFY `tournamentId` int(10) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tournament_matches`
--
ALTER TABLE `tournament_matches`
  MODIFY `matchId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tournament_type`
--
ALTER TABLE `tournament_type`
  MODIFY `tournamentTypeId` int(2) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `userId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_team`
--
ALTER TABLE `user_team`
  MODIFY `number` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_team_data`
--
ALTER TABLE `user_team_data`
  MODIFY `userTeamId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_team_new`
--
ALTER TABLE `user_team_new`
  MODIFY `userTeamId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `user_type`
--
ALTER TABLE `user_type`
  MODIFY `userType` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `venues`
--
ALTER TABLE `venues`
  MODIFY `venueId` int(11) NOT NULL AUTO_INCREMENT;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `discussion`
--
ALTER TABLE `discussion`
  ADD CONSTRAINT `match` FOREIGN KEY (`matchId`) REFERENCES `tournament_matches` (`matchId`),
  ADD CONSTRAINT `messenger` FOREIGN KEY (`messengerId`) REFERENCES `users` (`userId`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `teamCreater` FOREIGN KEY (`userId`) REFERENCES `users` (`userId`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `inning_batsmans`
--
ALTER TABLE `inning_batsmans`
  ADD CONSTRAINT `relation_scorcardInning` FOREIGN KEY (`scorcardInningId`) REFERENCES `scorcard_innings` (`scorcardInningId`) ON DELETE CASCADE,
  ADD CONSTRAINT `relation_scorcardInning_player` FOREIGN KEY (`playerId`) REFERENCES `players` (`playerId`);

--
-- Constraints for table `inning_batting`
--
ALTER TABLE `inning_batting`
  ADD CONSTRAINT `inning_batting_ibfk_1` FOREIGN KEY (`scorcardInningId`) REFERENCES `scorcard_innings` (`scorcardInningId`) ON DELETE CASCADE;

--
-- Constraints for table `inning_bowlers`
--
ALTER TABLE `inning_bowlers`
  ADD CONSTRAINT `inning_bowlers_ibfk_1` FOREIGN KEY (`scorcardInningId`) REFERENCES `scorcard_innings` (`scorcardInningId`) ON DELETE CASCADE;

--
-- Constraints for table `inning_bowling`
--
ALTER TABLE `inning_bowling`
  ADD CONSTRAINT `inning_bowling_ibfk_1` FOREIGN KEY (`scorcardInningId`) REFERENCES `scorcard_innings` (`scorcardInningId`) ON DELETE CASCADE;

--
-- Constraints for table `match_lineup`
--
ALTER TABLE `match_lineup`
  ADD CONSTRAINT `match_lineup_competitor` FOREIGN KEY (`competitorId`) REFERENCES `competitors` (`competitorId`),
  ADD CONSTRAINT `match_lineup_matchId` FOREIGN KEY (`matchId`) REFERENCES `tournament_matches` (`matchId`),
  ADD CONSTRAINT `match_lineup_playerId` FOREIGN KEY (`playerId`) REFERENCES `players` (`playerId`);

--
-- Constraints for table `match_players`
--
ALTER TABLE `match_players`
  ADD CONSTRAINT `match_players_ibfk_1` FOREIGN KEY (`matchId`) REFERENCES `tournament_matches` (`matchId`),
  ADD CONSTRAINT `match_players_ibfk_2` FOREIGN KEY (`competitorId`) REFERENCES `competitors` (`competitorId`),
  ADD CONSTRAINT `match_players_ibfk_3` FOREIGN KEY (`playerId`) REFERENCES `players` (`playerId`);

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notificationType` FOREIGN KEY (`notificationType`) REFERENCES `notification_type` (`notificationType`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `userNotification` FOREIGN KEY (`userId`) REFERENCES `users` (`userId`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `players`
--
ALTER TABLE `players`
  ADD CONSTRAINT `relation_batting_style` FOREIGN KEY (`playerBattingStyleId`) REFERENCES `player_batting_style` (`playerBattingStyleId`),
  ADD CONSTRAINT `relation_bowling_style` FOREIGN KEY (`playerBowlingStyleId`) REFERENCES `player_bowling_style` (`playerBowlingStyleId`),
  ADD CONSTRAINT `relation_player_role` FOREIGN KEY (`playerRole`) REFERENCES `player_roles` (`roleId`) ON UPDATE CASCADE;

--
-- Constraints for table `player_statistics_batting`
--
ALTER TABLE `player_statistics_batting`
  ADD CONSTRAINT `player_statistics_batting` FOREIGN KEY (`playerId`) REFERENCES `players` (`playerId`);

--
-- Constraints for table `player_statistics_bowling`
--
ALTER TABLE `player_statistics_bowling`
  ADD CONSTRAINT `player_statistics_bowling_ibfk_1` FOREIGN KEY (`playerId`) REFERENCES `players` (`playerId`);

--
-- Constraints for table `scorcard_details`
--
ALTER TABLE `scorcard_details`
  ADD CONSTRAINT `relation_scorcardMatch_match` FOREIGN KEY (`matchId`) REFERENCES `tournament_matches` (`matchId`),
  ADD CONSTRAINT `scorcard_details_ibfk_1` FOREIGN KEY (`manOfMatch`) REFERENCES `players` (`playerId`),
  ADD CONSTRAINT `scorcard_details_ibfk_2` FOREIGN KEY (`tossWonBy`) REFERENCES `competitors` (`competitorId`);

--
-- Constraints for table `scorcard_innings`
--
ALTER TABLE `scorcard_innings`
  ADD CONSTRAINT `relation_scordcard_scorcardTable` FOREIGN KEY (`scorcardId`) REFERENCES `scorcard_details` (`scorcardId`) ON DELETE CASCADE;

--
-- Constraints for table `tournament_competitor`
--
ALTER TABLE `tournament_competitor`
  ADD CONSTRAINT `relation_tournament` FOREIGN KEY (`tournamentId`) REFERENCES `tournament_information` (`tournamentId`),
  ADD CONSTRAINT `relation_tournament_competitor` FOREIGN KEY (`competitorId`) REFERENCES `competitors` (`competitorId`);

--
-- Constraints for table `tournament_competitor_player`
--
ALTER TABLE `tournament_competitor_player`
  ADD CONSTRAINT `relation_player_playersTable` FOREIGN KEY (`playerId`) REFERENCES `players` (`playerId`),
  ADD CONSTRAINT `relation_tournamentCompetitor` FOREIGN KEY (`tournamentCompetitorId`) REFERENCES `tournament_competitor` (`tournamentCompetitorId`);

--
-- Constraints for table `tournament_information`
--
ALTER TABLE `tournament_information`
  ADD CONSTRAINT `relation_tournament_category` FOREIGN KEY (`tournamentCategory`) REFERENCES `tournament_category` (`categoryId`),
  ADD CONSTRAINT `relation_tournament_type` FOREIGN KEY (`tournamentMatchType`) REFERENCES `tournament_type` (`tournamentTypeId`);

--
-- Constraints for table `tournament_matches`
--
ALTER TABLE `tournament_matches`
  ADD CONSTRAINT `relation_match_competitor1` FOREIGN KEY (`competitor1`) REFERENCES `competitors` (`competitorId`),
  ADD CONSTRAINT `relation_match_competitor2` FOREIGN KEY (`competitor2`) REFERENCES `competitors` (`competitorId`),
  ADD CONSTRAINT `relation_match_status` FOREIGN KEY (`matchStatus`) REFERENCES `match_status` (`statusId`),
  ADD CONSTRAINT `relation_match_tournament` FOREIGN KEY (`matchTournamentId`) REFERENCES `tournament_information` (`tournamentId`),
  ADD CONSTRAINT `relation_match_venue` FOREIGN KEY (`venueId`) REFERENCES `venues` (`venueId`),
  ADD CONSTRAINT `tournament_matches_ibfk_1` FOREIGN KEY (`tossWonBy`) REFERENCES `competitors` (`competitorId`);

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `user_type` FOREIGN KEY (`userType`) REFERENCES `user_type` (`userType`) ON UPDATE CASCADE;

--
-- Constraints for table `user_team`
--
ALTER TABLE `user_team`
  ADD CONSTRAINT `relation_matchId_matchTable` FOREIGN KEY (`matchId`) REFERENCES `tournament_matches` (`matchId`),
  ADD CONSTRAINT `relation_teamType_teamTypeTable` FOREIGN KEY (`userTeamId`) REFERENCES `user_team_data` (`userTeamId`),
  ADD CONSTRAINT `relation_userId_userTable` FOREIGN KEY (`userId`) REFERENCES `users` (`userId`);

--
-- Constraints for table `user_team_data`
--
ALTER TABLE `user_team_data`
  ADD CONSTRAINT `relation_captain_players` FOREIGN KEY (`captain`) REFERENCES `players` (`playerId`),
  ADD CONSTRAINT `relation_player10_players` FOREIGN KEY (`player10`) REFERENCES `players` (`playerId`),
  ADD CONSTRAINT `relation_player11_players` FOREIGN KEY (`player11`) REFERENCES `players` (`playerId`),
  ADD CONSTRAINT `relation_player1_players` FOREIGN KEY (`player1`) REFERENCES `players` (`playerId`),
  ADD CONSTRAINT `relation_player2_players` FOREIGN KEY (`player2`) REFERENCES `players` (`playerId`),
  ADD CONSTRAINT `relation_player3_players` FOREIGN KEY (`player3`) REFERENCES `players` (`playerId`),
  ADD CONSTRAINT `relation_player4_players` FOREIGN KEY (`player4`) REFERENCES `players` (`playerId`),
  ADD CONSTRAINT `relation_player5_players` FOREIGN KEY (`player5`) REFERENCES `players` (`playerId`),
  ADD CONSTRAINT `relation_player6_players` FOREIGN KEY (`player6`) REFERENCES `players` (`playerId`),
  ADD CONSTRAINT `relation_player7_players` FOREIGN KEY (`player7`) REFERENCES `players` (`playerId`),
  ADD CONSTRAINT `relation_player8_players` FOREIGN KEY (`player8`) REFERENCES `players` (`playerId`),
  ADD CONSTRAINT `relation_player9_players` FOREIGN KEY (`player9`) REFERENCES `players` (`playerId`),
  ADD CONSTRAINT `relation_viceCaptain_players` FOREIGN KEY (`viceCaptain`) REFERENCES `players` (`playerId`);

--
-- Constraints for table `user_team_data_new`
--
ALTER TABLE `user_team_data_new`
  ADD CONSTRAINT `user_team_data_new_ibfk_1` FOREIGN KEY (`playerId`) REFERENCES `players` (`playerId`),
  ADD CONSTRAINT `user_team_data_new_ibfk_2` FOREIGN KEY (`userTeamId`) REFERENCES `user_team_new` (`userTeamId`);

--
-- Constraints for table `user_team_likes`
--
ALTER TABLE `user_team_likes`
  ADD CONSTRAINT `relation_userTeamLikes_userTeamTable` FOREIGN KEY (`userTeamId`) REFERENCES `user_team` (`userTeamId`),
  ADD CONSTRAINT `relation_userTeamLikes_usersTable` FOREIGN KEY (`userId`) REFERENCES `users` (`userId`);

--
-- Constraints for table `user_team_new`
--
ALTER TABLE `user_team_new`
  ADD CONSTRAINT `user_team_new_ibfk_1` FOREIGN KEY (`matchId`) REFERENCES `tournament_matches` (`matchId`),
  ADD CONSTRAINT `user_team_new_ibfk_2` FOREIGN KEY (`userId`) REFERENCES `users` (`userId`),
  ADD CONSTRAINT `user_team_new_ibfk_3` FOREIGN KEY (`userTeamType`) REFERENCES `team_type` (`teamType`);

--
-- Constraints for table `user_team_views`
--
ALTER TABLE `user_team_views`
  ADD CONSTRAINT `relation_userId_usersTbale` FOREIGN KEY (`userId`) REFERENCES `users` (`userId`),
  ADD CONSTRAINT `relation_userTeamViews_userTeamTable` FOREIGN KEY (`userTeamId`) REFERENCES `user_team` (`userTeamId`);
COMMIT;
