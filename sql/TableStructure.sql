-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Jun 06, 2022 at 05:01 PM
-- Server version: 10.4.24-MariaDB
-- PHP Version: 8.1.6

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `dreamg-v3`
--

-- --------------------------------------------------------

--
-- Table structure for table `coinSpendSource`
--

CREATE TABLE `coinSpendSource` (
  `sourceId` int(11) NOT NULL,
  `sourceName` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `cointHistory`
--

CREATE TABLE `cointHistory` (
  `timeZone` timestamp NOT NULL DEFAULT current_timestamp(),
  `spendedCoints` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `spendSource` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `competitors`
--

CREATE TABLE `competitors` (
  `competitorId` int(11) NOT NULL,
  `competitorRadarId` int(11) NOT NULL,
  `competitorName` varchar(50) NOT NULL,
  `competitorCountry` varchar(30) DEFAULT NULL,
  `competitorCountryCode` varchar(20) DEFAULT NULL,
  `competitorDisplayName` tinytext DEFAULT NULL,
  `logTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `inning_batsmans`
--

CREATE TABLE `inning_batsmans` (
  `scorcardInningId` int(11) NOT NULL,
  `playerId` int(11) NOT NULL,
  `battingOrder` int(11) DEFAULT NULL,
  `runs` int(11) NOT NULL DEFAULT 0,
  `strikeRate` float DEFAULT 0,
  `isNotOut` tinyint(1) NOT NULL DEFAULT 0,
  `isDuck` tinyint(1) NOT NULL DEFAULT 0,
  `isRetiredHurt` tinyint(1) NOT NULL DEFAULT 0,
  `ballFaced` int(11) NOT NULL DEFAULT 0,
  `fours` int(11) NOT NULL DEFAULT 0,
  `sixes` int(11) NOT NULL DEFAULT 0,
  `attackIngShot` int(11) NOT NULL DEFAULT 0,
  `semiAttackingShot` int(11) NOT NULL DEFAULT 0,
  `defendingShot` int(11) NOT NULL DEFAULT 0,
  `leaves` int(11) NOT NULL DEFAULT 0,
  `onSideShot` int(11) NOT NULL DEFAULT 0,
  `offSideShot` int(11) NOT NULL DEFAULT 0,
  `squreLegShot` int(11) NOT NULL DEFAULT 0,
  `fineLegShot` int(11) NOT NULL DEFAULT 0,
  `thirdManShot` int(11) NOT NULL DEFAULT 0,
  `coverShot` int(11) NOT NULL DEFAULT 0,
  `pointsShot` int(11) NOT NULL DEFAULT 0,
  `midOnShot` int(11) NOT NULL DEFAULT 0,
  `midOffShot` int(11) NOT NULL DEFAULT 0,
  `midWicketShot` int(11) NOT NULL DEFAULT 0,
  `dismissalOverBallNumber` tinyint(1) DEFAULT NULL,
  `dismissalOverNumber` smallint(6) DEFAULT NULL,
  `dismissalBallerId` int(11) DEFAULT NULL,
  `dismissalDiliveryType` tinytext DEFAULT NULL,
  `dismissalFieldeManId` int(11) DEFAULT NULL,
  `dismissalIsOnStrike` tinyint(1) DEFAULT NULL,
  `dismissalShotType` tinytext DEFAULT NULL,
  `dismissalType` tinytext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `inning_batting`
--

CREATE TABLE `inning_batting` (
  `scorcardInningId` int(11) NOT NULL,
  `runs` int(11) NOT NULL,
  `fours` int(11) NOT NULL,
  `sixes` int(11) NOT NULL,
  `runRate` float NOT NULL,
  `ballFaced` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `inning_bowlers`
--

CREATE TABLE `inning_bowlers` (
  `scorcardInningId` int(11) NOT NULL,
  `playerId` int(11) NOT NULL,
  `runsConceded` int(11) NOT NULL DEFAULT 0,
  `wickets` int(11) NOT NULL DEFAULT 0,
  `overBowled` int(11) NOT NULL DEFAULT 0,
  `maidensOvers` int(11) NOT NULL DEFAULT 0,
  `dotBalls` int(11) NOT NULL DEFAULT 0,
  `fourConceded` int(11) NOT NULL DEFAULT 0,
  `sixConceded` int(11) NOT NULL DEFAULT 0,
  `noBalls` int(11) NOT NULL DEFAULT 0,
  `wides` int(11) NOT NULL DEFAULT 0,
  `slowerDeliveries` int(11) NOT NULL DEFAULT 0,
  `yorkers` int(11) NOT NULL DEFAULT 0,
  `economyRate` float NOT NULL DEFAULT 0,
  `fastestBall` int(11) NOT NULL DEFAULT 0,
  `slowestBall` int(11) NOT NULL DEFAULT 0,
  `averageSpeed` int(11) NOT NULL,
  `overTheWicketBalls` int(11) NOT NULL DEFAULT 0,
  `aroundTheWicketBalls` int(11) NOT NULL DEFAULT 0,
  `bouncers` int(11) NOT NULL DEFAULT 0,
  `beatBats` int(11) NOT NULL DEFAULT 0,
  `edge` int(11) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `inning_bowling`
--

CREATE TABLE `inning_bowling` (
  `scorcardInningId` int(11) NOT NULL,
  `overs` float NOT NULL,
  `wickets` int(11) NOT NULL,
  `maidens` int(11) NOT NULL,
  `extras` int(11) NOT NULL,
  `noBalls` int(11) NOT NULL,
  `byes` int(11) NOT NULL,
  `legByes` int(11) NOT NULL,
  `dotBalls` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
  `order` tinyint(4) NOT NULL,
  `points` int(11) DEFAULT 0,
  `runsPoints` int(11) NOT NULL DEFAULT 0,
  `foursPoints` int(11) NOT NULL DEFAULT 0,
  `sixesPoints` int(11) NOT NULL DEFAULT 0,
  `numberRunsPoints` int(11) NOT NULL DEFAULT 0,
  `numberWicketPoints` int(11) NOT NULL DEFAULT 0,
  `wicketPoints` int(11) NOT NULL DEFAULT 0,
  `maidenOverPoints` int(11) NOT NULL DEFAULT 0,
  `lbwOrBowledPoints` int(11) NOT NULL DEFAULT 0,
  `catchesPoints` int(11) NOT NULL DEFAULT 0,
  `runOutPoints` int(11) NOT NULL DEFAULT 0,
  `economyPoints` int(11) DEFAULT NULL,
  `strikeRatePoints` int(11) NOT NULL,
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
  `order` int(11) DEFAULT NULL,
  `credit` decimal(20,1) NOT NULL DEFAULT 7.5,
  `points` int(11) DEFAULT NULL,
  `runsPoints` int(11) NOT NULL DEFAULT 0,
  `foursPoints` int(11) NOT NULL DEFAULT 0,
  `sixesPoints` int(11) NOT NULL DEFAULT 0,
  `numberRunsPoints` int(11) NOT NULL DEFAULT 0,
  `numberWicketPoints` int(11) NOT NULL DEFAULT 0,
  `wicketPoints` int(11) NOT NULL DEFAULT 0,
  `maidenOverPoints` int(11) NOT NULL DEFAULT 0,
  `lbwOrBowledPoints` int(11) NOT NULL DEFAULT 0,
  `catchesPoints` int(11) NOT NULL DEFAULT 0,
  `runOutPoints` int(11) NOT NULL DEFAULT 0,
  `economyPoints` int(11) DEFAULT NULL,
  `strikeRatePoints` int(11) DEFAULT NULL,
  `logTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `match_status`
--

CREATE TABLE `match_status` (
  `statusId` int(11) NOT NULL,
  `statusString` tinytext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `playerImages`
--

CREATE TABLE `playerImages` (
  `ucPlayerId` int(11) NOT NULL,
  `name` tinytext NOT NULL,
  `dateOfBirth` varchar(15) NOT NULL,
  `imageId` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
  `playerRole` int(11) NOT NULL DEFAULT 0,
  `playerDOB` date DEFAULT NULL,
  `playerBattingStyleId` int(11) DEFAULT NULL,
  `playerBowlingStyleId` int(11) DEFAULT NULL,
  `playerCountry` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `player_statistics_batting`
--

CREATE TABLE `player_statistics_batting` (
  `playerId` int(11) NOT NULL,
  `type` varchar(30) NOT NULL,
  `matches` int(11) DEFAULT NULL,
  `innings` int(11) DEFAULT NULL,
  `ballFaced` int(11) DEFAULT NULL,
  `notOuts` int(11) DEFAULT NULL,
  `runs` int(11) DEFAULT NULL,
  `average` float DEFAULT NULL,
  `strikeRate` float DEFAULT NULL,
  `highestScore` int(11) DEFAULT NULL,
  `hundreds` int(11) DEFAULT NULL,
  `fifties` int(11) DEFAULT NULL,
  `fours` int(11) DEFAULT NULL,
  `sixes` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `player_statistics_bowling`
--

CREATE TABLE `player_statistics_bowling` (
  `playerId` int(11) NOT NULL,
  `type` varchar(30) NOT NULL,
  `matches` int(11) DEFAULT NULL,
  `innings` int(11) DEFAULT NULL,
  `overs` float DEFAULT NULL,
  `ballsBalled` int(11) DEFAULT NULL,
  `maidens` int(11) DEFAULT NULL,
  `runs` int(11) DEFAULT NULL,
  `wickets` int(11) DEFAULT NULL,
  `average` float DEFAULT NULL,
  `strikeRate` float DEFAULT NULL,
  `economy` float DEFAULT NULL,
  `bestBowling` int(11) DEFAULT NULL,
  `fourWicketHauls` int(11) DEFAULT NULL,
  `fiverWicketHauls` int(11) DEFAULT NULL,
  `tenWicketHauls` int(11) DEFAULT NULL,
  `catches` int(11) DEFAULT NULL,
  `stumping` int(11) DEFAULT NULL,
  `runOuts` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
  `isTie` tinyint(1) NOT NULL DEFAULT 0,
  `isDraw` tinyint(1) NOT NULL DEFAULT 0,
  `manOfMatch` int(11) DEFAULT NULL,
  `isPointsCalculated` tinyint(1) NOT NULL DEFAULT 0,
  `matchResultString` varchar(1000) DEFAULT NULL,
  `logTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

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
-- Table structure for table `tournament_category`
--

CREATE TABLE `tournament_category` (
  `categoryId` int(11) NOT NULL,
  `categoryRadarId` int(11) NOT NULL,
  `categoryString` varchar(50) NOT NULL,
  `logTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `tournament_competitor`
--

CREATE TABLE `tournament_competitor` (
  `tournamentCompetitorId` int(11) NOT NULL,
  `tournamentId` int(11) NOT NULL,
  `competitorId` int(11) NOT NULL,
  `isPlayerArrived` tinyint(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `tournament_competitor_player`
--

CREATE TABLE `tournament_competitor_player` (
  `tournamentCompetitorPlayerId` int(11) NOT NULL,
  `tournamentCompetitorId` int(11) NOT NULL,
  `playerId` int(11) NOT NULL,
  `credit` decimal(40,1) NOT NULL DEFAULT 0.0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `tournament_information`
--

CREATE TABLE `tournament_information` (
  `tournamentId` int(11) NOT NULL,
  `tournamentRadarId` int(11) NOT NULL,
  `currentSeasonRadarId` int(11) NOT NULL,
  `tournamentName` varchar(500) NOT NULL,
  `currentSeasonName` varchar(500) NOT NULL,
  `seasonStartDate` date NOT NULL,
  `seasonEndDate` date NOT NULL,
  `tournamentMatchType` int(11) NOT NULL,
  `tournamentCategory` int(11) NOT NULL,
  `tournamentPlayersGender` tinytext DEFAULT NULL,
  `tournamentCountry` varchar(30) DEFAULT NULL,
  `tournamentCountryCode` varchar(20) DEFAULT NULL,
  `isCompetitorsArrived` tinyint(1) NOT NULL DEFAULT 0,
  `isMatchesArrived` tinyint(1) NOT NULL DEFAULT 0,
  `logTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `tournament_matches`
--

CREATE TABLE `tournament_matches` (
  `matchId` int(11) NOT NULL,
  `matchRadarId` int(11) NOT NULL,
  `matchTournamentId` int(11) NOT NULL,
  `matchStartTime` varchar(15) NOT NULL,
  `isPointsCalculated` tinyint(1) NOT NULL DEFAULT 0,
  `competitor1` int(11) NOT NULL,
  `competitor2` int(11) NOT NULL,
  `tossWonBy` int(11) DEFAULT NULL,
  `tossDecision` tinytext DEFAULT NULL,
  `venueId` int(11) DEFAULT NULL,
  `matchStatus` int(11) NOT NULL,
  `isLineUpOut` tinyint(1) NOT NULL DEFAULT 0,
  `logTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Triggers `tournament_matches`
--
DELIMITER $$
CREATE TRIGGER `storeCreditsForPlayers` AFTER INSERT ON `tournament_matches` FOR EACH ROW BEGIN
CALL calculateCreditsForPlayers(NEW.matchId, 1);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `storePointsForTeamsAndCreditsForPlayers` AFTER UPDATE ON `tournament_matches` FOR EACH ROW BEGIN
IF NEW.isPointsCalculated = 1 THEN
CALL storePointsForUserTeams(OLD.matchId);
CALL calculateCreditsForPlayers(OLD.matchId, 0);
END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tournament_type`
--

CREATE TABLE `tournament_type` (
  `tournamentTypeId` int(11) NOT NULL,
  `tournamnetTypeString` varchar(50) NOT NULL,
  `logTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `userBankDetails`
--

CREATE TABLE `userBankDetails` (
  `userId` int(10) NOT NULL,
  `bankName` varchar(300) NOT NULL,
  `AccountNumber` varchar(20) NOT NULL,
  `IFSCCode` varchar(20) NOT NULL,
  `UPIId` varchar(300) DEFAULT NULL,
  `bankProof` longblob NOT NULL,
  `isVerified` tinyint(1) NOT NULL DEFAULT 0,
  `insertedTime` timestamp NOT NULL DEFAULT current_timestamp(),
  `lastUpdatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `userPanDetails`
--

CREATE TABLE `userPanDetails` (
  `userId` int(10) NOT NULL,
  `panCardNumber` varchar(10) NOT NULL,
  `panCardName` varchar(500) NOT NULL,
  `DateOfBirth` date NOT NULL,
  `panCardImage` longblob NOT NULL,
  `isVerified` tinyint(1) NOT NULL DEFAULT 0,
  `insertedTime` timestamp NOT NULL DEFAULT current_timestamp(),
  `lastUpdatedTime` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `userId` int(11) NOT NULL,
  `userType` int(11) NOT NULL DEFAULT 1,
  `phoneNumber` varchar(10) NOT NULL,
  `email` varchar(500) NOT NULL DEFAULT '',
  `coins` int(11) NOT NULL DEFAULT 0,
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
  `isPhoneVerified` tinyint(1) NOT NULL DEFAULT 1,
  `isEmailVerified` tinyint(1) NOT NULL DEFAULT 0,
  `registerTime` timestamp NOT NULL DEFAULT current_timestamp()
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
  `userTeamPoints` float DEFAULT NULL,
  `userTeamViews` int(11) NOT NULL DEFAULT 0,
  `userTeamLikes` int(11) NOT NULL DEFAULT 0,
  `creationTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `user_team_views`
--

CREATE TABLE `user_team_views` (
  `userTeamId` int(11) NOT NULL,
  `userId` int(11) NOT NULL,
  `viewCount` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `user_type`
--

CREATE TABLE `user_type` (
  `userType` int(11) NOT NULL,
  `userTypeString` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `venues`
--

CREATE TABLE `venues` (
  `venueId` int(11) NOT NULL,
  `venueName` varchar(500) DEFAULT NULL,
  `venueCapacity` int(11) DEFAULT NULL,
  `venueCity` tinytext DEFAULT NULL,
  `venueRadarId` int(11) NOT NULL,
  `venueCountry` varchar(50) DEFAULT NULL,
  `venueCountryCode` varchar(20) DEFAULT NULL,
  `venueMapCardinalities` varchar(100) DEFAULT NULL,
  `venueEnd1` varchar(100) DEFAULT NULL,
  `venueEnd2` varchar(100) DEFAULT NULL,
  `logTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `coinSpendSource`
--
ALTER TABLE `coinSpendSource`
  ADD PRIMARY KEY (`sourceId`);

--
-- Indexes for table `cointHistory`
--
ALTER TABLE `cointHistory`
  ADD KEY `userId` (`userId`),
  ADD KEY `transferToWhere` (`spendSource`);

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
-- Indexes for table `playerImages`
--
ALTER TABLE `playerImages`
  ADD PRIMARY KEY (`ucPlayerId`);

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
-- Indexes for table `userBankDetails`
--
ALTER TABLE `userBankDetails`
  ADD PRIMARY KEY (`userId`),
  ADD UNIQUE KEY `AccountNumber` (`AccountNumber`),
  ADD UNIQUE KEY `UPIId` (`UPIId`);

--
-- Indexes for table `userPanDetails`
--
ALTER TABLE `userPanDetails`
  ADD PRIMARY KEY (`userId`),
  ADD UNIQUE KEY `panCardName` (`panCardName`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`userId`,`phoneNumber`),
  ADD UNIQUE KEY `phone_number` (`phoneNumber`),
  ADD KEY `user_type` (`userType`);

--
-- Indexes for table `user_team_data_new`
--
ALTER TABLE `user_team_data_new`
  ADD UNIQUE KEY `userTeamId` (`userTeamId`,`playerId`),
  ADD KEY `user_team_data_new_ibfk_1` (`playerId`);

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
-- AUTO_INCREMENT for table `coinSpendSource`
--
ALTER TABLE `coinSpendSource`
  MODIFY `sourceId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `competitors`
--
ALTER TABLE `competitors`
  MODIFY `competitorId` int(11) NOT NULL AUTO_INCREMENT;

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
  MODIFY `categoryId` int(11) NOT NULL AUTO_INCREMENT;

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
  MODIFY `tournamentId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tournament_matches`
--
ALTER TABLE `tournament_matches`
  MODIFY `matchId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `tournament_type`
--
ALTER TABLE `tournament_type`
  MODIFY `tournamentTypeId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `userId` int(11) NOT NULL AUTO_INCREMENT;

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
-- Constraints for table `cointHistory`
--
ALTER TABLE `cointHistory`
  ADD CONSTRAINT `cointHistory_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`userId`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `cointHistory_ibfk_2` FOREIGN KEY (`spendSource`) REFERENCES `coinSpendSource` (`sourceId`);

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
-- Constraints for table `userBankDetails`
--
ALTER TABLE `userBankDetails`
  ADD CONSTRAINT `userBankDetails_ibfk_1` FOREIGN KEY (`userId`) REFERENCES `users` (`userId`);

--
-- Constraints for table `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `user_type` FOREIGN KEY (`userType`) REFERENCES `user_type` (`userType`) ON UPDATE CASCADE;

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
  ADD CONSTRAINT `relation_userTeamLikes_userTeamTable` FOREIGN KEY (`userTeamId`) REFERENCES `user_team_new` (`userTeamId`),
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
  ADD CONSTRAINT `relation_userTeamViews_userTeamTable` FOREIGN KEY (`userTeamId`) REFERENCES `user_team_new` (`userTeamId`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
