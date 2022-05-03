-- phpMyAdmin SQL Dump
-- version 5.1.3
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: May 03, 2022 at 11:37 AM
-- Server version: 10.4.24-MariaDB
-- PHP Version: 8.1.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

--
-- Database: `dreamg-v3`
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
,`playerRole` int(11)
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
`teamId` int(11)
,`teamRadarId` int(11)
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
,`competitorId` int(11)
,`competitorRadarId` int(11)
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
,`viewCount` int(11)
);

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
,`matchStartDateTime` varchar(15)
,`team1Id` int(11)
,`isPointsCalculated` tinyint(1)
,`team2Id` int(11)
,`tossWonBy` int(11)
,`tossDecision` tinytext
,`venueId` int(11)
,`venue` varchar(500)
,`matchTypeId` int(11)
,`matchTyprString` varchar(50)
,`venueCity` tinytext
,`venueCapacity` int(11)
,`venuesCountry` varchar(50)
,`end2` varchar(100)
,`end1` varchar(100)
,`matchStatus` int(11)
,`matchStatusString` tinytext
,`seriesName` varchar(500)
,`seriesDname` varchar(500)
,`team1Name` varchar(50)
,`team1RadarId` int(11)
,`team1Country` varchar(30)
,`team1CountryCode` varchar(20)
,`team1DisplayName` tinytext
,`team2Name` varchar(50)
,`team2RadarId` int(11)
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
,`points` int(11)
,`name` varchar(401)
,`displayName` varchar(401)
,`roleId` int(11)
,`roleName` varchar(255)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `fullseriesdetails`
-- (See below for the actual view)
--
CREATE TABLE `fullseriesdetails` (
`tournamentId` int(11)
,`tournamentRadarId` int(11)
,`currentSeasonRadarId` int(11)
,`tournamentName` varchar(500)
,`currentSeasonName` varchar(500)
,`seasonStartDate` date
,`seasonEndDate` date
,`tournamentMatchType` int(11)
,`tournamentCategory` int(11)
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
-- Stand-in structure for view `inningBatsmans`
-- (See below for the actual view)
--
CREATE TABLE `inningBatsmans` (
`scorcardInningId` int(11)
,`playerId` int(11)
,`battingOrder` int(11)
,`runs` int(11)
,`strikeRate` float
,`isNotOut` tinyint(1)
,`isDuck` tinyint(1)
,`isRetiredHurt` tinyint(1)
,`ballFaced` int(11)
,`fours` int(11)
,`sixes` int(11)
,`attackIngShot` int(11)
,`semiAttackingShot` int(11)
,`defendingShot` int(11)
,`leaves` int(11)
,`onSideShot` int(11)
,`offSideShot` int(11)
,`squreLegShot` int(11)
,`fineLegShot` int(11)
,`thirdManShot` int(11)
,`coverShot` int(11)
,`pointsShot` int(11)
,`midOnShot` int(11)
,`midOffShot` int(11)
,`midWicketShot` int(11)
,`dismissalOverBallNumber` tinyint(1)
,`dismissalOverNumber` smallint(6)
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
,`runs` int(11)
,`fours` int(11)
,`sixes` int(11)
,`runRate` float
,`ballFaced` int(11)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `inningBowlers`
-- (See below for the actual view)
--
CREATE TABLE `inningBowlers` (
`scorcardInningId` int(11)
,`playerId` int(11)
,`runsConceded` int(11)
,`wickets` int(11)
,`overBowled` int(11)
,`maidensOvers` int(11)
,`dotBalls` int(11)
,`fourConceded` int(11)
,`sixConceded` int(11)
,`noBalls` int(11)
,`wides` int(11)
,`slowerDeliveries` int(11)
,`yorkers` int(11)
,`economyRate` float
,`fastestBall` int(11)
,`slowestBall` int(11)
,`averageSpeed` int(11)
,`overTheWicketBalls` int(11)
,`aroundTheWicketBalls` int(11)
,`bouncers` int(11)
,`beatBats` int(11)
,`edge` int(11)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `inningBowling`
-- (See below for the actual view)
--
CREATE TABLE `inningBowling` (
`scorcardInningId` int(11)
,`overs` float
,`wickets` int(11)
,`maidens` int(11)
,`extras` int(11)
,`noBalls` int(11)
,`byes` int(11)
,`legByes` int(11)
,`dotBalls` int(11)
);

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
-- Stand-in structure for view `userTeamDetails`
-- (See below for the actual view)
--
CREATE TABLE `userTeamDetails` (
`userTeamId` int(11)
,`matchId` int(11)
,`userId` int(11)
,`userTeamType` int(11)
,`teamTypeString` tinytext
,`userTeamPoints` int(11)
,`userTeamViews` int(11)
,`userTeamLikes` int(11)
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
-- Structure for view `allplayers`
--
DROP TABLE IF EXISTS `allplayers`;

CREATE VIEW `allplayers`  AS SELECT `players`.`playerId` AS `playerId`, `players`.`playerRadarId` AS `playerRadarId`, `players`.`playerFirstName` AS `playerFirstName`, `players`.`playerLastName` AS `playerLastName`, `players`.`playerCountryCode` AS `playerCountryCode`, `players`.`playerRole` AS `playerRole`, `player_roles`.`roleString` AS `roleName`, `players`.`playerDOB` AS `playerDOB`, `players`.`playerCountry` AS `playerCountry` FROM (`players` join `player_roles` on(`player_roles`.`roleId` = `players`.`playerRole`))  ;

-- --------------------------------------------------------

--
-- Structure for view `allteams`
--
DROP TABLE IF EXISTS `allteams`;

CREATE VIEW `allteams`  AS SELECT `competitors`.`competitorId` AS `teamId`, `competitors`.`competitorRadarId` AS `teamRadarId`, `competitors`.`competitorName` AS `name`, `competitors`.`competitorCountry` AS `countryName`, `competitors`.`competitorCountryCode` AS `countryCode`, `competitors`.`competitorDisplayName` AS `displayName` FROM `competitors`  ;

-- --------------------------------------------------------

--
-- Structure for view `allteams2`
--
DROP TABLE IF EXISTS `allteams2`;

CREATE VIEW `allteams2`  AS SELECT `tournament_competitor`.`tournamentCompetitorId` AS `tournamentCompetitorId`, `tournament_competitor`.`tournamentId` AS `tournamentId`, `competitors`.`competitorId` AS `competitorId`, `competitors`.`competitorRadarId` AS `competitorRadarId`, `competitors`.`competitorName` AS `competitorName`, `competitors`.`competitorCountry` AS `competitorCountry`, `competitors`.`competitorCountryCode` AS `competitorCountryCode`, `competitors`.`competitorDisplayName` AS `competitorDisplayName`, `tournament_competitor`.`isPlayerArrived` AS `isPlayerArrived` FROM (`competitors` join `tournament_competitor` on(`tournament_competitor`.`competitorId` = `competitors`.`competitorId`))  ;

-- --------------------------------------------------------

--
-- Structure for view `allviews`
--
DROP TABLE IF EXISTS `allviews`;

CREATE VIEW `allviews`  AS SELECT `user_team_views`.`userTeamId` AS `userTeamId`, `user_team_views`.`userId` AS `userId`, `user_team_views`.`viewCount` AS `viewCount` FROM `user_team_views`  ;

-- --------------------------------------------------------

--
-- Structure for view `fulldiscussion`
--
DROP TABLE IF EXISTS `fulldiscussion`;

CREATE VIEW `fulldiscussion`  AS SELECT `discussion`.`discussionId` AS `discussionId`, `discussion`.`matchId` AS `matchId`, `discussion`.`userId` AS `userId`, `discussion`.`messengerId` AS `messengerId`, `discussion`.`message` AS `message`, `discussion`.`messageTime` AS `messageTime` FROM `discussion`  ;

-- --------------------------------------------------------

--
-- Structure for view `fulllikesdetails`
--
DROP TABLE IF EXISTS `fulllikesdetails`;

CREATE VIEW `fulllikesdetails`  AS SELECT `user_team_likes`.`userTeamId` AS `userTeamId`, `user_team_likes`.`userId` AS `userId` FROM `user_team_likes`  ;

-- --------------------------------------------------------

--
-- Structure for view `fullmatchdetails`
--
DROP TABLE IF EXISTS `fullmatchdetails`;

CREATE VIEW `fullmatchdetails`  AS SELECT `tournament_matches`.`matchId` AS `matchId`, `tournament_matches`.`matchRadarId` AS `matchRadarId`, `tournament_matches`.`matchTournamentId` AS `matchTournamentId`, `tournament_matches`.`matchStartTime` AS `matchStartDateTime`, `tournament_matches`.`competitor1` AS `team1Id`, `tournament_matches`.`isPointsCalculated` AS `isPointsCalculated`, `tournament_matches`.`competitor2` AS `team2Id`, `tournament_matches`.`tossWonBy` AS `tossWonBy`, `tournament_matches`.`tossDecision` AS `tossDecision`, `tournament_matches`.`venueId` AS `venueId`, `venues`.`venueName` AS `venue`, `fullseriesdetails`.`tournamentMatchType` AS `matchTypeId`, `fullseriesdetails`.`tournamentTypeString` AS `matchTyprString`, `venues`.`venueCity` AS `venueCity`, `venues`.`venueCapacity` AS `venueCapacity`, `venues`.`venueCountry` AS `venuesCountry`, `venues`.`venueEnd1` AS `end2`, `venues`.`venueEnd2` AS `end1`, `tournament_matches`.`matchStatus` AS `matchStatus`, `match_status`.`statusString` AS `matchStatusString`, `fullseriesdetails`.`tournamentName` AS `seriesName`, `fullseriesdetails`.`currentSeasonName` AS `seriesDname`, `comp1`.`competitorName` AS `team1Name`, `comp1`.`competitorRadarId` AS `team1RadarId`, `comp1`.`competitorCountry` AS `team1Country`, `comp1`.`competitorCountryCode` AS `team1CountryCode`, `comp1`.`competitorDisplayName` AS `team1DisplayName`, `comp2`.`competitorName` AS `team2Name`, `comp2`.`competitorRadarId` AS `team2RadarId`, `comp2`.`competitorCountry` AS `team2Country`, `comp2`.`competitorCountryCode` AS `team2CountryName`, `comp2`.`competitorDisplayName` AS `team2DisplayName`, concat(`comp1`.`competitorDisplayName`,' vs ',`comp2`.`competitorDisplayName`) AS `displayName` FROM (((((`tournament_matches` join `competitors` `comp1` on(`tournament_matches`.`competitor1` = `comp1`.`competitorId`)) join `competitors` `comp2` on(`tournament_matches`.`competitor2` = `comp2`.`competitorId`)) join `fullseriesdetails` on(`fullseriesdetails`.`tournamentId` = `tournament_matches`.`matchTournamentId`)) join `match_status` on(`tournament_matches`.`matchStatus` = `match_status`.`statusId`)) join `venues` on(`tournament_matches`.`venueId` = `venues`.`venueId`))  ;

-- --------------------------------------------------------

--
-- Structure for view `fullnotification`
--
DROP TABLE IF EXISTS `fullnotification`;

CREATE VIEW `fullnotification`  AS SELECT `notifications`.`notificationId` AS `notificationId`, `notifications`.`userId` AS `userId`, `notifications`.`notificationType` AS `notificationType`, `notification_type`.`notificationTypeString` AS `notificationTypeString`, `notifications`.`notificationMessage` AS `notificationMessage`, `notifications`.`creationTime` AS `creationTime`, `notifications`.`isReaded` AS `haveReaded` FROM (`notifications` join `notification_type` on(`notification_type`.`notificationType` = `notifications`.`notificationType`))  ;

-- --------------------------------------------------------

--
-- Structure for view `fullplayerdetails`
--
DROP TABLE IF EXISTS `fullplayerdetails`;

CREATE VIEW `fullplayerdetails`  AS SELECT `tournament_matches`.`matchId` AS `matchId`, `tournament_matches`.`matchRadarId` AS `matchRadarId`, `match_players`.`playerId` AS `playerId`, `match_players`.`competitorId` AS `teamId`, 8 AS `credits`, `match_players`.`isSelected` AS `isSelected`, `match_players`.`points` AS `points`, concat(`allplayers`.`playerFirstName`,' ',`allplayers`.`playerLastName`) AS `name`, concat(`allplayers`.`playerFirstName`,' ',`allplayers`.`playerLastName`) AS `displayName`, `allplayers`.`playerRole` AS `roleId`, ucase(`allplayers`.`roleName`) AS `roleName` FROM ((`tournament_matches` join `match_players` on(`match_players`.`matchId` = `tournament_matches`.`matchId`)) join `allplayers` on(`allplayers`.`playerId` = `match_players`.`playerId`))  ;

-- --------------------------------------------------------

--
-- Structure for view `fullseriesdetails`
--
DROP TABLE IF EXISTS `fullseriesdetails`;

CREATE VIEW `fullseriesdetails`  AS SELECT `tournament_information`.`tournamentId` AS `tournamentId`, `tournament_information`.`tournamentRadarId` AS `tournamentRadarId`, `tournament_information`.`currentSeasonRadarId` AS `currentSeasonRadarId`, `tournament_information`.`tournamentName` AS `tournamentName`, `tournament_information`.`currentSeasonName` AS `currentSeasonName`, `tournament_information`.`seasonStartDate` AS `seasonStartDate`, `tournament_information`.`seasonEndDate` AS `seasonEndDate`, `tournament_information`.`tournamentMatchType` AS `tournamentMatchType`, `tournament_information`.`tournamentCategory` AS `tournamentCategory`, `tournament_information`.`tournamentPlayersGender` AS `tournamentPlayersGender`, `tournament_information`.`tournamentCountry` AS `tournamentCountry`, `tournament_information`.`tournamentCountryCode` AS `tournamentCountryCode`, `tournament_information`.`isCompetitorsArrived` AS `isCompetitorsArrived`, `tournament_information`.`isMatchesArrived` AS `isMatchesArrived`, `tournament_category`.`categoryString` AS `categoryString`, `tournament_type`.`tournamnetTypeString` AS `tournamentTypeString` FROM ((`tournament_information` join `tournament_type` on(`tournament_type`.`tournamentTypeId` = `tournament_information`.`tournamentMatchType`)) join `tournament_category` on(`tournament_category`.`categoryId` = `tournament_information`.`tournamentCategory`))  ;

-- --------------------------------------------------------

--
-- Structure for view `inningBatsmans`
--
DROP TABLE IF EXISTS `inningBatsmans`;

CREATE VIEW `inningBatsmans`  AS SELECT `inning_batsmans`.`scorcardInningId` AS `scorcardInningId`, `inning_batsmans`.`playerId` AS `playerId`, `inning_batsmans`.`battingOrder` AS `battingOrder`, `inning_batsmans`.`runs` AS `runs`, `inning_batsmans`.`strikeRate` AS `strikeRate`, `inning_batsmans`.`isNotOut` AS `isNotOut`, `inning_batsmans`.`isDuck` AS `isDuck`, `inning_batsmans`.`isRetiredHurt` AS `isRetiredHurt`, `inning_batsmans`.`ballFaced` AS `ballFaced`, `inning_batsmans`.`fours` AS `fours`, `inning_batsmans`.`sixes` AS `sixes`, `inning_batsmans`.`attackIngShot` AS `attackIngShot`, `inning_batsmans`.`semiAttackingShot` AS `semiAttackingShot`, `inning_batsmans`.`defendingShot` AS `defendingShot`, `inning_batsmans`.`leaves` AS `leaves`, `inning_batsmans`.`onSideShot` AS `onSideShot`, `inning_batsmans`.`offSideShot` AS `offSideShot`, `inning_batsmans`.`squreLegShot` AS `squreLegShot`, `inning_batsmans`.`fineLegShot` AS `fineLegShot`, `inning_batsmans`.`thirdManShot` AS `thirdManShot`, `inning_batsmans`.`coverShot` AS `coverShot`, `inning_batsmans`.`pointsShot` AS `pointsShot`, `inning_batsmans`.`midOnShot` AS `midOnShot`, `inning_batsmans`.`midOffShot` AS `midOffShot`, `inning_batsmans`.`midWicketShot` AS `midWicketShot`, `inning_batsmans`.`dismissalOverBallNumber` AS `dismissalOverBallNumber`, `inning_batsmans`.`dismissalOverNumber` AS `dismissalOverNumber`, `inning_batsmans`.`dismissalBallerId` AS `dismissalBallerId`, `inning_batsmans`.`dismissalDiliveryType` AS `dismissalDiliveryType`, `inning_batsmans`.`dismissalFieldeManId` AS `dismissalFieldeManId`, `inning_batsmans`.`dismissalIsOnStrike` AS `dismissalIsOnStrike`, `inning_batsmans`.`dismissalShotType` AS `dismissalShotType`, `inning_batsmans`.`dismissalType` AS `dismissalType` FROM `inning_batsmans`  ;

-- --------------------------------------------------------

--
-- Structure for view `inningBatting`
--
DROP TABLE IF EXISTS `inningBatting`;

CREATE VIEW `inningBatting`  AS SELECT `inning_batting`.`scorcardInningId` AS `scorcardInningId`, `inning_batting`.`runs` AS `runs`, `inning_batting`.`fours` AS `fours`, `inning_batting`.`sixes` AS `sixes`, `inning_batting`.`runRate` AS `runRate`, `inning_batting`.`ballFaced` AS `ballFaced` FROM `inning_batting`  ;

-- --------------------------------------------------------

--
-- Structure for view `inningBowlers`
--
DROP TABLE IF EXISTS `inningBowlers`;

CREATE VIEW `inningBowlers`  AS SELECT `inning_bowlers`.`scorcardInningId` AS `scorcardInningId`, `inning_bowlers`.`playerId` AS `playerId`, `inning_bowlers`.`runsConceded` AS `runsConceded`, `inning_bowlers`.`wickets` AS `wickets`, `inning_bowlers`.`overBowled` AS `overBowled`, `inning_bowlers`.`maidensOvers` AS `maidensOvers`, `inning_bowlers`.`dotBalls` AS `dotBalls`, `inning_bowlers`.`fourConceded` AS `fourConceded`, `inning_bowlers`.`sixConceded` AS `sixConceded`, `inning_bowlers`.`noBalls` AS `noBalls`, `inning_bowlers`.`wides` AS `wides`, `inning_bowlers`.`slowerDeliveries` AS `slowerDeliveries`, `inning_bowlers`.`yorkers` AS `yorkers`, `inning_bowlers`.`economyRate` AS `economyRate`, `inning_bowlers`.`fastestBall` AS `fastestBall`, `inning_bowlers`.`slowestBall` AS `slowestBall`, `inning_bowlers`.`averageSpeed` AS `averageSpeed`, `inning_bowlers`.`overTheWicketBalls` AS `overTheWicketBalls`, `inning_bowlers`.`aroundTheWicketBalls` AS `aroundTheWicketBalls`, `inning_bowlers`.`bouncers` AS `bouncers`, `inning_bowlers`.`beatBats` AS `beatBats`, `inning_bowlers`.`edge` AS `edge` FROM `inning_bowlers`  ;

-- --------------------------------------------------------

--
-- Structure for view `inningBowling`
--
DROP TABLE IF EXISTS `inningBowling`;

CREATE VIEW `inningBowling`  AS SELECT `inning_bowling`.`scorcardInningId` AS `scorcardInningId`, `inning_bowling`.`overs` AS `overs`, `inning_bowling`.`wickets` AS `wickets`, `inning_bowling`.`maidens` AS `maidens`, `inning_bowling`.`extras` AS `extras`, `inning_bowling`.`noBalls` AS `noBalls`, `inning_bowling`.`byes` AS `byes`, `inning_bowling`.`legByes` AS `legByes`, `inning_bowling`.`dotBalls` AS `dotBalls` FROM `inning_bowling`  ;

-- --------------------------------------------------------

--
-- Structure for view `scorcardDetails`
--
DROP TABLE IF EXISTS `scorcardDetails`;

CREATE VIEW `scorcardDetails`  AS SELECT `scorcard_details`.`scorcardId` AS `scorcardId`, `scorcard_details`.`matchId` AS `matchId`, `scorcard_details`.`tossWonBy` AS `tossWonBy`, `scorcard_details`.`tossDecision` AS `tossDecision`, `scorcard_details`.`winnerId` AS `winnerId`, `scorcard_details`.`manOfMatch` AS `manOfMatch`, `scorcard_details`.`isPointsCalculated` AS `isPointsCalculated`, `scorcard_details`.`matchResultString` AS `matchResultString` FROM `scorcard_details`  ;

-- --------------------------------------------------------

--
-- Structure for view `scorcardInning`
--
DROP TABLE IF EXISTS `scorcardInning`;

CREATE VIEW `scorcardInning`  AS SELECT `scorcard_innings`.`scorcardInningId` AS `scorcardInningId`, `scorcard_innings`.`scorcardId` AS `scorcardId`, `scorcard_innings`.`inningNumber` AS `inningNumber`, `scorcard_innings`.`battingTeam` AS `battingTeam`, `scorcard_innings`.`bowlingTeam` AS `bowlingTeam`, `scorcard_innings`.`runs` AS `runs`, `scorcard_innings`.`wickets` AS `wickets`, `scorcard_innings`.`oversPlayed` AS `oversPlayed` FROM `scorcard_innings`  ;

-- --------------------------------------------------------

--
-- Structure for view `userdetails`
--
DROP TABLE IF EXISTS `userdetails`;

CREATE VIEW `userdetails`  AS SELECT `users`.`userId` AS `userId`, `users`.`userType` AS `userType`, `user_type`.`userTypeString` AS `userTypeString`, `users`.`phoneNumber` AS `phoneNumber`, `users`.`email` AS `email`, `users`.`dateOfBirth` AS `dateOfBirth`, `users`.`gender` AS `gender`, `users`.`firstName` AS `firstName`, `users`.`lastName` AS `lastName`, `users`.`address` AS `address`, `users`.`city` AS `city`, `users`.`pinCode` AS `pinCode`, `users`.`state` AS `state`, `users`.`country` AS `country`, `users`.`isVerified` AS `isVerified`, `users`.`imageStamp` AS `imageStamp`, `users`.`registerTime` AS `registerTime` FROM (`users` join `user_type` on(`user_type`.`userType` = `users`.`userType`))  ;

-- --------------------------------------------------------

--
-- Structure for view `userTeamDetails`
--
DROP TABLE IF EXISTS `userTeamDetails`;

CREATE VIEW `userTeamDetails`  AS SELECT `user_team_new`.`userTeamId` AS `userTeamId`, `user_team_new`.`matchId` AS `matchId`, `user_team_new`.`userId` AS `userId`, `user_team_new`.`userTeamType` AS `userTeamType`, `team_type`.`teamTypeString` AS `teamTypeString`, `user_team_new`.`userTeamPoints` AS `userTeamPoints`, `user_team_new`.`userTeamViews` AS `userTeamViews`, `user_team_new`.`userTeamLikes` AS `userTeamLikes`, `user_team_new`.`creationTime` AS `creationTime` FROM (`user_team_new` join `team_type` on(`team_type`.`teamType` = `user_team_new`.`userTeamType`))  ;

-- --------------------------------------------------------

--
-- Structure for view `userTeamPlayersDetails`
--
DROP TABLE IF EXISTS `userTeamPlayersDetails`;

CREATE VIEW `userTeamPlayersDetails`  AS SELECT `user_team_data_new`.`userTeamId` AS `userTeamId`, `user_team_data_new`.`playerId` AS `playerId`, `user_team_data_new`.`isCaptain` AS `isCaptain`, `user_team_data_new`.`isViceCaptain` AS `isViceCaptain` FROM `user_team_data_new` ;
COMMIT;
