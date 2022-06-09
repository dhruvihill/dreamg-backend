-- phpMyAdmin SQL Dump
-- version 5.1.3
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: May 13, 2022 at 09:04 AM
-- Server version: 10.4.24-MariaDB
-- PHP Version: 8.1.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

--
-- Database: `dreamg-v3`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `calculateCreditsForPlayers` (IN `matchId` INT, IN `creditForThisMatch` BOOLEAN)   BEGIN
DECLARE playerCredit DECIMAL(20, 1) DEFAULT 7.5;
DECLARE playerAVGPoints FLOAT DEFAULT 0;
DECLARE playerMatches INT DEFAULT 0;
DECLARE currentPlayerId INT DEFAULT 0;
DECLARE finished BOOLEAN DEFAULT 0;
DECLARE playerNextMatch INT DEFAULT NULL;

DEClARE matchPlayers CURSOR FOR SELECT fullplayerdetails.playerId FROM fullplayerdetails WHERE fullplayerdetails.matchId = matchId;

DECLARE CONTINUE HANDLER FOR NOT FOUND
BEGIN
SET finished = 1;
END;

OPEN matchPlayers;

nextPlayer: LOOP FETCH matchPlayers INTO currentPlayerId;
IF finished = 1 THEN 
	LEAVE nextPlayer;
END IF;

/* process start for credit */

IF creditForThisMatch != 1 THEN

SELECT IF(playerMatches.playedMatches >= 5, playerMatches.points, 0) INTO playerAVGPoints FROM (SELECT AVG(fullplayerdetails.points) AS points, COUNT(*) AS playedMatches FROM fullplayerdetails JOIN fullmatchdetails ON fullmatchdetails.matchId = fullplayerdetails.matchId WHERE fullplayerdetails.playerId = currentPlayerId AND (fullmatchdetails.matchStartDateTime < (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = matchId) OR fullmatchdetails.matchId = matchId) AND fullmatchdetails.matchStatusString IN ('ended', 'closed') AND fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = matchId) AND fullplayerdetails.isSelected = 1 ORDER BY fullmatchdetails.matchStartDateTime DESC LIMIT 5) AS playerMatches;

ELSE 
SELECT IF(playerMatches.playedMatches >= 5, playerMatches.points, 0) INTO playerAVGPoints FROM (SELECT AVG(fullplayerdetails.points) AS points, COUNT(*) AS playedMatches FROM fullplayerdetails JOIN fullmatchdetails ON fullmatchdetails.matchId = fullplayerdetails.matchId WHERE fullplayerdetails.playerId = currentPlayerId AND fullmatchdetails.matchStartDateTime < (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = matchId) AND fullmatchdetails.matchStatusString IN ('ended', 'closed') AND fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = matchId) AND fullplayerdetails.isSelected = 1 ORDER BY fullmatchdetails.matchStartDateTime DESC LIMIT 5) AS playerMatches;
END IF;

/* fetching */
IF playerAVGPoints > 100 THEN
	SET playerCredit = 10.5;
ELSEIF playerAVGPoints <= 100 AND playerAVGPoints > 85 THEN
	SET playerCredit = 10;
ELSEIF playerAVGPoints <= 85 AND playerAVGPoints > 75 THEN
	SET playerCredit = 9.5;
ELSEIF playerAVGPoints <= 75 AND playerAVGPoints > 65 THEN
	SET playerCredit = 9;
ELSEIF playerAVGPoints <= 65 AND playerAVGPoints > 50 THEN
	SET playerCredit = 8.5;
ELSEIF playerAVGPoints <= 50 AND playerAVGPoints > 30 THEN
	SET playerCredit = 8;
ELSEIF playerAVGPoints <= 30 THEN
	SET playerCredit = 7.5;
ELSE 
	SET playerCredit = 7;
END IF;
IF creditForThisMatch = 1 THEN 
	UPDATE match_players SET match_players.credit = playerCredit WHERE match_players.playerId = currentPlayerId AND match_players.matchId = matchId;

ELSE
	SELECT fullmatchdetails.matchId INTO playerNextMatch FROM fullplayerdetails JOIN fullmatchdetails ON fullmatchdetails.matchId = fullplayerdetails.matchId WHERE fullplayerdetails.playerId = currentPlayerId AND fullmatchdetails.matchStartDateTime > (SELECT fullmatchdetails.matchStartDateTime FROM fullmatchdetails WHERE fullmatchdetails.matchId = matchId) AND fullmatchdetails.matchStatusString IN ('not_started') AND fullmatchdetails.matchTypeId IN (SELECT fullmatchdetails.matchTypeId FROM fullmatchdetails WHERE fullmatchdetails.matchId = matchId) ORDER BY fullmatchdetails.matchStartDateTime DESC LIMIT 1;
IF playerNextMatch THEN
UPDATE match_players SET match_players.credit = playerCredit WHERE match_players.playerId = currentPlayerId AND match_players.matchId = playerNextMatch;
END IF;
END IF;
/* process end for credit */

END LOOP nextPlayer;
CLOSE matchPlayers;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getPlayers` (IN `matchId` INT, IN `userTeamId` INT)   BEGIN DECLARE teamCreatedBy INT(7) DEFAULT 0;
/* validating match */
IF EXISTS(
  SELECT 
    fullmatchdetails.matchId 
  FROM 
    fullmatchdetails 
  WHERE 
    fullmatchdetails.matchId = matchId
) THEN 
SELECT 
  COUNT(userTeamDetails.userTeamId) INTO teamCreatedBy 
FROM 
  userTeamDetails 
WHERE 
  userTeamDetails.matchId = matchId;
IF userTeamId != 0 THEN IF EXISTS(
  SELECT 
    userTeamDetails.userTeamId 
  FROM 
    userTeamDetails 
  WHERE 
    userTeamDetails.userTeamId = userTeamId 
    AND userTeamDetails.matchId = matchId
) THEN 
SELECT 
	EXISTS(SELECT * FROM fullplayerdetails AS innerFullPlayerDetails WHERE innerFullPlayerDetails.playerId = fullplayerdetails.playerId AND innerFullPlayerDetails.matchId = fullplayerdetails.matchId AND innerFullPlayerDetails.isSelected = 1) AS isLineUpSelected,
COALESCE((SELECT innerPlayerDetails.isSelected FROM fullmatchdetails AS innerFullmatch JOIN fullplayerdetails AS innerPlayerDetails ON innerPlayerDetails.playerId = fullplayerdetails.playerId AND innerPlayerDetails.matchId = innerFullmatch.matchId WHERE innerFullmatch.matchTournamentId IN (fullmatchdetails.matchTournamentId) AND innerFullmatch.matchId != fullmatchdetails.matchId AND (innerFullmatch.team1Id IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id) OR innerFullmatch.team2Id IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id)) AND innerFullmatch.matchStatusString IN ('ended', 'closed') AND innerFullmatch.matchStartDateTime < fullmatchdetails.matchStartDateTime ORDER BY innerFullmatch.matchStartDateTime DESC LIMIT 1), 0) AS isLastMatchPlayed,
  EXISTS(
    SELECT 
      userTeamPlayersDetails.playerId 
    FROM 
      userTeamDetails 
      JOIN userTeamPlayersDetails ON userTeamPlayersDetails.userTeamId = userTeamDetails.userTeamId 
    WHERE 
      userTeamDetails.userTeamId = userTeamId 
      AND userTeamPlayersDetails.playerId = fullplayerdetails.playerId
  ) AS isSelected, 
  EXISTS(
    SELECT 
      userTeamPlayersDetails.playerId 
    FROM 
      userTeamDetails 
      JOIN userTeamPlayersDetails ON userTeamPlayersDetails.userTeamId = userTeamDetails.userTeamId 
    WHERE 
      userTeamDetails.userTeamId = userTeamId 
      AND userTeamPlayersDetails.playerId = fullplayerdetails.playerId 
      AND userTeamPlayersDetails.isCaptain = 1
  ) AS isCaptain, 
  EXISTS(
    SELECT 
      userTeamPlayersDetails.playerId 
    FROM 
      userTeamDetails 
      JOIN userTeamPlayersDetails ON userTeamPlayersDetails.userTeamId = userTeamDetails.userTeamId 
    WHERE 
      userTeamDetails.userTeamId = userTeamId 
      AND userTeamPlayersDetails.playerId = fullplayerdetails.playerId 
      AND userTeamPlayersDetails.isViceCaptain = 1
  ) AS isViceCaptain, 
  COALESCE(
    (
      (
        SELECT 
          COUNT(
            userTeamPlayersDetails.playerId
          ) 
        FROM 
          userTeamDetails 
          JOIN userTeamPlayersDetails ON userTeamPlayersDetails.userTeamId = userTeamDetails.userTeamId 
        WHERE 
          userTeamDetails.matchId = matchId 
          AND userTeamPlayersDetails.playerId = fullplayerdetails.playerId
      ) / teamCreatedBy
    ) * 100, 
    0
  ) AS selectedBy, 
  COALESCE(
    (
      (
        SELECT 
          COUNT(
            userTeamPlayersDetails.playerId
          ) 
        FROM 
          userTeamDetails 
          JOIN userTeamPlayersDetails ON userTeamPlayersDetails.userTeamId = userTeamDetails.userTeamId 
        WHERE 
          userTeamDetails.matchId = matchId 
          AND userTeamPlayersDetails.playerId = fullplayerdetails.playerId 
          AND userTeamPlayersDetails.isCaptain = 1
      ) / teamCreatedBy
    ) * 100, 
    0
  ) AS captainBy, 
  COALESCE(
    (
      (
        SELECT 
          COUNT(
            userTeamPlayersDetails.playerId
          ) 
        FROM 
          userTeamDetails 
          JOIN userTeamPlayersDetails ON userTeamPlayersDetails.userTeamId = userTeamDetails.userTeamId 
        WHERE 
          userTeamDetails.matchId = matchId 
          AND userTeamPlayersDetails.playerId = fullplayerdetails.playerId 
          AND userTeamPlayersDetails.isViceCaptain = 1
      ) / teamCreatedBy
    ) * 100, 
    0
  ) AS viceCaptainBy, 
  fullplayerdetails.matchId, 
  fullplayerdetails.playerId, 
  fullplayerdetails.teamId, 
  fullplayerdetails.credits, 
  COALESCE(
    (
      SELECT 
        SUM(innerFullPlayerDetails.points) 
      FROM 
        fullplayerdetails AS innerFullPlayerDetails 
      WHERE 
        innerFullPlayerDetails.matchId IN(
          SELECT 
            innerFullMatchDetails.matchId 
          FROM 
            fullmatchdetails AS innerFullMatchDetails 
          WHERE            innerFullMatchDetails.matchTournamentId = fullmatchdetails.matchTournamentId AND innerFullMatchDetails.matchStartDateTime < fullmatchdetails.matchStartDateTime
        ) 
        AND innerFullPlayerDetails.playerId = fullplayerdetails.playerId
    ), 
    0
  ) AS points, 
  fullplayerdetails.name AS playerName, 
  fullplayerdetails.displayName AS playerDisplayName, 
  fullplayerdetails.roleId, 
  fullplayerdetails.roleName, 
  allteams.name AS teamName, 
  allteams.countryName, 
  allteams.countryCode, 
  allteams.displayName AS teamDisplayName 
FROM 
  fullplayerdetails 
  JOIN fullmatchdetails ON fullmatchdetails.matchId = fullplayerdetails.matchId 
  JOIN allteams ON allteams.teamId = fullplayerdetails.teamId 
WHERE 
  fullplayerdetails.matchId = matchId;
SELECT * FROM fullmatchdetails WHERE fullmatchdetails.matchId = matchId;
ELSE SIGNAL SQLSTATE '45000' 
SET 
  MESSAGE_TEXT = 'invalid userTeamId';
END IF;
ELSE 
SELECT 
EXISTS(SELECT * FROM fullplayerdetails AS innerFullPlayerDetails WHERE innerFullPlayerDetails.playerId = fullplayerdetails.playerId AND innerFullPlayerDetails.matchId = fullplayerdetails.matchId AND innerFullPlayerDetails.isSelected = 1) AS isLineUpSelected,
COALESCE((SELECT innerPlayerDetails.isSelected FROM fullmatchdetails AS innerFullmatch JOIN fullplayerdetails AS innerPlayerDetails ON innerPlayerDetails.playerId = fullplayerdetails.playerId AND innerPlayerDetails.matchId = innerFullmatch.matchId WHERE innerFullmatch.matchTournamentId IN (fullmatchdetails.matchTournamentId) AND innerFullmatch.matchId != fullmatchdetails.matchId AND (innerFullmatch.team1Id IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id) OR innerFullmatch.team2Id IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id)) AND innerFullmatch.matchStatusString IN ('ended', 'closed') AND innerFullmatch.matchStartDateTime < fullmatchdetails.matchStartDateTime ORDER BY innerFullmatch.matchStartDateTime DESC LIMIT 1), 0) AS isLastMatchPlayed,
  COALESCE(
    (
      (
        SELECT 
          COUNT(
            userTeamPlayersDetails.playerId
          ) 
        FROM 
          userTeamDetails 
          JOIN userTeamPlayersDetails ON userTeamPlayersDetails.userTeamId = userTeamDetails.userTeamId 
        WHERE 
          userTeamDetails.matchId = matchId 
          AND userTeamPlayersDetails.playerId = fullplayerdetails.playerId
      ) / teamCreatedBy
    ) * 100, 
    0
  ) AS selectedBy, 
  COALESCE(
    (
      (
        SELECT 
          COUNT(
            userTeamPlayersDetails.playerId
          ) 
        FROM 
          userTeamDetails 
          JOIN userTeamPlayersDetails ON userTeamPlayersDetails.userTeamId = userTeamDetails.userTeamId 
        WHERE 
          userTeamDetails.matchId = matchId 
          AND userTeamPlayersDetails.playerId = fullplayerdetails.playerId 
          AND userTeamPlayersDetails.isCaptain = 1
      ) / teamCreatedBy
    ) * 100, 
    0
  ) AS captainBy, 
  COALESCE(
    (
      (
        SELECT 
          COUNT(
            userTeamPlayersDetails.playerId
          ) 
        FROM 
          userTeamDetails 
          JOIN userTeamPlayersDetails ON userTeamPlayersDetails.userTeamId = userTeamDetails.userTeamId 
        WHERE 
          userTeamDetails.matchId = matchId 
          AND userTeamPlayersDetails.playerId = fullplayerdetails.playerId 
          AND userTeamPlayersDetails.isViceCaptain = 1
      ) / teamCreatedBy
    ) * 100, 
    0
  ) AS viceCaptainBy, 
  fullplayerdetails.matchId, 
  fullplayerdetails.playerId, 
  fullplayerdetails.teamId, 
  fullplayerdetails.credits, 
  COALESCE(
    (
      SELECT 
        SUM(innerFullPlayerDetails.points) 
      FROM 
        fullplayerdetails AS innerFullPlayerDetails 
      WHERE 
        innerFullPlayerDetails.matchId IN(
          SELECT 
            innerFullMatchDetails.matchId 
          FROM 
            fullmatchdetails AS innerFullMatchDetails 
          WHERE 
innerFullMatchDetails.matchTournamentId = fullmatchdetails.matchTournamentId  AND innerFullMatchDetails.matchStartDateTime < fullmatchdetails.matchStartDateTime
        ) 
        AND innerFullPlayerDetails.playerId = fullplayerdetails.playerId
    ), 
    0
  ) AS points, 
  fullplayerdetails.name AS playerName, 
  fullplayerdetails.displayName AS playerDisplayName, 
  fullplayerdetails.roleId, 
  fullplayerdetails.roleName, 
  allteams.name AS teamName, 
  allteams.countryName, 
  allteams.countryCode, 
  allteams.displayName AS teamDisplayName 
FROM 
  fullplayerdetails 
  JOIN fullmatchdetails ON fullmatchdetails.matchId = fullplayerdetails.matchId 
  JOIN allteams ON allteams.teamId = fullplayerdetails.teamId 
WHERE 
  fullplayerdetails.matchId = matchId;
END IF;
SELECT * FROM fullmatchdetails WHERE fullmatchdetails.matchId = matchId;
ELSE SIGNAL SQLSTATE '45000' 
SET 
  MESSAGE_TEXT = 'invalid matchId';
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `getUserTeam` (IN `matchId` INT, IN `userId` INT)   BEGIN
    IF EXISTS
        (
        SELECT
            userdetails.userId
        FROM
            userdetails
        WHERE
            userdetails.userId = userId
    ) = 1 THEN
    /* fetching userDetails */
SELECT
    userdetails.userId AS userId,
    userdetails.imageStamp AS imageStamp,
    `firstName`,
    `lastName`
FROM
    userdetails
WHERE
    userdetails.userId = userId;
    /* checking matchId */
    IF EXISTS(
    SELECT
        fullmatchdetails.matchId
    FROM
        fullmatchdetails
    WHERE
        fullmatchdetails.matchId = matchId
) THEN
/* getting competitors details */
SELECT
    allteams.teamId,
    allteams.name,
    allteams.countryName,
    allteams.countryCode,
    allteams.displayName
FROM
    fullmatchdetails
JOIN allteams ON allteams.teamId IN(team1Id, team2Id)
WHERE
    fullmatchdetails.matchId = matchId;
    /* getting players */
SELECT
    userTeamDetails.userTeamId,
    userTeamPlayersDetails.playerId,
    userTeamPlayersDetails.isCaptain,
    userTeamPlayersDetails.isViceCaptain,
    COALESCE(fullplayerdetails.credits, 0) AS credits,
    COALESCE(fullplayerdetails.points, 0) AS points,
    fullplayerdetails.name AS playerName,
    fullplayerdetails.displayName AS playerDisplayName,
    fullplayerdetails.roleId,
    fullplayerdetails.teamId,
    fullplayerdetails.roleName
FROM
    userTeamDetails
JOIN userTeamPlayersDetails ON userTeamDetails.userTeamId = userTeamPlayersDetails.userTeamId
JOIN fullplayerdetails ON fullplayerdetails.playerId = userTeamPlayersDetails.playerId AND fullplayerdetails.matchId = userTeamDetails.matchId
WHERE
    userTeamDetails.matchId = matchId AND userTeamDetails.userId = userId;
    /* fetting team details */
SELECT
    userTeamDetails.userTeamId,
    userTeamDetails.userTeamType,
    userTeamDetails.teamTypeString,
    COALESCE(userTeamDetails.userTeamPoints, 0) AS points,
userTeamDetails.userTeamViews AS 'views',
userTeamDetails.userTeamLikes AS likes,
(
    SELECT
        SUM(fullplayerdetails.credits)
    FROM
        userTeamPlayersDetails
    JOIN fullplayerdetails ON fullplayerdetails.playerId = userTeamPlayersDetails.playerId AND fullplayerdetails.matchId = matchId
    WHERE
        userTeamPlayersDetails.userTeamId = userTeamDetails.userTeamId
) AS creditUsed,
(
    SELECT
        COUNT(allplayers.playerId)
    FROM
        userTeamPlayersDetails
    JOIN allplayers ON allplayers.playerId = userTeamPlayersDetails.playerId
    WHERE
        userTeamPlayersDetails.userTeamId = userTeamDetails.userTeamId AND allplayers.roleName = "BATSMAN"
) AS totalBatsman,
(
    SELECT
        COUNT(allplayers.playerId)
    FROM
        userTeamPlayersDetails
    JOIN allplayers ON allplayers.playerId = userTeamPlayersDetails.playerId
    WHERE
        userTeamPlayersDetails.userTeamId = userTeamDetails.userTeamId AND allplayers.roleName = "BOWLER"
) AS totalBowler,
(
    SELECT
        COUNT(allplayers.playerId)
    FROM
        userTeamPlayersDetails
    JOIN allplayers ON allplayers.playerId = userTeamPlayersDetails.playerId
    WHERE
        userTeamPlayersDetails.userTeamId = userTeamDetails.userTeamId AND allplayers.roleName = "WICKET_KEEPER"
) AS totalWicketKeeper,
(
    SELECT
        COUNT(allplayers.playerId)
    FROM
        userTeamPlayersDetails
    JOIN allplayers ON allplayers.playerId = userTeamPlayersDetails.playerId
    WHERE
        userTeamPlayersDetails.userTeamId = userTeamDetails.userTeamId AND allplayers.roleName = "ALL_ROUNDER"
) AS totalAllrounders
FROM
    userTeamDetails
WHERE
    userTeamDetails.userId = userId AND userTeamDetails.matchId = matchId; ELSE SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT
    = 'invalid matchId';
END IF; ELSE SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT
    = 'invalid userId';
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `get_notifications` (IN `userId` INT(10))   BEGIN

/* checking user in notificatio history */
IF EXISTS(SELECT userId FROM userdetails WHERE userdetails.userId = userId) = 1 THEN

/* selecting notifications */
SELECT `notificationId`, `notificationType`, `notificationTypeString`, `notificationMessage`, `creationTime`, `haveReaded` FROM `fullnotification` WHERE fullnotification.userId = userId AND haveReaded = 0 ORDER BY creationTime DESC;

END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `registerUser` (IN `phoneNumber` VARCHAR(11))   BEGIN

/* error handling for duplicate entry */
DECLARE EXIT HANDLER FOR 1062
BEGIN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Duplicate entry';
END;

START TRANSACTION;

SAVEPOINT beforeRegister;

INSERT INTO users (`phoneNumber`) VALUES (phoneNumber);
SELECT LAST_INSERT_ID() AS userId;
COMMIT;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `setUserTeam` (IN `matchId` INT, IN `userId` INT, IN `userTeamId` INT, IN `userTeamType` INT, IN `captain` INT, IN `viceCaptain` INT, IN `player3` INT, IN `player4` INT, IN `player5` INT, IN `player6` INT, IN `player7` INT, IN `player8` INT, IN `player9` INT, IN `player10` INT, IN `player11` INT)   BEGIN
DECLARE validPlayers INT DEFAULT 0;
DECLARE validUser INT DEFAULT 0;
DECLARE validMatch INT DEFAULT 0;
DECLARE lastInsertId INT DEFAULT 0;

/* error handling for duplicate entry */
DECLARE EXIT HANDLER FOR 1062
BEGIN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Duplicate entry';
END;

DECLARE EXIT HANDLER FOR SQLEXCEPTION
BEGIN
ROLLBACK TO SAVEPOINT beforeInsertOrUpdate;
RESIGNAL;
END;

/* error handling for foriegn key */
DECLARE EXIT HANDLER FOR 1452
BEGIN
IF lastInsertId != 0 THEN
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'invalid input';
END IF;
END;

START TRANSACTION;
SAVEPOINT beforeInsertOrUpdate;

/* checking matchId */
SELECT EXISTS(SELECT * FROM (SELECT fullmatchdetails.matchId, EXISTS(SELECT * FROM fullmatchdetails AS innerFullMatch WHERE (innerFullMatch.team1Id IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id) OR innerFullMatch.team2Id IN (fullmatchdetails.team1Id, fullmatchdetails.team2Id)) AND innerFullMatch.matchStartDateTime < fullmatchdetails.matchStartDateTime AND innerFullMatch.matchTournamentId IN (fullmatchdetails.matchTournamentId) AND innerFullMatch.matchStatusString NOT IN ('ended', 'closed')) AS isDisabled FROM fullmatchdetails WHERE fullmatchdetails.matchId = matchId AND (fullmatchdetails.matchStatusString IN ('not_started') AND fullmatchdetails.matchStartDateTime > (UNIX_TIMESTAMP(NOW()) * 1000))) AS e WHERE e.isDisabled != 1) INTO validMatch;
/* checking userId */
SELECT EXISTS(SELECT userdetails.userId FROM userdetails WHERE userdetails.userId = userId) INTO validUser;

/* validation user */
IF validUser = 1 THEN

/* validation match */
IF validMatch = 1 THEN

/* inserting value into validPlayers */
SELECT COUNT(fullplayerdetails.playerId) INTO validPlayers FROM fullplayerdetails WHERE fullplayerdetails.playerId IN (captain, viceCaptain, player3, player4, player5, player6, player7, player8, player9, player10, player11) AND fullplayerdetails.matchId = matchId;

/* validation players */
IF validPlayers = 11 THEN

IF userTeamId != 0
THEN

DELETE FROM user_team_data_new WHERE user_team_data_new.userTeamId = userTeamId;
/* start insert */
INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId, user_team_data_new.isCaptain) VALUES (userTeamId, captain, 1);

INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId, user_team_data_new.isViceCaptain) VALUES (userTeamId, viceCaptain, 1);

INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId) VALUES (userTeamId, player3);

INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId) VALUES (userTeamId, player4);

INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId) VALUES (userTeamId, player5);

INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId) VALUES (userTeamId, player6);

INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId) VALUES (userTeamId, player7);

INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId) VALUES (userTeamId, player8);

INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId) VALUES (userTeamId, player9);

INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId) VALUES (userTeamId, player10);
                        
INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId) VALUES (userTeamId, player11);

SELECT "success" AS message;
COMMIT;
/* end insert */
ELSE
INSERT INTO user_team_new (user_team_new.matchId, user_team_new.userId, user_team_new.userTeamType) VALUES (matchId, userId, userTeamType);
SELECT LAST_INSERT_ID() INTO lastInsertId;
/* start insert */
INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId, user_team_data_new.isCaptain) VALUES (lastInsertId, captain, 1);

INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId, user_team_data_new.isViceCaptain) VALUES (lastInsertId, viceCaptain, 1);

INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId) VALUES (lastInsertId, player3);

INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId) VALUES (lastInsertId, player4);

INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId) VALUES (lastInsertId, player5);

INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId) VALUES (lastInsertId, player6);

INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId) VALUES (lastInsertId, player7);

INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId) VALUES (lastInsertId, player8);

INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId) VALUES (lastInsertId, player9);

INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId) VALUES (lastInsertId, player10);
                        
INSERT INTO user_team_data_new (user_team_data_new.userTeamId, user_team_data_new.playerId) VALUES (lastInsertId, player11);
SELECT "success" AS message;
COMMIT;
/* end insert */
END IF;

/* generation error for players */
ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'invalid input players';
END IF;

/* throwing error for match */
ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'invalid input match';
END If;

/* throwing error for user */
ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'invalid input user';
END If;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `set_discussion` (IN `matchId` VARCHAR(10), IN `messengerId` VARCHAR(10), IN `createrId` VARCHAR(10), IN `message` VARCHAR(5000))   BEGIN

START TRANSACTION;

/* checking match */
IF EXISTS(SELECT fullmatchdetails.matchId FROM fullmatchdetails WHERE fullmatchdetails.matchId = matchId) THEN

/* checking creater */
IF EXISTS(SELECT userdetails.userId FROM userdetails WHERE userdetails.userId = createrId) THEN

/* checking messenger */
IF EXISTS(SELECT userdetails.userId FROM userdetails WHERE userdetails.userId = messengerId) THEN

/* inserting into discussion */
INSERT INTO `discussion`(`matchId`, `userId`, `messengerId`, `message`) VALUES (matchId, createrId, messengerId, message);

/* selection inserted object */
SELECT messengerId, firstName, message, userdetails.imageStamp AS imageStamp, messageTime FROM fulldiscussion JOIN userdetails ON userdetails.userId = fulldiscussion.messengerId WHERE fulldiscussion.discussionId = LAST_INSERT_ID();
COMMIT;

/* generation error for messenger */
ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "invalid input";
END IF;

/* generation error for creater */
ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "invalid input";
END IF;

/* generation error for match */
ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "invalid input";
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `set_isreaded` (IN `userId` INT(9), IN `notificationId` INT(9))   BEGIN
START TRANSACTION;
IF (SELECT notifications.userId = userId FROM notifications WHERE notifications.notificationId = notificationId)
THEN
UPDATE notifications SET isReaded = 1 WHERE notifications.notificationId = notificationId;
COMMIT;
ELSE 
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "invalid input";
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `set_mark_as_read_all` (IN `userId` INT(9))   BEGIN
START TRANSACTION;
IF EXISTS(SELECT all_users.userId FROM all_users WHERE all_users.userId = userId)
THEN
UPDATE notifications SET isReaded = 1 WHERE notifications.userId = userId;
COMMIT;
ELSE
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "invalid input";
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `storePointsForUserTeams` (IN `matchId` INT)   BEGIN

DECLARE captainPoints FLOAT DEFAULT 0;
DECLARE viceCaptainPoints FLOAT DEFAULT 0;
DECLARE playerPoints FLOAT DEFAULT 0;
DECLARE finished INTEGER DEFAULT 0;
DECLARE userTeamId varchar(100) DEFAULT "";
DEClARE cursorUserTeam CURSOR FOR SELECT userTeamDetails.userTeamId FROM userTeamDetails JOIN fullmatchdetails ON fullmatchdetails.matchId = userTeamDetails.matchId WHERE userTeamDetails.matchId = matchId AND fullmatchdetails.isPointsCalculated = 1;

DECLARE EXIT HANDLER FOR NOT FOUND
BEGIN
SET finished = 1;
END;

OPEN cursorUserTeam;

getNextTeam: LOOP FETCH cursorUserTeam INTO userTeamId;
IF finished = 1 THEN 
	LEAVE getNextTeam;
END IF;

/* start process */
SET playerPoints = 0;
SELECT COALESCE(SUM(fullplayerdetails.points), 0) INTO playerPoints FROM userTeamDetails JOIN userTeamPlayersDetails ON userTeamPlayersDetails.userTeamId = userTeamDetails.userTeamId JOIN fullplayerdetails ON fullplayerdetails.matchId = userTeamDetails.matchId AND fullplayerdetails.playerId = userTeamPlayersDetails.playerId WHERE userTeamDetails.userTeamId = userTeamId AND userTeamPlayersDetails.isCaptain = 0 AND userTeamPlayersDetails.isViceCaptain = 0;
SELECT COALESCE(fullplayerdetails.points, 0) INTO captainPoints FROM userTeamDetails JOIN userTeamPlayersDetails ON userTeamPlayersDetails.userTeamId = userTeamDetails.userTeamId JOIN fullplayerdetails ON fullplayerdetails.matchId = userTeamDetails.matchId AND fullplayerdetails.playerId = userTeamPlayersDetails.playerId WHERE userTeamDetails.userTeamId = userTeamId AND userTeamPlayersDetails.isCaptain = 1;
SELECT COALESCE(fullplayerdetails.points, 0) INTO viceCaptainPoints FROM userTeamDetails JOIN userTeamPlayersDetails ON userTeamPlayersDetails.userTeamId = userTeamDetails.userTeamId JOIN fullplayerdetails ON fullplayerdetails.matchId = userTeamDetails.matchId AND fullplayerdetails.playerId = userTeamPlayersDetails.playerId WHERE userTeamDetails.userTeamId = userTeamId AND userTeamPlayersDetails.isViceCaptain = 1;
SET playerPoints = playerPoints + (viceCaptainPoints) * 1.5 + (captainPoints) * 2;
UPDATE userTeamDetails SET userTeamDetails.userTeamPoints = playerPoints WHERE userTeamDetails.userTeamId = userTeamId;

/* end process */

END LOOP getNextTeam;
CLOSE cursorUserTeam;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_likes` (IN `teamId` INT(7), IN `userId` INT(7))   BEGIN

/* Declaring variables */
DECLARE userLiked INT DEFAULT 0;
DECLARE likeCount INT DEFAULT 0;
DECLARE userExists INT DEFAULT 0;
DECLARE teamExists INT DEFAULT 0;
DECLARE isUserLikedTeam INT DEFAULT 0;

/* checking existance of user */
SELECT EXISTS(SELECT userdetails.userId FROM userdetails WHERE userdetails.userId = userId) INTO userExists;

IF userExists = 1 THEN

IF EXISTS(SELECT * FROM userTeamDetails JOIN fullmatchdetails ON fullmatchdetails.matchId = userTeamDetails.matchId WHERE userTeamDetails.userTeamId = teamId AND fullmatchdetails.matchStatusString IN ('not_started', 'live')) = 1 THEN

/* checking existance of team */
SELECT EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userTeamId = teamId) INTO teamExists;

IF teamExists = 1 THEN

/* storing value of isUserLiked in particular team */
SELECT EXISTS(SELECT userId FROM fulllikesdetails WHERE userTeamId = teamId AND fulllikesdetails.userId = userId) INTO userLiked;

/* getting total number of likes in team */
SELECT COUNT(*) INTO likeCount FROM fulllikesdetails WHERE userTeamId = teamId;

/* if user liked then removing like */
IF userLiked = 1 AND likeCount > 0 THEN
DELETE FROM user_team_likes
WHERE userTeamId = teamId AND user_team_likes.userId = userId;
SET likeCount = LikeCount - 1;
UPDATE user_team_new SET user_team_new.userTeamLikes = likeCount WHERE user_team_new.userTeamId = teamId;
SET isUserLikedTeam = 0;

/* if user not liked then adding like */
ELSEIF userLiked = 0 THEN 
INSERT INTO user_team_likes SET user_team_likes.userTeamId = teamId, user_team_likes.userId = userId;
SET isUserLikedTeam = 1;
SET likeCount = LikeCount + 1;
UPDATE user_team_new SET user_team_new.userTeamLikes = likeCount WHERE user_team_new.userTeamId = teamId;
END IF;

/* generating error for team not exists */
ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'invalid input';

/* generating error for user not exists */
END IF;

ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'you can only like live and upcoming match team';
END IF;

ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'invalid input';

END IF;

/* sending all response */
SELECT likeCount AS likes,isUserLikedTeam AS isUserLiked;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `update_views` (IN `teamId` VARCHAR(10), IN `viewerId` VARCHAR(10))   BEGIN

/* validation inputs */
IF (NOT teamId REGEXP '[^0123456789]' AND NOT viewerId REGEXP '[^0123456789]') = 1 THEN
    
/* checking team creater is not viewer */
IF viewerId NOT IN (SELECT userTeamDetails.userId FROM userTeamDetails WHERE userTeamDetails.userTeamId = teamId) = 1 THEN
    
IF EXISTS(SELECT allviews.userId FROM allviews WHERE allviews.userId = viewerId AND allviews.userTeamId = teamId) = 1 THEN

/* updating all views */
UPDATE user_team_views SET user_team_views.viewCount = user_team_views.viewCount + 1 WHERE user_team_views.userId = viewerId AND user_team_views.userTeamId = teamId;
UPDATE user_team_new SET user_team_new.userTeamViews = (SELECT COUNT(user_team_views.userId) FROM user_team_views WHERE user_team_views.userTeamId = teamId) WHERE user_team_new.userTeamId = teamId;

/* inserting into all views */
ELSE 
INSERT INTO user_team_views (userTeamId, userId) VALUES (teamId, viewerId);
UPDATE user_team_new SET user_team_new.userTeamViews = (SELECT COUNT(user_team_views.userId) FROM user_team_views WHERE user_team_views.userTeamId = teamId) WHERE user_team_new.userTeamId = teamId;
END IF;

SELECT "success" AS message;

/* viewer is the creater */
ELSE SELECT "fail" AS message;
END IF;
    
/* error for invalid inputs */
ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'invalid input';
END IF;
END$$

DELIMITER ;

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
-- Table structure for table `coinSpendSource`
--

CREATE TABLE `coinSpendSource` (
  `sourceId` int(11) NOT NULL,
  `sourceName` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `coinSpendSource`
--

INSERT INTO `coinSpendSource` (`sourceId`, `sourceName`) VALUES
(1, 'WITHDRAW'),
(2, 'CREATE_TEAM'),
(3, 'BONUS_FOR_WINNING_CONTEST');

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

--
-- Dumping data for table `competitors`
--

INSERT INTO `competitors` (`competitorId`, `competitorRadarId`, `competitorName`, `competitorCountry`, `competitorCountryCode`, `competitorDisplayName`, `logTime`) VALUES
(1, 152316, 'Sunrisers Hyderabad', 'India', 'IND', 'SRH', '2022-05-12 13:19:41'),
(2, 152324, 'Mumbai Indians', 'India', 'IND', 'MI', '2022-05-12 13:19:56'),
(3, 152326, 'Kolkata Knight Riders', 'India', 'IND', 'KKR', '2022-05-12 13:20:14'),
(4, 152330, 'Punjab Kings', 'India', 'IND', 'PBKS', '2022-05-12 13:20:29'),
(5, 152320, 'Rajasthan Royals', 'India', 'IND', 'RR', '2022-05-12 13:20:45'),
(6, 152334, 'Chennai Super Kings', 'India', 'IND', 'CSK', '2022-05-12 13:21:00'),
(7, 152318, 'Royal Challengers Bangalore', 'India', 'IND', 'RCB', '2022-05-12 13:21:16'),
(8, 152332, 'Delhi Capitals', 'India', 'IND', 'DC', '2022-05-12 13:21:29'),
(9, 877927, 'Gujarat Titans', 'India', 'IND', 'GT', '2022-05-12 13:21:45'),
(10, 877929, 'Lucknow Super Giants', 'India', 'IND', 'LSG', '2022-05-12 13:22:00');

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
,`isLineUpOut` tinyint(1)
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
,`credits` decimal(20,1)
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

--
-- Dumping data for table `match_players`
--

INSERT INTO `match_players` (`matchId`, `competitorId`, `playerId`, `isSelected`, `isCaptain`, `isWicketKeeper`, `order`, `credit`, `points`, `runsPoints`, `foursPoints`, `sixesPoints`, `numberRunsPoints`, `numberWicketPoints`, `wicketPoints`, `maidenOverPoints`, `lbwOrBowledPoints`, `catchesPoints`, `runOutPoints`, `economyPoints`, `strikeRatePoints`, `logTime`) VALUES
(1, 3, 49, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 50, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 51, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 52, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 53, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 54, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 55, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 56, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 57, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 58, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 59, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 60, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 61, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 62, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 63, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 64, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 65, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 66, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 67, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 68, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 69, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 70, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 71, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 72, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 3, 73, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 123, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 124, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 125, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 126, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 127, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 128, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 129, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 130, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 131, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 132, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 133, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 134, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 135, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 136, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 137, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 138, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 139, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 140, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 141, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 142, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 143, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 144, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 145, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(1, 6, 146, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:12'),
(2, 2, 24, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 25, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 26, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 27, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 28, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 29, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 30, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 31, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 32, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 33, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 34, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 35, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 36, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 37, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 38, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 39, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 40, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 41, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 42, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 43, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 44, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 45, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 46, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 47, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 2, 48, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 169, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 170, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 171, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 172, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 173, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 174, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 175, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 176, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 177, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 178, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 179, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 180, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 181, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 182, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 183, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 184, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 185, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 186, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 187, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 188, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 189, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 190, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 191, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(2, 8, 192, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 74, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 75, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 76, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 77, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 78, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 79, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 80, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 81, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 82, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 83, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 84, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 85, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 86, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 87, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 88, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 89, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 90, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 91, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 92, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 93, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 94, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 95, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 96, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 97, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 4, 98, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 147, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 148, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 149, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 150, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 151, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 152, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 153, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 154, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 155, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 156, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 157, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 158, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 159, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 160, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 161, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 162, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 163, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 164, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 165, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 166, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 167, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(3, 7, 168, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 193, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 194, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 195, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 196, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 197, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 198, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 199, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 200, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 201, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 202, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 203, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 204, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 205, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 206, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 207, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 208, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 209, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 210, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 211, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 212, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 213, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 214, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 9, 215, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 216, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 217, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 218, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 219, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 220, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 221, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 222, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 223, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 224, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 225, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 226, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 227, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 228, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 229, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 230, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 231, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 232, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 233, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 234, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 235, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(4, 10, 236, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 1, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 2, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 3, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 4, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 5, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 6, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 7, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 8, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 9, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 10, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 11, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 12, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 13, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 14, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 15, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 16, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 17, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 18, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 19, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 20, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 21, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 22, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 1, 23, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 99, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 100, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 101, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 102, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 103, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 104, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 105, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 106, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 107, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 108, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 109, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 110, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 111, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 112, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 113, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 114, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 115, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 116, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 117, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 118, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 119, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 120, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:13'),
(5, 5, 121, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(5, 5, 122, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 49, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 50, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 51, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 52, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 53, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 54, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 55, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 56, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 57, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 58, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 59, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 60, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 61, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 62, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 63, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 64, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 65, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 66, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 67, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 68, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 69, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 70, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 71, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 72, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 3, 73, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 147, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 148, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 149, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 150, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 151, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 152, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 153, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 154, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 155, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 156, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 157, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 158, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 159, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 160, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 161, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 162, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 163, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 164, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 165, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 166, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 167, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(6, 7, 168, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 123, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 124, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 125, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 126, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 127, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 128, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 129, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 130, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 131, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 132, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 133, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 134, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 135, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 136, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 137, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 138, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 139, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 140, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 141, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 142, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 143, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 144, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 145, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 6, 146, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 216, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 217, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 218, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 219, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 220, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 221, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 222, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 223, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 224, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 225, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 226, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 227, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 228, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 229, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 230, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 231, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 232, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 233, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 234, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 235, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(7, 10, 236, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 49, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 50, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 51, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 52, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 53, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 54, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 55, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 56, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 57, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 58, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 59, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 60, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 61, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 62, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 63, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 64, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 65, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 66, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 67, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 68, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 69, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 70, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 71, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 72, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 3, 73, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 74, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 75, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 76, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 77, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 78, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 79, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 80, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 81, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 82, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 83, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 84, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 85, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 86, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 87, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 88, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 89, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 90, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 91, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 92, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 93, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 94, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 95, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 96, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 97, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(8, 4, 98, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 24, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 25, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 26, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 27, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 28, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 29, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 30, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 31, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 32, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 33, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 34, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 35, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 36, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 37, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 38, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 39, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 40, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 41, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 42, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 43, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 44, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 45, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 46, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 47, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 2, 48, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 99, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 100, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 101, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 102, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 103, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 104, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 105, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 106, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 107, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 108, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 109, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 110, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 111, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 112, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 113, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 114, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 115, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 116, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 117, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 118, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 119, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 120, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 121, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(9, 5, 122, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:14'),
(10, 8, 169, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 170, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 171, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 172, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 173, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 174, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 175, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 176, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 177, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 178, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 179, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 180, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 181, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 182, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 183, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 184, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 185, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 186, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 187, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 188, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 189, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 190, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 191, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 8, 192, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 193, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 194, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 195, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 196, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 197, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 198, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 199, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 200, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 201, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 202, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 203, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 204, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 205, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 206, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 207, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 208, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 209, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 210, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 211, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 212, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 213, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 214, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(10, 9, 215, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 74, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 75, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 76, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 77, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15');
INSERT INTO `match_players` (`matchId`, `competitorId`, `playerId`, `isSelected`, `isCaptain`, `isWicketKeeper`, `order`, `credit`, `points`, `runsPoints`, `foursPoints`, `sixesPoints`, `numberRunsPoints`, `numberWicketPoints`, `wicketPoints`, `maidenOverPoints`, `lbwOrBowledPoints`, `catchesPoints`, `runOutPoints`, `economyPoints`, `strikeRatePoints`, `logTime`) VALUES
(11, 4, 78, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 79, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 80, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 81, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 82, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 83, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 84, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 85, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 86, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 87, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 88, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 89, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 90, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 91, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 92, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 93, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 94, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 95, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 96, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 97, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 4, 98, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 123, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 124, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 125, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 126, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 127, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 128, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 129, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 130, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 131, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 132, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 133, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 134, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 135, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 136, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 137, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 138, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 139, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 140, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 141, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 142, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 143, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 144, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 145, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(11, 6, 146, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 1, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 2, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 3, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 4, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 5, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 6, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 7, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 8, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 9, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 10, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 11, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 12, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 13, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 14, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 15, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 16, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 17, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 18, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 19, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 20, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 21, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 22, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 1, 23, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 216, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 217, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 218, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 219, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 220, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 221, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 222, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 223, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 224, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 225, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 226, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 227, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 228, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 229, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 230, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 231, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 232, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 233, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 234, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 235, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(12, 10, 236, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 99, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 100, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 101, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 102, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 103, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 104, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 105, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 106, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 107, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 108, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 109, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 110, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 111, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 112, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 113, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 114, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 115, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 116, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 117, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 118, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 119, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 120, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 121, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 5, 122, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 147, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 148, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 149, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 150, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 151, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 152, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 153, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 154, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 155, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 156, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 157, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 158, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 159, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 160, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 161, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 162, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 163, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 164, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 165, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 166, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 167, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(13, 7, 168, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(14, 2, 24, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 25, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 26, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 27, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 28, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 29, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 30, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 31, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 32, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 33, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 34, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 35, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 36, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 37, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 38, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 39, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 40, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 41, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 42, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 43, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 44, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 45, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 46, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 47, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 2, 48, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 3, 49, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(14, 3, 50, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(14, 3, 51, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(14, 3, 52, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(14, 3, 53, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(14, 3, 54, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:15'),
(14, 3, 55, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 3, 56, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 3, 57, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 3, 58, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 3, 59, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 3, 60, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 3, 61, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 3, 62, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 3, 63, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 3, 64, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 3, 65, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 3, 66, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 3, 67, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 3, 68, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 3, 69, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 3, 70, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 3, 71, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 3, 72, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(14, 3, 73, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 169, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 170, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 171, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 172, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 173, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 174, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 175, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 176, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 177, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 178, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 179, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 180, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 181, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 182, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 183, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 184, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 185, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 186, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 187, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 188, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 189, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 190, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 191, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 8, 192, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 216, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 217, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 218, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 219, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 220, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 221, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 222, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 223, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 224, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 225, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 226, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 227, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 228, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 229, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 230, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 231, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 232, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 233, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 234, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 235, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(15, 10, 236, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 74, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 75, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 76, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 77, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 78, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 79, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 80, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 81, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 82, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 83, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 84, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 85, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 86, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 87, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 88, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 89, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 90, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 91, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 92, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 93, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 94, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 95, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 96, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 97, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 4, 98, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 193, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 194, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 195, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 196, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 197, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 198, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 199, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 200, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 201, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 202, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 203, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 204, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 205, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 206, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 207, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 208, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 209, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 210, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 211, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 212, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 213, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 214, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(16, 9, 215, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 1, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 2, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 3, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 4, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 5, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 6, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 7, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 8, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 9, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 10, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 11, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 12, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 13, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 14, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 15, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 16, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 17, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 18, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 19, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 20, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 21, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 22, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 1, 23, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 123, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 124, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 125, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 126, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 127, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 128, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 129, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 130, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 131, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 132, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 133, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 134, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 135, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 136, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 137, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 138, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 139, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 140, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 141, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 142, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 143, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 144, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 145, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(17, 6, 146, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 24, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 25, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 26, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 27, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 28, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 29, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 30, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 31, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 32, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 33, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 34, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 35, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 36, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 37, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 38, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 39, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 40, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 41, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 42, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 43, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 44, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 45, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 46, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 47, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 2, 48, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 147, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 148, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 149, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 150, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 151, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 152, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 153, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 154, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 155, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 156, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 157, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 158, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 159, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 160, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 161, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 162, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 163, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 164, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 165, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 166, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 167, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(18, 7, 168, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 49, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 50, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 51, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 52, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 53, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 54, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 55, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 56, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 57, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 58, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 59, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 60, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 61, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 62, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 63, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 64, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 65, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 66, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 67, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 68, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 69, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 70, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 71, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 72, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 3, 73, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 169, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 170, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 171, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 172, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 173, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 174, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 175, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 176, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 177, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 178, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 179, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 180, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 181, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 182, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 183, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 184, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 185, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 186, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 187, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 188, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 189, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 190, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 191, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(19, 8, 192, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(20, 5, 99, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(20, 5, 100, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(20, 5, 101, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(20, 5, 102, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(20, 5, 103, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(20, 5, 104, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(20, 5, 105, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(20, 5, 106, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(20, 5, 107, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(20, 5, 108, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(20, 5, 109, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(20, 5, 110, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(20, 5, 111, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(20, 5, 112, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(20, 5, 113, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(20, 5, 114, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(20, 5, 115, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(20, 5, 116, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:16'),
(20, 5, 117, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 5, 118, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 5, 119, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 5, 120, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 5, 121, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 5, 122, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 216, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 217, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 218, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 219, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 220, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 221, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 222, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 223, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 224, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 225, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 226, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 227, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 228, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 229, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 230, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 231, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 232, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 233, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 234, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 235, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(20, 10, 236, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 1, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 2, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 3, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 4, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 5, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 6, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 7, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 8, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17');
INSERT INTO `match_players` (`matchId`, `competitorId`, `playerId`, `isSelected`, `isCaptain`, `isWicketKeeper`, `order`, `credit`, `points`, `runsPoints`, `foursPoints`, `sixesPoints`, `numberRunsPoints`, `numberWicketPoints`, `wicketPoints`, `maidenOverPoints`, `lbwOrBowledPoints`, `catchesPoints`, `runOutPoints`, `economyPoints`, `strikeRatePoints`, `logTime`) VALUES
(21, 1, 9, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 10, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 11, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 12, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 13, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 14, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 15, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 16, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 17, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 18, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 19, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 20, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 21, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 22, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 1, 23, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 193, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 194, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 195, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 196, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 197, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 198, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 199, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 200, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 201, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 202, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 203, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 204, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 205, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 206, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 207, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 208, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 209, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 210, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 211, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 212, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 213, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 214, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(21, 9, 215, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 123, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 124, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 125, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 126, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 127, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 128, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 129, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 130, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 131, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 132, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 133, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 134, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 135, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 136, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 137, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 138, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 139, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 140, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 141, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 142, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 143, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 144, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 145, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 6, 146, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 147, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 148, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 149, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 150, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 151, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 152, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 153, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 154, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 155, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 156, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 157, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 158, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 159, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 160, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 161, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 162, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 163, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 164, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 165, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 166, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 167, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(22, 7, 168, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 24, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 25, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 26, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 27, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 28, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 29, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 30, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 31, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 32, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 33, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 34, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 35, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 36, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 37, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 38, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 39, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 40, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 41, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 42, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 43, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 44, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 45, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 46, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 47, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 2, 48, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 74, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 75, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 76, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 77, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 78, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 79, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 80, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 81, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 82, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 83, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 84, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 85, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 86, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 87, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 88, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 89, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 90, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 91, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 92, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 93, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 94, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 95, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 96, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 97, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(23, 4, 98, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 99, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 100, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 101, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 102, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 103, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 104, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 105, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 106, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 107, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 108, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 109, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 110, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 111, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 112, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 113, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 114, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 115, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 116, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 117, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 118, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 119, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 120, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 121, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 5, 122, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 193, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 194, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 195, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 196, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 197, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 198, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 199, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 200, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 201, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 202, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 203, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 204, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 205, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 206, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 207, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 208, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 209, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 210, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 211, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 212, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 213, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 214, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(24, 9, 215, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 1, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 2, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 3, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 4, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 5, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 6, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 7, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 8, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 9, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 10, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 11, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 12, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 13, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 14, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 15, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 16, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 17, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 18, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 19, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 20, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 21, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 22, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 1, 23, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 49, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 50, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 51, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 52, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 53, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 54, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 55, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 56, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 57, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 58, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 59, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 60, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 61, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 62, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 63, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 64, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 65, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 66, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 67, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 68, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 69, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 70, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 71, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 72, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(25, 3, 73, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 24, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 25, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 26, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 27, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 28, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 29, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 30, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 31, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 32, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 33, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 34, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 35, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 36, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 37, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 38, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 39, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 40, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 41, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 42, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 43, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 44, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 45, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 46, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 47, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 2, 48, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 216, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 217, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 218, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 219, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 220, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 221, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 222, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 223, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 224, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 225, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 226, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 227, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 228, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 229, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 230, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 231, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 232, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 233, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 234, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 235, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(26, 10, 236, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 147, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 148, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 149, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 150, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 151, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 152, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 153, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 154, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 155, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 156, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 157, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 158, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 159, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 160, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 161, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 162, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 163, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 164, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 165, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 166, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 167, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 7, 168, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 169, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 170, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 171, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 172, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 173, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 174, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 175, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 176, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 177, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 178, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 179, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 180, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 181, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 182, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 183, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 184, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 185, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 186, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 187, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 188, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 189, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 190, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 191, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(27, 8, 192, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 1, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 2, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 3, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 4, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 5, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 6, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 7, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 8, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 9, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 10, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 11, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 12, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 13, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 14, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 15, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 16, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 17, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 18, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 19, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 20, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 21, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 22, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 1, 23, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 74, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 75, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 76, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 77, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 78, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 79, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 80, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 81, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 82, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 83, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 84, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 85, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 86, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 87, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 88, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 89, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 90, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 91, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 92, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 93, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 94, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 95, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 96, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 97, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(28, 4, 98, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 6, 123, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 124, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 125, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 126, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 127, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 128, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 129, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 130, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 131, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 132, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 133, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 134, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 135, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 136, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 137, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 138, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 139, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 140, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 141, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 142, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 143, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 144, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 145, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 6, 146, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 9, 193, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 9, 194, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 9, 195, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 9, 196, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 9, 197, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 9, 198, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 9, 199, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 9, 200, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 9, 201, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 9, 202, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 9, 203, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 9, 204, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 9, 205, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 9, 206, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 9, 207, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 9, 208, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 9, 209, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 9, 210, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 9, 211, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 9, 212, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:17'),
(29, 9, 213, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 9, 214, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(29, 9, 215, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 49, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 50, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 51, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 52, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 53, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 54, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 55, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 56, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 57, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 58, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 59, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 60, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 61, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 62, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 63, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 64, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 65, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 66, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 67, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 68, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 69, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 70, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 71, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 72, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 3, 73, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 99, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 100, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 101, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 102, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 103, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 104, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 105, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 106, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 107, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 108, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 109, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 110, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 111, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 112, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 113, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 114, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 115, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 116, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 117, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 118, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 119, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 120, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 121, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(30, 5, 122, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 147, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 148, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 149, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 150, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 151, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 152, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 153, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 154, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 155, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18');
INSERT INTO `match_players` (`matchId`, `competitorId`, `playerId`, `isSelected`, `isCaptain`, `isWicketKeeper`, `order`, `credit`, `points`, `runsPoints`, `foursPoints`, `sixesPoints`, `numberRunsPoints`, `numberWicketPoints`, `wicketPoints`, `maidenOverPoints`, `lbwOrBowledPoints`, `catchesPoints`, `runOutPoints`, `economyPoints`, `strikeRatePoints`, `logTime`) VALUES
(31, 7, 156, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 157, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 158, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 159, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 160, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 161, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 162, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 163, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 164, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 165, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 166, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 167, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 7, 168, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 216, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 217, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 218, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 219, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 220, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 221, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 222, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 223, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 224, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 225, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 226, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 227, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 228, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 229, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 230, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 231, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 232, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 233, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 234, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 235, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(31, 10, 236, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 74, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 75, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 76, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 77, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 78, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 79, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 80, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 81, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 82, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 83, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 84, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 85, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 86, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 87, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 88, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 89, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 90, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 91, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 92, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 93, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 94, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 95, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 96, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 97, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 4, 98, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 169, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 170, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 171, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 172, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 173, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 174, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 175, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 176, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 177, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 178, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 179, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 180, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 181, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 182, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 183, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 184, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 185, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 186, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 187, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 188, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 189, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 190, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 191, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(32, 8, 192, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 24, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 25, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 26, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 27, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 28, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 29, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 30, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 31, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 32, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 33, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 34, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 35, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 36, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 37, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 38, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 39, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 40, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 41, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 42, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 43, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 44, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 45, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 46, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 47, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 2, 48, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 123, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 124, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 125, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 126, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 127, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 128, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 129, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 130, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 131, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 132, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 133, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 134, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 135, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 136, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 137, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 138, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 139, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 140, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 141, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 142, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 143, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 144, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 145, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(33, 6, 146, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 99, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 100, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 101, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 102, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 103, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 104, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 105, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 106, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 107, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 108, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 109, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 110, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 111, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 112, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 113, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 114, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 115, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 116, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 117, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 118, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 119, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 120, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 121, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 5, 122, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 169, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 170, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 171, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 172, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 173, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 174, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 175, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 176, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 177, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 178, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 179, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 180, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 181, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 182, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 183, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 184, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 185, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 186, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 187, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 188, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 189, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 190, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 191, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(34, 8, 192, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 49, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 50, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 51, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 52, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 53, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 54, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 55, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 56, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 57, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 58, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 59, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 60, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 61, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 62, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 63, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 64, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 65, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 66, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 67, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 68, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 69, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 70, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 71, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 72, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 3, 73, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 193, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 194, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 195, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 196, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 197, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 198, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 199, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 200, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 201, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 202, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 203, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 204, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 205, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 206, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 207, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 208, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 209, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 210, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 211, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 212, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 213, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 214, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(35, 9, 215, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 1, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 2, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 3, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 4, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 5, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 6, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 7, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 8, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 9, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 10, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 11, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 12, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 13, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 14, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 15, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 16, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 17, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 18, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 19, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 20, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 21, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 22, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 1, 23, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 147, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 148, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 149, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 150, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 151, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 152, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 153, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 154, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 155, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 156, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 157, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 158, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 159, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 160, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 161, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 162, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 163, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 164, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 165, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 166, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 167, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(36, 7, 168, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 24, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 25, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 26, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 27, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 28, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 29, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 30, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 31, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 32, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 33, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 34, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 35, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 36, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 37, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 38, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 39, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 40, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 41, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 42, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 43, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 44, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 45, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 46, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 47, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 2, 48, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 216, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 217, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 218, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 219, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 220, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 221, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 222, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 223, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 224, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 225, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 226, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 227, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 228, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 229, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 230, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 231, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 232, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 233, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 234, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 235, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(37, 10, 236, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(38, 4, 74, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(38, 4, 75, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(38, 4, 76, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(38, 4, 77, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(38, 4, 78, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(38, 4, 79, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:18'),
(38, 4, 80, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 4, 81, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 4, 82, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 4, 83, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 4, 84, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 4, 85, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 4, 86, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 4, 87, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 4, 88, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 4, 89, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 4, 90, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 4, 91, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 4, 92, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 4, 93, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 4, 94, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 4, 95, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 4, 96, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 4, 97, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 4, 98, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 123, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 124, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 125, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 126, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 127, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 128, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 129, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 130, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 131, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 132, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 133, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 134, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 135, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 136, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 137, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 138, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 139, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 140, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 141, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 142, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 143, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 144, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 145, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(38, 6, 146, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 99, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 100, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 101, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 102, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 103, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 104, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 105, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 106, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 107, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 108, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 109, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 110, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 111, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 112, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 113, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 114, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 115, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 116, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 117, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 118, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 119, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 120, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 121, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 5, 122, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 147, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 148, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 149, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 150, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 151, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 152, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 153, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 154, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 155, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 156, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 157, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 158, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 159, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 160, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 161, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 162, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 163, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 164, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 165, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 166, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 167, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(39, 7, 168, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 1, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 2, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 3, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 4, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 5, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 6, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 7, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 8, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 9, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 10, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 11, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 12, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 13, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 14, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 15, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 16, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 17, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 18, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 19, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 20, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 21, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 22, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 1, 23, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 193, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 194, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 195, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 196, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 197, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 198, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 199, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 200, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 201, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 202, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 203, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 204, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 205, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 206, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 207, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 208, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 209, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 210, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 211, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 212, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 213, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 214, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(40, 9, 215, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 49, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 50, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 51, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 52, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 53, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 54, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 55, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 56, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 57, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 58, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 59, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 60, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 61, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 62, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19');
INSERT INTO `match_players` (`matchId`, `competitorId`, `playerId`, `isSelected`, `isCaptain`, `isWicketKeeper`, `order`, `credit`, `points`, `runsPoints`, `foursPoints`, `sixesPoints`, `numberRunsPoints`, `numberWicketPoints`, `wicketPoints`, `maidenOverPoints`, `lbwOrBowledPoints`, `catchesPoints`, `runOutPoints`, `economyPoints`, `strikeRatePoints`, `logTime`) VALUES
(41, 3, 63, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 64, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 65, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 66, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 67, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 68, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 69, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 70, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 71, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 72, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 3, 73, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 169, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 170, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 171, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 172, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 173, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 174, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 175, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 176, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 177, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 178, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 179, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 180, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 181, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 182, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 183, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 184, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 185, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 186, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 187, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 188, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 189, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 190, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 191, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(41, 8, 192, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 74, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 75, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 76, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 77, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 78, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 79, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 80, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 81, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 82, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 83, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 84, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 85, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 86, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 87, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 88, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 89, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 90, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 91, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 92, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 93, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 94, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 95, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 96, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 97, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 4, 98, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 216, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 217, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 218, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 219, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 220, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 221, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 222, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 223, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 224, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 225, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 226, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 227, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 228, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 229, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 230, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 231, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 232, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 233, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 234, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 235, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(42, 10, 236, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 147, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 148, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 149, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 150, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 151, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 152, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 153, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 154, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 155, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 156, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 157, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 158, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 159, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 160, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 161, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 162, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 163, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 164, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 165, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 166, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 167, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 7, 168, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 193, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 194, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 195, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 196, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 197, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 198, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 199, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 200, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 201, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 202, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 203, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 204, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 205, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 206, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 207, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 208, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 209, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 210, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 211, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 212, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 213, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 214, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(43, 9, 215, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 24, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 25, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 26, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 27, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 28, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 29, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 30, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 31, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 32, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 33, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 34, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 35, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 36, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 37, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 38, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 39, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 40, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 41, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 42, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 43, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 44, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 45, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 46, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 47, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 2, 48, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 99, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 100, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 101, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 102, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 103, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 104, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 105, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 106, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 107, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 108, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 109, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 110, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 111, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 112, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 113, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 114, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 115, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 116, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 117, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 118, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 119, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 120, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 121, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(44, 5, 122, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 169, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 170, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 171, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 172, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 173, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 174, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 175, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 176, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 177, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 178, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 179, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 180, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 181, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 182, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 183, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 184, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 185, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 186, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 187, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 188, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 189, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 190, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 191, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 8, 192, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 216, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 217, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 218, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 219, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 220, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 221, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 222, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 223, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 224, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 225, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 226, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 227, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 228, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 229, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 230, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 231, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 232, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 233, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 234, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 235, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(45, 10, 236, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(46, 1, 1, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(46, 1, 2, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(46, 1, 3, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(46, 1, 4, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:19'),
(46, 1, 5, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 1, 6, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 1, 7, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 1, 8, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 1, 9, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 1, 10, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 1, 11, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 1, 12, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 1, 13, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 1, 14, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 1, 15, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 1, 16, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 1, 17, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 1, 18, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 1, 19, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 1, 20, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 1, 21, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 1, 22, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 1, 23, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 123, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 124, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 125, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 126, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 127, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 128, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 129, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 130, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 131, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 132, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 133, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 134, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 135, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 136, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 137, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 138, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 139, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 140, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 141, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 142, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 143, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 144, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 145, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(46, 6, 146, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 49, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 50, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 51, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 52, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 53, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 54, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 55, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 56, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 57, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 58, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 59, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 60, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 61, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 62, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 63, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 64, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 65, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 66, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 67, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 68, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 69, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 70, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 71, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 72, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 3, 73, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 99, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 100, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 101, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 102, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 103, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 104, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 105, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 106, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 107, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 108, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 109, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 110, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 111, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 112, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 113, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 114, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 115, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 116, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 117, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 118, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 119, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 120, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 121, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(47, 5, 122, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 74, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 75, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 76, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 77, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 78, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 79, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 80, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 81, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 82, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 83, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 84, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 85, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 86, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 87, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 88, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 89, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 90, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 91, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 92, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 93, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 94, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 95, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 96, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 97, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 4, 98, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 193, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 194, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 195, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 196, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 197, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 198, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 199, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 200, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 201, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 202, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 203, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 204, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 205, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 206, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 207, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 208, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 209, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 210, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 211, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 212, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 213, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 214, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(48, 9, 215, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 123, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 124, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 125, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 126, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 127, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 128, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 129, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 130, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 131, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 132, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 133, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 134, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 135, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 136, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 137, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 138, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 139, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 140, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 141, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 142, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 143, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 144, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 145, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 6, 146, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 147, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 148, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 149, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 150, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 151, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 152, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 153, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 154, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 155, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 156, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 157, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 158, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 159, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 160, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 161, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 162, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 163, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 164, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 165, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 166, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 167, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(49, 7, 168, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 1, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 2, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 3, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 4, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 5, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 6, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 7, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 8, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 9, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 10, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 11, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 12, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 13, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 14, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 15, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 16, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 17, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 18, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 19, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 20, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 21, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 22, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 1, 23, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 169, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 170, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 171, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 172, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 173, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 174, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 175, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 176, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 177, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 178, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 179, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 180, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 181, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 182, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 183, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 184, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 185, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 186, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 187, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 188, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 189, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 190, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 191, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(50, 8, 192, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 24, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 25, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 26, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 27, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 28, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 29, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 30, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 31, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 32, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 33, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 34, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 35, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 36, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 37, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 38, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 39, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 40, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20');
INSERT INTO `match_players` (`matchId`, `competitorId`, `playerId`, `isSelected`, `isCaptain`, `isWicketKeeper`, `order`, `credit`, `points`, `runsPoints`, `foursPoints`, `sixesPoints`, `numberRunsPoints`, `numberWicketPoints`, `wicketPoints`, `maidenOverPoints`, `lbwOrBowledPoints`, `catchesPoints`, `runOutPoints`, `economyPoints`, `strikeRatePoints`, `logTime`) VALUES
(51, 2, 41, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 42, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 43, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 44, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 45, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 46, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 47, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 2, 48, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 193, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 194, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 195, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 196, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 197, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 198, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 199, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 200, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 201, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 202, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 203, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 204, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 205, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 206, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 207, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 208, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 209, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 210, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 211, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 212, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 213, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 214, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(51, 9, 215, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 74, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 75, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 76, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 77, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 78, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 79, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 80, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 81, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 82, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 83, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 84, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 85, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 86, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 87, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 88, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 89, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 90, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 91, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 92, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 93, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 94, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 95, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 96, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 97, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 4, 98, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 99, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 100, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 101, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 102, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 103, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 104, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 105, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 106, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 107, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 108, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 109, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 110, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 111, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 112, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 113, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 114, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 115, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 116, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 117, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 118, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 119, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 120, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 121, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(52, 5, 122, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 49, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 50, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 51, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 52, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 53, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 54, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 55, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 56, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 57, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 58, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 59, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 60, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 61, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 62, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 63, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 64, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 65, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 66, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 67, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 68, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 69, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 70, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 71, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 72, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 3, 73, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 216, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 217, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 218, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 219, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 220, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 221, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 222, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 223, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 224, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 225, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 226, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 227, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 228, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 229, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 230, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 231, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 232, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 233, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 234, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 235, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(53, 10, 236, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(54, 1, 1, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(54, 1, 2, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(54, 1, 3, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(54, 1, 4, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(54, 1, 5, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(54, 1, 6, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(54, 1, 7, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(54, 1, 8, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(54, 1, 9, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(54, 1, 10, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(54, 1, 11, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(54, 1, 12, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(54, 1, 13, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(54, 1, 14, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:20'),
(54, 1, 15, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 1, 16, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 1, 17, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 1, 18, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 1, 19, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 1, 20, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 1, 21, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 1, 22, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 1, 23, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 147, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 148, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 149, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 150, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 151, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 152, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 153, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 154, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 155, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 156, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 157, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 158, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 159, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 160, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 161, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 162, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 163, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 164, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 165, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 166, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 167, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(54, 7, 168, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 123, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 124, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 125, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 126, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 127, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 128, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 129, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 130, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 131, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 132, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 133, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 134, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 135, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 136, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 137, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 138, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 139, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 140, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 141, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 142, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 143, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 144, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 145, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 6, 146, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 169, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 170, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 171, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 172, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 173, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 174, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 175, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 176, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 177, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 178, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 179, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 180, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 181, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 182, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 183, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 184, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 185, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 186, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 187, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 188, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 189, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 190, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 191, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(55, 8, 192, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 24, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 25, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 26, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 27, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 28, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 29, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 30, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 31, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 32, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 33, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 34, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 35, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 36, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 37, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 38, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 39, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 40, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 41, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 42, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 43, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 44, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 45, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 46, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 47, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 2, 48, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 49, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 50, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 51, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 52, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 53, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 54, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 55, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 56, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 57, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 58, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 59, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 60, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 61, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 62, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 63, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 64, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 65, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 66, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 67, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 68, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 69, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 70, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 71, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 72, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(56, 3, 73, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 193, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 194, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 195, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 196, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 197, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 198, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 199, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 200, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 201, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 202, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 203, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 204, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 205, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 206, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 207, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 208, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 209, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 210, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 211, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 212, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 213, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 214, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 9, 215, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 216, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 217, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 218, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 219, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 220, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 221, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 222, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 223, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 224, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 225, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 226, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 227, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 228, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 229, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 230, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 231, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 232, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 233, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 234, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 235, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(57, 10, 236, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 99, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 100, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 101, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 102, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 103, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 104, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 105, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 106, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 107, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 108, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 109, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 110, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 111, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 112, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 113, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 114, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 115, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 116, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 117, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 118, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 119, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 120, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 121, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 5, 122, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 169, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 170, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 171, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 172, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 173, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 174, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 175, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 176, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 177, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 178, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 179, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 180, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 181, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 182, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 183, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 184, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 185, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 186, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 187, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 188, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 189, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 190, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 191, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(58, 8, 192, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 24, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 25, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 26, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 27, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 28, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 29, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 30, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 31, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 32, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 33, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 34, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 35, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 36, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 37, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 38, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 39, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 40, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 41, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 42, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 43, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 44, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 45, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 46, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 47, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 2, 48, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 123, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 124, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 125, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 126, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 127, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 128, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 129, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 130, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 131, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 132, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 133, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 134, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 135, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 136, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 137, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 138, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 139, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 140, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 141, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 142, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 143, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 144, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 145, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(59, 6, 146, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 74, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 75, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 76, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 77, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 78, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 79, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 80, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 81, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 82, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 83, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 84, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 85, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 86, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 87, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 88, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 89, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 90, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 91, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 92, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 93, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 94, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 95, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 96, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 97, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 4, 98, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 147, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 148, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 149, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 150, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 151, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 152, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 153, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 154, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 155, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 156, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 157, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 158, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 159, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 160, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 161, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 162, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 163, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 164, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 165, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 166, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 167, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(60, 7, 168, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 1, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 2, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 3, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 4, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 5, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 6, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 7, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 8, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 9, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 10, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 11, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 12, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 13, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 14, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 15, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 16, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 17, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21');
INSERT INTO `match_players` (`matchId`, `competitorId`, `playerId`, `isSelected`, `isCaptain`, `isWicketKeeper`, `order`, `credit`, `points`, `runsPoints`, `foursPoints`, `sixesPoints`, `numberRunsPoints`, `numberWicketPoints`, `wicketPoints`, `maidenOverPoints`, `lbwOrBowledPoints`, `catchesPoints`, `runOutPoints`, `economyPoints`, `strikeRatePoints`, `logTime`) VALUES
(61, 1, 18, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 19, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 20, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 21, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 22, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 1, 23, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 49, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 50, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 51, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 52, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 53, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 54, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 55, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 56, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 57, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 58, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 59, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 60, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 61, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 62, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 63, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 64, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 65, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 66, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 67, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 68, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 69, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 70, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 71, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 72, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(61, 3, 73, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:21'),
(62, 6, 123, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 124, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 125, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 126, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 127, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 128, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 129, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 130, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 131, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 132, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 133, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 134, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 135, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 136, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 137, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 138, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 139, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 140, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 141, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 142, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 143, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 144, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 145, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 6, 146, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 193, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 194, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 195, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 196, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 197, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 198, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 199, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 200, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 201, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 202, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 203, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 204, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 205, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 206, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 207, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 208, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 209, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 210, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 211, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 212, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 213, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 214, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(62, 9, 215, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 99, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 100, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 101, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 102, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 103, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 104, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 105, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 106, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 107, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 108, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 109, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 110, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 111, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 112, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 113, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 114, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 115, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 116, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 117, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 118, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 119, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 120, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 121, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 5, 122, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 216, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 217, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 218, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 219, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 220, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 221, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 222, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 223, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 224, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 225, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 226, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 227, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 228, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 229, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 230, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 231, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 232, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 233, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 234, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 235, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(63, 10, 236, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 74, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 75, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 76, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 77, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 78, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 79, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 80, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 81, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 82, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 83, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 84, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 85, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 86, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 87, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 88, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 89, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 90, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 91, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 92, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 93, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 94, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 95, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 96, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 97, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 4, 98, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 169, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 170, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 171, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 172, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 173, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 174, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 175, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 176, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 177, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 178, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 179, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 180, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 181, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 182, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 183, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 184, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 185, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 186, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 187, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 188, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 189, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 190, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 191, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(64, 8, 192, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 1, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 2, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 3, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 4, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 5, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 6, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 7, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 8, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 9, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 10, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 11, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 12, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 13, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 14, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 15, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 16, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 17, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 18, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 19, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 20, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 21, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 22, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 1, 23, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 24, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 25, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 26, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 27, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 28, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 29, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 30, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 31, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 32, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 33, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 34, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 35, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 36, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 37, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 38, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 39, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 40, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 41, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 42, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 43, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 44, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 45, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 46, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 47, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(65, 2, 48, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 49, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 50, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 51, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 52, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 53, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 54, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 55, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 56, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 57, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 58, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 59, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 60, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 61, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 62, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 63, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 64, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 65, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 66, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 67, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 68, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 69, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 70, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 71, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 72, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 3, 73, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 216, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 217, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 218, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 219, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 220, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 221, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 222, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 223, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 224, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 225, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 226, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 227, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 228, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 229, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 230, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 231, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 232, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 233, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 234, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 235, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(66, 10, 236, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:22'),
(67, 7, 147, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 148, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 149, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 150, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 151, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 152, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 153, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 154, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 155, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 156, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 157, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 158, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 159, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 160, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 161, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 162, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 163, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 164, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 165, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 166, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 167, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 7, 168, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 193, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 194, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 195, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 196, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 197, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 198, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 199, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 200, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 201, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 202, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 203, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 204, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 205, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 206, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 207, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 208, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 209, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 210, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 211, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 212, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 213, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 214, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(67, 9, 215, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 99, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 100, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 101, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 102, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 103, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 104, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 105, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 106, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 107, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 108, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 109, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 110, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 111, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 112, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 113, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 114, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 115, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 116, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 117, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 118, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 119, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 120, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 121, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 5, 122, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 123, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 124, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 125, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 126, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 127, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 128, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 129, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 130, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 131, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 132, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 133, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 134, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 135, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 136, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 137, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 138, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 139, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 140, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 141, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 142, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 143, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 144, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 145, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(68, 6, 146, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 24, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 25, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 26, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 27, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 28, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 29, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 30, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 31, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 32, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 33, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 34, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 35, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 36, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 37, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 38, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 39, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 40, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 41, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 42, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 43, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 44, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 45, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 46, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 47, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 2, 48, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 169, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 170, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 171, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 172, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 173, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 174, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 175, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 176, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 177, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 178, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 179, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 180, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 181, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 182, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 183, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 184, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 185, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 186, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 187, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 188, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 189, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 190, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 191, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(69, 8, 192, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 1, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 2, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 3, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 4, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 5, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 6, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 7, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 8, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 9, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 10, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 11, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 12, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 13, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 14, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 15, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 16, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 17, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 18, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 19, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 20, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 21, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 22, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 1, 23, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 74, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 75, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 76, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 77, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 78, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 79, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 80, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 81, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 82, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 83, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 84, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 85, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 86, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 87, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 88, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 89, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 90, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 91, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 92, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 93, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 94, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 95, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 96, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 97, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23'),
(70, 4, 98, 0, 0, 0, NULL, '7.5', NULL, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, NULL, NULL, '2022-05-12 14:14:23');

-- --------------------------------------------------------

--
-- Table structure for table `match_status`
--

CREATE TABLE `match_status` (
  `statusId` int(11) NOT NULL,
  `statusString` tinytext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `match_status`
--

INSERT INTO `match_status` (`statusId`, `statusString`) VALUES
(1, 'closed'),
(2, 'not_started'),
(3, 'live');

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

--
-- Dumping data for table `playerImages`
--

INSERT INTO `playerImages` (`ucPlayerId`, `name`, `dateOfBirth`, `imageId`) VALUES
(6635, 'Usman Khawaja', '535228200000', 170640);

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

--
-- Dumping data for table `players`
--

INSERT INTO `players` (`playerId`, `playerRadarId`, `playerFirstName`, `playerLastName`, `playerCountryCode`, `playerRole`, `playerDOB`, `playerBattingStyleId`, `playerBowlingStyleId`, `playerCountry`) VALUES
(1, 649634, 'Kane', 'Williamson', 'NZL', 1, '1990-08-08', 1, 1, 'New Zealand'),
(2, 663662, 'Bhuvneshwar', 'Kumar', 'IND', 2, '1990-02-05', 1, 2, 'India'),
(3, 670856, 'Shreyas', 'Gopal', 'IND', 3, '1993-09-04', 1, 3, 'India'),
(4, 673874, 'Rahul', 'Tripathi', 'IND', 1, '1991-03-02', 1, 2, 'India'),
(5, 679826, 'Shashank', 'Singh', 'IND', 1, '1991-11-21', 1, 1, 'India'),
(6, 686052, 'Sean', 'Abbott', 'AUS', 2, '1992-02-29', 1, 2, 'Australia'),
(7, 707784, 'Ravikumar', 'Samarth', 'IND', 1, '1993-01-22', 1, 2, 'India'),
(8, 722888, 'Jagadeesha', 'Suchith', 'IND', 2, '1994-01-16', 2, 1, 'India'),
(9, 737528, 'Aiden', 'Markram', 'ZAF', 1, '1994-10-04', 1, 1, 'South Africa'),
(10, 737834, 'Nicholas', 'Pooran', 'TTO', 4, '1995-10-02', 2, NULL, 'Trinidad and Tobago'),
(11, 743416, 'Marco', 'Jansen', 'ZAF', 3, '2000-05-01', 1, 4, 'South Africa'),
(12, 745140, 'Washington', 'Sundar', 'IND', 3, '1999-10-05', 2, 1, 'India'),
(13, 746000, 'Vishnu', 'Vinod', 'IND', 4, '1993-12-02', 1, NULL, 'India'),
(14, 1026435, 'T', 'Natarajan', 'IND', 2, '1991-05-27', 2, 5, 'India'),
(15, 1097786, 'Abhishek', 'Sharma', 'IND', 3, '2000-09-04', 2, 6, 'India'),
(16, 1097832, 'Priyam K', 'Garg', 'IND', 1, '2000-11-30', 1, 2, 'India'),
(17, 1103865, 'Glenn', 'Phillips', 'NZL', 4, '1996-12-06', 1, NULL, 'New Zealand'),
(18, 1323358, 'Abdul', 'Samad Farooq', 'IND', 1, '2001-10-28', NULL, NULL, 'India'),
(19, 1325582, 'Kartik', 'Tyagi', 'IND', 2, '2000-11-08', NULL, NULL, 'India'),
(20, 1403809, 'Romario', 'Shepherd', 'GUY', 2, '1994-11-26', NULL, NULL, 'Guyana'),
(21, 1859224, 'Sushant', 'Mishra', 'IND', 2, '2000-12-23', NULL, NULL, 'India'),
(22, 2116784, 'Umran', 'Malik', 'IND', 2, '1999-11-22', NULL, NULL, 'India'),
(23, 2288183, 'Fazalhaq', 'Farooqi', 'AFG', 2, '2000-09-22', NULL, NULL, 'Afghanistan'),
(24, 637822, 'Kieron', 'Pollard', 'TTO', 3, '1987-05-12', 1, 7, 'Trinidad and Tobago'),
(25, 670112, 'Rohit', 'Sharma', 'IND', 1, '1987-04-30', 1, 1, 'India'),
(26, 683872, 'Jaydev', 'Unadkat', 'IND', 2, '1991-10-18', 1, 5, 'India'),
(27, 722998, 'Murugan', 'Ashwin', 'IND', 2, '1990-09-08', 1, 8, 'India'),
(28, 736364, 'Tristan', 'Stubbs', 'ZAF', 1, '2000-08-14', 1, 3, 'South Africa'),
(29, 738634, 'Jasprit', 'Bumrah', 'IND', 2, '1993-12-06', 1, 2, 'India'),
(30, 741558, 'Jofra', 'Archer', 'ENG', 2, '1995-04-01', 1, 9, 'England'),
(31, 741568, 'Fabian', 'Allen', 'JAM', 3, '1995-05-07', 1, 6, 'Jamaica'),
(32, 745168, 'Ishan', 'Kishan', 'IND', 4, '1998-07-18', 2, NULL, 'India'),
(33, 745998, 'Basil', 'Thampi', 'IND', 2, '1993-09-11', 1, 2, 'India'),
(34, 768813, 'Suryakumar', 'Yadav', 'IND', 1, '1990-09-14', 1, 2, 'India'),
(35, 1026491, 'Sanjay', 'Yadav', 'IND', 3, '1995-05-10', 2, 6, 'India'),
(36, 1234912, 'Ramandeep', 'Singh', 'IND', 1, '1997-04-13', NULL, NULL, 'India'),
(37, 1315052, 'Riley', 'Meredith', 'AUS', 2, '1996-06-21', NULL, NULL, 'Australia'),
(38, 1326030, 'Anmolpreet', 'Singh', 'IND', 1, '1998-03-28', 1, 1, 'India'),
(39, 1354830, 'Daniel', 'Sams', 'AUS', 3, '1992-10-27', NULL, NULL, 'Australia'),
(40, 1378659, 'Aryan', 'Juyal', 'IND', 4, NULL, NULL, NULL, 'India'),
(41, 1384327, 'Tim', 'David', 'SGP', 1, '1996-03-16', NULL, NULL, 'Singapore'),
(42, 1430019, 'Mayank', 'Markande', 'IND', 2, '1997-11-11', 1, NULL, 'India'),
(43, 1604018, 'Kumar', 'Kartikeya', 'IND', 2, NULL, 2, 6, 'India'),
(44, 1712061, 'Tilak', 'Varma', 'IND', 1, '2002-11-08', NULL, NULL, 'India'),
(45, 1742825, 'Arjun Sachin', 'Tendulkar', 'IND', 2, '1999-09-24', NULL, NULL, 'India'),
(46, 1884232, 'Hrithik Rakesh', 'Shokeen', 'IND', 2, '2000-01-18', NULL, NULL, 'India'),
(47, 2001895, 'Rahul Ravinder', 'Buddhi', NULL, 1, '1997-09-20', NULL, NULL, NULL),
(48, 2138442, 'Dewald', 'Brevis', NULL, 3, '2003-04-29', NULL, NULL, NULL),
(49, 637820, 'Sunil', 'Narine', 'TTO', 3, '1988-05-26', 2, 1, 'Trinidad and Tobago'),
(50, 638286, 'Tim', 'Southee', 'NZL', 2, '1988-12-11', 1, 7, 'New Zealand'),
(51, 639596, 'Sheldon', 'Jackson', 'IND', 4, '1986-09-27', 1, NULL, 'India'),
(52, 644342, 'Mohammad', 'Nabi', 'AFG', 3, '1985-01-01', 1, 1, 'Afghanistan'),
(53, 649232, 'Andre', 'Russell', 'JAM', 3, '1988-04-29', 1, 10, 'Jamaica'),
(54, 649652, 'Ajinkya', 'Rahane', 'IND', 1, '1988-06-06', 1, 2, 'India'),
(55, 655096, 'Sam', 'Billings', 'ENG', 4, '1991-06-15', 1, NULL, 'England'),
(56, 674582, 'Venkatesh', 'Iyer', 'IND', 3, '1994-12-25', NULL, NULL, 'India'),
(57, 708488, 'Baba', 'Indrajith', 'IND', 1, '1994-07-08', 1, 11, 'India'),
(58, 737848, 'Nitish', 'Rana', 'IND', 1, '1993-12-27', 2, 6, 'India'),
(59, 738490, 'Chamika', 'Karunaratne', 'LKA', 3, '1996-05-29', 1, 7, 'Sri Lanka'),
(60, 740150, 'Shreyas', 'Iyer', 'IND', 1, '1994-12-06', 1, 1, 'India'),
(61, 745468, 'Rinku', 'Singh', 'IND', 1, '1997-10-12', 2, 1, 'India'),
(62, 768811, 'Umesh', 'Yadav', 'IND', 2, '1987-10-25', 1, 9, 'India'),
(63, 768815, 'Pat', 'Cummins', 'AUS', 2, '1993-05-08', 1, 10, 'Australia'),
(64, 768865, 'Aaron', 'Finch', 'AUS', 1, '1986-11-17', 1, 5, 'Australia'),
(65, 1119673, 'Pratham', 'Singh', 'IND', 1, '1992-08-31', 2, 1, 'India'),
(66, 1233364, 'Varun', 'Chakravarthy', 'IND', 2, '1991-08-29', NULL, NULL, 'India'),
(67, 1234840, 'Abhijeet', 'Tomar', 'IND', 1, '1995-03-14', 1, NULL, 'India'),
(68, 1378655, 'Shivam', 'Mavi', 'IND', 2, '1998-11-26', NULL, NULL, 'India'),
(69, 1389131, 'Anukul', 'Roy', 'IND', 3, '1998-11-30', NULL, NULL, 'India'),
(70, 1423817, 'Aman Hakim', 'Khan', NULL, 3, '1996-11-23', NULL, NULL, NULL),
(71, 2301683, 'Ramesh', 'Kumar', 'IND', 3, '1999-01-01', NULL, NULL, 'India'),
(72, 2301685, 'Ashok', 'Sharma', 'IND', 2, '2002-06-17', NULL, NULL, 'India'),
(73, 2333889, 'Harshit', 'Rana', 'IND', 2, NULL, NULL, NULL, 'India'),
(74, 633516, 'Benny', 'Howell', 'ENG', 3, '1988-10-05', 1, 7, 'England'),
(75, 650706, 'Shikhar', 'Dhawan', 'IND', 1, '1985-12-05', 2, 1, 'India'),
(76, 652464, 'Rishi', 'Dhawan', 'IND', 3, '1990-02-19', 1, 7, 'India'),
(77, 654928, 'Jonny', 'Bairstow', 'ENG', 4, '1989-09-26', 1, 2, 'England'),
(78, 670438, 'Bhanuka', 'Rajapaksa', 'LKA', 1, '1991-10-24', 2, 2, 'Sri Lanka'),
(79, 672724, 'Prab Simran', 'Singh', 'IND', 4, '2000-08-10', NULL, NULL, 'India'),
(80, 685992, 'Mayank', 'Agarwal', 'IND', 1, '1991-02-16', 1, NULL, 'India'),
(81, 687410, 'Liam', 'Livingstone', 'ENG', 3, '1993-08-04', 1, 3, 'England'),
(82, 697254, 'Sandeep', 'Sharma', 'IND', 2, '1993-05-18', 1, 2, 'India'),
(83, 722766, 'Baltej', 'Singh', 'IND', 2, '1990-11-04', 1, 2, 'India'),
(84, 728930, 'Kagiso', 'Rabada', 'ZAF', 2, '1995-05-25', 2, 10, 'South Africa'),
(85, 744100, 'Writtick', 'Chatterjee', 'IND', 3, '1992-09-28', 1, 1, 'India'),
(86, 745144, 'Shahrukh', 'Khan', 'IND', 1, '1995-05-27', 1, 1, 'India'),
(87, 745214, 'Jitesh', 'Sharma', 'IND', 4, '1993-10-22', 1, NULL, 'India'),
(88, 1097814, 'Rahul', 'Chahar', 'IND', 2, '1999-08-04', 1, 12, 'India'),
(89, 1097856, 'Ishan', 'Porel', 'IND', 2, '1998-09-05', 1, 2, 'India'),
(90, 1142404, 'Vaibhav', 'Arora', NULL, 2, NULL, NULL, NULL, NULL),
(91, 1246368, 'Odean', 'Smith', 'JAM', 2, '1996-11-01', NULL, NULL, 'Jamaica'),
(92, 1378657, 'Arshdeep', 'Singh', 'IND', 2, '1999-02-05', NULL, NULL, 'India'),
(93, 1603274, 'Atharwa', 'Taide', 'IND', 1, '2000-04-26', NULL, NULL, 'India'),
(94, 1603620, 'Prerak', 'Mankad', 'IND', 3, '1994-03-23', 1, 7, 'India'),
(95, 1609704, 'Nathan', 'Ellis', 'AUS', 2, '1994-09-22', 1, 2, 'Australia'),
(96, 1710289, 'Harpreet', 'Brar', 'IND', 2, '1995-09-16', NULL, NULL, 'India'),
(97, 2114204, 'Ansh P', 'Patel', NULL, 2, NULL, NULL, NULL, NULL),
(98, 2276005, 'Raj Angad', 'Bawa', NULL, 3, '2002-11-12', NULL, NULL, NULL),
(99, 645482, 'Ravichandran', 'Ashwin', 'IND', 3, '1986-09-17', 1, 1, 'India'),
(100, 649644, 'Trent', 'Boult', 'NZL', 2, '1989-07-22', 1, 13, 'New Zealand'),
(101, 658988, 'Jos', 'Buttler', 'ENG', 4, '1990-09-08', 1, NULL, 'England'),
(102, 667796, 'Rassie', 'van der Dussen', 'ZAF', 1, '1989-02-07', 1, 3, 'South Africa'),
(103, 673864, 'Jimmy', 'Neesham', 'NZL', 3, '1990-09-17', 2, 2, 'New Zealand'),
(104, 681428, 'Daryl', 'Mitchell', 'NZL', 3, '1991-05-20', 1, 2, 'New Zealand'),
(105, 685994, 'Karun', 'Nair', 'IND', 1, '1991-12-06', 1, 14, 'India'),
(106, 693396, 'Sanju', 'Samson', 'IND', 4, '1994-11-11', 1, NULL, 'India'),
(107, 695120, 'Yuzvendra', 'Chahal', 'IND', 2, '1990-07-23', 1, 11, 'India'),
(108, 741576, 'Shimron', 'Hetmyer', 'GUY', 1, '1996-12-26', 2, NULL, 'Guyana'),
(109, 744204, 'Navdeep', 'Saini', 'IND', 2, '1992-11-23', 1, 2, 'India'),
(110, 768825, 'Nathan', 'Coulter-Nile', 'AUS', 2, '1987-10-11', 1, 10, 'Australia'),
(111, 980953, 'KC', 'Cariappa', 'IND', 2, '1994-04-13', 1, 3, 'India'),
(112, 1117851, 'Prasidh', 'Krishna', 'IND', 2, '1996-02-19', 1, 2, 'India'),
(113, 1119679, 'Tejas Singh', 'Baroka', 'IND', 2, '1996-02-01', 1, 12, 'India'),
(114, 1246972, 'Obed', 'McCoy', NULL, 2, '1997-01-04', NULL, NULL, NULL),
(115, 1276214, 'Devdutt Babunu', 'Padikkal', 'IND', 1, '2000-07-07', NULL, NULL, 'India'),
(116, 1357108, 'Riyan', 'Parag', 'IND', 1, '2001-11-10', NULL, NULL, 'India'),
(117, 1423793, 'Yashasvi', 'Jaiswal', 'IND', 1, '2001-12-28', NULL, NULL, 'India'),
(118, 1604256, 'Anunay', 'Singh', 'IND', 2, '1993-01-03', NULL, NULL, 'India'),
(119, 1641650, 'Kuldeep', 'Sen', 'IND', 2, '1996-10-22', NULL, NULL, 'India'),
(120, 1868936, 'Dhruv Chand', 'Jurel', 'IND', 4, '2001-01-21', NULL, NULL, 'India'),
(121, 1975081, 'Kuldip', 'Yadav', NULL, 2, '1996-10-15', 2, 5, NULL),
(122, 2250263, 'Shubham', 'Garhwal', 'IND', 3, '1995-05-14', NULL, NULL, 'India'),
(123, 638948, 'Ravindra', 'Jadeja', 'IND', 3, '1988-12-06', 2, 6, 'India'),
(124, 650386, 'MS', 'Dhoni', 'IND', 4, '1981-07-07', 1, 2, 'India'),
(125, 652062, 'Chris', 'Jordan', 'ENG', 2, '1988-10-04', 1, 9, 'England'),
(126, 664282, 'Dwaine', 'Pretorius', 'ZAF', 3, '1989-03-29', 1, 7, 'South Africa'),
(127, 665660, 'Ambati', 'Rayudu', 'IND', 1, '1985-09-23', 1, 1, 'India'),
(128, 673998, 'Robin', 'Uthappa', 'IND', 4, '1985-11-11', 1, 2, 'India'),
(129, 680246, 'Devon', 'Conway', 'NZL', 1, '1991-07-08', 2, 2, 'New Zealand'),
(130, 715672, 'Mitchell', 'Santner', 'NZL', 3, '1992-02-05', 2, 6, 'New Zealand'),
(131, 718468, 'Dwayne', 'Bravo', 'TTO', 3, '1983-10-07', 1, 7, 'Trinidad and Tobago'),
(132, 744748, 'Shivam', 'Dube', 'IND', 3, '1993-06-26', 2, 2, 'India'),
(133, 750794, 'Moeen', 'Ali', 'ENG', 3, '1987-06-18', 2, 1, 'England'),
(134, 1026433, 'Narayan', 'Jagadeesan', 'IND', 4, '1995-12-24', 1, NULL, 'India'),
(135, 1026475, 'C Hari', 'Nishanth', 'IND', 1, '1996-08-16', 2, 1, 'India'),
(136, 1117849, 'Ruturaj', 'Gaikwad', 'IND', 1, '1997-01-31', 1, 1, 'India'),
(137, 1235038, 'Prashant', 'Solanki', 'IND', 2, '2000-02-22', NULL, NULL, 'India'),
(138, 1321344, 'Subhranshu', 'Senapati', 'IND', 1, '1996-12-30', NULL, NULL, 'India'),
(139, 1354770, 'Mukesh', 'Choudhary', 'IND', 2, '1986-07-06', 2, 5, 'India'),
(140, 1423857, 'Tushar', 'Deshpande', 'IND', 2, '1995-05-15', NULL, NULL, 'India'),
(141, 1429671, 'KM', 'Asif', 'IND', 2, '1993-07-24', 1, 2, 'India'),
(142, 1600670, 'Simarjeet', 'Singh', 'IND', 2, '1998-01-17', NULL, NULL, 'India'),
(143, 1707115, 'Rajvardhan', 'Hangargekar', NULL, 2, '2002-11-10', NULL, NULL, NULL),
(144, 1726626, 'Morawakage Maheesh', 'Theekshana', 'LKA', 2, '2000-08-01', NULL, NULL, 'Sri Lanka'),
(145, 1969109, 'Matheesha', 'Pathirana', 'LKA', 2, '2002-12-18', NULL, NULL, 'Sri Lanka'),
(146, 2129114, 'K Bhagath', 'Varma', NULL, 3, '1998-09-21', NULL, NULL, NULL),
(147, 643154, 'Virat', 'Kohli', 'IND', 1, '1988-11-05', 1, 2, 'India'),
(148, 648088, 'Jason', 'Behrendorff', 'AUS', 2, '1990-04-20', 1, 13, 'Australia'),
(149, 655834, 'Dinesh', 'Karthik', 'IND', 4, '1985-06-01', 1, NULL, 'India'),
(150, 656636, 'Karn', 'Sharma', 'IND', 2, '1987-10-23', 2, 11, 'India'),
(151, 658586, 'David', 'Willey', 'ENG', 2, '1990-02-28', 2, 13, 'England'),
(152, 663378, 'Glenn', 'Maxwell', 'AUS', 3, '1988-10-14', 1, 1, 'Australia'),
(153, 663664, 'Siddarth', 'Kaul', 'IND', 2, '1990-05-19', 1, 2, 'India'),
(154, 683870, 'Harshal', 'Patel', 'IND', 2, '1990-11-23', 1, 2, 'India'),
(155, 699754, 'Faf', 'du Plessis', 'ZAF', 1, '1984-07-13', 1, 3, 'South Africa'),
(156, 737892, 'Chama', 'Milind', 'IND', 2, '1994-09-04', 2, 5, 'India'),
(157, 774669, 'Josh', 'Hazlewood', 'AUS', 2, '1991-01-08', 2, 9, 'Australia'),
(158, 980915, 'Mahipal', 'Lomror', 'IND', 3, '1999-11-16', 2, 6, 'India'),
(159, 1021407, 'Wanindu', 'Hasaranga', 'LKA', 3, '1997-07-29', NULL, NULL, 'Sri Lanka'),
(160, 1104247, 'Mohammed', 'Siraj', 'IND', 2, '1994-03-13', 1, 7, 'India'),
(161, 1322738, 'Rajat', 'Patidar', 'IND', 1, '1993-06-01', NULL, NULL, 'India'),
(162, 1325934, 'Anuj', 'Rawat', 'IND', 4, '1999-10-17', NULL, NULL, 'India'),
(163, 1344854, 'Sherfane', 'Rutherford', 'GUY', 1, '1998-08-15', NULL, NULL, 'Guyana'),
(164, 1389507, 'Finn', 'Allen', 'NZL', 4, '1999-04-22', NULL, NULL, 'New Zealand'),
(165, 1602982, 'Shahbaz', 'Ahmed', 'IND', 1, '1994-12-12', NULL, NULL, 'India'),
(166, 1602994, 'Suyash', 'Prabhudessai', 'IND', 1, '1997-12-06', NULL, NULL, 'India'),
(167, 1717659, 'Akash', 'Deep', NULL, 2, '1996-12-15', NULL, NULL, NULL),
(168, 2275737, '', 'Aneeshwar Gautam', NULL, 2, NULL, NULL, NULL, NULL),
(169, 648048, 'Mitchell', 'Marsh', 'AUS', 3, '1991-10-20', 1, 2, 'Australia'),
(170, 661550, 'Mustafizur', 'Rahman', 'BGD', 2, '1995-09-06', 2, 5, 'Bangladesh'),
(171, 686010, 'Mandeep', 'Singh', 'IND', 1, '1991-12-18', 1, 2, 'India'),
(172, 708026, 'Shardul', 'Thakur', 'IND', 2, '1991-10-16', 1, 2, 'India'),
(173, 709706, 'Anrich', 'Nortje', 'ZAF', 2, '1993-11-16', 1, 10, 'South Africa'),
(174, 723400, 'Srikar', 'Bharat', 'IND', 4, '1993-10-03', 1, NULL, 'India'),
(175, 726868, 'Lungi', 'Ngidi', 'ZAF', 2, '1996-03-29', 1, 7, 'South Africa'),
(176, 730072, 'Axar', 'Patel', 'IND', 3, '1994-01-20', 2, 6, 'India'),
(177, 731200, 'Kuldeep', 'Yadav', 'IND', 2, '1994-12-14', 2, 15, 'India'),
(178, 738744, 'Tim', 'Seifert', 'NZL', 4, '1994-12-14', 1, NULL, 'New Zealand'),
(179, 740154, 'Sarfaraz', 'Khan', 'IND', 1, '1997-10-27', 1, 1, 'India'),
(180, 748464, 'Praveen', 'Dubey', 'IND', 2, '1993-07-01', 1, 11, 'India'),
(181, 768877, 'David', 'Warner', 'AUS', 1, '1986-10-27', 2, 3, 'Australia'),
(182, 980911, 'Khaleel', 'Ahmed', 'IND', 2, '1997-12-05', 1, 5, 'India'),
(183, 980925, 'Rishabh', 'Pant', 'IND', 4, '1997-10-04', 2, NULL, 'India'),
(184, 1005501, 'Rovman', 'Powell', 'JAM', 1, '1993-07-23', 1, 9, 'Jamaica'),
(185, 1097792, 'Kamlesh', 'Nagarkoti', 'IND', 2, '1999-12-28', 1, 7, 'India'),
(186, 1097858, 'Prithvi', 'Shaw', 'IND', 1, '1999-11-09', 1, 1, 'India'),
(187, 1321352, 'Ashwin', 'Hebbar', 'IND', 3, '1995-11-15', NULL, NULL, 'India'),
(188, 1693393, 'Chetan', 'Sakariya', 'IND', 2, '1998-08-20', 2, 16, 'India'),
(189, 1889638, 'Ripal', 'Patel', 'IND', 1, '1995-09-28', NULL, NULL, 'India'),
(190, 1976535, 'Yash', 'Dhull', NULL, 1, NULL, NULL, NULL, NULL),
(191, 2029291, 'Lalit', 'Yadav', 'IND', 3, '1997-01-03', NULL, NULL, 'India'),
(192, 2275735, 'Vicky', 'Ostwal', NULL, 2, NULL, NULL, NULL, NULL),
(193, 650072, 'Pradeep', 'Sangwan', 'IND', 2, '1990-11-05', 1, 5, 'India'),
(194, 650188, 'Wriddhiman', 'Saha', 'IND', 4, '1984-10-24', 1, NULL, 'India'),
(195, 662292, 'David', 'Miller', 'ZAF', 1, '1989-06-10', 2, 1, 'South Africa'),
(196, 675214, 'Varun', 'Aaron', 'IND', 2, '1989-10-29', 1, 10, 'India'),
(197, 692718, 'Rahul', 'Tewatia', 'IND', 3, '1993-05-20', 2, 3, 'India'),
(198, 708454, 'Vijay', 'Shankar', 'IND', 3, '1991-01-26', 1, 1, 'India'),
(199, 709682, 'Mohammed', 'Shami', 'IND', 2, '1990-03-09', 1, 2, 'India'),
(200, 713202, 'Lockie', 'Ferguson', 'NZL', 2, '1991-06-13', 1, 10, 'New Zealand'),
(201, 725770, 'Gurkeerat', 'Singh', 'IND', 1, '1990-06-29', 1, 1, 'India'),
(202, 738620, 'Hardik', 'Pandya', 'IND', 3, '1993-10-11', 1, 16, 'India'),
(203, 741580, 'Alzarri', 'Joseph', 'ATG', 2, '1996-11-20', 1, 9, 'Antigua and Barbuda'),
(204, 774609, 'Matthew', 'Wade', 'AUS', 4, '1987-12-26', 2, 2, 'Australia'),
(205, 815518, 'Jayant', 'Yadav', 'IND', 2, '1990-01-22', 1, 14, 'India'),
(206, 968267, 'Rashid', 'Khan', 'AFG', 2, '1998-09-20', 1, 11, 'Afghanistan'),
(207, 1026129, 'R Sai', 'Kishore', 'IND', 3, '1996-11-06', 2, 6, 'India'),
(208, 1097864, 'Shubman', 'Gill', 'IND', 1, '1999-09-08', 1, 1, 'India'),
(209, 1381037, 'Rahmanullah', 'Gurbaz', 'AFG', 4, '2001-11-28', NULL, NULL, 'Afghanistan'),
(210, 1410673, 'Dominic', 'Drakes', 'BRB', 2, '1998-02-06', NULL, NULL, 'Barbados'),
(211, 1511871, 'Sai', 'Sudharsan', 'IND', 1, NULL, 2, 8, 'India'),
(212, 1603338, 'Yash', 'Dayal', 'IND', 2, '1997-12-13', NULL, NULL, 'India'),
(213, 1610942, 'Darshan', 'Nalkande', 'IND', 2, '1998-10-04', NULL, NULL, 'India'),
(214, 1712951, 'Noor', 'Ahmad', 'AFG', 2, '2005-01-03', NULL, NULL, 'Afghanistan'),
(215, 2323707, 'Abhinav', 'Sadarangani', 'IND', 1, '1994-09-16', NULL, NULL, 'India'),
(216, 652380, 'Manish', 'Pandey', 'IND', 1, '1989-09-10', 1, 1, 'India'),
(217, 661284, 'Shahbaz', 'Nadeem', 'IND', 2, '1989-08-12', 1, 6, 'India'),
(218, 663358, 'Marcus', 'Stoinis', 'AUS', 3, '1989-08-16', 1, 2, 'Australia'),
(219, 671908, 'Kyle', 'Mayers', 'BRB', 1, '1992-09-08', 2, 2, 'Barbados'),
(220, 680252, 'Quinton', 'de Kock', 'ZAF', 4, '1992-12-17', 2, NULL, 'South Africa'),
(221, 684188, 'Jason', 'Holder', 'BRB', 3, '1991-11-05', 1, 7, 'Barbados'),
(222, 692218, 'KL', 'Rahul', 'IND', 4, '1992-04-18', 1, NULL, 'India'),
(223, 692972, 'Krishnappa', 'Gowtham', 'IND', 3, '1988-10-20', 1, 1, 'India'),
(224, 695604, 'Evin', 'Lewis', 'TTO', 1, '1991-12-27', 2, NULL, 'Trinidad and Tobago'),
(225, 702818, 'Andrew', 'Tye', 'AUS', 2, '1986-12-12', 1, 7, 'Australia'),
(226, 706710, 'Krunal', 'Pandya', 'IND', 3, '1991-03-24', 2, 6, 'India'),
(227, 713934, 'Deepak', 'Hooda', 'IND', 3, '1995-04-19', 1, 1, 'India'),
(228, 724436, 'Manan', 'Vohra', 'IND', 1, '1993-07-18', 1, 2, 'India'),
(229, 729354, 'Dushmantha', 'Chameera', 'LKA', 2, '1992-01-11', 1, 7, 'Sri Lanka'),
(230, 735160, 'Ankit', 'Rajpoot', 'IND', 2, '1993-12-04', 1, 2, 'India'),
(231, 743036, 'Avesh', 'Khan', 'IND', 2, '1996-12-13', 1, 2, 'India'),
(232, 1430021, 'Mohsin', 'Khan', 'IND', 2, '1998-07-15', 2, 4, 'India'),
(233, 1710461, 'Ravi', 'Bishnoi', 'IND', 2, '2000-09-05', NULL, NULL, 'India'),
(234, 2114916, 'Ayush', 'Badoni', NULL, 1, '1999-12-03', NULL, NULL, NULL),
(235, 2115474, 'Karan', 'Sharma', 'IND', 3, '1998-10-31', NULL, NULL, 'India'),
(236, 2269801, 'Mayank', 'Yadav', NULL, 2, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `player_batting_style`
--

CREATE TABLE `player_batting_style` (
  `playerBattingStyleId` int(11) NOT NULL,
  `battingStyleString` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `player_batting_style`
--

INSERT INTO `player_batting_style` (`playerBattingStyleId`, `battingStyleString`) VALUES
(2, 'left_handed_batsman'),
(1, 'right_handed_batsman');

-- --------------------------------------------------------

--
-- Table structure for table `player_bowling_style`
--

CREATE TABLE `player_bowling_style` (
  `playerBowlingStyleId` int(11) NOT NULL,
  `playerBowlingStyleString` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `player_bowling_style`
--

INSERT INTO `player_bowling_style` (`playerBowlingStyleId`, `playerBowlingStyleString`) VALUES
(4, 'left_arm_fast'),
(13, 'left_arm_fast_medium'),
(5, 'left_arm_medium'),
(16, 'left_arm_medium_fast'),
(8, 'leg_break'),
(12, 'leg_break_googly'),
(11, 'leg_break_googly_right_arm'),
(3, 'leg_break_right_arm'),
(1, 'off_break_right_arm'),
(14, 'off_spin'),
(10, 'right_arm_fast'),
(9, 'right_arm_fast_medium'),
(2, 'right_arm_medium'),
(7, 'right_arm_medium_fast'),
(15, 'slow_left_arm_chinaman'),
(6, 'slow_left_arm_orthodox');

-- --------------------------------------------------------

--
-- Table structure for table `player_roles`
--

CREATE TABLE `player_roles` (
  `roleId` int(11) NOT NULL,
  `roleString` tinytext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `player_roles`
--

INSERT INTO `player_roles` (`roleId`, `roleString`) VALUES
(1, 'batsman'),
(2, 'bowler'),
(3, 'all_rounder'),
(4, 'wicket_keeper');

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

--
-- Dumping data for table `player_statistics_batting`
--

INSERT INTO `player_statistics_batting` (`playerId`, `type`, `matches`, `innings`, `ballFaced`, `notOuts`, `runs`, `average`, `strikeRate`, `highestScore`, `hundreds`, `fifties`, `fours`, `sixes`) VALUES
(1, 'first_class', 154, 263, 23259, 21, 12083, 49.92, 51.94, 284, 34, 60, 1416, 37),
(1, 'list_a', 212, 201, 10194, 22, 8294, 46.33, 81.36, 148, 17, 51, 729, 70),
(1, 'odi', 151, 144, 7551, 14, 6173, 47.48, 81.75, 148, 13, 39, 563, 49),
(1, 't20', 230, 221, 4742, 35, 5844, 31.41, 123.23, 101, 1, 41, 541, 148),
(1, 't20i', 74, 72, 1630, 10, 2021, 32.59, 123.98, 95, 0, 14, 202, 46),
(1, 'test', 86, 150, 14143, 14, 7272, 53.47, 51.41, 251, 24, 33, 803, 17),
(2, 'first_class', 70, 101, 5691, 11, 2433, 27.03, 42.75, 128, 1, 14, 314, 8),
(2, 'list_a', 168, 92, 0, 33, 1198, 20.3, 0, 72, 0, 3, 110, 13),
(2, 'odi', 121, 55, 747, 16, 552, 14.15, 73.89, 53, 0, 1, 46, 8),
(2, 't20', 218, 77, 402, 41, 374, 10.38, 93.03, 24, 0, 0, 26, 6),
(2, 't20i', 59, 13, 76, 8, 57, 11.4, 75, 16, 0, 0, 0, 0),
(2, 'test', 21, 29, 1225, 4, 552, 22.08, 45.06, 63, 0, 3, 77, 1),
(3, 'first_class', 67, 100, 5530, 18, 2718, 33.14, 49.15, 150, 4, 11, 314, 9),
(3, 'list_a', 47, 30, 465, 10, 434, 21.7, 93.33, 38, 0, 0, 38, 7),
(3, 't20', 83, 35, 323, 10, 389, 15.56, 120.43, 47, 0, 0, 39, 7),
(4, 'first_class', 47, 79, 4595, 4, 2540, 33.86, 55.27, 132, 7, 13, 310, 51),
(4, 'list_a', 43, 42, 1400, 3, 1209, 31, 86.35, 125, 1, 8, 114, 25),
(4, 't20', 115, 111, 1887, 17, 2523, 26.84, 133.7, 93, 0, 15, 237, 93),
(5, 'first_class', 9, 10, 833, 0, 436, 43.6, 52.34, 122, 1, 3, 55, 11),
(5, 'list_a', 23, 21, 540, 3, 536, 29.77, 99.25, 63, 0, 2, 39, 23),
(5, 't20', 41, 31, 333, 7, 482, 20.08, 144.74, 61, 0, 3, 36, 26),
(6, 'first_class', 66, 97, 3662, 9, 1935, 21.98, 52.84, 102, 1, 10, 198, 42),
(6, 'list_a', 70, 49, 737, 6, 766, 17.81, 103.93, 50, 0, 1, 58, 32),
(6, 'odi', 5, 5, 81, 0, 98, 19.6, 120.98, 49, 0, 0, 12, 1),
(6, 't20', 110, 67, 516, 17, 571, 11.42, 110.65, 41, 0, 0, 33, 23),
(6, 't20i', 8, 3, 17, 1, 17, 8.5, 100, 12, 0, 0, 1, 1),
(7, 'first_class', 69, 120, 8874, 7, 4419, 39.1, 49.79, 235, 10, 23, 510, 12),
(7, 'list_a', 45, 43, 2381, 5, 2078, 54.68, 87.27, 192, 7, 11, 208, 10),
(7, 't20', 23, 21, 291, 1, 275, 13.75, 94.5, 40, 0, 0, 27, 3),
(8, 'first_class', 17, 26, 880, 8, 284, 15.77, 32.27, 41, 0, 0, 24, 4),
(8, 'list_a', 27, 19, 284, 4, 233, 15.53, 82.04, 46, 0, 0, 22, 3),
(8, 't20', 71, 35, 237, 17, 299, 16.61, 126.16, 34, 0, 0, 24, 11),
(9, 'first_class', 84, 145, 10195, 8, 5973, 43.59, 58.58, 204, 17, 27, 850, 47),
(9, 'list_a', 85, 81, 3379, 3, 3276, 42, 96.95, 183, 10, 9, 345, 71),
(9, 'odi', 38, 35, 1038, 2, 899, 27.24, 86.6, 96, 0, 3, 99, 19),
(9, 't20', 81, 73, 1571, 14, 2058, 34.88, 130.99, 82, 0, 17, 179, 72),
(9, 't20i', 20, 18, 400, 3, 588, 39.2, 147, 70, 0, 6, 45, 28),
(9, 'test', 31, 57, 3403, 1, 1973, 35.23, 57.97, 152, 5, 9, 286, 10),
(10, 'first_class', 5, 10, 473, 0, 319, 31.9, 67.44, 69, 0, 2, 39, 10),
(10, 'list_a', 62, 57, 0, 10, 1784, 37.95, 0, 118, 1, 12, 158, 62),
(10, 'odi', 37, 34, 1134, 6, 1121, 40.03, 98.85, 118, 1, 8, 100, 36),
(10, 't20', 228, 207, 3193, 34, 4555, 26.32, 142.65, 100, 1, 25, 292, 313),
(10, 't20i', 57, 50, 925, 7, 1193, 27.74, 128.97, 70, 0, 8, 86, 69),
(11, 'first_class', 24, 40, 1228, 7, 751, 22.75, 61.15, 87, 0, 5, 114, 10),
(11, 'list_a', 16, 10, 122, 5, 119, 23.8, 97.54, 43, 0, 0, 14, 2),
(11, 'odi', 2, 1, 4, 0, 2, 2, 50, 2, 0, 0, 0, 0),
(11, 't20', 20, 11, 68, 3, 79, 9.87, 116.17, 47, 0, 0, 4, 5),
(11, 'test', 5, 8, 249, 2, 118, 19.66, 47.38, 37, 0, 0, 17, 0),
(12, 'first_class', 17, 24, 1523, 2, 798, 36.27, 52.39, 159, 1, 5, 90, 13),
(12, 'list_a', 50, 37, 797, 7, 632, 21.06, 79.29, 70, 0, 1, 42, 8),
(12, 'odi', 4, 2, 75, 0, 57, 28.5, 76, 33, 0, 0, 3, 1),
(12, 't20', 104, 65, 764, 19, 929, 20.19, 121.59, 54, 0, 2, 72, 30),
(12, 't20i', 31, 11, 32, 4, 47, 6.71, 146.87, 14, 0, 0, 4, 3),
(12, 'test', 4, 6, 502, 2, 265, 66.25, 52.78, 96, 0, 3, 31, 5),
(13, 'first_class', 23, 38, 1394, 3, 842, 24.05, 60.4, 193, 2, 1, 101, 10),
(13, 'list_a', 38, 38, 1607, 3, 1499, 42.82, 93.27, 139, 5, 4, 129, 66),
(13, 't20', 43, 39, 775, 7, 1096, 34.25, 141.41, 71, 0, 7, 87, 61),
(14, 'first_class', 21, 23, 163, 9, 29, 2.07, 17.79, 12, 0, 0, 3, 0),
(14, 'list_a', 17, 4, 12, 4, 7, 0, 58.33, 7, 0, 0, 1, 0),
(14, 'odi', 2, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0),
(14, 't20', 58, 5, 10, 4, 5, 5, 50, 3, 0, 0, 0, 0),
(14, 't20i', 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(14, 'test', 1, 1, 9, 1, 1, 0, 11.11, 1, 0, 0, 0, 0),
(15, 'first_class', 12, 20, 785, 2, 516, 28.66, 65.73, 98, 0, 3, 65, 12),
(15, 'list_a', 32, 31, 920, 3, 865, 30.89, 94.02, 169, 2, 2, 106, 27),
(15, 't20', 54, 52, 819, 9, 1122, 26.09, 136.99, 107, 1, 6, 103, 48),
(16, 'first_class', 15, 22, 2075, 3, 1168, 61.47, 56.28, 206, 3, 6, 147, 7),
(16, 'list_a', 29, 28, 1071, 3, 1004, 40.16, 93.74, 120, 3, 6, 107, 18),
(16, 't20', 38, 32, 451, 3, 518, 17.86, 114.85, 59, 0, 3, 37, 15),
(17, 'first_class', 44, 76, 4165, 6, 2736, 39.08, 65.69, 138, 6, 18, 351, 72),
(17, 'list_a', 47, 47, 1843, 2, 1627, 36.15, 88.28, 156, 5, 3, 178, 47),
(17, 't20', 155, 147, 2928, 18, 4107, 31.83, 140.26, 116, 4, 25, 322, 226),
(17, 't20i', 35, 30, 460, 5, 645, 25.8, 140.21, 108, 1, 2, 43, 37),
(17, 'test', 1, 2, 119, 0, 52, 26, 43.69, 52, 0, 1, 6, 1),
(18, 'first_class', 13, 22, 742, 2, 825, 41.25, 111.18, 128, 3, 4, 81, 46),
(18, 'list_a', 16, 16, 278, 0, 342, 21.37, 123.02, 68, 0, 4, 27, 20),
(18, 't20', 46, 38, 508, 10, 733, 26.17, 144.29, 76, 0, 3, 45, 46),
(19, 'first_class', 2, 4, 51, 2, 14, 7, 27.45, 7, 0, 0, 2, 0),
(19, 'list_a', 7, 5, 59, 4, 20, 20, 33.89, 8, 0, 0, 1, 0),
(19, 't20', 16, 7, 16, 3, 13, 3.25, 81.25, 7, 0, 0, 1, 0),
(20, 'first_class', 25, 35, 1357, 5, 793, 26.43, 58.43, 133, 1, 4, 81, 22),
(20, 'list_a', 40, 30, 479, 10, 398, 19.9, 83.08, 58, 0, 2, 39, 7),
(20, 'odi', 10, 6, 88, 0, 80, 13.33, 90.9, 50, 0, 1, 8, 1),
(20, 't20', 49, 25, 242, 10, 376, 25.06, 155.37, 72, 0, 1, 22, 29),
(20, 't20i', 17, 6, 94, 3, 146, 48.66, 155.31, 44, 0, 0, 6, 13),
(21, 'first_class', 4, 7, 75, 1, 27, 4.5, 36, 20, 0, 0, 4, 1),
(21, 'list_a', 2, 2, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0),
(22, 'first_class', 3, 3, 12, 1, 16, 8, 133.33, 8, 0, 0, 4, 0),
(22, 'list_a', 1, 1, 8, 0, 14, 14, 175, 14, 0, 0, 0, 2),
(22, 't20', 19, 4, 3, 3, 2, 2, 66.66, 1, 0, 0, 0, 0),
(23, 'first_class', 12, 18, 119, 9, 48, 5.33, 40.33, 17, 0, 0, 6, 3),
(23, 'list_a', 10, 5, 15, 2, 8, 2.66, 53.33, 7, 0, 0, 0, 1),
(23, 'odi', 4, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0),
(23, 't20', 8, 3, 10, 2, 2, 2, 20, 2, 0, 0, 0, 0),
(23, 't20i', 3, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0),
(24, 'first_class', 27, 44, 0, 2, 1584, 37.71, 0, 174, 4, 7, 0, 0),
(24, 'list_a', 167, 151, 0, 14, 3642, 26.58, 0, 119, 3, 19, 0, 0),
(24, 'odi', 123, 113, 2866, 9, 2706, 26.01, 94.41, 119, 3, 13, 171, 135),
(24, 't20', 592, 526, 7658, 154, 11571, 31.1, 151.09, 104, 1, 56, 729, 773),
(24, 't20i', 101, 83, 1161, 21, 1569, 25.3, 135.14, 75, 0, 6, 94, 99),
(25, 'first_class', 106, 168, 13264, 18, 8123, 54.15, 61.24, 309, 25, 34, 934, 141),
(25, 'list_a', 301, 290, 0, 40, 11525, 46.1, 0, 264, 32, 57, 1053, 286),
(25, 'odi', 230, 223, 10428, 32, 9283, 48.6, 89.01, 264, 29, 44, 845, 245),
(25, 't20', 381, 368, 7558, 47, 10095, 31.44, 133.56, 118, 6, 69, 893, 431),
(25, 't20i', 125, 117, 2374, 15, 3313, 32.48, 139.55, 118, 4, 26, 293, 155),
(25, 'test', 45, 77, 5625, 9, 3137, 46.13, 55.76, 212, 8, 14, 335, 64),
(26, 'first_class', 92, 118, 3199, 28, 1581, 17.56, 49.42, 92, 0, 6, 160, 36),
(26, 'list_a', 106, 56, 578, 14, 422, 10.04, 73.01, 57, 0, 1, 29, 16),
(26, 'odi', 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(26, 't20', 163, 61, 357, 32, 477, 16.44, 133.61, 58, 0, 1, 32, 24),
(26, 't20i', 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(26, 'test', 1, 2, 15, 1, 2, 2, 13.33, 1, 0, 0, 0, 0),
(27, 'first_class', 4, 3, 133, 2, 25, 25, 18.79, 23, 0, 0, 2, 1),
(27, 'list_a', 23, 14, 128, 5, 93, 10.33, 72.65, 25, 0, 0, 6, 1),
(27, 't20', 93, 30, 157, 13, 131, 7.7, 83.43, 34, 0, 0, 5, 4),
(28, 'first_class', 8, 10, 779, 0, 465, 46.5, 59.69, 132, 2, 1, 51, 9),
(28, 'list_a', 12, 11, 371, 0, 310, 28.18, 83.55, 82, 0, 1, 23, 5),
(28, 't20', 17, 17, 322, 4, 506, 38.92, 157.14, 80, 0, 3, 25, 32),
(29, 'first_class', 57, 74, 971, 36, 354, 9.31, 36.45, 55, 0, 1, 41, 5),
(29, 'list_a', 95, 32, 145, 19, 108, 8.3, 74.48, 42, 0, 0, 10, 4),
(29, 'odi', 70, 19, 87, 12, 45, 6.42, 51.72, 14, 0, 0, 5, 1),
(29, 't20', 204, 35, 101, 24, 90, 8.18, 89.1, 16, 0, 0, 6, 3),
(29, 't20i', 57, 6, 13, 4, 8, 4, 61.53, 7, 0, 0, 1, 0),
(29, 'test', 29, 44, 419, 16, 174, 6.21, 41.52, 34, 0, 0, 20, 3),
(30, 'first_class', 43, 63, 1794, 10, 1201, 22.66, 66.94, 81, 0, 6, 146, 25),
(30, 'list_a', 31, 20, 192, 8, 219, 18.25, 114.06, 45, 0, 0, 16, 9),
(30, 'odi', 17, 9, 34, 5, 27, 6.75, 79.41, 8, 0, 0, 2, 0),
(30, 't20', 121, 61, 373, 29, 551, 17.21, 147.72, 36, 0, 0, 41, 24),
(30, 't20i', 12, 2, 10, 1, 19, 19, 190, 18, 0, 0, 2, 1),
(30, 'test', 13, 20, 306, 0, 155, 7.75, 50.65, 30, 0, 0, 22, 1),
(31, 'first_class', 15, 27, 1242, 2, 776, 31.04, 62.47, 169, 2, 4, 80, 17),
(31, 'list_a', 36, 30, 546, 7, 476, 20.69, 87.17, 62, 0, 2, 38, 17),
(31, 'odi', 20, 16, 203, 3, 200, 15.38, 98.52, 51, 0, 1, 18, 8),
(31, 't20', 70, 56, 512, 20, 758, 21.05, 148.04, 64, 0, 2, 52, 52),
(31, 't20i', 34, 24, 195, 8, 267, 16.68, 136.92, 34, 0, 0, 15, 21),
(32, 'first_class', 46, 78, 4080, 5, 2805, 38.42, 68.75, 273, 5, 16, 346, 66),
(32, 'list_a', 80, 77, 2860, 5, 2637, 36.62, 92.2, 173, 4, 13, 257, 87),
(32, 'odi', 3, 3, 82, 0, 88, 29.33, 107.31, 59, 0, 1, 10, 3),
(32, 't20', 126, 120, 2469, 9, 3223, 29.03, 130.53, 113, 2, 19, 314, 137),
(32, 't20i', 10, 10, 238, 1, 289, 32.11, 121.42, 89, 0, 2, 34, 8),
(33, 'first_class', 38, 52, 928, 7, 532, 11.82, 57.32, 60, 0, 2, 76, 10),
(33, 'list_a', 31, 16, 95, 6, 64, 6.4, 67.36, 12, 0, 0, 3, 1),
(33, 't20', 73, 18, 64, 11, 67, 9.57, 104.68, 22, 0, 0, 4, 3),
(34, 'first_class', 77, 129, 8496, 8, 5326, 44.01, 62.68, 200, 14, 26, 756, 52),
(34, 'list_a', 109, 98, 2998, 15, 3121, 37.6, 104.1, 134, 3, 19, 311, 88),
(34, 'odi', 7, 7, 259, 2, 267, 53.4, 103.08, 64, 0, 2, 33, 1),
(34, 't20', 206, 184, 3187, 41, 4538, 31.73, 142.39, 94, 0, 28, 468, 162),
(34, 't20i', 14, 12, 212, 3, 351, 39, 165.56, 65, 0, 4, 32, 20),
(35, 'first_class', 9, 14, 831, 1, 603, 46.38, 72.56, 254, 1, 2, 57, 26),
(35, 'list_a', 13, 11, 349, 3, 364, 45.5, 104.29, 81, 0, 3, 19, 22),
(35, 't20', 27, 23, 398, 5, 494, 27.44, 124.12, 55, 0, 2, 26, 27),
(36, 'first_class', 2, 4, 169, 1, 124, 41.33, 73.37, 69, 0, 1, 15, 1),
(36, 'list_a', 10, 7, 211, 1, 141, 23.5, 66.82, 62, 0, 1, 12, 3),
(36, 't20', 15, 10, 100, 1, 116, 12.88, 116, 54, 0, 1, 6, 6),
(37, 'first_class', 20, 27, 419, 18, 124, 13.77, 29.59, 20, 0, 0, 15, 1),
(37, 'list_a', 24, 12, 62, 9, 18, 6, 29.03, 5, 0, 0, 0, 0),
(37, 'odi', 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0),
(37, 't20', 60, 11, 24, 5, 23, 3.83, 95.83, 10, 0, 0, 2, 0),
(37, 't20i', 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(38, 'first_class', 30, 45, 2911, 3, 1858, 44.23, 63.82, 267, 5, 9, 242, 19),
(38, 'list_a', 37, 33, 1421, 2, 1227, 39.58, 86.34, 141, 3, 7, 131, 26),
(38, 't20', 39, 31, 484, 2, 516, 17.79, 106.61, 84, 0, 2, 36, 16),
(39, 'first_class', 5, 10, 280, 0, 255, 25.5, 91.07, 88, 0, 2, 22, 12),
(39, 'list_a', 14, 11, 283, 0, 302, 27.45, 106.71, 62, 0, 2, 17, 17),
(39, 't20', 82, 66, 484, 14, 722, 13.88, 149.17, 98, 0, 3, 41, 48),
(39, 't20i', 7, 5, 38, 2, 72, 24, 189.47, 41, 0, 0, 6, 4),
(40, 'first_class', 8, 12, 816, 1, 371, 33.72, 45.46, 109, 1, 3, 45, 0),
(40, 'list_a', 20, 20, 718, 2, 532, 29.55, 74.09, 120, 1, 3, 49, 4),
(40, 't20', 7, 5, 54, 1, 67, 16.75, 124.07, 23, 0, 0, 6, 1),
(41, 'list_a', 16, 14, 605, 5, 745, 82.77, 123.14, 140, 2, 5, 69, 28),
(41, 't20', 92, 87, 1277, 27, 2040, 34, 159.74, 92, 0, 9, 149, 119),
(41, 't20i', 14, 14, 352, 2, 558, 46.5, 158.52, 92, 0, 4, 50, 26),
(42, 'first_class', 19, 22, 749, 3, 332, 17.47, 44.32, 76, 0, 2, 36, 1),
(42, 'list_a', 50, 22, 196, 9, 171, 13.15, 87.24, 32, 0, 0, 15, 3),
(42, 't20', 43, 16, 69, 11, 78, 15.6, 113.04, 33, 0, 0, 8, 1),
(42, 't20i', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(43, 'first_class', 9, 13, 254, 2, 80, 7.27, 31.49, 19, 0, 0, 7, 3),
(43, 'list_a', 19, 15, 136, 6, 75, 8.33, 55.14, 21, 0, 0, 4, 2),
(43, 't20', 11, 3, 10, 1, 7, 3.5, 70, 4, 0, 0, 0, 0),
(44, 'first_class', 4, 8, 449, 0, 255, 31.87, 56.79, 90, 0, 2, 30, 4),
(44, 'list_a', 16, 16, 813, 1, 784, 52.26, 96.43, 156, 3, 3, 58, 30),
(44, 't20', 26, 26, 510, 4, 715, 32.5, 140.19, 75, 0, 5, 51, 32),
(45, 't20', 2, 2, 7, 1, 3, 3, 42.85, 3, 0, 0, 0, 0),
(46, 'list_a', 8, 3, 40, 0, 24, 8, 60, 16, 0, 0, 2, 0),
(46, 't20', 3, 2, 25, 1, 25, 25, 100, 25, 0, 0, 3, 0),
(47, 'first_class', 3, 6, 196, 0, 123, 20.5, 62.75, 52, 0, 1, 15, 3),
(47, 'list_a', 5, 5, 127, 0, 111, 22.2, 87.4, 49, 0, 0, 9, 6),
(47, 't20', 12, 12, 163, 5, 222, 31.71, 136.19, 38, 0, 0, 21, 7),
(48, 'list_a', 2, 2, 44, 1, 54, 54, 122.72, 54, 0, 1, 4, 4),
(48, 't20', 15, 15, 245, 1, 331, 23.64, 135.1, 49, 0, 0, 31, 17),
(49, 'first_class', 13, 18, 0, 6, 213, 17.75, 0, 40, 0, 0, 0, 0),
(49, 'list_a', 100, 69, 0, 17, 625, 12.01, 0, 51, 0, 1, 0, 0),
(49, 'odi', 65, 45, 441, 12, 363, 11, 82.31, 36, 0, 0, 36, 12),
(49, 't20', 395, 237, 1978, 45, 2913, 15.17, 147.27, 79, 0, 11, 284, 174),
(49, 't20i', 51, 23, 138, 8, 155, 10.33, 112.31, 30, 0, 0, 13, 5),
(49, 'test', 6, 7, 92, 2, 40, 8, 43.47, 22, 0, 0, 4, 1),
(50, 'first_class', 126, 170, 3163, 16, 2596, 16.85, 82.07, 156, 1, 7, 265, 99),
(50, 'list_a', 157, 97, 827, 33, 833, 13.01, 100.72, 66, 0, 2, 67, 32),
(50, 'odi', 143, 86, 696, 32, 679, 12.57, 97.55, 55, 0, 1, 53, 26),
(50, 't20', 223, 106, 582, 34, 829, 11.51, 142.44, 74, 0, 2, 61, 46),
(50, 't20i', 92, 36, 175, 14, 249, 11.31, 142.28, 39, 0, 0, 16, 16),
(50, 'test', 85, 120, 2146, 11, 1769, 16.22, 82.43, 77, 0, 5, 173, 75),
(51, 'first_class', 79, 133, 9786, 15, 5946, 50.38, 60.76, 186, 19, 31, 673, 128),
(51, 'list_a', 67, 65, 2825, 2, 2346, 37.23, 83.04, 150, 8, 12, 257, 52),
(51, 't20', 70, 67, 1276, 11, 1534, 27.39, 120.21, 106, 1, 10, 148, 56),
(52, 'first_class', 35, 57, 2482, 4, 1284, 24.22, 51.73, 117, 2, 5, 136, 41),
(52, 'list_a', 165, 149, 4404, 15, 3873, 28.9, 87.94, 146, 3, 18, 251, 130),
(52, 'odi', 130, 116, 3374, 12, 2869, 27.58, 85.03, 116, 1, 15, 182, 89),
(52, 't20', 323, 275, 3572, 53, 4963, 22.35, 138.94, 89, 0, 14, 344, 249),
(52, 't20i', 88, 81, 1082, 14, 1539, 22.97, 142.23, 89, 0, 4, 103, 85),
(52, 'test', 3, 6, 68, 0, 33, 5.5, 48.52, 24, 0, 0, 4, 1),
(53, 'first_class', 17, 24, 0, 1, 609, 26.47, 0, 128, 2, 0, 0, 0),
(53, 'list_a', 93, 78, 0, 18, 1953, 32.55, 0, 132, 2, 8, 0, 0),
(53, 'odi', 56, 47, 794, 9, 1034, 27.21, 130.22, 92, 0, 4, 94, 57),
(53, 't20', 410, 350, 4037, 91, 6855, 26.46, 169.8, 121, 2, 26, 465, 550),
(53, 't20i', 67, 57, 475, 19, 741, 19.5, 156, 51, 0, 1, 42, 62),
(53, 'test', 1, 1, 9, 0, 2, 2, 22.22, 2, 0, 0, 0, 0),
(54, 'first_class', 167, 285, 22545, 27, 11981, 46.43, 53.14, 265, 36, 53, 1459, 77),
(54, 'list_a', 167, 163, 0, 10, 6054, 39.56, 0, 187, 10, 42, 598, 74),
(54, 'odi', 90, 87, 3767, 3, 2962, 35.26, 78.63, 111, 3, 24, 293, 33),
(54, 't20', 218, 208, 4600, 20, 5500, 29.25, 119.56, 105, 2, 40, 571, 108),
(54, 't20i', 20, 20, 331, 2, 375, 20.83, 113.29, 61, 0, 1, 32, 6),
(54, 'test', 82, 140, 9972, 12, 4931, 38.52, 49.44, 188, 12, 25, 560, 34),
(55, 'first_class', 75, 110, 5568, 11, 3357, 33.9, 60.29, 171, 6, 15, 480, 11),
(55, 'list_a', 100, 87, 2912, 15, 3030, 42.08, 104.05, 175, 7, 20, 316, 51),
(55, 'odi', 25, 20, 657, 2, 607, 33.72, 92.38, 118, 1, 4, 68, 6),
(55, 't20', 213, 200, 3130, 30, 4109, 24.17, 131.27, 95, 0, 24, 343, 130),
(55, 't20i', 37, 33, 368, 5, 478, 17.07, 129.89, 87, 0, 2, 41, 16),
(55, 'test', 1, 2, 57, 0, 30, 15, 52.63, 29, 0, 0, 6, 0),
(56, 'first_class', 10, 15, 1003, 0, 545, 36.33, 54.33, 93, 0, 6, 62, 7),
(56, 'list_a', 32, 30, 1183, 4, 1252, 48.15, 105.83, 198, 4, 4, 91, 42),
(56, 'odi', 2, 2, 40, 0, 24, 12, 60, 22, 0, 0, 0, 1),
(56, 't20', 73, 64, 1165, 19, 1557, 34.6, 133.64, 88, 0, 8, 153, 57),
(56, 't20i', 9, 7, 82, 3, 133, 33.25, 162.19, 35, 0, 0, 15, 5),
(57, 'first_class', 56, 81, 7278, 10, 3788, 53.35, 52.04, 200, 12, 19, 427, 22),
(57, 'list_a', 41, 37, 1274, 11, 1154, 44.38, 90.58, 101, 1, 8, 84, 16),
(57, 't20', 23, 21, 335, 2, 340, 17.89, 101.49, 46, 0, 0, 22, 5),
(58, 'first_class', 41, 63, 4248, 4, 2436, 41.28, 57.34, 174, 6, 11, 317, 38),
(58, 'list_a', 62, 60, 2312, 10, 1951, 39.02, 84.38, 137, 3, 11, 195, 52),
(58, 'odi', 1, 1, 14, 0, 7, 7, 50, 7, 0, 0, 0, 0),
(58, 't20', 151, 140, 2568, 15, 3477, 27.81, 135.39, 97, 0, 24, 293, 187),
(58, 't20i', 2, 2, 27, 0, 15, 7.5, 55.55, 9, 0, 0, 0, 0),
(59, 'first_class', 39, 58, 1619, 4, 1314, 24.33, 81.16, 100, 1, 9, 135, 44),
(59, 'list_a', 73, 53, 1036, 22, 923, 29.77, 89.09, 63, 0, 2, 48, 27),
(59, 'odi', 13, 12, 319, 5, 269, 38.42, 84.32, 44, 0, 0, 13, 5),
(59, 't20', 59, 48, 396, 24, 466, 19.41, 117.67, 75, 0, 1, 35, 17),
(59, 't20i', 22, 18, 130, 9, 144, 16, 110.76, 24, 0, 0, 4, 8),
(59, 'test', 1, 2, 43, 0, 22, 11, 51.16, 22, 0, 0, 4, 0),
(60, 'first_class', 58, 99, 6209, 4, 4980, 52.42, 80.2, 202, 13, 26, 585, 117),
(60, 'list_a', 108, 103, 4298, 10, 4110, 44.19, 95.62, 148, 8, 26, 368, 107),
(60, 'odi', 26, 24, 986, 1, 947, 41.17, 96.04, 103, 1, 9, 93, 17),
(60, 't20', 176, 172, 3642, 29, 4745, 33.18, 130.28, 147, 2, 30, 399, 186),
(60, 't20i', 36, 32, 572, 10, 809, 36.77, 141.43, 74, 0, 6, 70, 29),
(60, 'test', 4, 7, 578, 0, 388, 55.42, 67.12, 105, 1, 3, 46, 9),
(61, 'first_class', 30, 46, 3284, 10, 2307, 64.08, 70.24, 163, 5, 16, 266, 24),
(61, 'list_a', 42, 39, 1514, 11, 1414, 50.5, 93.39, 104, 1, 12, 129, 34),
(61, 't20', 66, 61, 812, 16, 1110, 24.66, 136.7, 63, 0, 5, 94, 42),
(62, 'first_class', 102, 121, 1562, 48, 1056, 14.46, 67.6, 128, 1, 1, 109, 47),
(62, 'list_a', 118, 52, 297, 25, 284, 10.51, 95.62, 30, 0, 0, 24, 15),
(62, 'odi', 75, 24, 134, 14, 79, 7.9, 58.95, 18, 0, 0, 8, 1),
(62, 't20', 161, 56, 212, 31, 266, 10.64, 125.47, 26, 0, 0, 20, 17),
(62, 't20i', 7, 1, 4, 0, 2, 2, 50, 2, 0, 0, 0, 0),
(62, 'test', 52, 61, 822, 26, 408, 11.65, 49.63, 31, 0, 0, 37, 20),
(63, 'first_class', 55, 75, 2689, 17, 1167, 20.12, 43.39, 82, 0, 5, 128, 16),
(63, 'list_a', 94, 59, 623, 19, 496, 12.4, 79.61, 49, 0, 0, 35, 11),
(63, 'odi', 69, 44, 387, 15, 285, 9.82, 73.64, 36, 0, 0, 20, 5),
(63, 't20', 117, 65, 459, 27, 645, 16.97, 140.52, 66, 0, 3, 38, 39),
(63, 't20i', 39, 16, 52, 7, 68, 7.55, 130.76, 13, 0, 0, 3, 4),
(63, 'test', 41, 58, 2114, 9, 833, 17, 39.4, 63, 0, 2, 85, 14),
(64, 'first_class', 88, 143, 7979, 6, 4915, 35.87, 61.59, 288, 7, 33, 561, 73),
(64, 'list_a', 222, 218, 9799, 9, 8620, 41.24, 87.96, 188, 23, 50, 828, 222),
(64, 'odi', 135, 131, 5957, 3, 5255, 41.05, 88.21, 153, 17, 29, 518, 127),
(64, 't20', 353, 347, 7573, 33, 10585, 33.71, 139.77, 172, 8, 70, 1014, 426),
(64, 't20i', 89, 89, 1892, 10, 2741, 34.69, 144.87, 172, 2, 16, 273, 113),
(64, 'test', 5, 10, 618, 0, 278, 27.8, 44.98, 62, 0, 2, 30, 1),
(65, 'first_class', 16, 27, 1724, 2, 738, 29.52, 42.8, 98, 0, 5, 96, 4),
(65, 'list_a', 20, 20, 1115, 1, 785, 41.31, 70.4, 129, 1, 5, 74, 13),
(65, 't20', 27, 27, 649, 2, 829, 33.16, 127.73, 89, 0, 6, 84, 23),
(66, 'first_class', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(66, 'list_a', 9, 5, 74, 2, 60, 20, 81.08, 32, 0, 0, 3, 3),
(66, 't20', 46, 11, 39, 7, 24, 6, 61.53, 10, 0, 0, 2, 0),
(66, 't20i', 6, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(67, 'list_a', 9, 9, 546, 1, 389, 48.62, 71.24, 104, 1, 2, 38, 8),
(67, 't20', 5, 5, 89, 0, 65, 13, 73.03, 28, 0, 0, 7, 0),
(68, 'first_class', 6, 6, 252, 0, 115, 19.16, 45.63, 42, 0, 0, 15, 0),
(68, 'list_a', 31, 15, 140, 2, 101, 7.76, 72.14, 22, 0, 0, 9, 1),
(68, 't20', 39, 15, 71, 4, 57, 5.18, 80.28, 20, 0, 0, 4, 2),
(69, 'first_class', 17, 28, 1168, 2, 729, 28.03, 62.41, 153, 2, 3, 76, 15),
(69, 'list_a', 32, 27, 662, 3, 695, 28.95, 104.98, 96, 0, 3, 49, 32),
(69, 't20', 33, 25, 217, 10, 304, 20.26, 140.09, 47, 0, 0, 17, 17),
(70, 'list_a', 3, 1, 18, 0, 25, 25, 138.88, 25, 0, 0, 2, 1),
(70, 't20', 6, 6, 30, 2, 45, 11.25, 150, 18, 0, 0, 4, 2),
(73, 't20', 2, 2, 2, 1, 2, 2, 100, 2, 0, 0, 0, 0),
(74, 'first_class', 86, 136, 6215, 13, 3378, 27.46, 54.35, 163, 2, 18, 405, 43),
(74, 'list_a', 86, 72, 2260, 14, 2050, 35.34, 90.7, 122, 1, 13, 138, 53),
(74, 't20', 148, 124, 1593, 35, 2060, 23.14, 129.31, 57, 0, 6, 151, 76),
(75, 'first_class', 122, 202, 14372, 10, 8499, 44.26, 59.13, 224, 25, 29, 1146, 43),
(75, 'list_a', 282, 278, 0, 21, 11464, 44.6, 0, 248, 30, 62, 1440, 117),
(75, 'odi', 149, 146, 6730, 8, 6284, 45.53, 93.37, 143, 17, 35, 783, 74),
(75, 't20', 314, 311, 7344, 32, 9156, 32.81, 124.67, 106, 2, 66, 1027, 209),
(75, 't20i', 68, 66, 1392, 3, 1759, 27.92, 126.36, 92, 0, 11, 191, 50),
(75, 'test', 34, 58, 3458, 1, 2315, 40.61, 66.94, 190, 7, 5, 316, 12),
(76, 'first_class', 83, 114, 5884, 20, 3726, 39.63, 63.32, 128, 4, 30, 515, 21),
(76, 'list_a', 110, 91, 2521, 30, 2385, 39.09, 94.6, 117, 1, 14, 235, 39),
(76, 'odi', 3, 2, 13, 1, 12, 12, 92.3, 9, 0, 0, 1, 0),
(76, 't20', 105, 84, 1224, 38, 1449, 31.5, 118.38, 65, 0, 3, 134, 30),
(76, 't20i', 1, 1, 2, 1, 1, 0, 50, 1, 0, 0, 0, 0),
(77, 'first_class', 196, 327, 0, 35, 12449, 42.63, 0, 246, 26, 64, 0, 0),
(77, 'list_a', 157, 143, 5215, 14, 5420, 42.01, 103.93, 174, 14, 24, 549, 148),
(77, 'odi', 89, 81, 3331, 8, 3498, 47.91, 105.01, 141, 11, 14, 391, 89),
(77, 't20', 172, 159, 2879, 26, 3912, 29.41, 135.88, 114, 3, 21, 340, 163),
(77, 't20i', 63, 57, 876, 12, 1190, 26.44, 135.84, 86, 0, 7, 111, 49),
(77, 'test', 83, 148, 8815, 9, 4801, 34.53, 54.46, 167, 8, 22, 559, 33),
(78, 'first_class', 77, 121, 4554, 9, 4087, 36.49, 89.74, 268, 9, 21, 421, 158),
(78, 'list_a', 121, 115, 3129, 11, 3040, 29.23, 97.15, 117, 4, 17, 308, 104),
(78, 'odi', 5, 5, 85, 0, 89, 17.8, 104.7, 65, 0, 1, 14, 2),
(78, 't20', 112, 98, 1541, 10, 2113, 24.01, 137.11, 96, 0, 10, 175, 109),
(78, 't20i', 18, 15, 235, 3, 320, 26.66, 136.17, 77, 0, 2, 25, 18),
(79, 'first_class', 3, 5, 177, 1, 152, 38, 85.87, 123, 1, 0, 26, 1),
(79, 'list_a', 18, 17, 620, 2, 568, 37.86, 91.61, 167, 1, 3, 50, 24),
(79, 't20', 31, 31, 612, 6, 836, 33.44, 136.6, 119, 1, 5, 79, 40),
(80, 'first_class', 77, 134, 9654, 6, 5675, 44.33, 58.78, 304, 12, 30, 742, 70),
(80, 'list_a', 89, 89, 4045, 3, 4085, 47.5, 100.98, 176, 13, 15, 499, 74),
(80, 'odi', 5, 5, 83, 0, 86, 17.2, 103.61, 32, 0, 0, 12, 1),
(80, 't20', 174, 168, 3050, 11, 4093, 26.07, 134.19, 111, 2, 25, 402, 147),
(80, 'test', 21, 36, 2782, 0, 1488, 41.33, 53.48, 243, 4, 6, 189, 28),
(81, 'first_class', 62, 94, 5162, 14, 3069, 38.36, 59.45, 224, 7, 15, 384, 31),
(81, 'list_a', 58, 49, 1624, 4, 1624, 36.08, 100, 129, 1, 10, 117, 64),
(81, 'odi', 3, 3, 64, 1, 72, 36, 112.5, 36, 0, 0, 5, 4),
(81, 't20', 169, 160, 2829, 12, 4077, 27.54, 144.11, 103, 2, 23, 287, 241),
(81, 't20i', 17, 13, 180, 1, 285, 23.75, 158.33, 103, 1, 0, 14, 20),
(82, 'first_class', 46, 63, 1417, 9, 560, 10.37, 39.52, 51, 0, 1, 72, 0),
(82, 'list_a', 55, 27, 259, 17, 189, 18.9, 72.97, 26, 0, 0, 15, 1),
(82, 't20', 152, 38, 114, 29, 101, 11.22, 88.59, 13, 0, 0, 8, 0),
(82, 't20i', 2, 1, 1, 1, 1, 0, 100, 1, 0, 0, 0, 0),
(83, 'first_class', 17, 24, 338, 9, 87, 5.8, 25.73, 19, 0, 0, 12, 2),
(83, 'list_a', 10, 2, 11, 2, 13, 0, 118.18, 12, 0, 0, 3, 0),
(83, 't20', 22, 6, 15, 2, 15, 3.75, 100, 5, 0, 0, 2, 0),
(84, 'first_class', 71, 100, 2010, 16, 998, 11.88, 49.65, 48, 0, 0, 137, 18),
(84, 'list_a', 103, 45, 453, 18, 364, 13.48, 80.35, 31, 0, 0, 32, 7),
(84, 'odi', 85, 35, 381, 15, 315, 15.75, 82.67, 31, 0, 0, 26, 7),
(84, 't20', 145, 56, 351, 26, 379, 12.63, 107.97, 44, 0, 0, 35, 12),
(84, 't20i', 40, 15, 104, 11, 121, 30.25, 116.34, 22, 0, 0, 11, 5),
(84, 'test', 52, 79, 1607, 13, 786, 11.9, 48.91, 47, 0, 0, 108, 14),
(85, 'first_class', 16, 28, 1353, 2, 698, 26.84, 51.58, 216, 2, 1, 78, 4),
(85, 'list_a', 20, 19, 360, 3, 293, 18.31, 81.38, 35, 0, 0, 17, 7),
(85, 't20', 27, 15, 200, 3, 262, 21.83, 131, 51, 0, 1, 21, 10),
(86, 'first_class', 8, 13, 722, 2, 516, 46.9, 71.46, 194, 1, 3, 51, 16),
(86, 'list_a', 33, 24, 573, 7, 737, 43.35, 128.62, 79, 0, 7, 55, 40),
(86, 't20', 57, 46, 499, 14, 645, 20.15, 129.25, 47, 0, 0, 40, 41),
(87, 'first_class', 16, 23, 1091, 0, 553, 24.04, 50.68, 61, 0, 3, 79, 3),
(87, 'list_a', 41, 38, 1636, 1, 1266, 34.21, 77.38, 107, 2, 7, 140, 16),
(87, 't20', 63, 58, 1034, 6, 1491, 28.67, 144.19, 106, 1, 8, 157, 59),
(88, 'first_class', 18, 20, 521, 3, 353, 20.76, 67.75, 84, 0, 1, 37, 11),
(88, 'list_a', 40, 28, 307, 8, 257, 12.85, 83.71, 48, 0, 0, 12, 13),
(88, 'odi', 1, 1, 25, 0, 13, 13, 52, 13, 0, 0, 0, 0),
(88, 't20', 82, 32, 142, 13, 142, 7.47, 100, 22, 0, 0, 14, 3),
(88, 't20i', 6, 1, 5, 0, 5, 5, 100, 5, 0, 0, 1, 0),
(89, 'first_class', 27, 34, 230, 17, 58, 3.41, 25.21, 9, 0, 0, 7, 0),
(89, 'list_a', 30, 14, 34, 8, 24, 4, 70.58, 9, 0, 0, 4, 2),
(89, 't20', 23, 1, 5, 1, 2, 0, 40, 2, 0, 0, 0, 0),
(90, 'first_class', 9, 10, 111, 4, 60, 10, 54.05, 40, 0, 0, 5, 3),
(90, 'list_a', 5, 4, 20, 2, 17, 8.5, 85, 10, 0, 0, 0, 1),
(90, 't20', 17, 7, 13, 5, 5, 2.5, 38.46, 2, 0, 0, 0, 0),
(91, 'first_class', 14, 23, 431, 1, 440, 20, 102.08, 54, 0, 1, 37, 26),
(91, 'list_a', 34, 29, 434, 12, 542, 31.88, 124.88, 68, 0, 2, 38, 36),
(91, 'odi', 5, 5, 75, 1, 144, 36, 192, 46, 0, 0, 8, 14),
(91, 't20', 41, 23, 195, 8, 247, 16.46, 126.66, 43, 0, 0, 11, 22),
(91, 't20i', 10, 5, 34, 0, 53, 10.6, 155.88, 24, 0, 0, 4, 4),
(92, 'first_class', 6, 6, 89, 1, 60, 12, 67.41, 26, 0, 0, 10, 1),
(92, 'list_a', 17, 5, 24, 2, 17, 5.66, 70.83, 6, 0, 0, 2, 0),
(92, 't20', 46, 8, 32, 4, 21, 5.25, 65.62, 10, 0, 0, 3, 0),
(93, 'first_class', 8, 10, 797, 0, 388, 38.8, 48.68, 95, 0, 3, 56, 1),
(93, 'list_a', 20, 20, 749, 2, 686, 38.11, 91.58, 164, 2, 3, 63, 17),
(93, 't20', 20, 20, 391, 3, 507, 29.82, 129.66, 56, 0, 1, 61, 14),
(94, 'first_class', 35, 56, 2720, 8, 1591, 33.14, 58.49, 126, 1, 11, 209, 8),
(94, 'list_a', 43, 39, 1276, 5, 1353, 39.79, 106.03, 174, 3, 7, 145, 33),
(94, 't20', 34, 30, 543, 7, 763, 33.17, 140.51, 72, 0, 6, 70, 29),
(95, 'first_class', 7, 10, 439, 0, 164, 16.4, 37.35, 41, 0, 0, 21, 1),
(95, 'list_a', 15, 11, 132, 5, 109, 18.16, 82.57, 31, 0, 0, 7, 2),
(95, 'odi', 3, 3, 7, 2, 6, 6, 85.71, 3, 0, 0, 0, 0),
(95, 't20', 46, 27, 149, 9, 173, 9.61, 116.1, 20, 0, 0, 11, 6),
(95, 't20i', 3, 1, 7, 0, 1, 1, 14.28, 1, 0, 0, 0, 0),
(96, 'list_a', 9, 6, 73, 2, 63, 15.75, 86.3, 29, 0, 0, 5, 2),
(96, 't20', 33, 19, 150, 11, 163, 20.37, 108.66, 25, 0, 0, 10, 7),
(97, 't20', 4, 1, 4, 0, 6, 6, 150, 6, 0, 0, 1, 0),
(98, 'first_class', 2, 3, 319, 0, 152, 50.66, 47.64, 44, 0, 0, 22, 0),
(98, 't20', 2, 2, 14, 0, 11, 5.5, 78.57, 11, 0, 0, 1, 0),
(99, 'first_class', 142, 200, 8830, 31, 4843, 28.65, 54.84, 124, 7, 23, 601, 22),
(99, 'list_a', 173, 103, 1740, 27, 1345, 17.69, 77.29, 79, 0, 4, 0, 0),
(99, 'odi', 113, 63, 813, 20, 707, 16.44, 86.96, 65, 0, 1, 60, 7),
(99, 't20', 277, 104, 791, 39, 928, 14.27, 117.32, 50, 0, 1, 84, 25),
(99, 't20i', 51, 11, 115, 7, 123, 30.75, 106.95, 31, 0, 0, 14, 1),
(99, 'test', 86, 123, 5364, 14, 2931, 26.88, 54.64, 124, 5, 12, 339, 16),
(100, 'first_class', 110, 130, 2118, 53, 1157, 15.02, 54.62, 61, 0, 2, 127, 45),
(100, 'list_a', 122, 54, 292, 28, 214, 8.23, 73.28, 21, 0, 0, 19, 6),
(100, 'odi', 93, 40, 213, 23, 159, 9.35, 74.64, 21, 0, 0, 15, 6),
(100, 't20', 160, 37, 99, 25, 79, 6.58, 79.79, 8, 0, 0, 2, 2),
(100, 't20i', 44, 11, 40, 6, 30, 6, 75, 8, 0, 0, 2, 0),
(100, 'test', 75, 88, 1205, 43, 704, 15.64, 58.42, 52, 0, 1, 72, 30),
(101, 'first_class', 122, 199, 10293, 16, 5888, 32.17, 57.2, 152, 7, 33, 732, 72),
(101, 'list_a', 218, 182, 5049, 43, 6037, 43.43, 119.56, 150, 11, 36, 546, 188),
(101, 'odi', 148, 123, 3263, 23, 3872, 38.72, 118.66, 150, 9, 20, 323, 125),
(101, 't20', 308, 286, 5469, 51, 7922, 33.71, 144.85, 124, 5, 53, 690, 346),
(101, 't20i', 88, 80, 1516, 18, 2140, 34.51, 141.16, 101, 1, 15, 184, 90),
(101, 'test', 57, 100, 5365, 9, 2907, 31.94, 54.18, 152, 2, 18, 340, 33),
(102, 'first_class', 133, 225, 17718, 26, 8371, 42.06, 47.24, 175, 17, 47, 1039, 45),
(102, 'list_a', 126, 117, 6142, 22, 4806, 50.58, 78.24, 134, 10, 30, 385, 74),
(102, 'odi', 35, 29, 1537, 10, 1365, 71.84, 88.8, 129, 2, 11, 94, 28),
(102, 't20', 143, 135, 3196, 25, 4151, 37.73, 129.88, 112, 3, 28, 286, 181),
(102, 't20i', 34, 31, 713, 7, 933, 38.87, 130.85, 94, 0, 6, 55, 40),
(102, 'test', 15, 27, 2006, 2, 824, 32.96, 41.07, 98, 0, 6, 90, 4),
(103, 'first_class', 67, 112, 4552, 10, 3249, 31.85, 71.37, 147, 5, 17, 435, 50),
(103, 'list_a', 129, 113, 3015, 22, 3087, 33.92, 102.38, 120, 2, 18, 282, 88),
(103, 'odi', 66, 56, 1352, 10, 1320, 28.69, 97.63, 97, 0, 6, 117, 30),
(103, 't20', 176, 137, 1717, 37, 2346, 23.46, 136.63, 59, 0, 5, 168, 104),
(103, 't20i', 38, 29, 274, 10, 416, 21.89, 151.82, 48, 0, 0, 31, 25),
(103, 'test', 12, 22, 1069, 1, 709, 33.76, 66.32, 137, 2, 4, 88, 11),
(104, 'first_class', 85, 135, 9290, 17, 4449, 37.7, 47.89, 170, 10, 25, 433, 81),
(104, 'list_a', 88, 80, 3145, 10, 2649, 37.84, 84.22, 126, 4, 18, 200, 76),
(104, 'odi', 3, 2, 98, 2, 112, 0, 114.28, 100, 1, 0, 11, 2),
(104, 't20', 133, 119, 2099, 29, 2755, 30.61, 131.25, 88, 0, 11, 179, 111),
(104, 't20i', 25, 23, 291, 5, 392, 21.77, 134.7, 72, 0, 1, 32, 14),
(104, 'test', 9, 11, 764, 1, 403, 40.3, 52.74, 102, 1, 3, 41, 7),
(105, 'first_class', 84, 134, 11138, 15, 5883, 49.43, 52.81, 328, 15, 27, 728, 25),
(105, 'list_a', 90, 82, 2636, 13, 2119, 30.71, 80.38, 120, 2, 12, 219, 32),
(105, 'odi', 2, 2, 88, 0, 46, 23, 52.27, 39, 0, 0, 6, 0),
(105, 't20', 150, 135, 2279, 16, 2989, 25.11, 131.15, 111, 2, 16, 293, 99),
(105, 'test', 6, 7, 506, 1, 374, 62.33, 73.91, 303, 1, 0, 41, 4),
(106, 'first_class', 55, 91, 5596, 7, 3162, 37.64, 56.5, 211, 10, 12, 368, 67),
(106, 'list_a', 102, 96, 2931, 9, 2610, 30, 89.04, 212, 1, 14, 230, 70),
(106, 'odi', 1, 1, 46, 0, 46, 46, 100, 46, 0, 0, 5, 1),
(106, 't20', 210, 203, 3909, 22, 5161, 28.51, 132.02, 119, 3, 32, 407, 227),
(106, 't20i', 13, 12, 143, 0, 174, 14.5, 121.67, 39, 0, 0, 10, 8),
(107, 'first_class', 31, 47, 1084, 10, 324, 8.75, 29.88, 42, 0, 0, 38, 2),
(107, 'list_a', 119, 47, 496, 22, 290, 11.6, 58.46, 24, 0, 0, 28, 1),
(107, 'odi', 61, 12, 106, 5, 66, 9.42, 62.26, 18, 0, 0, 8, 0),
(107, 't20', 237, 39, 146, 23, 76, 4.75, 52.05, 10, 0, 0, 1, 0),
(107, 't20i', 54, 4, 11, 2, 5, 2.5, 45.45, 3, 0, 0, 0, 0),
(108, 'first_class', 41, 74, 2876, 3, 2163, 30.46, 75.2, 107, 1, 12, 276, 49),
(108, 'list_a', 69, 66, 2132, 5, 2215, 36.31, 103.89, 139, 7, 9, 178, 82),
(108, 'odi', 47, 44, 1360, 3, 1447, 35.29, 106.39, 139, 5, 4, 111, 52),
(108, 't20', 133, 122, 1959, 26, 2630, 27.39, 134.25, 100, 1, 14, 191, 134),
(108, 't20i', 42, 35, 561, 4, 666, 21.48, 118.71, 81, 0, 3, 43, 32),
(108, 'test', 16, 30, 1138, 0, 838, 27.93, 73.63, 93, 0, 5, 85, 27),
(109, 'first_class', 54, 55, 747, 22, 332, 10.06, 44.44, 42, 0, 0, 42, 3),
(109, 'list_a', 56, 26, 341, 16, 206, 20.6, 60.41, 45, 0, 0, 18, 5),
(109, 'odi', 8, 5, 137, 3, 107, 53.5, 78.1, 45, 0, 0, 9, 3),
(109, 't20', 68, 16, 67, 11, 55, 11, 82.08, 12, 0, 0, 5, 0),
(109, 't20i', 11, 3, 11, 3, 12, 0, 109.09, 11, 0, 0, 2, 0),
(109, 'test', 2, 3, 27, 1, 8, 4, 29.62, 5, 0, 0, 1, 0),
(110, 'first_class', 37, 56, 1389, 3, 994, 18.75, 71.56, 64, 0, 3, 125, 23),
(110, 'list_a', 80, 53, 739, 13, 703, 17.57, 95.12, 92, 0, 3, 68, 18),
(110, 'odi', 32, 21, 262, 6, 252, 16.8, 96.18, 92, 0, 1, 20, 6),
(110, 't20', 146, 80, 506, 30, 669, 13.38, 132.21, 42, 0, 0, 47, 40),
(110, 't20i', 28, 15, 120, 4, 150, 13.63, 125, 34, 0, 0, 10, 10),
(111, 'list_a', 6, 3, 32, 0, 30, 10, 93.75, 11, 0, 0, 1, 2),
(111, 't20', 38, 11, 43, 6, 54, 10.8, 125.58, 21, 0, 0, 0, 5),
(112, 'first_class', 11, 15, 162, 8, 62, 8.85, 38.27, 25, 0, 0, 6, 4),
(112, 'list_a', 57, 20, 66, 16, 30, 7.5, 45.45, 9, 0, 0, 2, 1),
(112, 'odi', 7, 4, 9, 3, 2, 2, 22.22, 2, 0, 0, 0, 0),
(112, 't20', 66, 11, 29, 7, 10, 2.5, 34.48, 4, 0, 0, 0, 0),
(113, 'first_class', 4, 4, 38, 3, 17, 17, 44.73, 7, 0, 0, 1, 0),
(113, 'list_a', 2, 1, 11, 1, 10, 0, 90.9, 10, 0, 0, 0, 0),
(113, 't20', 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(114, 'first_class', 4, 6, 28, 4, 15, 7.5, 53.57, 11, 0, 0, 2, 1),
(114, 'list_a', 20, 13, 114, 6, 70, 10, 61.4, 14, 0, 0, 3, 3),
(114, 'odi', 2, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0),
(114, 't20', 37, 11, 49, 4, 64, 9.14, 130.61, 23, 0, 0, 5, 5),
(114, 't20i', 13, 6, 26, 2, 36, 9, 138.46, 23, 0, 0, 3, 3),
(115, 'first_class', 19, 36, 2319, 3, 1190, 36.06, 51.31, 178, 1, 10, 141, 8),
(115, 'list_a', 22, 22, 1623, 4, 1391, 77.27, 85.7, 152, 6, 8, 135, 32),
(115, 't20', 66, 66, 1577, 5, 2124, 34.81, 134.68, 122, 2, 14, 225, 77),
(115, 't20i', 2, 2, 38, 0, 38, 19, 100, 29, 0, 0, 2, 1),
(116, 'first_class', 16, 27, 1649, 0, 952, 35.25, 57.73, 123, 1, 7, 107, 30),
(116, 'list_a', 29, 27, 901, 1, 756, 29.07, 83.9, 82, 0, 6, 80, 19),
(116, 't20', 70, 58, 895, 9, 1154, 23.55, 128.93, 77, 0, 9, 82, 59),
(117, 'first_class', 1, 2, 42, 1, 20, 20, 47.61, 20, 0, 0, 3, 0),
(117, 'list_a', 26, 26, 1339, 3, 1115, 48.47, 83.27, 203, 3, 5, 112, 29),
(117, 't20', 28, 27, 417, 0, 541, 20.03, 129.73, 68, 0, 2, 63, 21),
(118, 'first_class', 1, 2, 68, 0, 36, 18, 52.94, 35, 0, 0, 4, 2),
(118, 'list_a', 8, 2, 23, 1, 11, 11, 47.82, 7, 0, 0, 1, 0),
(118, 't20', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(119, 'first_class', 16, 19, 173, 5, 108, 7.71, 62.42, 26, 0, 0, 10, 8),
(119, 'list_a', 5, 3, 6, 1, 0, 0, 0, 0, 0, 0, 0, 0),
(119, 't20', 26, 5, 12, 3, 2, 1, 16.66, 1, 0, 0, 0, 0),
(120, 'first_class', 3, 4, 295, 1, 138, 46, 46.77, 64, 0, 2, 22, 0),
(120, 't20', 2, 2, 37, 0, 28, 14, 75.67, 23, 0, 0, 0, 1),
(121, 'first_class', 1, 1, 37, 1, 9, 0, 24.32, 9, 0, 0, 2, 0),
(121, 'list_a', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(121, 't20', 1, 1, 4, 1, 0, 0, 0, 0, 0, 0, 0, 0),
(123, 'first_class', 113, 167, 10780, 28, 6452, 46.41, 59.85, 331, 11, 34, 676, 114),
(123, 'list_a', 221, 157, 3927, 51, 3460, 32.64, 88.1, 134, 2, 18, 254, 76),
(123, 'odi', 168, 113, 2769, 39, 2411, 32.58, 87.07, 87, 0, 13, 178, 49),
(123, 't20', 286, 203, 2361, 84, 3038, 25.52, 128.67, 62, 0, 2, 224, 108),
(123, 't20i', 58, 29, 262, 14, 326, 21.73, 124.42, 45, 0, 0, 25, 8),
(123, 'test', 59, 87, 3988, 20, 2396, 35.76, 60.08, 175, 2, 17, 239, 55),
(124, 'first_class', 131, 210, 11145, 19, 7054, 36.93, 63.29, 224, 9, 47, 862, 106),
(124, 'list_a', 423, 364, 0, 99, 13353, 50.38, 0, 183, 17, 87, 0, 0),
(124, 'odi', 350, 297, 12303, 84, 10773, 50.57, 87.56, 183, 10, 73, 826, 229),
(124, 't20', 358, 316, 5278, 130, 7098, 38.16, 134.48, 84, 0, 28, 495, 312),
(124, 't20i', 98, 85, 1282, 42, 1617, 37.6, 126.13, 56, 0, 2, 116, 52),
(124, 'test', 90, 144, 8249, 16, 4876, 38.09, 59.11, 224, 6, 33, 544, 78),
(125, 'first_class', 114, 159, 0, 23, 3443, 25.31, 0, 166, 3, 15, 0, 0),
(125, 'list_a', 84, 56, 0, 15, 634, 15.46, 0, 55, 0, 1, 45, 18),
(125, 'odi', 34, 23, 193, 9, 170, 12.14, 88.08, 38, 0, 0, 12, 5),
(125, 't20', 258, 150, 1043, 60, 1265, 14.05, 121.28, 45, 0, 0, 91, 49),
(125, 't20i', 75, 43, 271, 19, 358, 14.91, 132.1, 36, 0, 0, 24, 18),
(125, 'test', 8, 11, 320, 1, 180, 18, 56.25, 35, 0, 0, 24, 1),
(126, 'first_class', 61, 87, 4215, 8, 2805, 35.5, 66.54, 177, 5, 16, 359, 59),
(126, 'list_a', 95, 66, 1701, 13, 1608, 30.33, 94.53, 115, 1, 11, 120, 51),
(126, 'odi', 24, 12, 199, 1, 175, 15.9, 87.93, 50, 0, 1, 13, 5),
(126, 't20', 163, 130, 1531, 29, 2110, 20.89, 137.81, 77, 0, 5, 139, 112),
(126, 't20i', 22, 11, 105, 4, 170, 24.28, 161.9, 77, 0, 1, 13, 8),
(126, 'test', 3, 6, 163, 0, 83, 13.83, 50.92, 37, 0, 0, 13, 1),
(127, 'first_class', 97, 156, 0, 21, 6151, 45.56, 0, 210, 16, 34, 0, 0),
(127, 'list_a', 172, 162, 6826, 27, 5476, 40.56, 80.22, 124, 5, 40, 503, 0),
(127, 'odi', 55, 50, 2143, 14, 1694, 47.05, 79.04, 124, 3, 10, 145, 30),
(127, 't20', 267, 250, 4610, 38, 5750, 27.12, 124.72, 100, 1, 30, 476, 214),
(127, 't20i', 6, 5, 50, 1, 42, 10.5, 84, 20, 0, 0, 5, 0),
(128, 'first_class', 142, 238, 14185, 6, 9446, 40.71, 66.59, 162, 22, 52, 1302, 102),
(128, 'list_a', 203, 197, 6910, 12, 6535, 35.32, 94.57, 169, 16, 33, 754, 135),
(128, 'odi', 46, 42, 1031, 6, 934, 25.94, 90.59, 86, 0, 6, 107, 19),
(128, 't20', 290, 281, 5458, 24, 7271, 28.29, 133.21, 92, 0, 42, 720, 267),
(128, 't20i', 13, 12, 211, 2, 249, 24.9, 118, 50, 0, 1, 26, 6),
(129, 'first_class', 117, 189, 14437, 23, 8018, 48.3, 55.53, 327, 21, 36, 1106, 53),
(129, 'list_a', 85, 82, 3874, 9, 3329, 45.6, 85.93, 152, 9, 19, 320, 41),
(129, 'odi', 3, 3, 255, 0, 225, 75, 88.23, 126, 1, 1, 26, 0),
(129, 't20', 115, 110, 3001, 25, 3899, 45.87, 129.92, 105, 2, 31, 419, 91),
(129, 't20i', 20, 17, 432, 5, 602, 50.16, 139.35, 99, 0, 4, 62, 15),
(129, 'test', 7, 12, 1507, 0, 767, 63.91, 50.89, 200, 3, 3, 94, 3),
(130, 'first_class', 56, 85, 4851, 5, 2344, 29.3, 48.31, 126, 3, 14, 294, 39),
(130, 'list_a', 104, 83, 1839, 25, 1633, 28.15, 88.79, 86, 0, 7, 134, 43),
(130, 'odi', 75, 57, 1047, 23, 927, 27.26, 88.53, 67, 0, 2, 64, 27),
(130, 't20', 125, 95, 1018, 35, 1328, 22.13, 130.45, 92, 0, 2, 90, 62),
(130, 't20i', 62, 43, 290, 19, 358, 14.91, 123.44, 37, 0, 0, 25, 11),
(130, 'test', 24, 32, 1803, 1, 766, 24.7, 42.48, 126, 1, 2, 90, 18),
(131, 'first_class', 100, 180, 0, 7, 5302, 30.64, 0, 197, 8, 30, 0, 0),
(131, 'list_a', 227, 198, 0, 30, 4046, 24.08, 0, 112, 2, 13, 0, 0),
(131, 'odi', 164, 141, 3606, 24, 2968, 25.36, 82.3, 112, 2, 10, 240, 58),
(131, 't20', 531, 410, 5324, 121, 6758, 23.38, 126.93, 70, 0, 20, 436, 327),
(131, 't20i', 91, 74, 1091, 17, 1255, 22.01, 115.03, 66, 0, 4, 73, 55),
(131, 'test', 40, 71, 4527, 1, 2200, 31.42, 48.59, 113, 3, 13, 269, 21),
(132, 'first_class', 16, 25, 1509, 4, 1012, 48.19, 67.06, 114, 2, 7, 99, 39),
(132, 'list_a', 47, 33, 683, 12, 803, 38.23, 117.57, 118, 1, 1, 46, 47),
(132, 'odi', 1, 1, 6, 0, 9, 9, 150, 9, 0, 0, 1, 0),
(132, 't20', 78, 71, 942, 16, 1299, 23.61, 137.89, 95, 0, 5, 83, 76),
(132, 't20i', 13, 9, 77, 3, 105, 17.5, 136.36, 54, 0, 1, 7, 6),
(133, 'first_class', 198, 339, 20597, 27, 11334, 36.32, 55.02, 250, 20, 69, 1462, 137),
(133, 'list_a', 229, 200, 5087, 16, 5172, 28.1, 101.67, 158, 11, 20, 547, 131),
(133, 'odi', 112, 89, 1853, 14, 1877, 25.02, 101.29, 128, 3, 5, 162, 63),
(133, 't20', 216, 204, 3264, 20, 4576, 24.86, 140.19, 121, 2, 24, 425, 215),
(133, 't20i', 49, 44, 465, 10, 637, 18.73, 136.98, 72, 0, 4, 50, 32),
(133, 'test', 64, 111, 5697, 8, 2914, 28.29, 51.14, 155, 5, 14, 355, 30),
(134, 'first_class', 26, 38, 2309, 4, 1261, 37.08, 54.61, 183, 4, 5, 124, 19),
(134, 'list_a', 36, 36, 1539, 0, 1260, 35, 81.87, 133, 3, 6, 128, 18),
(134, 't20', 43, 38, 771, 10, 914, 32.64, 118.54, 78, 0, 5, 79, 30),
(135, 'first_class', 1, 2, 109, 0, 45, 22.5, 41.28, 23, 0, 0, 6, 0),
(135, 'list_a', 8, 8, 183, 0, 150, 18.75, 81.96, 73, 0, 1, 16, 3),
(135, 't20', 27, 26, 475, 4, 593, 26.95, 124.84, 92, 0, 3, 57, 25),
(136, 'first_class', 21, 36, 2653, 1, 1349, 38.54, 50.84, 129, 4, 6, 161, 15),
(136, 'list_a', 64, 63, 3281, 3, 3284, 54.73, 100.09, 187, 11, 16, 333, 82),
(136, 't20', 74, 74, 1778, 7, 2380, 35.52, 133.85, 101, 1, 18, 235, 81),
(136, 't20i', 3, 3, 36, 0, 39, 13, 108.33, 21, 0, 0, 4, 0),
(137, 'first_class', 1, 2, 10, 1, 4, 4, 40, 4, 0, 0, 1, 0),
(137, 'list_a', 9, 3, 6, 3, 13, 0, 216.66, 13, 0, 0, 1, 1),
(137, 't20', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(138, 'first_class', 37, 61, 3983, 6, 1934, 35.16, 48.55, 173, 5, 7, 250, 19),
(138, 'list_a', 32, 28, 1299, 4, 988, 41.16, 76.05, 119, 2, 5, 70, 17),
(138, 't20', 26, 24, 521, 2, 637, 28.95, 122.26, 67, 0, 3, 50, 24),
(139, 'first_class', 13, 17, 280, 9, 111, 13.87, 39.64, 25, 0, 0, 21, 0),
(139, 'list_a', 12, 4, 17, 2, 16, 8, 94.11, 14, 0, 0, 2, 0),
(139, 't20', 22, 5, 15, 4, 19, 19, 126.66, 11, 0, 0, 3, 0),
(140, 'first_class', 20, 24, 418, 8, 224, 14, 53.58, 62, 0, 1, 27, 6),
(140, 'list_a', 27, 6, 24, 3, 14, 4.66, 58.33, 6, 0, 0, 2, 0),
(140, 't20', 33, 9, 25, 4, 31, 6.2, 124, 20, 0, 0, 3, 1),
(141, 'first_class', 3, 5, 31, 2, 8, 2.66, 25.8, 7, 0, 0, 0, 1),
(141, 'list_a', 8, 6, 21, 2, 6, 1.5, 28.57, 2, 0, 0, 0, 0),
(141, 't20', 20, 3, 3, 3, 1, 0, 33.33, 1, 0, 0, 0, 0),
(142, 'first_class', 11, 14, 264, 3, 89, 8.09, 33.71, 23, 0, 0, 11, 1),
(142, 'list_a', 23, 7, 104, 2, 55, 11, 52.88, 25, 0, 0, 4, 0),
(142, 't20', 23, 4, 7, 3, 4, 4, 57.14, 2, 0, 0, 0, 0),
(143, 'list_a', 5, 1, 2, 1, 7, 0, 350, 7, 0, 0, 0, 1),
(143, 't20', 2, 2, 7, 1, 6, 6, 85.71, 6, 0, 0, 1, 0),
(144, 'first_class', 3, 5, 131, 0, 72, 14.4, 54.96, 24, 0, 0, 9, 0),
(144, 'list_a', 15, 7, 57, 5, 24, 12, 42.1, 10, 0, 0, 0, 0),
(144, 'odi', 4, 3, 32, 3, 15, 0, 46.87, 10, 0, 0, 0, 0),
(144, 't20', 56, 16, 50, 9, 56, 8, 112, 14, 0, 0, 6, 2),
(144, 't20i', 15, 5, 12, 2, 18, 6, 150, 7, 0, 0, 1, 1),
(145, 'list_a', 1, 1, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0),
(145, 't20', 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(147, 'first_class', 133, 219, 18343, 17, 10292, 50.95, 56.1, 254, 34, 36, 1217, 39),
(147, 'list_a', 294, 284, 14785, 42, 13753, 56.83, 93.02, 183, 47, 72, 1317, 149),
(147, 'odi', 260, 251, 13249, 39, 12311, 58.07, 92.92, 183, 43, 64, 1153, 125),
(147, 't20', 338, 321, 7904, 60, 10489, 40.18, 132.7, 113, 5, 77, 934, 326),
(147, 't20i', 97, 89, 2394, 25, 3296, 51.5, 137.67, 94, 0, 30, 298, 92),
(147, 'test', 101, 171, 14440, 10, 8043, 49.95, 55.69, 254, 27, 28, 904, 24),
(148, 'first_class', 31, 45, 1084, 13, 389, 12.15, 35.88, 39, 0, 0, 39, 6),
(148, 'list_a', 56, 31, 369, 14, 235, 13.82, 63.68, 35, 0, 0, 14, 5),
(148, 'odi', 12, 6, 23, 3, 21, 7, 91.3, 11, 0, 0, 0, 0),
(148, 't20', 94, 21, 95, 12, 97, 10.77, 102.1, 26, 0, 0, 7, 1),
(148, 't20i', 9, 1, 7, 0, 5, 5, 71.42, 5, 0, 0, 0, 0),
(149, 'first_class', 167, 254, 16393, 19, 9620, 40.93, 58.68, 213, 28, 43, 1234, 75),
(149, 'list_a', 251, 221, 7990, 37, 7350, 39.94, 91.99, 154, 12, 39, 753, 0),
(149, 'odi', 94, 79, 2392, 21, 1752, 30.2, 73.24, 79, 0, 9, 176, 15),
(149, 't20', 339, 302, 4851, 67, 6557, 27.9, 135.16, 97, 0, 31, 637, 214),
(149, 't20i', 32, 26, 278, 14, 399, 33.25, 143.52, 48, 0, 0, 42, 15),
(149, 'test', 26, 42, 2080, 1, 1025, 25, 49.27, 129, 1, 7, 134, 4),
(150, 'first_class', 77, 110, 4979, 12, 2435, 24.84, 48.9, 120, 2, 15, 299, 45),
(150, 'list_a', 99, 79, 1540, 16, 1441, 22.87, 93.57, 109, 1, 5, 90, 61),
(150, 'odi', 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(150, 't20', 138, 94, 1067, 25, 1318, 19.1, 123.52, 67, 0, 2, 90, 59),
(150, 't20i', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(150, 'test', 1, 2, 28, 1, 8, 8, 28.57, 4, 0, 0, 0, 0),
(151, 'first_class', 77, 108, 3944, 16, 2515, 27.33, 63.76, 104, 2, 14, 302, 58),
(151, 'list_a', 135, 94, 1944, 21, 1859, 25.46, 95.62, 167, 3, 7, 159, 69),
(151, 'odi', 52, 29, 427, 13, 377, 23.56, 88.29, 51, 0, 2, 31, 11),
(151, 't20', 208, 151, 2064, 30, 2857, 23.61, 138.42, 118, 2, 11, 220, 149),
(151, 't20i', 32, 21, 137, 8, 182, 14, 132.84, 29, 0, 0, 10, 11),
(152, 'first_class', 67, 112, 5536, 10, 4061, 39.81, 73.35, 278, 7, 23, 459, 63),
(152, 'list_a', 191, 173, 4278, 20, 5163, 33.74, 120.68, 146, 5, 32, 501, 179),
(152, 'odi', 116, 106, 2575, 12, 3230, 34.36, 125.43, 108, 2, 22, 309, 116),
(152, 't20', 355, 334, 5311, 48, 8050, 28.14, 151.57, 154, 5, 46, 675, 383),
(152, 't20i', 84, 77, 1287, 13, 1982, 30.96, 154, 145, 3, 9, 164, 97),
(152, 'test', 7, 14, 570, 1, 339, 26.07, 59.47, 104, 1, 0, 33, 7),
(153, 'first_class', 65, 80, 1854, 14, 699, 10.59, 37.7, 50, 0, 1, 92, 7),
(153, 'list_a', 100, 46, 410, 17, 237, 8.17, 57.8, 33, 0, 0, 16, 2),
(153, 'odi', 3, 2, 3, 0, 1, 0.5, 33.33, 1, 0, 0, 0, 0),
(153, 't20', 124, 34, 86, 24, 75, 7.5, 87.2, 8, 0, 0, 5, 0),
(153, 't20i', 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(154, 'first_class', 64, 99, 2738, 16, 1363, 16.42, 49.78, 83, 0, 5, 136, 45),
(154, 'list_a', 61, 47, 700, 7, 654, 16.35, 93.42, 69, 0, 4, 43, 33),
(154, 't20', 135, 81, 662, 23, 981, 16.91, 148.18, 82, 0, 3, 96, 57),
(154, 't20i', 8, 2, 12, 1, 19, 19, 158.33, 18, 0, 0, 2, 1),
(155, 'first_class', 150, 250, 17522, 26, 8798, 39.27, 50.21, 199, 18, 52, 1109, 44),
(155, 'list_a', 262, 244, 10599, 42, 9483, 46.94, 89.47, 185, 21, 57, 844, 129),
(155, 'odi', 143, 136, 6215, 20, 5507, 47.47, 88.6, 185, 12, 35, 495, 66),
(155, 't20', 289, 272, 5800, 32, 7529, 31.37, 129.81, 120, 3, 48, 671, 235),
(155, 't20i', 50, 50, 1137, 7, 1528, 35.53, 134.38, 119, 1, 10, 140, 50),
(155, 'test', 69, 118, 8986, 14, 4163, 40.02, 46.32, 199, 10, 21, 516, 21),
(156, 'first_class', 39, 52, 2029, 13, 900, 23.07, 44.35, 136, 1, 3, 123, 12),
(156, 'list_a', 45, 33, 483, 10, 400, 17.39, 82.81, 42, 0, 0, 31, 12),
(156, 't20', 53, 31, 175, 16, 226, 15.06, 129.14, 26, 0, 0, 16, 9),
(157, 'first_class', 98, 115, 1798, 45, 793, 11.32, 44.1, 43, 0, 0, 113, 4),
(157, 'list_a', 108, 40, 265, 24, 161, 10.06, 60.75, 30, 0, 0, 11, 2),
(157, 'odi', 56, 19, 82, 16, 54, 18, 65.85, 11, 0, 0, 6, 0),
(157, 't20', 75, 15, 59, 11, 54, 13.5, 91.52, 13, 0, 0, 5, 1),
(157, 't20i', 27, 6, 13, 4, 21, 10.5, 161.53, 13, 0, 0, 2, 1),
(157, 'test', 57, 70, 990, 33, 445, 12.02, 44.94, 39, 0, 0, 62, 2),
(158, 'first_class', 35, 58, 4427, 4, 2065, 38.24, 46.64, 133, 4, 13, 268, 21),
(158, 'list_a', 39, 38, 1805, 3, 1481, 42.31, 82.04, 101, 1, 14, 117, 37),
(158, 't20', 62, 60, 1143, 11, 1425, 29.08, 124.67, 78, 0, 8, 112, 55),
(159, 'first_class', 41, 69, 2889, 8, 2486, 40.75, 86.05, 120, 3, 18, 303, 43),
(159, 'list_a', 72, 66, 1379, 11, 1478, 26.87, 107.17, 87, 0, 10, 132, 46),
(159, 'odi', 29, 27, 545, 4, 546, 23.73, 100.18, 80, 0, 3, 40, 19),
(159, 't20', 97, 74, 774, 13, 1042, 17.08, 134.62, 74, 0, 3, 105, 26),
(159, 't20i', 35, 29, 286, 6, 345, 15, 120.62, 71, 0, 1, 35, 2),
(159, 'test', 4, 7, 227, 0, 196, 28, 86.34, 59, 0, 1, 29, 1),
(160, 'first_class', 51, 66, 710, 14, 387, 7.44, 54.5, 46, 0, 0, 48, 12),
(160, 'list_a', 49, 30, 184, 12, 145, 8.05, 78.8, 36, 0, 0, 15, 3),
(160, 'odi', 4, 2, 11, 0, 7, 3.5, 63.63, 4, 0, 0, 1, 0),
(160, 't20', 99, 27, 128, 14, 110, 8.46, 85.93, 14, 0, 0, 12, 2),
(160, 't20i', 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(160, 'test', 12, 17, 103, 7, 62, 6.2, 60.19, 16, 0, 0, 7, 2),
(161, 'first_class', 39, 67, 5253, 3, 2588, 40.43, 49.26, 196, 7, 14, 362, 7),
(161, 'list_a', 43, 42, 1481, 1, 1397, 34.07, 94.32, 158, 3, 5, 162, 26),
(161, 't20', 36, 35, 722, 3, 998, 31.18, 138.22, 96, 0, 8, 83, 40),
(162, 'first_class', 22, 33, 1762, 2, 954, 30.77, 54.14, 134, 2, 3, 101, 18),
(162, 'list_a', 20, 16, 667, 3, 573, 44.07, 85.9, 95, 0, 5, 45, 22),
(162, 't20', 35, 30, 532, 5, 630, 25.2, 118.42, 88, 0, 3, 46, 36),
(163, 'first_class', 17, 24, 793, 3, 486, 23.14, 61.28, 93, 0, 3, 57, 18),
(163, 'list_a', 20, 16, 439, 3, 388, 29.84, 88.38, 69, 0, 2, 32, 15),
(163, 't20', 89, 77, 1079, 17, 1409, 23.48, 130.58, 70, 0, 6, 93, 87),
(163, 't20i', 6, 4, 36, 0, 43, 10.75, 119.44, 26, 0, 0, 1, 3),
(164, 'first_class', 16, 28, 1042, 2, 526, 20.23, 50.47, 66, 0, 3, 78, 3),
(164, 'list_a', 27, 27, 679, 0, 745, 27.59, 109.72, 128, 1, 3, 80, 30),
(164, 't20', 43, 43, 765, 3, 1372, 34.3, 179.34, 92, 0, 14, 147, 67),
(164, 't20i', 6, 6, 82, 0, 156, 26, 190.24, 71, 0, 1, 19, 8),
(165, 'first_class', 16, 25, 1409, 3, 779, 35.4, 55.28, 82, 0, 6, 85, 6),
(165, 'list_a', 26, 21, 716, 7, 662, 47.28, 92.45, 107, 2, 2, 45, 21),
(165, 't20', 53, 33, 409, 8, 491, 19.64, 120.04, 60, 0, 1, 33, 18),
(166, 'first_class', 19, 30, 2072, 3, 1158, 42.88, 55.88, 135, 1, 8, 158, 12),
(166, 'list_a', 34, 33, 889, 0, 787, 23.84, 88.52, 59, 0, 5, 74, 20),
(166, 't20', 27, 25, 358, 6, 510, 26.84, 142.45, 60, 0, 1, 44, 22),
(167, 'first_class', 11, 14, 227, 1, 111, 8.53, 48.89, 44, 0, 0, 9, 5),
(167, 'list_a', 16, 8, 68, 1, 74, 10.57, 108.82, 25, 0, 0, 4, 5),
(167, 't20', 27, 8, 36, 3, 42, 8.4, 116.66, 13, 0, 0, 2, 2),
(169, 'first_class', 104, 180, 9550, 15, 5349, 32.41, 56.01, 211, 11, 22, 746, 73),
(169, 'list_a', 122, 115, 3817, 22, 3480, 37.41, 91.17, 124, 4, 23, 295, 89),
(169, 'odi', 63, 59, 1847, 9, 1672, 33.44, 90.52, 102, 1, 12, 139, 41),
(169, 't20', 143, 134, 2650, 33, 3429, 33.95, 129.39, 100, 1, 21, 240, 151),
(169, 't20i', 36, 35, 708, 7, 885, 31.6, 125, 77, 0, 6, 70, 35),
(169, 'test', 32, 55, 2486, 5, 1260, 25.2, 50.68, 181, 2, 3, 160, 17),
(170, 'first_class', 35, 47, 383, 23, 142, 5.91, 37.07, 30, 0, 0, 13, 8),
(170, 'list_a', 85, 37, 169, 22, 89, 5.93, 52.66, 18, 0, 0, 9, 0),
(170, 'odi', 74, 33, 150, 21, 82, 6.83, 54.66, 18, 0, 0, 9, 0),
(170, 't20', 190, 59, 205, 34, 151, 6.04, 73.65, 21, 0, 0, 8, 9),
(170, 't20i', 63, 22, 85, 7, 59, 3.93, 69.41, 15, 0, 0, 3, 3),
(170, 'test', 14, 20, 149, 7, 59, 4.53, 39.59, 16, 0, 0, 3, 4),
(171, 'first_class', 81, 131, 10428, 17, 5674, 49.77, 54.41, 235, 14, 30, 663, 43),
(171, 'list_a', 114, 105, 4458, 9, 3340, 34.79, 74.92, 119, 3, 24, 269, 49),
(171, 't20', 185, 163, 2823, 34, 3612, 28, 127.94, 99, 0, 18, 371, 94),
(171, 't20i', 3, 3, 73, 1, 87, 43.5, 119.17, 52, 0, 1, 11, 1),
(172, 'first_class', 69, 96, 2280, 7, 1503, 16.88, 65.92, 87, 0, 9, 193, 31),
(172, 'list_a', 78, 46, 541, 14, 614, 19.18, 113.49, 92, 0, 2, 52, 26),
(172, 'odi', 19, 11, 170, 5, 205, 34.16, 120.58, 50, 0, 1, 18, 8),
(172, 't20', 137, 43, 240, 16, 296, 10.96, 123.33, 29, 0, 0, 19, 13),
(172, 't20i', 25, 6, 38, 3, 69, 23, 181.57, 22, 0, 0, 5, 4),
(172, 'test', 7, 12, 329, 1, 249, 22.63, 75.68, 67, 0, 3, 32, 9),
(173, 'first_class', 60, 81, 1909, 20, 834, 13.67, 43.68, 79, 0, 4, 97, 12),
(173, 'list_a', 45, 18, 191, 4, 115, 8.21, 60.2, 17, 0, 0, 9, 0),
(173, 'odi', 12, 3, 27, 1, 19, 9.5, 70.37, 10, 0, 0, 1, 0),
(173, 't20', 69, 18, 78, 9, 72, 8, 92.3, 25, 0, 0, 4, 2),
(173, 't20i', 16, 5, 20, 2, 8, 2.66, 40, 4, 0, 0, 0, 0),
(173, 'test', 12, 21, 481, 4, 115, 6.76, 23.9, 40, 0, 0, 15, 0),
(174, 'first_class', 79, 125, 7218, 8, 4289, 36.65, 59.42, 308, 9, 23, 535, 78),
(174, 'list_a', 56, 55, 2279, 3, 1721, 33.09, 75.51, 161, 5, 5, 178, 32),
(174, 't20', 63, 58, 972, 5, 1058, 19.96, 108.84, 78, 0, 5, 89, 39),
(175, 'first_class', 26, 34, 282, 15, 105, 5.52, 37.23, 15, 0, 0, 14, 1),
(175, 'list_a', 61, 23, 151, 15, 108, 13.5, 71.52, 19, 0, 0, 9, 4),
(175, 'odi', 35, 12, 90, 8, 62, 15.5, 68.88, 19, 0, 0, 4, 4),
(175, 't20', 85, 9, 26, 4, 14, 2.8, 53.84, 4, 0, 0, 0, 0),
(175, 't20i', 23, 5, 17, 1, 7, 1.75, 41.17, 4, 0, 0, 0, 0),
(175, 'test', 13, 20, 143, 8, 52, 4.33, 36.36, 14, 0, 0, 9, 0),
(176, 'first_class', 46, 66, 3044, 10, 1862, 33.25, 61.16, 110, 1, 14, 230, 25),
(176, 'list_a', 133, 92, 2098, 25, 2036, 30.38, 97.04, 98, 0, 9, 163, 48),
(176, 'odi', 38, 20, 190, 6, 181, 12.92, 95.26, 38, 0, 0, 8, 8),
(176, 't20', 178, 131, 1442, 44, 1891, 21.73, 131.13, 70, 0, 2, 127, 81),
(176, 't20i', 15, 10, 62, 6, 78, 19.5, 125.8, 20, 0, 0, 4, 3),
(176, 'test', 6, 10, 378, 2, 197, 24.62, 52.11, 52, 0, 1, 18, 8),
(177, 'first_class', 33, 43, 2061, 4, 866, 22.2, 42.01, 117, 1, 6, 108, 6),
(177, 'list_a', 76, 29, 280, 14, 172, 11.46, 61.42, 25, 0, 0, 13, 0),
(177, 'odi', 66, 22, 196, 12, 123, 12.3, 62.75, 19, 0, 0, 10, 0),
(177, 't20', 114, 28, 215, 17, 193, 17.54, 89.76, 23, 0, 0, 15, 2),
(177, 't20i', 24, 3, 48, 2, 43, 43, 89.58, 23, 0, 0, 2, 0),
(177, 'test', 7, 8, 185, 0, 54, 6.75, 29.18, 26, 0, 0, 6, 0),
(178, 'first_class', 54, 92, 6055, 6, 2976, 34.6, 49.14, 167, 6, 14, 331, 29),
(178, 'list_a', 43, 42, 1066, 3, 917, 23.51, 86.02, 104, 1, 6, 75, 19),
(178, 'odi', 3, 2, 27, 0, 33, 16.5, 122.22, 22, 0, 0, 2, 1),
(178, 't20', 145, 130, 2183, 18, 2783, 24.84, 127.48, 107, 1, 13, 249, 120),
(178, 't20i', 40, 37, 580, 5, 753, 23.53, 129.82, 84, 0, 5, 63, 37),
(179, 'first_class', 22, 32, 2925, 5, 2099, 77.74, 71.76, 301, 6, 6, 246, 43),
(179, 'list_a', 21, 16, 369, 6, 325, 32.5, 88.07, 100, 1, 0, 40, 3),
(179, 't20', 72, 54, 625, 17, 830, 22.43, 132.8, 67, 0, 3, 81, 24),
(180, 'first_class', 1, 1, 106, 1, 46, 0, 43.39, 46, 0, 0, 5, 1),
(180, 'list_a', 13, 6, 106, 1, 87, 17.4, 82.07, 37, 0, 0, 8, 1),
(180, 'odi', 1, 1, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0);
INSERT INTO `player_statistics_batting` (`playerId`, `type`, `matches`, `innings`, `ballFaced`, `notOuts`, `runs`, `average`, `strikeRate`, `highestScore`, `hundreds`, `fifties`, `fours`, `sixes`) VALUES
(180, 't20', 22, 16, 123, 7, 126, 14, 102.43, 33, 0, 0, 10, 3),
(181, 'first_class', 125, 225, 14282, 10, 10232, 47.59, 71.64, 335, 32, 43, 1240, 81),
(181, 'list_a', 177, 175, 7626, 8, 7409, 44.36, 97.15, 197, 24, 29, 768, 143),
(181, 'odi', 128, 126, 5710, 6, 5455, 45.45, 95.53, 179, 18, 23, 571, 85),
(181, 't20', 323, 322, 7597, 42, 10735, 38.33, 141.3, 135, 8, 90, 1056, 404),
(181, 't20i', 88, 88, 1818, 10, 2554, 32.74, 140.48, 100, 1, 21, 250, 99),
(181, 'test', 94, 172, 10879, 7, 7753, 46.98, 71.26, 335, 24, 34, 915, 61),
(182, 'first_class', 6, 8, 90, 5, 41, 13.66, 45.55, 18, 0, 0, 6, 1),
(182, 'list_a', 50, 14, 71, 5, 40, 4.44, 56.33, 15, 0, 0, 2, 1),
(182, 'odi', 11, 3, 17, 1, 9, 4.5, 52.94, 5, 0, 0, 1, 0),
(182, 't20', 77, 12, 29, 5, 10, 1.42, 34.48, 3, 0, 0, 0, 0),
(182, 't20i', 14, 1, 1, 1, 1, 0, 100, 1, 0, 0, 0, 0),
(183, 'first_class', 54, 87, 4640, 7, 3772, 47.15, 81.29, 308, 9, 17, 399, 125),
(183, 'list_a', 61, 56, 1547, 4, 1633, 31.4, 105.55, 135, 1, 11, 163, 56),
(183, 'odi', 24, 22, 654, 0, 715, 32.5, 109.32, 85, 0, 5, 70, 24),
(183, 't20', 154, 147, 2732, 26, 4004, 33.09, 146.55, 128, 2, 22, 360, 186),
(183, 't20i', 43, 37, 543, 9, 683, 24.39, 125.78, 65, 0, 3, 51, 29),
(183, 'test', 30, 51, 2725, 4, 1920, 40.85, 70.45, 159, 4, 9, 205, 44),
(184, 'first_class', 13, 25, 714, 1, 383, 15.95, 53.64, 71, 0, 1, 36, 11),
(184, 'list_a', 90, 86, 2455, 9, 2463, 31.98, 100.32, 106, 3, 15, 143, 142),
(184, 'odi', 37, 34, 952, 3, 786, 25.35, 82.56, 101, 1, 2, 47, 35),
(184, 't20', 122, 108, 1519, 21, 2071, 23.8, 136.34, 107, 1, 8, 116, 141),
(184, 't20i', 39, 31, 446, 6, 619, 24.76, 138.78, 107, 1, 3, 41, 37),
(185, 'first_class', 1, 2, 76, 0, 13, 6.5, 17.1, 12, 0, 0, 1, 0),
(185, 'list_a', 15, 10, 191, 2, 150, 18.75, 78.53, 56, 0, 1, 12, 2),
(185, 't20', 18, 9, 87, 4, 66, 13.2, 75.86, 39, 0, 0, 5, 0),
(186, 'first_class', 31, 55, 3088, 2, 2521, 47.56, 81.63, 202, 9, 11, 354, 25),
(186, 'list_a', 44, 44, 1853, 3, 2316, 56.48, 124.98, 227, 8, 8, 317, 57),
(186, 'odi', 6, 6, 166, 0, 189, 31.5, 113.85, 49, 0, 0, 32, 2),
(186, 't20', 81, 81, 1377, 0, 2045, 25.24, 148.51, 99, 0, 17, 232, 86),
(186, 't20i', 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(186, 'test', 5, 9, 394, 1, 339, 42.37, 86.04, 134, 1, 2, 48, 2),
(187, 'first_class', 22, 32, 1373, 7, 680, 27.2, 49.52, 77, 0, 3, 75, 12),
(187, 'list_a', 36, 36, 1341, 2, 1023, 30.08, 76.28, 101, 2, 4, 114, 22),
(187, 't20', 41, 39, 893, 7, 1117, 34.9, 125.08, 103, 1, 7, 112, 37),
(188, 'first_class', 18, 24, 614, 15, 181, 20.11, 29.47, 45, 0, 0, 20, 2),
(188, 'list_a', 15, 5, 23, 5, 27, 0, 117.39, 25, 0, 0, 3, 1),
(188, 'odi', 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0),
(188, 't20', 41, 8, 36, 2, 21, 3.5, 58.33, 7, 0, 0, 2, 0),
(188, 't20i', 2, 1, 9, 1, 5, 0, 55.55, 5, 0, 0, 0, 0),
(189, 'list_a', 14, 13, 191, 0, 185, 14.23, 96.85, 35, 0, 0, 10, 13),
(189, 't20', 21, 17, 196, 6, 305, 27.72, 155.61, 41, 0, 0, 21, 20),
(190, 'first_class', 3, 6, 700, 2, 479, 119.75, 68.42, 200, 3, 0, 66, 1),
(191, 'first_class', 15, 20, 1588, 2, 841, 46.72, 52.95, 177, 1, 7, 104, 16),
(191, 'list_a', 30, 24, 762, 8, 669, 41.81, 87.79, 75, 0, 5, 70, 10),
(191, 't20', 58, 44, 605, 19, 835, 33.4, 138.01, 52, 0, 1, 81, 33),
(192, 'first_class', 2, 2, 64, 0, 7, 3.5, 10.93, 5, 0, 0, 1, 0),
(193, 'first_class', 58, 79, 2437, 14, 1275, 19.61, 52.31, 100, 1, 4, 145, 28),
(193, 'list_a', 56, 33, 570, 11, 526, 23.9, 92.28, 69, 0, 2, 40, 15),
(193, 't20', 100, 44, 241, 22, 262, 11.9, 108.71, 29, 0, 0, 26, 7),
(194, 'first_class', 122, 186, 13347, 33, 6423, 41.98, 48.12, 203, 13, 38, 786, 54),
(194, 'list_a', 102, 90, 0, 25, 2762, 42.49, 0, 116, 2, 19, 240, 43),
(194, 'odi', 9, 5, 56, 2, 41, 13.66, 73.21, 16, 0, 0, 5, 0),
(194, 't20', 216, 188, 2974, 33, 3864, 24.92, 129.92, 129, 2, 20, 359, 128),
(194, 'test', 40, 56, 2973, 10, 1353, 29.41, 45.5, 117, 3, 6, 129, 14),
(195, 'first_class', 63, 99, 5781, 7, 3342, 36.32, 57.81, 177, 6, 19, 459, 42),
(195, 'list_a', 245, 212, 6533, 53, 6509, 40.93, 99.63, 139, 9, 39, 495, 181),
(195, 'odi', 143, 122, 3467, 36, 3503, 40.73, 101.03, 139, 5, 17, 260, 96),
(195, 't20', 373, 340, 5925, 111, 8200, 35.8, 138.39, 120, 3, 39, 585, 359),
(195, 't20i', 95, 83, 1270, 27, 1786, 31.89, 140.63, 101, 1, 4, 119, 79),
(196, 'first_class', 63, 95, 1928, 19, 799, 10.51, 41.44, 72, 0, 1, 103, 12),
(196, 'list_a', 73, 38, 381, 12, 299, 11.5, 78.47, 34, 0, 0, 26, 9),
(196, 'odi', 9, 3, 15, 2, 8, 8, 53.33, 6, 0, 0, 1, 0),
(196, 't20', 89, 31, 177, 17, 124, 8.85, 70.05, 17, 0, 0, 11, 3),
(196, 'test', 9, 14, 110, 5, 35, 3.88, 31.81, 9, 0, 0, 4, 0),
(197, 'first_class', 7, 13, 360, 2, 190, 17.27, 52.77, 35, 0, 0, 21, 1),
(197, 'list_a', 23, 21, 477, 6, 568, 37.86, 119.07, 91, 0, 4, 50, 24),
(197, 't20', 99, 78, 965, 29, 1385, 28.26, 143.52, 59, 0, 2, 125, 62),
(198, 'first_class', 48, 63, 4433, 9, 2286, 42.33, 51.56, 111, 5, 16, 269, 24),
(198, 'list_a', 92, 80, 2557, 16, 2316, 36.18, 90.57, 129, 2, 12, 181, 45),
(198, 'odi', 12, 8, 246, 1, 223, 31.85, 90.65, 46, 0, 0, 20, 4),
(198, 't20', 115, 91, 1391, 22, 1733, 25.11, 124.58, 69, 0, 6, 118, 64),
(198, 't20i', 9, 4, 73, 0, 101, 25.25, 138.35, 43, 0, 0, 11, 5),
(199, 'first_class', 83, 115, 1404, 34, 955, 11.79, 68.01, 56, 0, 2, 100, 31),
(199, 'list_a', 110, 61, 368, 21, 341, 8.52, 92.66, 26, 0, 0, 28, 16),
(199, 'odi', 79, 38, 194, 17, 161, 7.66, 82.98, 25, 0, 0, 12, 7),
(199, 't20', 129, 31, 87, 17, 81, 5.78, 93.1, 21, 0, 0, 6, 2),
(199, 't20i', 17, 2, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0),
(199, 'test', 59, 82, 883, 25, 656, 11.5, 74.29, 56, 0, 2, 71, 22),
(200, 'first_class', 45, 60, 1092, 23, 505, 13.64, 46.24, 41, 0, 0, 67, 9),
(200, 'list_a', 75, 41, 289, 15, 181, 6.96, 62.62, 24, 0, 0, 10, 6),
(200, 'odi', 37, 16, 132, 7, 63, 7, 47.72, 19, 0, 0, 3, 1),
(200, 't20', 102, 31, 166, 16, 207, 13.8, 124.69, 30, 0, 0, 13, 11),
(200, 't20i', 15, 2, 11, 0, 15, 7.5, 136.36, 14, 0, 0, 0, 2),
(200, 'test', 1, 2, 9, 2, 1, 0, 11.11, 1, 0, 0, 0, 0),
(201, 'first_class', 58, 86, 4199, 6, 3449, 43.11, 82.13, 201, 7, 20, 468, 40),
(201, 'list_a', 96, 86, 3782, 15, 3375, 47.53, 89.23, 139, 5, 25, 340, 59),
(201, 'odi', 3, 3, 13, 1, 13, 6.5, 100, 8, 0, 0, 2, 0),
(201, 't20', 118, 100, 1600, 23, 1985, 25.77, 124.06, 93, 0, 7, 188, 70),
(202, 'first_class', 29, 46, 2382, 1, 1351, 30.02, 56.71, 108, 1, 10, 167, 24),
(202, 'list_a', 84, 64, 1492, 12, 1620, 31.15, 108.57, 92, 0, 9, 113, 63),
(202, 'odi', 63, 46, 1100, 7, 1286, 32.97, 116.9, 92, 0, 7, 93, 54),
(202, 't20', 186, 158, 2234, 47, 3141, 28.29, 140.6, 91, 0, 11, 220, 173),
(202, 't20i', 54, 36, 378, 9, 553, 20.48, 146.29, 42, 0, 0, 34, 32),
(202, 'test', 11, 18, 720, 1, 532, 31.29, 73.88, 108, 1, 4, 68, 12),
(203, 'first_class', 53, 79, 1777, 12, 1073, 16.01, 60.38, 89, 0, 5, 113, 41),
(203, 'list_a', 57, 33, 509, 13, 355, 17.75, 69.74, 51, 0, 1, 21, 19),
(203, 'odi', 43, 25, 387, 10, 249, 16.6, 64.34, 29, 0, 0, 19, 10),
(203, 't20', 45, 24, 123, 15, 126, 14, 102.43, 21, 0, 0, 7, 5),
(203, 'test', 20, 31, 805, 0, 443, 14.29, 55.03, 86, 0, 2, 46, 17),
(204, 'first_class', 157, 251, 17065, 41, 8603, 40.96, 50.41, 152, 17, 53, 993, 97),
(204, 'list_a', 181, 161, 5313, 17, 4761, 33.06, 89.61, 155, 9, 21, 400, 113),
(204, 'odi', 97, 83, 2288, 12, 1867, 26.29, 81.59, 100, 1, 11, 129, 34),
(204, 't20', 180, 156, 2560, 24, 3480, 26.36, 135.93, 130, 1, 21, 285, 121),
(204, 't20i', 60, 45, 610, 9, 789, 21.91, 129.34, 80, 0, 3, 57, 32),
(204, 'test', 36, 63, 3203, 9, 1613, 29.87, 50.35, 117, 4, 5, 175, 12),
(205, 'first_class', 64, 99, 4954, 13, 2194, 25.51, 44.28, 211, 3, 9, 241, 5),
(205, 'list_a', 62, 49, 1173, 8, 915, 22.31, 78, 71, 0, 5, 83, 11),
(205, 'odi', 2, 2, 7, 1, 3, 3, 42.85, 2, 0, 0, 0, 0),
(205, 't20', 73, 38, 268, 16, 313, 14.22, 116.79, 31, 0, 0, 17, 12),
(205, 'test', 6, 9, 575, 1, 248, 31, 43.13, 104, 1, 1, 30, 1),
(206, 'first_class', 9, 11, 300, 1, 231, 23.1, 77, 52, 0, 2, 29, 4),
(206, 'list_a', 82, 64, 1048, 10, 1090, 20.18, 104, 60, 0, 5, 96, 38),
(206, 'odi', 80, 63, 1034, 10, 1069, 20.16, 103.38, 60, 0, 5, 91, 38),
(206, 't20', 314, 178, 983, 60, 1448, 12.27, 147.3, 56, 0, 1, 104, 95),
(206, 't20i', 58, 29, 154, 13, 183, 11.43, 118.83, 33, 0, 0, 11, 11),
(206, 'test', 5, 7, 133, 0, 106, 15.14, 79.69, 51, 0, 1, 11, 4),
(207, 'first_class', 20, 28, 1122, 5, 391, 17, 34.84, 81, 0, 1, 41, 7),
(207, 'list_a', 33, 19, 306, 6, 204, 15.69, 66.66, 61, 0, 1, 15, 6),
(207, 't20', 39, 6, 17, 2, 19, 4.75, 111.76, 7, 0, 0, 1, 1),
(208, 'first_class', 33, 57, 4051, 7, 2828, 56.56, 69.8, 268, 7, 15, 344, 38),
(208, 'list_a', 59, 58, 2652, 6, 2336, 44.92, 88.08, 143, 6, 11, 238, 42),
(208, 'odi', 3, 3, 71, 0, 49, 16.33, 69.01, 33, 0, 0, 5, 1),
(208, 't20', 85, 82, 1751, 13, 2218, 32.14, 126.67, 96, 0, 16, 219, 58),
(208, 'test', 10, 19, 983, 2, 558, 32.82, 56.76, 91, 0, 4, 70, 8),
(209, 'first_class', 12, 19, 1300, 0, 941, 49.52, 72.38, 153, 1, 7, 109, 32),
(209, 'list_a', 38, 34, 1261, 5, 1232, 42.48, 97.7, 128, 5, 3, 109, 52),
(209, 'odi', 9, 9, 466, 1, 428, 53.5, 91.84, 127, 3, 0, 33, 19),
(209, 't20', 69, 68, 1067, 1, 1620, 24.17, 151.82, 99, 0, 10, 127, 113),
(209, 't20i', 20, 20, 388, 0, 534, 26.7, 137.62, 87, 0, 3, 39, 35),
(210, 'first_class', 1, 1, 79, 0, 33, 33, 41.77, 33, 0, 0, 5, 1),
(210, 'list_a', 25, 21, 370, 6, 261, 17.4, 70.54, 38, 0, 0, 21, 7),
(210, 't20', 24, 12, 106, 2, 162, 16.2, 152.83, 48, 0, 0, 13, 10),
(210, 't20i', 5, 3, 10, 0, 9, 3, 90, 5, 0, 0, 2, 0),
(211, 'list_a', 3, 3, 90, 0, 54, 18, 60, 24, 0, 0, 8, 0),
(211, 't20', 12, 12, 266, 3, 322, 35.77, 121.05, 65, 0, 1, 33, 3),
(212, 'first_class', 14, 15, 231, 6, 157, 17.44, 67.96, 41, 0, 0, 26, 3),
(212, 'list_a', 14, 5, 24, 3, 18, 9, 75, 6, 0, 0, 2, 0),
(212, 't20', 20, 6, 14, 4, 10, 5, 71.42, 4, 0, 0, 1, 0),
(213, 'first_class', 3, 5, 92, 1, 74, 18.5, 80.43, 66, 0, 1, 9, 3),
(213, 'list_a', 17, 11, 177, 2, 197, 21.88, 111.29, 53, 0, 1, 10, 12),
(213, 't20', 24, 12, 85, 2, 73, 7.3, 85.88, 21, 0, 0, 3, 4),
(214, 'first_class', 1, 1, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(214, 'list_a', 8, 1, 16, 0, 2, 2, 12.5, 2, 0, 0, 0, 0),
(214, 't20', 37, 12, 38, 8, 37, 9.25, 97.36, 13, 0, 0, 3, 1),
(215, 'list_a', 2, 1, 32, 0, 34, 34, 106.25, 34, 0, 0, 2, 2),
(215, 't20', 12, 11, 183, 2, 270, 30, 147.54, 70, 0, 1, 25, 14),
(216, 'first_class', 94, 147, 10094, 20, 6714, 52.86, 66.51, 238, 21, 29, 771, 115),
(216, 'list_a', 173, 163, 6143, 36, 5764, 45.38, 93.83, 142, 10, 36, 447, 140),
(216, 'odi', 29, 24, 625, 7, 566, 33.29, 90.56, 104, 1, 2, 45, 5),
(216, 't20', 280, 257, 5178, 56, 6403, 31.85, 123.65, 129, 3, 36, 532, 195),
(216, 't20i', 39, 33, 562, 17, 709, 44.31, 126.15, 79, 0, 3, 49, 19),
(217, 'first_class', 122, 165, 4787, 7, 2411, 15.25, 50.36, 177, 2, 7, 304, 17),
(217, 'list_a', 119, 83, 1209, 20, 943, 14.96, 77.99, 53, 0, 1, 89, 5),
(217, 't20', 140, 51, 309, 16, 274, 7.82, 88.67, 36, 0, 0, 18, 7),
(217, 'test', 2, 3, 30, 1, 1, 0.5, 3.33, 1, 0, 0, 0, 0),
(218, 'first_class', 61, 105, 6178, 7, 3255, 33.21, 52.68, 170, 4, 24, 413, 34),
(218, 'list_a', 98, 91, 2927, 11, 2572, 32.15, 87.87, 146, 4, 14, 214, 91),
(218, 'odi', 48, 45, 1293, 7, 1200, 31.57, 92.8, 146, 1, 6, 103, 40),
(218, 't20', 192, 173, 2960, 46, 3986, 31.38, 134.66, 147, 1, 20, 343, 147),
(218, 't20i', 41, 33, 405, 13, 565, 28.25, 139.5, 78, 0, 1, 55, 19),
(219, 'first_class', 43, 74, 3166, 6, 2082, 30.61, 65.76, 210, 3, 14, 247, 42),
(219, 'list_a', 59, 53, 0, 11, 1131, 26.92, 0, 113, 1, 4, 0, 0),
(219, 'odi', 3, 3, 88, 0, 51, 17, 57.95, 40, 0, 0, 6, 1),
(219, 't20', 76, 69, 854, 14, 992, 18.03, 116.15, 85, 0, 2, 63, 54),
(219, 't20i', 7, 7, 99, 1, 142, 23.66, 143.43, 40, 0, 0, 15, 8),
(219, 'test', 11, 21, 1065, 2, 664, 34.94, 62.34, 210, 1, 2, 83, 11),
(220, 'first_class', 84, 142, 7240, 10, 5463, 41.38, 75.45, 194, 12, 36, 684, 71),
(220, 'list_a', 170, 168, 7298, 7, 7044, 43.75, 96.51, 178, 21, 34, 783, 121),
(220, 'odi', 129, 129, 5895, 6, 5658, 46, 95.97, 178, 17, 28, 646, 88),
(220, 't20', 249, 243, 5460, 18, 7477, 33.23, 136.94, 126, 4, 46, 783, 279),
(220, 't20i', 61, 61, 1353, 7, 1827, 33.83, 135.03, 79, 0, 11, 189, 65),
(220, 'test', 54, 91, 4652, 6, 3300, 38.82, 70.93, 141, 6, 22, 411, 33),
(221, 'first_class', 88, 143, 0, 16, 3310, 26.06, 0, 202, 3, 13, 0, 0),
(221, 'list_a', 185, 150, 0, 28, 2980, 24.42, 0, 99, 0, 16, 0, 0),
(221, 'odi', 127, 103, 2214, 21, 2019, 24.62, 91.19, 99, 0, 11, 146, 64),
(221, 't20', 174, 129, 1159, 32, 1481, 15.26, 127.78, 69, 0, 2, 96, 89),
(221, 't20i', 37, 24, 218, 8, 264, 16.5, 121.1, 36, 0, 0, 14, 16),
(221, 'test', 56, 100, 4546, 16, 2571, 30.6, 56.55, 202, 3, 11, 308, 43),
(222, 'first_class', 86, 146, 11779, 5, 6444, 45.7, 54.7, 337, 17, 31, 810, 50),
(222, 'list_a', 94, 93, 4538, 11, 3644, 44.43, 80.29, 131, 9, 23, 293, 69),
(222, 'odi', 42, 41, 1844, 6, 1634, 46.68, 88.61, 112, 5, 10, 124, 38),
(222, 't20', 184, 171, 4489, 29, 6201, 43.66, 138.13, 132, 6, 51, 537, 252),
(222, 't20i', 56, 52, 1285, 7, 1831, 40.68, 142.49, 110, 2, 16, 164, 73),
(222, 'test', 43, 74, 4833, 2, 2547, 35.37, 52.7, 199, 7, 13, 310, 17),
(223, 'first_class', 47, 60, 1394, 3, 1112, 19.5, 79.77, 149, 1, 5, 102, 45),
(223, 'list_a', 49, 34, 398, 7, 560, 20.74, 140.7, 57, 0, 1, 42, 36),
(223, 'odi', 1, 1, 3, 0, 2, 2, 66.66, 2, 0, 0, 0, 0),
(223, 't20', 70, 54, 391, 12, 610, 14.52, 156.01, 60, 0, 2, 53, 32),
(224, 'first_class', 22, 42, 0, 2, 1229, 30.72, 0, 104, 1, 8, 0, 0),
(224, 'list_a', 100, 95, 0, 6, 3243, 36.43, 0, 176, 7, 19, 334, 106),
(224, 'odi', 57, 54, 2226, 4, 1847, 36.94, 82.97, 176, 4, 10, 185, 52),
(224, 't20', 196, 192, 3847, 13, 5589, 31.22, 145.28, 125, 5, 39, 453, 385),
(224, 't20i', 50, 49, 915, 3, 1423, 30.93, 155.51, 125, 2, 10, 106, 110),
(225, 'first_class', 9, 10, 112, 0, 52, 5.2, 46.42, 10, 0, 0, 4, 2),
(225, 'list_a', 52, 32, 291, 12, 325, 16.25, 111.68, 44, 0, 0, 24, 15),
(225, 'odi', 7, 7, 48, 3, 57, 14.25, 118.75, 19, 0, 0, 5, 2),
(225, 't20', 185, 74, 432, 28, 522, 11.34, 120.83, 44, 0, 0, 34, 27),
(225, 't20i', 32, 15, 76, 7, 83, 10.37, 109.21, 20, 0, 0, 5, 4),
(226, 'first_class', 9, 17, 746, 0, 486, 28.58, 65.14, 160, 2, 2, 68, 3),
(226, 'list_a', 77, 73, 2639, 12, 2267, 37.16, 85.9, 133, 2, 12, 228, 45),
(226, 'odi', 5, 4, 128, 2, 130, 65, 101.56, 58, 0, 1, 11, 2),
(226, 't20', 152, 122, 1423, 36, 1911, 22.22, 134.29, 86, 0, 4, 166, 73),
(226, 't20i', 19, 10, 95, 5, 124, 24.8, 130.52, 26, 0, 0, 8, 6),
(227, 'first_class', 46, 73, 4639, 5, 2908, 42.76, 62.68, 293, 9, 15, 337, 50),
(227, 'list_a', 78, 71, 2498, 10, 2338, 38.32, 93.59, 161, 4, 12, 187, 61),
(227, 'odi', 2, 2, 57, 1, 55, 55, 96.49, 29, 0, 0, 4, 0),
(227, 't20', 156, 129, 1846, 25, 2540, 24.42, 137.59, 108, 1, 16, 171, 116),
(227, 't20i', 3, 1, 16, 0, 21, 21, 131.25, 21, 0, 0, 1, 1),
(228, 'first_class', 40, 63, 3924, 0, 2386, 37.87, 60.8, 224, 7, 11, 332, 14),
(228, 'list_a', 57, 55, 2166, 2, 1854, 34.98, 85.59, 143, 5, 10, 194, 29),
(228, 't20', 109, 105, 2170, 8, 2813, 29, 129.63, 106, 1, 16, 276, 102),
(229, 'first_class', 42, 47, 648, 14, 236, 7.15, 36.41, 28, 0, 0, 33, 0),
(229, 'list_a', 81, 46, 441, 25, 291, 13.85, 65.98, 29, 0, 0, 20, 5),
(229, 'odi', 39, 28, 334, 10, 217, 12.05, 64.97, 29, 0, 0, 15, 3),
(229, 't20', 98, 43, 180, 20, 176, 7.65, 97.77, 24, 0, 0, 14, 6),
(229, 't20i', 47, 23, 89, 11, 85, 7.08, 95.5, 24, 0, 0, 8, 1),
(229, 'test', 12, 21, 342, 2, 104, 5.47, 30.4, 22, 0, 0, 13, 0),
(230, 'first_class', 66, 78, 724, 24, 236, 4.37, 32.59, 32, 0, 0, 30, 4),
(230, 'list_a', 41, 21, 139, 9, 90, 7.5, 64.74, 18, 0, 0, 10, 1),
(230, 't20', 87, 20, 88, 11, 66, 7.33, 75, 8, 0, 0, 5, 2),
(231, 'first_class', 27, 28, 556, 7, 292, 13.9, 52.51, 64, 0, 1, 24, 17),
(231, 'list_a', 22, 15, 83, 8, 64, 9.14, 77.1, 28, 0, 0, 4, 3),
(231, 't20', 60, 13, 41, 5, 48, 6, 117.07, 12, 0, 0, 3, 3),
(231, 't20i', 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(232, 'first_class', 1, 1, 13, 0, 8, 8, 61.53, 8, 0, 0, 1, 0),
(232, 'list_a', 18, 11, 61, 3, 76, 9.5, 124.59, 34, 0, 0, 5, 5),
(232, 't20', 32, 14, 57, 4, 69, 6.9, 121.05, 19, 0, 0, 5, 3),
(233, 'list_a', 17, 12, 98, 4, 102, 12.75, 104.08, 20, 0, 0, 6, 7),
(233, 't20', 57, 13, 80, 5, 61, 7.62, 76.25, 22, 0, 0, 7, 1),
(233, 't20i', 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(234, 't20', 17, 11, 140, 3, 169, 21.12, 120.71, 54, 0, 1, 12, 7),
(235, 'first_class', 3, 6, 368, 0, 204, 34, 55.43, 116, 1, 0, 18, 8),
(235, 'list_a', 15, 15, 539, 2, 369, 28.38, 68.46, 83, 0, 1, 35, 5),
(235, 't20', 11, 11, 225, 1, 305, 30.5, 135.55, 68, 0, 4, 30, 11),
(236, 'list_a', 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

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

--
-- Dumping data for table `player_statistics_bowling`
--

INSERT INTO `player_statistics_bowling` (`playerId`, `type`, `matches`, `innings`, `overs`, `ballsBalled`, `maidens`, `runs`, `wickets`, `average`, `strikeRate`, `economy`, `bestBowling`, `fourWicketHauls`, `fiverWicketHauls`, `tenWicketHauls`, `catches`, `stumping`, `runOuts`) VALUES
(1, 'first_class', 154, 142, 1104, 6624, 175, 3721, 86, 43.26, 77.02, 3.37, 5, 1, 1, 0, 136, 0, 3),
(1, 'list_a', 212, 99, 459.2, 2756, 7, 2383, 67, 35.56, 41.13, 5.18, 5, 1, 1, 0, 87, 0, 11),
(1, 'odi', 151, 65, 244.3, 1467, 2, 1310, 37, 35.4, 39.64, 5.35, 4, 1, 0, 0, 60, 0, 7),
(1, 't20', 230, 54, 128.2, 770, 1, 909, 30, 30.3, 25.66, 7.08, 3, 0, 0, 0, 99, 0, 10),
(1, 't20i', 74, 12, 19.4, 118, 0, 164, 6, 27.33, 19.66, 8.33, 2, 0, 0, 0, 34, 0, 3),
(1, 'test', 86, 67, 358.3, 2151, 48, 1207, 30, 40.23, 71.7, 3.36, 4, 1, 0, 0, 72, 0, 3),
(2, 'first_class', 70, 123, 2065.3, 12393, 526, 5785, 218, 26.53, 56.84, 2.8, 9, 9, 12, 0, 18, 0, 1),
(2, 'list_a', 168, 165, 1352.2, 8114, 108, 6583, 208, 31.64, 39, 4.86, 5, 6, 1, 0, 42, 0, 6),
(2, 'odi', 121, 120, 974.3, 5847, 68, 4951, 141, 35.11, 41.46, 5.08, 5, 4, 1, 0, 29, 0, 3),
(2, 't20', 218, 218, 801.1, 4807, 13, 5751, 222, 25.9, 21.65, 7.17, 5, 3, 2, 0, 46, 0, 10),
(2, 't20i', 59, 59, 208.5, 1253, 3, 1460, 58, 25.17, 21.6, 6.99, 5, 1, 1, 0, 10, 0, 2),
(2, 'test', 21, 37, 558, 3348, 141, 1644, 63, 26.09, 53.14, 2.94, 8, 3, 4, 0, 8, 0, 0),
(3, 'first_class', 67, 122, 1577.1, 9463, 195, 5735, 202, 28.39, 46.84, 3.63, 9, 14, 7, 0, 21, 0, 5),
(3, 'list_a', 47, 46, 344.5, 2069, 9, 1801, 77, 23.38, 26.87, 5.22, 5, 1, 2, 0, 16, 0, 2),
(3, 't20', 83, 80, 255.3, 1533, 3, 1934, 92, 21.02, 16.66, 7.56, 5, 2, 2, 0, 19, 0, 2),
(4, 'first_class', 47, 50, 275.2, 1652, 62, 832, 11, 75.63, 150.18, 3.02, 2, 0, 0, 0, 30, 0, 1),
(4, 'list_a', 43, 23, 74.3, 447, 3, 408, 5, 81.6, 89.4, 5.47, 2, 0, 0, 0, 14, 0, 7),
(4, 't20', 115, 17, 37, 222, 0, 281, 12, 23.41, 18.5, 7.59, 5, 0, 1, 0, 56, 0, 3),
(5, 'first_class', 9, 9, 73.3, 441, 16, 227, 4, 56.75, 110.25, 3.08, 2, 0, 0, 0, 5, 0, 0),
(5, 'list_a', 23, 21, 121.5, 731, 1, 673, 22, 30.59, 33.22, 5.52, 3, 0, 0, 0, 4, 0, 2),
(5, 't20', 41, 18, 42, 252, 0, 352, 10, 35.2, 25.2, 8.38, 3, 0, 0, 0, 7, 0, 1),
(6, 'first_class', 66, 119, 1872.4, 11236, 383, 5822, 180, 32.34, 62.42, 3.1, 8, 7, 5, 0, 39, 0, 3),
(6, 'list_a', 70, 67, 521, 3126, 17, 2774, 109, 25.44, 28.67, 5.32, 5, 3, 2, 0, 31, 0, 3),
(6, 'odi', 5, 5, 34, 204, 0, 234, 3, 78, 68, 6.88, 1, 0, 0, 0, 2, 0, 0),
(6, 't20', 110, 108, 347.5, 2087, 1, 2961, 136, 21.77, 15.34, 8.51, 5, 3, 1, 0, 66, 0, 7),
(6, 't20i', 8, 8, 22, 132, 0, 178, 5, 35.6, 26.4, 8.09, 2, 0, 0, 0, 4, 0, 0),
(7, 'first_class', 69, 36, 105, 630, 9, 415, 6, 69.16, 105, 3.95, 2, 0, 0, 0, 75, 0, 4),
(7, 'list_a', 45, 3, 12, 72, 0, 51, 1, 51, 72, 4.25, 1, 0, 0, 0, 17, 0, 6),
(7, 't20', 23, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 1),
(8, 'first_class', 17, 30, 470.5, 2825, 91, 1409, 51, 27.62, 55.39, 2.99, 9, 3, 3, 0, 10, 0, 3),
(8, 'list_a', 27, 26, 205.1, 1231, 11, 866, 34, 25.47, 36.2, 4.22, 5, 2, 1, 0, 4, 0, 4),
(8, 't20', 71, 70, 234, 1404, 2, 1711, 63, 27.15, 22.28, 7.31, 3, 0, 0, 0, 30, 0, 7),
(9, 'first_class', 84, 35, 142.4, 856, 25, 398, 6, 66.33, 142.66, 2.78, 2, 0, 0, 0, 84, 0, 10),
(9, 'list_a', 85, 40, 197.1, 1183, 1, 1014, 35, 28.97, 33.8, 5.14, 4, 1, 0, 0, 42, 0, 9),
(9, 'odi', 38, 13, 67, 402, 0, 355, 9, 39.44, 44.66, 5.29, 2, 0, 0, 0, 18, 0, 3),
(9, 't20', 81, 32, 68.3, 411, 2, 485, 13, 37.3, 31.61, 7.08, 3, 0, 0, 0, 39, 0, 3),
(9, 't20i', 20, 8, 18, 108, 2, 134, 5, 26.8, 21.6, 7.44, 3, 0, 0, 0, 16, 0, 0),
(9, 'test', 31, 12, 41.2, 248, 5, 130, 2, 65, 124, 3.14, 2, 0, 0, 0, 29, 0, 4),
(10, 'first_class', 5, 1, 1, 6, 0, 3, 1, 3, 6, 3, 1, 0, 0, 0, 2, 2, 0),
(10, 'list_a', 62, 1, 0.3, 3, 0, 6, 0, 0, 0, 12, 0, 0, 0, 0, 32, 2, 3),
(10, 'odi', 37, 1, 0.3, 3, 0, 6, 0, 0, 0, 12, 0, 0, 0, 0, 12, 2, 2),
(10, 't20', 228, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 121, 20, 19),
(10, 't20i', 57, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 28, 5, 4),
(11, 'first_class', 24, 41, 682.3, 4095, 168, 2126, 98, 21.69, 41.78, 3.11, 8, 7, 3, 0, 11, 0, 1),
(11, 'list_a', 16, 16, 112.5, 677, 7, 606, 19, 31.89, 35.63, 5.37, 3, 0, 0, 0, 4, 0, 0),
(11, 'odi', 2, 2, 19, 114, 1, 106, 2, 53, 57, 5.57, 2, 0, 0, 0, 0, 0, 0),
(11, 't20', 20, 20, 73, 438, 0, 593, 15, 39.53, 29.2, 8.12, 3, 0, 0, 0, 8, 0, 1),
(11, 'test', 5, 9, 178.2, 1070, 40, 570, 28, 20.35, 38.21, 3.19, 7, 4, 0, 0, 4, 0, 0),
(12, 'first_class', 17, 27, 377.4, 2266, 77, 1107, 36, 30.75, 62.94, 2.93, 11, 1, 2, 1, 8, 0, 0),
(12, 'list_a', 50, 44, 321.3, 1929, 11, 1486, 44, 33.77, 43.84, 4.62, 5, 0, 1, 0, 20, 0, 2),
(12, 'odi', 4, 4, 28, 168, 1, 140, 5, 28, 33.6, 5, 3, 0, 0, 0, 2, 0, 0),
(12, 't20', 104, 101, 332.3, 1995, 2, 2273, 78, 29.14, 25.57, 6.83, 3, 0, 0, 0, 28, 0, 0),
(12, 't20i', 31, 30, 103.3, 621, 1, 750, 25, 30, 24.84, 7.24, 3, 0, 0, 0, 10, 0, 0),
(12, 'test', 4, 7, 87.4, 526, 10, 299, 6, 49.83, 87.66, 3.41, 4, 0, 0, 0, 1, 0, 0),
(13, 'first_class', 23, 2, 7, 42, 2, 22, 0, 0, 0, 3.14, 0, 0, 0, 0, 40, 3, 0),
(13, 'list_a', 38, 9, 32.2, 194, 0, 214, 6, 35.66, 32.33, 6.61, 3, 0, 0, 0, 22, 1, 2),
(13, 't20', 43, 2, 3.1, 19, 0, 24, 0, 0, 0, 7.57, 0, 0, 0, 0, 12, 5, 1),
(14, 'first_class', 21, 35, 609.4, 3658, 131, 1849, 67, 27.59, 54.59, 3.03, 8, 3, 3, 0, 5, 0, 0),
(14, 'list_a', 17, 17, 134.3, 807, 5, 636, 19, 33.47, 42.47, 4.72, 3, 0, 0, 0, 2, 0, 0),
(14, 'odi', 2, 2, 20, 120, 1, 143, 3, 47.66, 40, 7.15, 2, 0, 0, 0, 0, 0, 0),
(14, 't20', 58, 58, 207, 1242, 2, 1657, 67, 24.73, 18.53, 8, 3, 0, 0, 0, 16, 0, 0),
(14, 't20i', 4, 4, 16, 96, 0, 122, 7, 17.42, 13.71, 7.62, 3, 0, 0, 0, 0, 0, 0),
(14, 'test', 1, 2, 38.2, 230, 7, 119, 3, 39.66, 76.66, 3.1, 3, 0, 0, 0, 0, 0, 0),
(15, 'first_class', 12, 15, 190, 1140, 19, 657, 14, 46.92, 81.42, 3.45, 4, 1, 0, 0, 14, 0, 1),
(15, 'list_a', 32, 19, 103, 618, 3, 536, 9, 59.55, 68.66, 5.2, 2, 0, 0, 0, 10, 0, 2),
(15, 't20', 54, 24, 49, 294, 2, 348, 16, 21.75, 18.37, 7.1, 3, 0, 0, 0, 15, 0, 1),
(16, 'first_class', 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 0, 0),
(16, 'list_a', 29, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 2),
(16, 't20', 38, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 13, 0, 3),
(17, 'first_class', 44, 47, 357.5, 2147, 65, 1229, 34, 36.14, 63.14, 3.43, 4, 1, 0, 0, 42, 0, 0),
(17, 'list_a', 47, 16, 68, 408, 0, 360, 11, 32.72, 37.09, 5.29, 3, 0, 0, 0, 28, 2, 4),
(17, 't20', 155, 18, 33.3, 201, 0, 275, 11, 25, 18.27, 8.2, 2, 0, 0, 0, 79, 10, 14),
(17, 't20i', 35, 5, 8.3, 51, 0, 68, 2, 34, 25.5, 8, 1, 0, 0, 0, 19, 2, 1),
(17, 'test', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0),
(18, 'first_class', 13, 15, 41, 246, 2, 177, 6, 29.5, 41, 4.31, 2, 0, 0, 0, 11, 0, 0),
(18, 'list_a', 16, 8, 30, 180, 0, 174, 2, 87, 90, 5.8, 1, 0, 0, 0, 3, 0, 0),
(18, 't20', 46, 13, 20, 120, 0, 204, 4, 51, 30, 10.2, 1, 0, 0, 0, 26, 0, 1),
(19, 'first_class', 2, 4, 38, 228, 8, 106, 3, 35.33, 76, 2.78, 3, 0, 0, 0, 1, 0, 0),
(19, 'list_a', 7, 7, 59, 354, 1, 335, 10, 33.5, 35.4, 5.67, 3, 0, 0, 0, 1, 0, 0),
(19, 't20', 16, 16, 60.1, 361, 0, 570, 14, 40.71, 25.78, 9.47, 2, 0, 0, 0, 3, 0, 0),
(20, 'first_class', 25, 48, 588, 3528, 139, 1822, 74, 24.62, 47.67, 3.09, 8, 1, 2, 0, 13, 0, 1),
(20, 'list_a', 40, 39, 273.5, 1643, 12, 1518, 47, 32.29, 34.95, 5.54, 4, 1, 0, 0, 11, 0, 1),
(20, 'odi', 10, 10, 66.1, 397, 3, 331, 8, 41.37, 49.62, 5, 3, 0, 0, 0, 4, 0, 1),
(20, 't20', 49, 44, 144.3, 867, 3, 1306, 58, 22.51, 14.94, 9.03, 4, 1, 0, 0, 12, 0, 1),
(20, 't20i', 17, 14, 44.5, 269, 0, 503, 14, 35.92, 19.21, 11.21, 3, 0, 0, 0, 4, 0, 0),
(21, 'first_class', 4, 7, 75.2, 452, 7, 307, 13, 23.61, 34.76, 4.07, 6, 0, 1, 0, 0, 0, 0),
(21, 'list_a', 2, 2, 14, 84, 0, 85, 1, 85, 84, 6.07, 1, 0, 0, 0, 0, 0, 0),
(22, 'first_class', 3, 5, 58, 348, 3, 289, 7, 41.28, 49.71, 4.98, 4, 0, 0, 0, 0, 0, 0),
(22, 'list_a', 1, 1, 10, 60, 0, 98, 1, 98, 60, 9.8, 1, 0, 0, 0, 0, 0, 0),
(22, 't20', 19, 19, 72, 432, 1, 637, 26, 24.5, 16.61, 8.84, 5, 2, 1, 0, 6, 0, 1),
(23, 'first_class', 12, 21, 210.1, 1261, 30, 794, 22, 36.09, 57.31, 3.77, 7, 0, 1, 0, 8, 0, 0),
(23, 'list_a', 10, 10, 81.2, 488, 4, 474, 13, 36.46, 37.53, 5.82, 4, 1, 0, 0, 1, 0, 0),
(23, 'odi', 4, 4, 33.5, 203, 3, 176, 7, 25.14, 29, 5.2, 4, 1, 0, 0, 1, 0, 0),
(23, 't20', 8, 8, 28.3, 171, 0, 227, 8, 28.37, 21.37, 7.96, 3, 0, 0, 0, 1, 0, 0),
(23, 't20i', 3, 3, 12, 72, 0, 72, 6, 12, 12, 6, 3, 0, 0, 0, 0, 0, 0),
(24, 'first_class', 27, 24, 135.1, 811, 19, 436, 14, 31.14, 57.92, 3.22, 5, 0, 1, 0, 42, 0, 2),
(24, 'list_a', 167, 109, 500, 3000, 9, 2750, 96, 28.64, 31.25, 5.5, 5, 1, 1, 0, 93, 0, 11),
(24, 'odi', 123, 82, 379.1, 2275, 4, 2161, 55, 39.29, 41.36, 5.69, 3, 0, 0, 0, 64, 0, 9),
(24, 't20', 592, 375, 936.5, 5621, 1, 7699, 308, 24.99, 18.25, 8.21, 4, 7, 0, 0, 324, 0, 31),
(24, 't20i', 101, 63, 142.4, 856, 0, 1188, 42, 28.28, 20.38, 8.32, 4, 1, 0, 0, 42, 0, 1),
(25, 'first_class', 106, 70, 358.5, 2153, 48, 1154, 24, 48.08, 89.7, 3.21, 5, 1, 0, 0, 95, 0, 5),
(25, 'list_a', 301, 70, 227.5, 1367, 5, 1162, 30, 38.73, 45.56, 5.1, 4, 1, 0, 0, 106, 0, 20),
(25, 'odi', 230, 38, 98.5, 593, 2, 515, 8, 64.37, 74.12, 5.21, 2, 0, 0, 0, 82, 0, 15),
(25, 't20', 381, 59, 105.5, 635, 0, 830, 29, 28.62, 21.89, 7.84, 4, 1, 0, 0, 153, 0, 16),
(25, 't20i', 125, 9, 11.2, 68, 0, 113, 1, 113, 68, 9.97, 1, 0, 0, 0, 50, 0, 5),
(25, 'test', 45, 16, 63.5, 383, 5, 224, 2, 112, 191.5, 3.5, 1, 0, 0, 0, 49, 0, 1),
(26, 'first_class', 92, 157, 2657.1, 15943, 608, 7816, 336, 23.26, 47.44, 2.94, 13, 17, 20, 5, 36, 0, 4),
(26, 'list_a', 106, 106, 930.2, 5582, 68, 4561, 149, 30.61, 37.46, 4.9, 5, 5, 1, 0, 26, 0, 10),
(26, 'odi', 7, 7, 52, 312, 5, 209, 8, 26.12, 39, 4.01, 4, 1, 0, 0, 0, 0, 1),
(26, 't20', 163, 162, 583.1, 3499, 5, 4666, 201, 23.21, 17.4, 8, 5, 2, 2, 0, 45, 0, 14),
(26, 't20i', 10, 10, 34.4, 208, 0, 301, 14, 21.5, 14.85, 8.68, 3, 0, 0, 0, 3, 0, 0),
(26, 'test', 1, 1, 26, 156, 4, 101, 0, 0, 0, 3.88, 0, 0, 0, 0, 0, 0, 0),
(27, 'first_class', 4, 3, 75, 450, 3, 280, 1, 280, 450, 3.73, 1, 0, 0, 0, 1, 0, 0),
(27, 'list_a', 23, 21, 140.1, 841, 3, 817, 21, 38.9, 40.04, 5.82, 3, 0, 0, 0, 10, 0, 2),
(27, 't20', 93, 93, 320.3, 1923, 1, 2339, 91, 25.7, 21.13, 7.29, 3, 0, 0, 0, 28, 0, 3),
(28, 'first_class', 8, 5, 20, 120, 5, 68, 1, 68, 120, 3.4, 1, 0, 0, 0, 12, 0, 2),
(28, 'list_a', 12, 1, 2, 12, 0, 11, 0, 0, 0, 5.5, 0, 0, 0, 0, 10, 0, 0),
(28, 't20', 17, 5, 11, 66, 0, 93, 1, 93, 66, 8.45, 1, 0, 0, 0, 3, 0, 1),
(29, 'first_class', 57, 102, 1886.2, 11318, 494, 5037, 215, 23.42, 52.64, 2.67, 9, 5, 14, 0, 16, 0, 0),
(29, 'list_a', 95, 95, 843, 5058, 58, 3774, 165, 22.87, 30.65, 4.47, 5, 8, 2, 0, 25, 0, 7),
(29, 'odi', 70, 70, 617.1, 3703, 39, 2873, 113, 25.42, 32.76, 4.65, 5, 5, 1, 0, 17, 0, 5),
(29, 't20', 204, 203, 763, 4578, 16, 5365, 248, 21.63, 18.45, 7.03, 5, 2, 1, 0, 29, 0, 10),
(29, 't20i', 57, 56, 204.5, 1229, 8, 1333, 67, 19.89, 18.34, 6.5, 3, 0, 0, 0, 7, 0, 2),
(29, 'test', 29, 56, 1008.4, 6052, 250, 2673, 123, 21.73, 49.2, 2.65, 9, 2, 8, 0, 7, 0, 0),
(30, 'first_class', 43, 82, 1476, 8856, 316, 4510, 181, 24.91, 48.92, 3.05, 11, 10, 8, 1, 21, 0, 0),
(30, 'list_a', 31, 30, 273.4, 1642, 20, 1365, 51, 26.76, 32.19, 4.98, 5, 0, 1, 0, 9, 0, 1),
(30, 'odi', 17, 17, 151.5, 911, 12, 720, 30, 24, 30.36, 4.74, 3, 0, 0, 0, 5, 0, 0),
(30, 't20', 121, 118, 450, 2700, 4, 3446, 153, 22.52, 17.64, 7.65, 4, 2, 0, 0, 35, 0, 10),
(30, 't20i', 12, 12, 47, 282, 1, 371, 14, 26.5, 20.14, 7.89, 4, 1, 0, 0, 4, 0, 2),
(30, 'test', 13, 24, 434.5, 2609, 95, 1304, 42, 31.04, 62.11, 2.99, 8, 0, 3, 0, 2, 0, 0),
(31, 'first_class', 15, 19, 177.5, 1067, 20, 575, 15, 38.33, 71.13, 3.23, 5, 1, 0, 0, 10, 0, 0),
(31, 'list_a', 36, 31, 207.5, 1247, 3, 1080, 19, 56.84, 65.63, 5.19, 2, 0, 0, 0, 17, 0, 4),
(31, 'odi', 20, 18, 111, 666, 0, 627, 7, 89.57, 95.14, 5.64, 2, 0, 0, 0, 10, 0, 3),
(31, 't20', 70, 60, 175, 1050, 2, 1382, 43, 32.13, 24.41, 7.89, 2, 0, 0, 0, 35, 0, 4),
(31, 't20i', 34, 29, 86.5, 521, 1, 646, 24, 26.91, 21.7, 7.43, 2, 0, 0, 0, 22, 0, 4),
(32, 'first_class', 46, 1, 4, 24, 1, 14, 0, 0, 0, 3.5, 0, 0, 0, 0, 97, 11, 1),
(32, 'list_a', 80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 90, 9, 9),
(32, 'odi', 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1),
(32, 't20', 126, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 60, 9, 8),
(32, 't20i', 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 2, 2),
(33, 'first_class', 38, 64, 773.1, 4639, 131, 2570, 90, 28.55, 51.54, 3.32, 8, 5, 2, 0, 8, 0, 1),
(33, 'list_a', 31, 30, 210.3, 1263, 8, 1102, 40, 27.55, 31.57, 5.23, 6, 1, 1, 0, 4, 0, 0),
(33, 't20', 73, 73, 254, 1524, 3, 2149, 74, 29.04, 20.59, 8.46, 4, 1, 0, 0, 16, 0, 5),
(34, 'first_class', 77, 50, 192.2, 1154, 29, 550, 24, 22.91, 48.08, 2.85, 4, 1, 0, 0, 101, 0, 1),
(34, 'list_a', 109, 17, 71.4, 430, 2, 378, 6, 63, 71.66, 5.27, 2, 0, 0, 0, 65, 0, 5),
(34, 'odi', 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0),
(34, 't20', 206, 10, 22, 132, 0, 140, 6, 23.33, 22, 6.36, 2, 0, 0, 0, 103, 0, 7),
(34, 't20i', 14, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 13, 0, 1),
(35, 'first_class', 9, 15, 277.5, 1667, 69, 696, 55, 12.65, 30.3, 2.5, 13, 3, 5, 3, 3, 0, 1),
(35, 'list_a', 13, 13, 98.2, 590, 4, 345, 21, 16.42, 28.09, 3.5, 4, 1, 0, 0, 1, 0, 0),
(35, 't20', 27, 19, 67, 402, 3, 446, 16, 27.87, 25.12, 6.65, 2, 0, 0, 0, 18, 0, 1),
(36, 'first_class', 2, 1, 3, 18, 1, 14, 0, 0, 0, 4.66, 0, 0, 0, 0, 1, 0, 0),
(36, 'list_a', 10, 2, 9, 54, 0, 52, 1, 52, 54, 5.77, 1, 0, 0, 0, 3, 0, 0),
(36, 't20', 15, 5, 11, 66, 0, 76, 3, 25.33, 22, 6.9, 2, 0, 0, 0, 5, 0, 1),
(37, 'first_class', 20, 35, 551.2, 3308, 101, 2001, 58, 34.5, 57.03, 3.62, 5, 2, 1, 0, 4, 0, 0),
(37, 'list_a', 24, 24, 205, 1230, 5, 1081, 33, 32.75, 37.27, 5.27, 4, 1, 0, 0, 11, 0, 0),
(37, 'odi', 1, 1, 5, 30, 0, 36, 0, 0, 0, 7.2, 0, 0, 0, 0, 0, 0, 0),
(37, 't20', 60, 60, 216.5, 1301, 0, 1815, 76, 23.88, 17.11, 8.37, 4, 1, 0, 0, 10, 0, 1),
(37, 't20i', 5, 5, 18.5, 113, 0, 188, 8, 23.5, 14.12, 9.98, 3, 0, 0, 0, 0, 0, 0),
(38, 'first_class', 30, 7, 18, 108, 1, 54, 1, 54, 108, 3, 1, 0, 0, 0, 25, 0, 0),
(38, 'list_a', 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 3),
(38, 't20', 39, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 0, 2),
(39, 'first_class', 5, 8, 154.4, 928, 34, 494, 13, 38, 71.38, 3.19, 6, 1, 0, 0, 2, 0, 0),
(39, 'list_a', 14, 13, 100.2, 602, 2, 519, 21, 24.71, 28.66, 5.17, 5, 0, 1, 0, 4, 0, 2),
(39, 't20', 82, 80, 271.5, 1631, 2, 2331, 95, 24.53, 17.16, 8.57, 4, 4, 0, 0, 33, 0, 1),
(39, 't20i', 7, 7, 20.5, 125, 0, 210, 4, 52.5, 31.25, 10.08, 2, 0, 0, 0, 3, 0, 1),
(40, 'first_class', 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0),
(40, 'list_a', 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 13, 2, 0),
(40, 't20', 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0),
(41, 'list_a', 16, 6, 36, 216, 1, 151, 9, 16.77, 24, 4.19, 3, 0, 0, 0, 12, 0, 0),
(41, 't20', 92, 29, 55, 330, 0, 493, 8, 61.62, 41.25, 8.96, 1, 0, 0, 0, 50, 0, 3),
(41, 't20i', 14, 11, 27.2, 164, 0, 255, 5, 51, 32.8, 9.32, 1, 0, 0, 0, 12, 0, 1),
(42, 'first_class', 19, 32, 534.2, 3206, 77, 1572, 64, 24.56, 50.09, 2.94, 8, 3, 4, 0, 4, 0, 1),
(42, 'list_a', 50, 46, 405.3, 2433, 16, 1849, 83, 22.27, 29.31, 4.55, 4, 5, 0, 0, 11, 0, 1),
(42, 't20', 43, 43, 146.1, 877, 1, 1076, 43, 25.02, 20.39, 7.36, 4, 1, 0, 0, 10, 0, 1),
(42, 't20i', 1, 1, 4, 24, 0, 31, 0, 0, 0, 7.75, 0, 0, 0, 0, 0, 0, 0),
(43, 'first_class', 9, 16, 276.3, 1659, 67, 715, 35, 20.42, 47.4, 2.58, 9, 0, 2, 0, 2, 0, 0),
(43, 'list_a', 19, 17, 159.1, 955, 10, 650, 18, 36.11, 53.05, 4.08, 3, 0, 0, 0, 2, 0, 2),
(43, 't20', 11, 11, 37, 222, 0, 225, 12, 18.75, 18.5, 6.08, 3, 0, 0, 0, 1, 0, 0),
(44, 'first_class', 4, 1, 3, 18, 0, 13, 3, 4.33, 6, 4.33, 3, 0, 0, 0, 1, 0, 0),
(44, 'list_a', 16, 6, 23.2, 140, 1, 107, 5, 21.4, 28, 4.58, 4, 1, 0, 0, 9, 0, 1),
(44, 't20', 26, 5, 6, 36, 0, 50, 0, 0, 0, 8.33, 0, 0, 0, 0, 11, 0, 3),
(45, 't20', 2, 2, 7, 42, 0, 67, 2, 33.5, 21, 9.57, 1, 0, 0, 0, 0, 0, 0),
(46, 'list_a', 8, 8, 66, 396, 2, 325, 8, 40.62, 49.5, 4.92, 2, 0, 0, 0, 4, 0, 0),
(46, 't20', 3, 3, 9, 54, 0, 81, 2, 40.5, 27, 9, 2, 0, 0, 0, 1, 0, 0),
(47, 'first_class', 3, 1, 0.4, 4, 0, 6, 0, 0, 0, 9, 0, 0, 0, 0, 1, 0, 0),
(47, 'list_a', 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0),
(47, 't20', 12, 1, 0.2, 2, 0, 4, 0, 0, 0, 12, 0, 0, 0, 0, 4, 0, 0),
(48, 'list_a', 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(48, 't20', 15, 8, 20.3, 123, 0, 150, 6, 25, 20.5, 7.31, 2, 0, 0, 0, 6, 0, 0),
(49, 'first_class', 13, 25, 503.5, 3023, 121, 1398, 65, 21.5, 46.5, 2.77, 13, 1, 8, 3, 10, 0, 0),
(49, 'list_a', 100, 100, 913.3, 5481, 86, 3399, 163, 20.85, 33.62, 3.72, 6, 7, 6, 0, 22, 0, 1),
(49, 'odi', 65, 65, 590, 3540, 35, 2435, 92, 26.46, 38.47, 4.12, 6, 4, 2, 0, 14, 0, 1),
(49, 't20', 395, 390, 1514.2, 9086, 27, 9083, 430, 21.12, 21.13, 5.99, 5, 12, 1, 0, 84, 0, 10),
(49, 't20i', 51, 49, 183.4, 1102, 1, 1105, 52, 21.25, 21.19, 6.01, 4, 1, 0, 0, 7, 0, 1),
(49, 'test', 6, 11, 275, 1650, 60, 851, 21, 40.52, 78.57, 3.09, 8, 0, 2, 0, 2, 0, 0),
(50, 'first_class', 126, 232, 4456.2, 26738, 1054, 13149, 502, 26.19, 53.26, 2.95, 10, 24, 25, 1, 78, 0, 3),
(50, 'list_a', 157, 155, 1320.2, 7922, 84, 7205, 209, 34.47, 37.9, 5.45, 7, 4, 3, 0, 44, 0, 8),
(50, 'odi', 143, 141, 1199.1, 7195, 74, 6558, 190, 34.51, 37.86, 5.46, 7, 4, 3, 0, 39, 0, 6),
(50, 't20', 223, 219, 803.1, 4819, 8, 6580, 256, 25.7, 18.82, 8.19, 6, 1, 2, 0, 103, 0, 10),
(50, 't20i', 92, 90, 332.5, 1997, 2, 2729, 111, 24.58, 17.99, 8.19, 5, 1, 1, 0, 47, 0, 3),
(50, 'test', 85, 160, 3225.2, 19352, 742, 9530, 338, 28.19, 57.25, 2.95, 10, 18, 14, 1, 65, 0, 2),
(51, 'first_class', 79, 4, 15, 90, 1, 56, 2, 28, 45, 3.73, 1, 0, 0, 0, 57, 2, 4),
(51, 'list_a', 67, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 36, 9, 3),
(51, 't20', 70, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 8, 4),
(52, 'first_class', 35, 57, 808, 4848, 198, 2178, 94, 23.17, 51.57, 2.69, 8, 4, 3, 0, 20, 0, 1),
(52, 'list_a', 165, 161, 1339.4, 8038, 56, 5699, 182, 31.31, 44.16, 4.25, 5, 4, 1, 0, 72, 0, 11),
(52, 'odi', 130, 126, 1040.3, 6243, 40, 4459, 134, 33.27, 46.58, 4.28, 4, 3, 0, 0, 56, 0, 8),
(52, 't20', 323, 316, 1047.5, 6287, 9, 7283, 296, 24.6, 21.23, 6.95, 5, 7, 1, 0, 152, 0, 21),
(52, 't20i', 88, 87, 287.4, 1726, 5, 2074, 74, 28.02, 23.32, 7.2, 4, 3, 0, 0, 49, 0, 7),
(52, 'test', 3, 5, 91, 546, 17, 254, 8, 31.75, 68.25, 2.79, 4, 0, 0, 0, 2, 0, 0),
(53, 'first_class', 17, 31, 347.1, 2083, 68, 1104, 54, 20.44, 38.57, 3.18, 9, 4, 3, 0, 6, 0, 1),
(53, 'list_a', 93, 90, 629.3, 3777, 25, 3418, 131, 26.09, 28.83, 5.42, 6, 5, 4, 0, 22, 0, 9),
(53, 'odi', 56, 55, 381.4, 2290, 14, 2229, 70, 31.84, 32.71, 5.84, 4, 5, 0, 0, 11, 0, 8),
(53, 't20', 410, 368, 1101.1, 6607, 6, 9361, 368, 25.43, 17.95, 8.5, 5, 9, 1, 0, 176, 0, 16),
(53, 't20i', 67, 56, 148.3, 891, 0, 1364, 39, 34.97, 22.84, 9.18, 3, 0, 0, 0, 16, 0, 4),
(53, 'test', 1, 2, 23, 138, 2, 104, 1, 104, 138, 4.52, 1, 0, 0, 0, 1, 0, 0),
(54, 'first_class', 167, 9, 18, 108, 2, 75, 0, 0, 0, 4.16, 0, 0, 0, 0, 172, 0, 6),
(54, 'list_a', 167, 3, 8.5, 53, 0, 51, 4, 12.75, 13.25, 5.77, 2, 0, 0, 0, 80, 0, 11),
(54, 'odi', 90, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 48, 0, 5),
(54, 't20', 218, 1, 1, 6, 0, 5, 1, 5, 6, 5, 1, 0, 0, 0, 90, 0, 13),
(54, 't20i', 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0),
(54, 'test', 82, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 99, 0, 2),
(55, 'first_class', 75, 1, 0.1, 1, 0, 4, 0, 0, 0, 24, 0, 0, 0, 0, 178, 11, 1),
(55, 'list_a', 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 87, 8, 10),
(55, 'odi', 25, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 18, 0, 4),
(55, 't20', 213, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 121, 22, 14),
(55, 't20i', 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 2, 2),
(55, 'test', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0),
(56, 'first_class', 10, 16, 131, 786, 36, 340, 7, 48.57, 112.28, 2.59, 3, 0, 0, 0, 4, 0, 1),
(56, 'list_a', 32, 21, 111.3, 669, 3, 619, 19, 32.57, 35.21, 5.55, 3, 0, 0, 0, 17, 0, 4),
(56, 'odi', 2, 1, 5, 30, 0, 28, 0, 0, 0, 5.6, 0, 0, 0, 0, 0, 0, 1),
(56, 't20', 73, 46, 112.5, 677, 1, 818, 34, 24.05, 19.91, 7.24, 2, 0, 0, 0, 32, 0, 2),
(56, 't20i', 9, 4, 9.1, 55, 0, 75, 5, 15, 11, 8.18, 2, 0, 0, 0, 4, 0, 0),
(57, 'first_class', 56, 4, 21, 126, 2, 93, 0, 0, 0, 4.42, 0, 0, 0, 0, 79, 1, 1),
(57, 'list_a', 41, 2, 3.5, 23, 0, 31, 0, 0, 0, 8.08, 0, 0, 0, 0, 16, 0, 0),
(57, 't20', 23, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 2),
(58, 'first_class', 41, 39, 281.3, 1689, 41, 883, 23, 38.39, 73.43, 3.13, 5, 0, 0, 0, 23, 0, 4),
(58, 'list_a', 62, 50, 244.2, 1466, 7, 1160, 33, 35.15, 44.42, 4.74, 3, 0, 0, 0, 19, 0, 1),
(58, 'odi', 1, 1, 3, 18, 0, 10, 0, 0, 0, 3.33, 0, 0, 0, 0, 0, 0, 0),
(58, 't20', 151, 50, 95.1, 571, 0, 665, 29, 22.93, 19.68, 6.98, 4, 1, 0, 0, 39, 0, 6),
(58, 't20i', 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(59, 'first_class', 39, 59, 638.4, 3832, 58, 2611, 73, 35.76, 52.49, 4.08, 6, 4, 1, 0, 20, 0, 4),
(59, 'list_a', 73, 61, 370.4, 2224, 14, 1973, 84, 23.48, 26.47, 5.32, 5, 4, 1, 0, 21, 0, 5),
(59, 'odi', 13, 11, 59, 354, 2, 313, 11, 28.45, 32.18, 5.3, 3, 0, 0, 0, 3, 0, 2),
(59, 't20', 59, 50, 138.2, 830, 2, 1162, 36, 32.27, 23.05, 8.4, 4, 1, 0, 0, 27, 0, 1),
(59, 't20i', 22, 21, 60.5, 365, 0, 481, 11, 43.72, 33.18, 7.9, 2, 0, 0, 0, 7, 0, 0),
(59, 'test', 1, 2, 26, 156, 1, 148, 1, 148, 156, 5.69, 1, 0, 0, 0, 1, 0, 0),
(60, 'first_class', 58, 24, 94.1, 565, 4, 401, 4, 100.25, 141.25, 4.25, 2, 0, 0, 0, 43, 0, 6),
(60, 'list_a', 108, 21, 42.3, 255, 0, 259, 5, 51.8, 51, 6.09, 1, 0, 0, 0, 48, 0, 10),
(60, 'odi', 26, 4, 5.1, 31, 0, 37, 0, 0, 0, 7.16, 0, 0, 0, 0, 10, 0, 5),
(60, 't20', 176, 4, 7.5, 47, 0, 79, 1, 79, 47, 10.08, 1, 0, 0, 0, 71, 0, 10),
(60, 't20i', 36, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 0, 0),
(60, 'test', 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0),
(61, 'first_class', 30, 15, 63, 378, 7, 210, 5, 42, 75.6, 3.33, 2, 0, 0, 0, 22, 0, 1),
(61, 'list_a', 42, 8, 38, 228, 2, 149, 7, 21.28, 32.57, 3.92, 2, 0, 0, 0, 20, 0, 2),
(61, 't20', 66, 5, 11, 66, 0, 114, 3, 38, 22, 10.36, 1, 0, 0, 0, 39, 0, 4),
(62, 'first_class', 102, 187, 2847, 17082, 535, 9463, 327, 28.93, 52.23, 3.32, 12, 11, 15, 2, 35, 0, 7),
(62, 'list_a', 118, 116, 947, 5682, 42, 5451, 164, 33.23, 34.64, 5.75, 5, 4, 1, 0, 32, 0, 8),
(62, 'odi', 75, 73, 593, 3558, 23, 3565, 106, 33.63, 33.56, 6.01, 4, 4, 0, 0, 22, 0, 6),
(62, 't20', 161, 159, 562.2, 3374, 8, 4609, 165, 27.93, 20.44, 8.19, 5, 3, 1, 0, 43, 0, 11),
(62, 't20i', 7, 7, 25, 150, 0, 219, 9, 24.33, 16.66, 8.76, 2, 0, 0, 0, 3, 0, 1),
(62, 'test', 52, 102, 1372.3, 8235, 228, 4867, 158, 30.8, 52.12, 3.54, 10, 5, 3, 1, 17, 0, 4),
(63, 'first_class', 55, 104, 1959.3, 11757, 469, 5445, 243, 22.4, 48.38, 2.77, 10, 16, 7, 1, 26, 0, 4),
(63, 'list_a', 94, 94, 822.1, 4933, 50, 4261, 150, 28.4, 32.88, 5.18, 5, 7, 1, 0, 27, 0, 5),
(63, 'odi', 69, 69, 608.3, 3651, 38, 3195, 111, 28.78, 32.89, 5.25, 5, 5, 1, 0, 16, 0, 3),
(63, 't20', 117, 117, 437, 2622, 6, 3467, 132, 26.26, 19.86, 7.93, 4, 3, 0, 0, 28, 0, 9),
(63, 't20i', 39, 39, 142, 852, 3, 1002, 44, 22.77, 19.36, 7.05, 3, 0, 0, 0, 12, 0, 2),
(63, 'test', 41, 79, 1525.5, 9155, 376, 4191, 197, 21.27, 46.47, 2.74, 10, 13, 7, 1, 21, 0, 3),
(64, 'first_class', 88, 28, 77.2, 464, 12, 318, 5, 63.6, 92.8, 4.11, 1, 0, 0, 0, 81, 0, 3),
(64, 'list_a', 222, 31, 79.5, 479, 0, 439, 9, 48.77, 53.22, 5.49, 2, 0, 0, 0, 91, 0, 3),
(64, 'odi', 135, 21, 47.2, 284, 0, 259, 4, 64.75, 71, 5.47, 1, 0, 0, 0, 63, 0, 2),
(64, 't20', 353, 28, 39.5, 239, 0, 369, 7, 52.71, 34.14, 9.26, 1, 0, 0, 0, 149, 0, 13),
(64, 't20i', 89, 2, 2, 12, 0, 27, 0, 0, 0, 13.5, 0, 0, 0, 0, 40, 0, 3),
(64, 'test', 5, 1, 2, 12, 0, 8, 0, 0, 0, 4, 0, 0, 0, 0, 7, 0, 1),
(65, 'first_class', 16, 2, 2, 12, 0, 6, 0, 0, 0, 3, 0, 0, 0, 0, 10, 0, 1),
(65, 'list_a', 20, 3, 5.2, 32, 0, 39, 0, 0, 0, 7.31, 0, 0, 0, 0, 5, 0, 0),
(65, 't20', 27, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0),
(66, 'first_class', 1, 1, 39, 234, 8, 105, 1, 105, 234, 2.69, 1, 0, 0, 0, 0, 0, 0),
(66, 'list_a', 9, 9, 86.4, 520, 4, 367, 22, 16.68, 23.63, 4.23, 5, 0, 1, 0, 2, 0, 0),
(66, 't20', 46, 46, 176.3, 1059, 0, 1240, 43, 28.83, 24.62, 7.02, 5, 0, 1, 0, 6, 0, 2),
(66, 't20i', 6, 6, 22.3, 135, 0, 132, 2, 66, 67.5, 5.86, 1, 0, 0, 0, 0, 0, 0),
(67, 'list_a', 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0),
(67, 't20', 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 1),
(68, 'first_class', 6, 12, 178, 1068, 33, 540, 25, 21.6, 42.72, 3.03, 6, 3, 1, 0, 0, 0, 0),
(68, 'list_a', 31, 30, 227.3, 1365, 12, 1144, 49, 23.34, 27.85, 5.02, 5, 3, 1, 0, 16, 0, 5),
(68, 't20', 39, 39, 133.1, 799, 3, 1137, 36, 31.58, 22.19, 8.53, 4, 1, 0, 0, 19, 0, 2),
(69, 'first_class', 17, 29, 406.4, 2440, 95, 1190, 50, 23.8, 48.8, 2.92, 6, 4, 0, 0, 13, 0, 1),
(69, 'list_a', 32, 31, 216.5, 1301, 9, 1041, 34, 30.61, 38.26, 4.8, 4, 3, 0, 0, 17, 0, 0),
(69, 't20', 33, 33, 104.5, 629, 2, 749, 20, 37.45, 31.45, 7.14, 3, 0, 0, 0, 16, 0, 2),
(70, 'list_a', 3, 1, 2, 12, 0, 22, 0, 31.4, 32.4, 11, 2, 0, 0, 0, 1, 0, 0),
(70, 't20', 6, 2, 2, 12, 0, 20, 0, 16, 12, 10, 1, 0, 0, 0, 4, 0, 0),
(73, 't20', 2, 2, 5, 30, 0, 51, 1, 51, 30, 10.2, 1, 0, 0, 0, 0, 0, 0),
(74, 'first_class', 86, 103, 1075.5, 6455, 238, 3222, 96, 33.56, 67.23, 2.99, 8, 2, 1, 0, 52, 0, 4),
(74, 'list_a', 86, 68, 507.1, 3043, 8, 2640, 76, 34.73, 40.03, 5.2, 3, 0, 0, 0, 27, 0, 4),
(74, 't20', 148, 130, 461.2, 2768, 2, 3312, 152, 21.78, 18.21, 7.17, 5, 3, 1, 0, 59, 0, 6),
(75, 'first_class', 122, 17, 49.4, 298, 12, 142, 3, 47.33, 99.33, 2.85, 2, 0, 0, 0, 120, 0, 4),
(75, 'list_a', 282, 10, 45.2, 272, 0, 249, 9, 27.66, 30.22, 5.49, 2, 0, 0, 0, 136, 0, 14),
(75, 'odi', 149, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 71, 0, 3),
(75, 't20', 314, 6, 8, 48, 0, 66, 4, 16.5, 12, 8.25, 1, 0, 0, 0, 124, 0, 10),
(75, 't20i', 68, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 19, 0, 1),
(75, 'test', 34, 5, 9, 54, 2, 18, 0, 0, 0, 2, 0, 0, 0, 0, 28, 0, 1),
(76, 'first_class', 83, 139, 2899.1, 17395, 602, 8556, 315, 27.16, 55.22, 2.95, 11, 14, 21, 2, 40, 0, 3),
(76, 'list_a', 110, 109, 889.2, 5336, 36, 4762, 161, 29.57, 33.14, 5.35, 6, 7, 3, 0, 29, 0, 8),
(76, 'odi', 3, 3, 25, 150, 0, 160, 1, 160, 150, 6.4, 1, 0, 0, 0, 0, 0, 0),
(76, 't20', 105, 100, 330.3, 1983, 2, 2476, 91, 27.2, 21.79, 7.49, 6, 0, 1, 0, 24, 0, 10),
(76, 't20i', 1, 1, 4, 24, 0, 42, 1, 42, 24, 10.5, 1, 0, 0, 0, 2, 0, 0),
(77, 'first_class', 196, 1, 1, 6, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 489, 24, 5),
(77, 'list_a', 157, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 9, 11),
(77, 'odi', 89, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 45, 3, 8),
(77, 't20', 172, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 99, 15, 9),
(77, 't20i', 63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 44, 1, 3),
(77, 'test', 83, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 198, 13, 3),
(78, 'first_class', 77, 67, 419, 2514, 70, 1366, 47, 29.06, 53.48, 3.26, 6, 1, 0, 0, 66, 0, 1),
(78, 'list_a', 121, 30, 100, 600, 4, 486, 14, 34.71, 42.85, 4.86, 2, 0, 0, 0, 46, 2, 2),
(78, 'odi', 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(78, 't20', 112, 24, 64, 384, 2, 480, 27, 17.77, 14.22, 7.5, 3, 0, 0, 0, 35, 0, 4),
(78, 't20i', 18, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0),
(79, 'first_class', 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0),
(79, 'list_a', 18, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 2, 2),
(79, 't20', 31, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 3, 0),
(80, 'first_class', 77, 20, 65.3, 393, 5, 257, 3, 85.66, 131, 3.92, 2, 0, 0, 0, 43, 0, 2),
(80, 'list_a', 89, 4, 6, 36, 0, 44, 0, 0, 0, 7.33, 0, 0, 0, 0, 33, 0, 3),
(80, 'odi', 5, 1, 1, 6, 0, 10, 0, 0, 0, 10, 0, 0, 0, 0, 2, 0, 0),
(80, 't20', 174, 1, 1, 6, 0, 8, 0, 0, 0, 8, 0, 0, 0, 0, 70, 0, 7),
(80, 'test', 21, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 14, 0, 0),
(81, 'first_class', 62, 68, 562.3, 3375, 112, 1552, 43, 36.09, 78.48, 2.75, 6, 0, 1, 0, 74, 0, 0),
(81, 'list_a', 58, 37, 220.3, 1323, 1, 1154, 24, 48.08, 55.12, 5.23, 3, 0, 0, 0, 26, 0, 0),
(81, 'odi', 3, 1, 3, 18, 0, 20, 1, 20, 18, 6.66, 1, 0, 0, 0, 1, 0, 0),
(81, 't20', 169, 76, 191, 1146, 0, 1520, 67, 22.68, 17.1, 7.95, 4, 2, 0, 0, 74, 0, 3),
(81, 't20i', 17, 12, 33, 198, 0, 235, 12, 19.58, 16.5, 7.12, 2, 0, 0, 0, 8, 0, 0),
(82, 'first_class', 46, 79, 1581.3, 9489, 319, 4566, 168, 27.17, 56.48, 2.88, 10, 10, 9, 1, 12, 0, 5),
(82, 'list_a', 55, 55, 466.2, 2798, 40, 2223, 86, 25.84, 32.53, 4.76, 7, 1, 3, 0, 19, 0, 1),
(82, 't20', 152, 151, 553.3, 3321, 11, 4147, 163, 25.44, 20.37, 7.49, 4, 3, 0, 0, 30, 0, 11),
(82, 't20i', 2, 2, 7, 42, 0, 73, 1, 73, 42, 10.42, 1, 0, 0, 0, 0, 0, 0),
(83, 'first_class', 17, 32, 524.2, 3146, 141, 1335, 55, 24.27, 57.2, 2.54, 7, 2, 2, 0, 6, 0, 1),
(83, 'list_a', 10, 10, 83.2, 500, 7, 395, 21, 18.8, 23.8, 4.74, 5, 1, 1, 0, 2, 0, 1),
(83, 't20', 22, 22, 81.3, 489, 0, 637, 26, 24.5, 18.8, 7.81, 3, 0, 0, 0, 4, 0, 1),
(84, 'first_class', 71, 130, 2275.2, 13652, 499, 7257, 315, 23.03, 43.33, 3.18, 14, 14, 14, 5, 34, 0, 4),
(84, 'list_a', 103, 100, 878.3, 5271, 53, 4502, 153, 29.42, 34.45, 5.12, 6, 8, 2, 0, 31, 0, 2),
(84, 'odi', 85, 83, 727.1, 4363, 47, 3655, 132, 27.68, 33.05, 5.02, 6, 6, 2, 0, 27, 0, 2),
(84, 't20', 145, 143, 533.1, 3199, 4, 4237, 198, 21.39, 16.15, 7.94, 4, 7, 0, 0, 51, 0, 9),
(84, 't20i', 40, 40, 145.1, 871, 0, 1245, 49, 25.4, 17.77, 8.57, 3, 0, 0, 0, 12, 0, 2),
(84, 'test', 52, 95, 1651.2, 9908, 341, 5446, 243, 22.41, 40.77, 3.29, 13, 11, 11, 4, 27, 0, 2),
(85, 'first_class', 16, 21, 107.4, 646, 17, 291, 10, 29.1, 64.6, 2.7, 5, 0, 1, 0, 7, 0, 0),
(85, 'list_a', 20, 18, 105, 630, 2, 523, 14, 37.35, 45, 4.98, 3, 0, 0, 0, 8, 0, 0),
(85, 't20', 27, 22, 67, 402, 0, 418, 21, 19.9, 19.14, 6.23, 3, 0, 0, 0, 11, 0, 0),
(86, 'first_class', 8, 6, 49.5, 299, 10, 140, 5, 28, 59.8, 2.8, 3, 0, 0, 0, 6, 0, 0),
(86, 'list_a', 33, 5, 10.2, 62, 0, 68, 3, 22.66, 20.66, 6.58, 1, 0, 0, 0, 10, 0, 0),
(86, 't20', 57, 6, 13.2, 80, 0, 103, 2, 51.5, 40, 7.72, 1, 0, 0, 0, 24, 0, 2),
(87, 'first_class', 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50, 5, 0),
(87, 'list_a', 41, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 43, 6, 2),
(87, 't20', 63, 1, 1, 6, 0, 5, 0, 0, 0, 5, 0, 0, 0, 0, 45, 8, 5),
(88, 'first_class', 18, 31, 574.5, 3449, 88, 2100, 70, 30, 49.27, 3.65, 9, 5, 7, 0, 5, 0, 1),
(88, 'list_a', 40, 40, 337.5, 2027, 7, 1733, 67, 25.86, 30.25, 5.12, 5, 2, 1, 0, 12, 0, 3),
(88, 'odi', 1, 1, 10, 60, 0, 54, 3, 18, 20, 5.4, 3, 0, 0, 0, 0, 0, 0),
(88, 't20', 82, 81, 296.5, 1781, 3, 2202, 96, 22.93, 18.55, 7.41, 5, 1, 1, 0, 24, 0, 2),
(88, 't20i', 6, 6, 22, 132, 0, 167, 7, 23.85, 18.85, 7.59, 3, 0, 0, 0, 3, 0, 0),
(89, 'first_class', 27, 42, 707.2, 4244, 190, 1998, 81, 24.66, 52.39, 2.82, 7, 5, 3, 0, 1, 0, 1),
(89, 'list_a', 30, 30, 231.3, 1389, 21, 1171, 47, 24.91, 29.55, 5.05, 6, 1, 2, 0, 4, 0, 2),
(89, 't20', 23, 22, 80, 480, 0, 537, 30, 17.9, 16, 6.71, 4, 2, 0, 0, 1, 0, 0),
(90, 'first_class', 9, 13, 204.2, 1226, 41, 623, 30, 20.76, 40.86, 3.04, 9, 0, 2, 0, 2, 0, 0),
(90, 'list_a', 5, 5, 38.1, 229, 2, 197, 8, 24.62, 28.62, 5.16, 4, 1, 0, 0, 0, 0, 0),
(90, 't20', 17, 17, 61.1, 367, 2, 466, 15, 31.06, 24.46, 7.61, 3, 0, 0, 0, 3, 0, 0),
(91, 'first_class', 14, 27, 242.3, 1455, 36, 922, 30, 30.73, 48.5, 3.8, 5, 1, 0, 0, 12, 0, 0),
(91, 'list_a', 34, 33, 191.3, 1149, 8, 1119, 35, 31.97, 32.82, 5.84, 3, 0, 0, 0, 14, 0, 1),
(91, 'odi', 5, 5, 24.1, 145, 0, 122, 6, 20.33, 24.16, 5.04, 2, 0, 0, 0, 1, 0, 0),
(91, 't20', 41, 40, 117.2, 704, 1, 1109, 42, 26.4, 16.76, 9.45, 4, 1, 0, 0, 19, 0, 1),
(91, 't20i', 10, 9, 25, 150, 0, 278, 7, 39.71, 21.42, 11.12, 2, 0, 0, 0, 6, 0, 0),
(92, 'first_class', 6, 10, 180.4, 1084, 44, 519, 21, 24.71, 51.61, 2.87, 5, 0, 1, 0, 3, 0, 1),
(92, 'list_a', 17, 16, 136.2, 818, 10, 650, 21, 30.95, 38.95, 4.76, 4, 1, 0, 0, 4, 0, 1),
(92, 't20', 46, 46, 158.4, 952, 1, 1278, 48, 26.62, 19.83, 8.05, 5, 0, 1, 0, 13, 0, 3),
(93, 'first_class', 8, 4, 14, 84, 1, 40, 0, 0, 0, 2.85, 0, 0, 0, 0, 7, 0, 1),
(93, 'list_a', 20, 13, 50.2, 302, 3, 239, 8, 29.87, 37.75, 4.74, 2, 0, 0, 0, 7, 0, 1),
(93, 't20', 20, 12, 25, 150, 1, 134, 10, 13.4, 15, 5.36, 2, 0, 0, 0, 6, 0, 3),
(94, 'first_class', 35, 51, 491.4, 2950, 109, 1301, 35, 37.17, 84.28, 2.64, 4, 0, 0, 0, 29, 0, 0),
(94, 'list_a', 43, 38, 215, 1290, 2, 998, 30, 33.26, 43, 4.64, 4, 1, 0, 0, 17, 0, 5),
(94, 't20', 34, 28, 71, 426, 0, 611, 20, 30.55, 21.3, 8.6, 4, 1, 0, 0, 16, 0, 2),
(95, 'first_class', 7, 13, 261.4, 1570, 41, 879, 35, 25.11, 44.85, 3.35, 9, 1, 2, 0, 2, 0, 0),
(95, 'list_a', 15, 15, 108, 648, 4, 542, 21, 25.8, 30.85, 5.01, 5, 0, 1, 0, 0, 0, 0),
(95, 'odi', 3, 3, 23, 138, 0, 143, 3, 47.66, 46, 6.21, 1, 0, 0, 0, 0, 0, 0),
(95, 't20', 46, 46, 166.2, 998, 0, 1336, 54, 24.74, 18.48, 8.03, 4, 2, 0, 0, 21, 0, 2),
(95, 't20i', 3, 3, 12, 72, 0, 78, 9, 8.66, 8, 6.5, 4, 1, 0, 0, 1, 0, 0),
(96, 'list_a', 9, 9, 74, 444, 6, 306, 9, 34, 49.33, 4.13, 4, 1, 0, 0, 1, 0, 0),
(96, 't20', 33, 33, 109.2, 656, 1, 730, 30, 24.33, 21.86, 6.67, 4, 1, 0, 0, 5, 0, 1),
(97, 't20', 4, 3, 7, 42, 0, 52, 1, 52, 42, 7.42, 1, 0, 0, 0, 1, 0, 0),
(98, 'first_class', 2, 3, 44, 264, 7, 147, 3, 49, 88, 3.34, 2, 0, 0, 0, 0, 0, 1),
(98, 't20', 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(99, 'first_class', 142, 254, 6270.5, 37625, 1324, 17221, 684, 25.17, 55, 2.74, 13, 31, 49, 11, 56, 0, 5),
(99, 'list_a', 173, 171, 1558.4, 9352, 66, 7242, 231, 31.35, 40.48, 4.64, 4, 1, 0, 0, 49, 0, 6),
(99, 'odi', 113, 111, 1023.3, 6141, 36, 5058, 151, 33.49, 40.66, 4.94, 4, 1, 0, 0, 30, 0, 3),
(99, 't20', 277, 274, 995, 5970, 7, 6896, 273, 25.26, 21.86, 6.93, 4, 4, 0, 0, 65, 0, 10),
(99, 't20i', 51, 51, 191, 1146, 2, 1298, 61, 21.27, 18.78, 6.79, 4, 2, 0, 0, 9, 0, 0),
(99, 'test', 86, 162, 3848.1, 23089, 794, 10666, 442, 24.13, 52.23, 2.77, 13, 23, 30, 7, 31, 0, 5),
(100, 'first_class', 110, 200, 3787.3, 22725, 893, 11171, 417, 26.78, 54.49, 2.94, 10, 20, 17, 1, 56, 0, 4),
(100, 'list_a', 122, 120, 1092.4, 6556, 72, 5490, 211, 26.01, 31.07, 5.02, 7, 10, 5, 0, 44, 0, 5),
(100, 'odi', 93, 93, 852.5, 5117, 59, 4261, 169, 25.21, 30.27, 4.99, 7, 8, 5, 0, 34, 0, 4),
(100, 't20', 160, 160, 588, 3528, 10, 4812, 186, 25.87, 18.96, 8.18, 4, 2, 0, 0, 59, 0, 7),
(100, 't20i', 44, 44, 165.3, 993, 1, 1345, 62, 21.69, 16.01, 8.12, 4, 1, 0, 0, 16, 0, 1),
(100, 'test', 75, 143, 2781.3, 16689, 634, 8254, 301, 27.42, 55.44, 2.96, 10, 17, 9, 1, 40, 0, 3),
(101, 'first_class', 122, 1, 2, 12, 0, 11, 0, 0, 0, 5.5, 0, 0, 0, 0, 274, 3, 3),
(101, 'list_a', 218, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 231, 37, 8),
(101, 'odi', 148, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 181, 32, 7),
(101, 't20', 308, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 167, 34, 15),
(101, 't20i', 88, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 39, 10, 6),
(101, 'test', 57, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 153, 1, 1),
(102, 'first_class', 133, 18, 65.1, 391, 2, 257, 5, 51.4, 78.2, 3.94, 2, 0, 0, 0, 91, 0, 1),
(102, 'list_a', 126, 5, 23, 138, 1, 85, 5, 17, 27.6, 3.69, 2, 0, 0, 0, 43, 0, 2),
(102, 'odi', 35, 1, 1, 6, 0, 3, 1, 3, 6, 3, 1, 0, 0, 0, 15, 0, 2),
(102, 't20', 143, 6, 9, 54, 0, 55, 3, 18.33, 18, 6.11, 2, 0, 0, 0, 43, 0, 5),
(102, 't20i', 34, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 1),
(102, 'test', 15, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 0, 0),
(103, 'first_class', 67, 113, 1176.3, 7059, 234, 4012, 123, 32.61, 57.39, 3.41, 6, 2, 2, 0, 67, 0, 1),
(103, 'list_a', 129, 112, 700.5, 4205, 23, 4059, 145, 27.99, 29, 5.79, 5, 6, 4, 0, 51, 0, 11),
(103, 'odi', 66, 62, 352.3, 2115, 6, 2139, 68, 31.45, 31.1, 6.06, 5, 2, 2, 0, 24, 0, 7),
(103, 't20', 176, 155, 434.4, 2608, 2, 3923, 151, 25.98, 17.27, 9.02, 4, 2, 0, 0, 59, 0, 7),
(103, 't20i', 38, 29, 63.3, 381, 0, 586, 21, 27.9, 18.14, 9.22, 3, 0, 0, 0, 11, 0, 1),
(103, 'test', 12, 21, 179.2, 1076, 18, 675, 14, 48.21, 76.85, 3.76, 3, 0, 0, 0, 12, 0, 0),
(104, 'first_class', 85, 107, 841.5, 5051, 184, 2691, 90, 29.9, 56.12, 3.19, 6, 3, 1, 0, 95, 0, 1),
(104, 'list_a', 88, 56, 273.1, 1639, 4, 1674, 51, 32.82, 32.13, 6.12, 3, 0, 0, 0, 39, 0, 4),
(104, 'odi', 3, 2, 5, 30, 0, 33, 0, 0, 0, 6.6, 0, 0, 0, 0, 0, 0, 0),
(104, 't20', 133, 65, 151.3, 909, 0, 1414, 59, 23.96, 15.4, 9.33, 4, 2, 0, 0, 68, 0, 5),
(104, 't20i', 25, 7, 11.5, 71, 0, 121, 6, 20.16, 11.83, 10.22, 2, 0, 0, 0, 12, 0, 0),
(104, 'test', 9, 8, 58, 348, 13, 160, 2, 80, 174, 2.75, 1, 0, 0, 0, 11, 0, 0),
(105, 'first_class', 84, 61, 230.3, 1383, 37, 730, 13, 56.15, 106.38, 3.16, 2, 0, 0, 0, 69, 0, 2),
(105, 'list_a', 90, 37, 146, 876, 1, 750, 15, 50, 58.4, 5.13, 2, 0, 0, 0, 33, 0, 5),
(105, 'odi', 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(105, 't20', 150, 10, 13, 78, 0, 81, 4, 20.25, 19.5, 6.23, 1, 0, 0, 0, 59, 0, 10),
(105, 'test', 6, 2, 2, 12, 0, 11, 0, 0, 0, 5.5, 0, 0, 0, 0, 6, 0, 0),
(106, 'first_class', 55, 1, 1, 6, 0, 7, 0, 0, 0, 7, 0, 0, 0, 0, 73, 7, 4),
(106, 'list_a', 102, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 100, 14, 3),
(106, 'odi', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0),
(106, 't20', 210, 1, 0.3, 3, 0, 4, 1, 4, 3, 8, 1, 0, 0, 0, 110, 20, 22),
(106, 't20i', 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 2, 2),
(107, 'first_class', 31, 48, 910.3, 5463, 181, 2790, 84, 33.21, 65.03, 3.06, 8, 3, 2, 0, 11, 0, 0),
(107, 'list_a', 119, 114, 978.5, 5873, 30, 4746, 179, 26.51, 32.81, 4.84, 6, 4, 4, 0, 27, 0, 2),
(107, 'odi', 61, 60, 551, 3306, 14, 2854, 104, 27.44, 31.78, 5.17, 6, 3, 2, 0, 16, 0, 1),
(107, 't20', 237, 235, 849.4, 5098, 8, 6421, 270, 23.78, 18.88, 7.55, 6, 5, 2, 0, 56, 0, 7),
(107, 't20i', 54, 54, 210.3, 1263, 1, 1723, 68, 25.33, 18.57, 8.18, 6, 2, 1, 0, 10, 0, 1),
(108, 'first_class', 41, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 0),
(108, 'list_a', 69, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 38, 0, 1),
(108, 'odi', 47, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 19, 0, 1),
(108, 't20', 133, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 62, 0, 3),
(108, 't20i', 42, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 0),
(108, 'test', 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 0),
(109, 'first_class', 54, 91, 1458.4, 8752, 364, 4264, 148, 28.81, 59.13, 2.92, 7, 4, 4, 0, 15, 0, 2),
(109, 'list_a', 56, 56, 475.3, 2853, 20, 2513, 85, 29.56, 33.56, 5.28, 5, 3, 1, 0, 12, 0, 0),
(109, 'odi', 8, 8, 70, 420, 0, 481, 6, 80.16, 70, 6.87, 2, 0, 0, 0, 3, 0, 0),
(109, 't20', 68, 66, 239, 1434, 3, 1783, 56, 31.83, 25.6, 7.46, 3, 0, 0, 0, 18, 0, 2),
(109, 't20i', 11, 9, 32.5, 197, 1, 235, 13, 18.07, 15.15, 7.15, 3, 0, 0, 0, 3, 0, 0),
(109, 'test', 2, 4, 41.5, 251, 5, 172, 4, 43, 62.75, 4.11, 4, 0, 0, 0, 1, 0, 0),
(110, 'first_class', 37, 63, 1143.3, 6861, 277, 3557, 124, 28.68, 55.33, 3.11, 9, 6, 2, 0, 24, 0, 3),
(110, 'list_a', 80, 80, 718.2, 4310, 34, 3647, 146, 24.97, 29.52, 5.07, 5, 4, 2, 0, 28, 0, 4),
(110, 'odi', 32, 32, 279.4, 1678, 10, 1555, 52, 29.9, 32.26, 5.56, 4, 1, 0, 0, 7, 0, 1),
(110, 't20', 146, 143, 517.3, 3105, 4, 4029, 170, 23.7, 18.26, 7.78, 4, 4, 0, 0, 46, 0, 11),
(110, 't20i', 28, 27, 97, 582, 1, 802, 34, 23.58, 17.11, 8.26, 4, 1, 0, 0, 13, 0, 0),
(111, 'list_a', 6, 6, 49.3, 297, 2, 179, 7, 25.57, 42.42, 3.61, 3, 0, 0, 0, 0, 0, 0),
(111, 't20', 38, 38, 140, 840, 0, 946, 37, 25.56, 22.7, 6.75, 4, 1, 0, 0, 5, 0, 1),
(112, 'first_class', 11, 21, 309.3, 1857, 73, 863, 49, 17.61, 37.89, 2.78, 10, 3, 2, 1, 3, 0, 0),
(112, 'list_a', 57, 57, 441.4, 2650, 35, 2244, 102, 22, 25.98, 5.08, 6, 7, 2, 0, 15, 0, 2),
(112, 'odi', 7, 7, 62.1, 373, 5, 301, 18, 16.72, 20.72, 4.84, 4, 2, 0, 0, 0, 0, 0),
(112, 't20', 66, 66, 239.5, 1439, 4, 2057, 61, 33.72, 23.59, 8.57, 4, 1, 0, 0, 16, 0, 2),
(113, 'first_class', 4, 4, 57.3, 345, 1, 245, 6, 40.83, 57.5, 4.26, 3, 0, 0, 0, 2, 0, 0),
(113, 'list_a', 2, 2, 17, 102, 1, 72, 1, 72, 102, 4.23, 1, 0, 0, 0, 0, 0, 0),
(113, 't20', 3, 3, 6.3, 39, 0, 78, 0, 0, 0, 12, 0, 0, 0, 0, 0, 0, 0),
(114, 'first_class', 4, 7, 69, 414, 11, 278, 6, 46.33, 69, 4.02, 4, 0, 0, 0, 3, 0, 0),
(114, 'list_a', 20, 19, 103.5, 623, 3, 594, 19, 31.26, 32.78, 5.72, 2, 0, 0, 0, 7, 0, 2),
(114, 'odi', 2, 2, 14, 84, 0, 109, 4, 27.25, 21, 7.78, 2, 0, 0, 0, 0, 0, 0),
(114, 't20', 37, 36, 121, 726, 0, 1029, 48, 21.43, 15.12, 8.5, 4, 3, 0, 0, 3, 0, 2),
(114, 't20i', 13, 12, 42, 252, 0, 320, 19, 16.84, 13.26, 7.61, 4, 2, 0, 0, 1, 0, 1),
(115, 'first_class', 19, 2, 2, 12, 1, 6, 0, 0, 0, 3, 0, 0, 0, 0, 19, 0, 0),
(115, 'list_a', 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 2),
(115, 't20', 66, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 0, 1),
(115, 't20i', 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(116, 'first_class', 16, 24, 202.1, 1213, 23, 773, 21, 36.8, 57.76, 3.82, 6, 0, 1, 0, 12, 0, 0),
(116, 'list_a', 29, 24, 174, 1044, 6, 838, 26, 32.23, 40.15, 4.81, 4, 1, 0, 0, 13, 0, 0),
(116, 't20', 70, 44, 102.5, 617, 2, 776, 24, 32.33, 25.7, 7.54, 3, 0, 0, 0, 32, 0, 5),
(117, 'first_class', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0),
(117, 'list_a', 26, 11, 44.3, 267, 1, 232, 7, 33.14, 38.14, 5.21, 2, 0, 0, 0, 7, 0, 1),
(117, 't20', 28, 3, 2.1, 13, 0, 30, 0, 0, 0, 13.84, 0, 0, 0, 0, 4, 0, 1),
(118, 'first_class', 1, 1, 11, 66, 1, 32, 1, 32, 66, 2.9, 1, 0, 0, 0, 0, 0, 0),
(118, 'list_a', 8, 8, 51, 306, 7, 177, 10, 17.7, 30.6, 3.47, 3, 0, 0, 0, 0, 0, 2),
(118, 't20', 1, 1, 3.1, 19, 0, 32, 1, 32, 19, 10.1, 1, 0, 0, 0, 0, 0, 0),
(119, 'first_class', 16, 28, 409, 2454, 78, 1342, 44, 30.5, 55.77, 3.28, 7, 0, 1, 0, 4, 0, 0),
(119, 'list_a', 5, 5, 47, 282, 1, 304, 4, 76, 70.5, 6.46, 2, 0, 0, 0, 1, 0, 0),
(119, 't20', 26, 24, 85.3, 513, 0, 732, 20, 36.6, 25.65, 8.56, 4, 1, 0, 0, 5, 0, 0),
(120, 'first_class', 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 1, 0),
(120, 't20', 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0),
(121, 'first_class', 1, 1, 18, 108, 2, 105, 1, 105, 108, 5.83, 1, 0, 0, 0, 0, 0, 0),
(121, 'list_a', 1, 1, 9, 54, 1, 39, 1, 39, 54, 4.33, 1, 0, 0, 0, 0, 0, 0),
(121, 't20', 1, 1, 2, 12, 0, 16, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0),
(123, 'first_class', 113, 203, 4447.3, 26685, 1128, 10960, 453, 24.19, 58.9, 2.46, 13, 21, 28, 7, 90, 0, 15),
(123, 'list_a', 221, 212, 1822, 10932, 69, 8715, 249, 35, 43.9, 4.78, 5, 10, 1, 0, 82, 0, 30),
(123, 'odi', 168, 164, 1426.1, 8557, 50, 7024, 188, 37.36, 45.51, 4.92, 5, 7, 1, 0, 60, 0, 21),
(123, 't20', 286, 255, 769.4, 4618, 6, 5833, 191, 30.53, 24.17, 7.57, 5, 3, 1, 0, 114, 0, 32),
(123, 't20i', 58, 56, 187.1, 1123, 4, 1318, 48, 27.45, 23.39, 7.04, 3, 0, 0, 0, 22, 0, 7),
(123, 'test', 59, 112, 2437.5, 14627, 615, 5915, 242, 24.44, 60.44, 2.42, 10, 11, 10, 1, 39, 0, 8),
(124, 'first_class', 131, 9, 21, 126, 2, 87, 0, 0, 0, 4.14, 0, 0, 0, 0, 363, 59, 3),
(124, 'list_a', 423, 4, 10.3, 63, 0, 53, 2, 26.5, 31.5, 5.04, 1, 0, 0, 0, 402, 141, 29),
(124, 'odi', 350, 2, 6, 36, 0, 31, 1, 31, 36, 5.16, 1, 0, 0, 0, 321, 123, 22),
(124, 't20', 358, 1, 2, 12, 0, 25, 0, 0, 0, 12.5, 0, 0, 0, 0, 205, 84, 34),
(124, 't20i', 98, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 57, 34, 8),
(124, 'test', 90, 7, 16, 96, 1, 67, 0, 0, 0, 4.18, 0, 0, 0, 0, 256, 38, 3),
(125, 'first_class', 114, 201, 3164.2, 18986, 582, 10730, 335, 32.02, 56.67, 3.39, 9, 11, 10, 0, 137, 0, 0),
(125, 'list_a', 84, 82, 633, 3798, 17, 3633, 121, 30.02, 31.38, 5.73, 5, 1, 2, 0, 45, 0, 3),
(125, 'odi', 34, 34, 269.4, 1618, 5, 1611, 45, 35.8, 35.95, 5.97, 5, 0, 1, 0, 19, 0, 1),
(125, 't20', 258, 252, 859.5, 5159, 3, 7362, 265, 27.78, 19.46, 8.56, 4, 3, 0, 0, 142, 0, 15),
(125, 't20i', 75, 74, 259.5, 1559, 2, 2250, 80, 28.12, 19.48, 8.65, 4, 2, 0, 0, 40, 0, 7),
(125, 'test', 8, 16, 255, 1530, 74, 752, 21, 35.8, 72.85, 2.94, 7, 1, 0, 0, 14, 0, 0),
(126, 'first_class', 61, 108, 1558.3, 9351, 454, 4263, 173, 24.64, 54.05, 2.73, 10, 5, 6, 1, 18, 0, 1),
(126, 'list_a', 95, 94, 722.4, 4336, 56, 3433, 111, 30.92, 39.06, 4.75, 4, 3, 0, 0, 21, 0, 4),
(126, 'odi', 24, 24, 181.4, 1090, 9, 885, 31, 28.54, 35.16, 4.87, 3, 0, 0, 0, 7, 0, 2),
(126, 't20', 163, 142, 385.1, 2311, 1, 3146, 118, 26.66, 19.58, 8.16, 5, 1, 1, 0, 30, 0, 2),
(126, 't20i', 22, 20, 57.4, 346, 0, 448, 23, 19.47, 15.04, 7.76, 5, 0, 1, 0, 1, 0, 0),
(126, 'test', 3, 6, 80, 480, 22, 252, 7, 36, 68.57, 3.15, 3, 0, 0, 0, 2, 0, 0),
(127, 'first_class', 97, 35, 133, 798, 12, 518, 10, 51.8, 79.8, 3.89, 4, 1, 0, 0, 73, 0, 2),
(127, 'list_a', 172, 19, 70.1, 421, 1, 406, 13, 31.23, 32.38, 5.78, 4, 1, 0, 0, 68, 0, 13),
(127, 'odi', 55, 9, 20.1, 121, 1, 124, 3, 41.33, 40.33, 6.14, 1, 0, 0, 0, 17, 0, 5),
(127, 't20', 267, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 98, 3, 12),
(127, 't20i', 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0),
(128, 'first_class', 142, 39, 125.4, 754, 16, 485, 12, 40.41, 62.83, 3.85, 5, 0, 0, 0, 134, 2, 2),
(128, 'list_a', 203, 16, 47.2, 284, 0, 286, 5, 57.2, 56.8, 6.04, 2, 0, 0, 0, 110, 9, 14),
(128, 'odi', 46, 1, 0.2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 19, 2, 3),
(128, 't20', 290, 1, 1, 6, 0, 11, 0, 0, 0, 11, 0, 0, 0, 0, 131, 39, 13),
(128, 't20i', 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1),
(129, 'first_class', 117, 25, 104.2, 626, 5, 467, 9, 51.88, 69.55, 4.47, 4, 0, 0, 0, 100, 0, 2),
(129, 'list_a', 85, 9, 21.2, 128, 0, 127, 3, 42.33, 42.66, 5.95, 1, 0, 0, 0, 40, 0, 0),
(129, 'odi', 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0),
(129, 't20', 115, 8, 17.1, 103, 0, 141, 3, 47, 34.33, 8.21, 1, 0, 0, 0, 50, 2, 5),
(129, 't20i', 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 1, 0),
(129, 'test', 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0),
(130, 'first_class', 56, 88, 1379, 8274, 291, 4061, 86, 47.22, 96.2, 2.94, 5, 1, 0, 0, 46, 0, 7),
(130, 'list_a', 104, 97, 792.3, 4755, 24, 3708, 112, 33.1, 42.45, 4.67, 5, 1, 1, 0, 46, 0, 9),
(130, 'odi', 75, 70, 564.1, 3385, 12, 2742, 75, 36.56, 45.13, 4.86, 5, 0, 1, 0, 30, 0, 8),
(130, 't20', 125, 122, 423, 2538, 3, 3007, 122, 24.64, 20.8, 7.1, 4, 2, 0, 0, 45, 0, 4),
(130, 't20i', 62, 61, 208.2, 1250, 1, 1515, 66, 22.95, 18.93, 7.27, 4, 2, 0, 0, 26, 0, 1),
(130, 'test', 24, 40, 672.5, 4037, 140, 1871, 41, 45.63, 98.46, 2.78, 5, 0, 0, 0, 16, 0, 4),
(131, 'first_class', 100, 140, 1836.3, 11019, 362, 5918, 177, 33.43, 62.25, 3.22, 8, 9, 7, 0, 89, 0, 2),
(131, 'list_a', 227, 204, 1434.5, 8609, 55, 7494, 271, 27.65, 31.76, 5.22, 6, 8, 2, 0, 105, 0, 22),
(131, 'odi', 164, 150, 1085.1, 6511, 38, 5874, 199, 29.51, 32.71, 5.41, 6, 6, 1, 0, 73, 0, 21),
(131, 't20', 531, 503, 1715.1, 10291, 4, 14087, 587, 23.99, 17.53, 8.21, 5, 11, 2, 0, 252, 0, 49),
(131, 't20i', 91, 77, 250.5, 1505, 0, 2036, 78, 26.1, 19.29, 8.11, 4, 3, 0, 0, 44, 0, 9),
(131, 'test', 40, 61, 1077.4, 6466, 213, 3426, 86, 39.83, 75.18, 3.17, 6, 6, 2, 0, 41, 0, 1),
(132, 'first_class', 16, 27, 345.3, 2073, 80, 971, 40, 24.27, 51.82, 2.81, 7, 0, 2, 0, 6, 0, 0),
(132, 'list_a', 47, 43, 271, 1626, 7, 1456, 36, 40.44, 45.16, 5.37, 3, 0, 0, 0, 13, 0, 0),
(132, 'odi', 1, 1, 7.5, 47, 0, 68, 0, 0, 0, 8.68, 0, 0, 0, 0, 0, 0, 0),
(132, 't20', 78, 55, 122.3, 735, 1, 1088, 33, 32.96, 22.27, 8.88, 3, 0, 0, 0, 25, 0, 0),
(132, 't20i', 13, 11, 21.3, 129, 0, 216, 5, 43.2, 25.8, 10.04, 3, 0, 0, 0, 8, 0, 0),
(133, 'first_class', 198, 292, 4097.2, 24584, 591, 14490, 382, 37.93, 64.35, 3.53, 12, 17, 12, 2, 120, 0, 2),
(133, 'list_a', 229, 193, 1361.1, 8167, 20, 7307, 162, 45.1, 50.41, 5.36, 4, 2, 0, 0, 69, 0, 1),
(133, 'odi', 112, 104, 842.4, 5056, 10, 4424, 87, 50.85, 58.11, 5.25, 4, 1, 0, 0, 36, 0, 1),
(133, 't20', 216, 179, 499.4, 2998, 2, 3723, 150, 24.82, 19.98, 7.45, 5, 1, 1, 0, 72, 0, 4),
(133, 't20i', 49, 42, 108.1, 649, 1, 854, 33, 25.87, 19.66, 7.89, 3, 0, 0, 0, 13, 0, 3),
(133, 'test', 64, 112, 1975.4, 11854, 278, 7149, 195, 36.66, 60.78, 3.61, 10, 13, 5, 1, 40, 0, 2),
(134, 'first_class', 26, 1, 1, 6, 0, 2, 0, 0, 0, 2, 0, 0, 0, 0, 61, 3, 0),
(134, 'list_a', 36, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 15, 3, 4),
(134, 't20', 43, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 14, 3, 1),
(135, 'first_class', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(135, 'list_a', 8, 1, 5, 30, 1, 5, 1, 5, 30, 1, 1, 0, 0, 0, 3, 0, 1),
(135, 't20', 27, 2, 1.5, 11, 0, 18, 0, 0, 0, 9.81, 0, 0, 0, 0, 7, 0, 0),
(136, 'first_class', 21, 1, 0.1, 1, 0, 1, 0, 0, 0, 6, 0, 0, 0, 0, 14, 0, 0),
(136, 'list_a', 64, 1, 3, 18, 0, 11, 0, 0, 0, 3.66, 0, 0, 0, 0, 16, 0, 4),
(136, 't20', 74, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 30, 0, 2),
(136, 't20i', 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0),
(137, 'first_class', 1, 2, 9, 54, 0, 51, 0, 0, 0, 5.66, 0, 0, 0, 0, 0, 0, 0),
(137, 'list_a', 9, 9, 81, 486, 0, 483, 21, 23, 23.14, 5.96, 5, 1, 1, 0, 1, 0, 0),
(137, 't20', 1, 1, 4, 24, 0, 26, 1, 26, 24, 6.5, 1, 0, 0, 0, 0, 0, 0),
(138, 'first_class', 37, 5, 24, 144, 5, 70, 1, 70, 144, 2.91, 1, 0, 0, 0, 12, 0, 2),
(138, 'list_a', 32, 1, 2, 12, 0, 11, 0, 0, 0, 5.5, 0, 0, 0, 0, 10, 0, 1),
(138, 't20', 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 13, 0, 2),
(139, 'first_class', 13, 23, 395.1, 2371, 62, 1271, 38, 33.44, 62.39, 3.21, 6, 1, 0, 0, 3, 0, 2),
(139, 'list_a', 12, 12, 111.5, 671, 4, 644, 17, 37.88, 39.47, 5.75, 4, 1, 0, 0, 4, 0, 0),
(139, 't20', 22, 22, 77.4, 466, 1, 699, 29, 24.1, 16.06, 9, 4, 1, 0, 0, 3, 0, 0),
(140, 'first_class', 20, 29, 444.5, 2669, 83, 1433, 50, 28.66, 53.38, 3.22, 9, 3, 3, 0, 3, 0, 1),
(140, 'list_a', 27, 26, 192.2, 1154, 7, 1195, 29, 41.2, 39.79, 6.21, 5, 0, 1, 0, 5, 0, 1),
(140, 't20', 33, 33, 116.4, 700, 1, 1018, 45, 22.62, 15.55, 8.72, 4, 2, 0, 0, 6, 0, 1),
(141, 'first_class', 3, 6, 50, 300, 10, 164, 2, 82, 150, 3.28, 2, 0, 0, 0, 2, 0, 0),
(141, 'list_a', 8, 8, 66, 396, 3, 387, 17, 22.76, 23.29, 5.86, 4, 1, 0, 0, 3, 0, 0),
(141, 't20', 20, 20, 62.1, 373, 0, 505, 21, 24.04, 17.76, 8.12, 3, 0, 0, 0, 3, 0, 2),
(142, 'first_class', 11, 19, 310, 1860, 49, 1089, 37, 29.43, 50.27, 3.51, 7, 5, 1, 0, 2, 0, 0),
(142, 'list_a', 23, 23, 168.2, 1010, 7, 891, 23, 38.73, 43.91, 5.29, 4, 1, 0, 0, 2, 0, 0),
(142, 't20', 23, 23, 73.3, 441, 2, 560, 26, 21.53, 16.96, 7.61, 3, 0, 0, 0, 3, 0, 0),
(143, 'list_a', 5, 5, 43.5, 263, 0, 224, 10, 22.4, 26.3, 5.11, 4, 2, 0, 0, 0, 0, 0),
(143, 't20', 2, 2, 7, 42, 0, 62, 0, 0, 0, 8.85, 0, 0, 0, 0, 0, 0, 0),
(144, 'first_class', 3, 3, 69, 414, 1, 234, 8, 29.25, 51.75, 3.39, 5, 0, 1, 0, 1, 0, 0),
(144, 'list_a', 15, 15, 122.4, 736, 10, 448, 24, 18.66, 30.66, 3.65, 4, 2, 0, 0, 3, 0, 0),
(144, 'odi', 4, 4, 36, 216, 1, 136, 6, 22.66, 36, 3.77, 4, 1, 0, 0, 1, 0, 0),
(144, 't20', 56, 55, 206, 1236, 2, 1288, 63, 20.44, 19.61, 6.25, 4, 2, 0, 0, 14, 0, 1),
(144, 't20i', 15, 15, 56, 336, 0, 359, 14, 25.64, 24, 6.41, 3, 0, 0, 0, 4, 0, 0),
(145, 'list_a', 1, 1, 5, 30, 0, 41, 0, 0, 0, 8.2, 0, 0, 0, 0, 0, 0, 0),
(145, 't20', 2, 2, 4, 24, 0, 33, 2, 16.5, 12, 8.25, 2, 0, 0, 0, 0, 0, 1),
(147, 'first_class', 133, 25, 107.1, 643, 14, 338, 3, 112.66, 214.33, 3.15, 2, 0, 0, 0, 132, 0, 4),
(147, 'list_a', 294, 55, 117.3, 705, 1, 726, 4, 181.5, 176.25, 6.17, 1, 0, 0, 0, 155, 0, 23),
(147, 'odi', 260, 48, 106.5, 641, 1, 665, 4, 166.25, 160.25, 6.22, 1, 0, 0, 0, 137, 0, 21),
(147, 't20', 338, 44, 75.4, 454, 0, 661, 8, 82.62, 56.75, 8.73, 2, 0, 0, 0, 149, 0, 29),
(147, 't20i', 97, 12, 24.2, 146, 0, 198, 4, 49.5, 36.5, 8.13, 1, 0, 0, 0, 43, 0, 7),
(147, 'test', 101, 11, 29.1, 175, 2, 84, 0, 0, 0, 2.88, 0, 0, 0, 0, 101, 0, 4),
(148, 'first_class', 31, 54, 955.1, 5731, 218, 3006, 126, 23.85, 45.48, 3.14, 14, 10, 6, 2, 11, 0, 0),
(148, 'list_a', 56, 56, 457, 2742, 33, 2265, 79, 28.67, 34.7, 4.95, 5, 2, 2, 0, 11, 0, 1),
(148, 'odi', 12, 12, 107.3, 645, 7, 568, 16, 35.5, 40.31, 5.28, 5, 0, 1, 0, 3, 0, 0),
(148, 't20', 94, 92, 326, 1956, 2, 2380, 106, 22.45, 18.45, 7.3, 4, 2, 0, 0, 35, 0, 6),
(148, 't20i', 9, 8, 22, 132, 0, 187, 7, 26.71, 18.85, 8.5, 4, 1, 0, 0, 6, 0, 1),
(149, 'first_class', 167, 5, 20, 120, 0, 130, 0, 0, 0, 6.5, 0, 0, 0, 0, 386, 46, 8),
(149, 'list_a', 251, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 226, 44, 11),
(149, 'odi', 94, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 7, 2);
INSERT INTO `player_statistics_bowling` (`playerId`, `type`, `matches`, `innings`, `overs`, `ballsBalled`, `maidens`, `runs`, `wickets`, `average`, `strikeRate`, `economy`, `bestBowling`, `fourWicketHauls`, `fiverWicketHauls`, `tenWicketHauls`, `catches`, `stumping`, `runOuts`) VALUES
(149, 't20', 339, 1, 2, 12, 0, 10, 1, 10, 12, 5, 1, 0, 0, 0, 199, 63, 21),
(149, 't20i', 32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 14, 5, 1),
(149, 'test', 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 57, 6, 2),
(150, 'first_class', 77, 120, 1845.4, 11074, 284, 5963, 210, 28.39, 52.73, 3.23, 11, 9, 12, 2, 27, 0, 0),
(150, 'list_a', 99, 93, 786.1, 4717, 24, 3668, 116, 31.62, 40.66, 4.66, 5, 0, 2, 0, 39, 0, 5),
(150, 'odi', 2, 2, 19, 114, 1, 125, 0, 0, 0, 6.57, 0, 0, 0, 0, 3, 0, 0),
(150, 't20', 138, 127, 400.5, 2405, 1, 2990, 120, 24.91, 20.04, 7.45, 5, 2, 1, 0, 34, 0, 12),
(150, 't20i', 1, 1, 4, 24, 0, 28, 1, 28, 24, 7, 1, 0, 0, 0, 0, 0, 0),
(150, 'test', 1, 2, 49, 294, 3, 238, 4, 59.5, 73.5, 4.85, 4, 0, 0, 0, 0, 0, 0),
(151, 'first_class', 77, 119, 1790.5, 10745, 348, 5895, 198, 29.77, 54.26, 3.29, 10, 4, 6, 1, 18, 0, 10),
(151, 'list_a', 135, 125, 849.2, 5096, 43, 4823, 157, 30.71, 32.45, 5.67, 5, 6, 2, 0, 49, 0, 4),
(151, 'odi', 52, 51, 384.1, 2305, 23, 2181, 69, 31.6, 33.4, 5.67, 5, 3, 1, 0, 23, 0, 3),
(151, 't20', 208, 185, 593.2, 3560, 5, 4654, 205, 22.7, 17.36, 7.84, 4, 4, 0, 0, 87, 0, 18),
(151, 't20i', 32, 32, 106.5, 641, 0, 854, 38, 22.47, 16.86, 7.99, 4, 1, 0, 0, 15, 0, 1),
(152, 'first_class', 67, 98, 946.4, 5680, 146, 3174, 77, 41.22, 73.76, 3.35, 6, 3, 1, 0, 55, 0, 5),
(152, 'list_a', 191, 146, 788.3, 4731, 17, 4348, 96, 45.29, 49.28, 5.51, 4, 2, 0, 0, 118, 0, 15),
(152, 'odi', 116, 91, 473.2, 2840, 9, 2683, 51, 52.6, 55.68, 5.66, 4, 2, 0, 0, 72, 0, 11),
(152, 't20', 355, 237, 521.2, 3128, 1, 4007, 124, 32.31, 25.22, 7.68, 3, 0, 0, 0, 175, 0, 23),
(152, 't20i', 84, 56, 126, 756, 0, 939, 34, 27.61, 22.23, 7.45, 3, 0, 0, 0, 39, 0, 6),
(152, 'test', 7, 9, 77, 462, 4, 341, 8, 42.62, 57.75, 4.42, 4, 1, 0, 0, 5, 0, 1),
(153, 'first_class', 65, 115, 2051.3, 12309, 397, 6194, 241, 25.7, 51.07, 3.01, 8, 10, 15, 0, 15, 0, 8),
(153, 'list_a', 100, 100, 819.1, 4915, 54, 4278, 170, 25.16, 28.91, 5.22, 6, 9, 6, 0, 27, 0, 5),
(153, 'odi', 3, 3, 27, 162, 0, 179, 0, 0, 0, 6.62, 0, 0, 0, 0, 1, 0, 0),
(153, 't20', 124, 124, 445.4, 2674, 4, 3389, 147, 23.05, 18.19, 7.6, 4, 5, 0, 0, 20, 0, 6),
(153, 't20i', 3, 3, 9.4, 58, 0, 84, 4, 21, 14.5, 8.68, 2, 0, 0, 0, 0, 0, 0),
(154, 'first_class', 64, 113, 1753.1, 10519, 358, 5326, 226, 23.56, 46.54, 3.03, 12, 12, 12, 4, 25, 0, 5),
(154, 'list_a', 61, 60, 429.4, 2578, 15, 2281, 85, 26.83, 30.32, 5.3, 5, 1, 1, 0, 13, 0, 3),
(154, 't20', 135, 133, 470, 2820, 4, 3746, 163, 22.98, 17.3, 7.97, 5, 1, 1, 0, 27, 0, 7),
(154, 't20i', 8, 8, 29, 174, 0, 247, 11, 22.45, 15.81, 8.51, 3, 0, 0, 0, 1, 0, 0),
(155, 'first_class', 150, 71, 426.2, 2558, 41, 1477, 41, 36.02, 62.39, 3.46, 8, 3, 0, 0, 142, 0, 1),
(155, 'list_a', 262, 93, 373, 2238, 5, 2030, 54, 37.59, 41.44, 5.44, 4, 1, 0, 0, 147, 0, 13),
(155, 'odi', 143, 11, 32, 192, 0, 189, 2, 94.5, 96, 5.9, 1, 0, 0, 0, 81, 0, 7),
(155, 't20', 289, 52, 131.4, 790, 0, 917, 50, 18.34, 15.8, 6.96, 5, 1, 2, 0, 153, 0, 10),
(155, 't20i', 50, 2, 1.2, 8, 0, 3, 0, 0, 0, 2.25, 0, 0, 0, 0, 24, 0, 1),
(155, 'test', 69, 5, 13, 78, 0, 69, 0, 0, 0, 5.3, 0, 0, 0, 0, 63, 0, 1),
(156, 'first_class', 39, 64, 1023.3, 6141, 216, 3161, 85, 37.18, 72.24, 3.08, 7, 2, 2, 0, 7, 0, 1),
(156, 'list_a', 45, 45, 351.4, 2110, 19, 1880, 82, 22.92, 25.73, 5.34, 6, 2, 3, 0, 10, 0, 1),
(156, 't20', 53, 52, 187.1, 1123, 1, 1427, 83, 17.19, 13.53, 7.62, 5, 2, 2, 0, 18, 0, 5),
(157, 'first_class', 98, 181, 3243.1, 19459, 851, 8890, 360, 24.69, 54.05, 2.74, 9, 13, 11, 0, 37, 0, 5),
(157, 'list_a', 108, 106, 967.5, 5807, 71, 4599, 172, 26.73, 33.76, 4.75, 7, 2, 4, 0, 30, 0, 0),
(157, 'odi', 56, 55, 494.5, 2969, 35, 2333, 93, 25.08, 31.92, 4.71, 6, 1, 3, 0, 17, 0, 0),
(157, 't20', 75, 75, 284, 1704, 5, 2081, 99, 21.02, 17.21, 7.32, 4, 4, 0, 0, 9, 0, 2),
(157, 't20i', 27, 27, 102.4, 616, 2, 772, 40, 19.3, 15.4, 7.51, 4, 3, 0, 0, 4, 0, 0),
(157, 'test', 57, 107, 2039.1, 12235, 531, 5573, 215, 25.92, 56.9, 2.73, 9, 7, 9, 0, 21, 0, 3),
(158, 'first_class', 35, 42, 413.3, 2481, 65, 1317, 39, 33.76, 63.61, 3.18, 5, 1, 1, 0, 13, 0, 0),
(158, 'list_a', 39, 28, 105.2, 632, 0, 597, 10, 59.7, 63.2, 5.66, 2, 0, 0, 0, 17, 0, 3),
(158, 't20', 62, 36, 67.1, 403, 0, 496, 8, 62, 50.37, 7.38, 2, 0, 0, 0, 25, 0, 2),
(159, 'first_class', 41, 66, 688, 4128, 84, 2436, 80, 30.45, 51.6, 3.54, 10, 3, 5, 1, 44, 0, 2),
(159, 'list_a', 72, 64, 459.1, 2755, 23, 2239, 86, 26.03, 32.03, 4.87, 5, 4, 3, 0, 28, 0, 2),
(159, 'odi', 29, 28, 218.1, 1309, 10, 1099, 29, 37.89, 45.13, 5.03, 3, 0, 0, 0, 8, 0, 2),
(159, 't20', 97, 92, 320.3, 1923, 4, 2130, 136, 15.66, 14.13, 6.64, 5, 2, 2, 0, 43, 0, 10),
(159, 't20i', 35, 33, 122.4, 736, 0, 784, 57, 13.75, 12.91, 6.39, 4, 1, 0, 0, 11, 0, 2),
(159, 'test', 4, 7, 112.2, 674, 8, 403, 4, 100.75, 168.5, 3.58, 4, 1, 0, 0, 2, 0, 0),
(160, 'first_class', 51, 92, 1500.4, 9004, 336, 4667, 190, 24.56, 47.38, 3.1, 11, 15, 5, 2, 13, 0, 4),
(160, 'list_a', 49, 49, 383, 2298, 21, 1986, 86, 23.09, 26.72, 5.18, 5, 2, 3, 0, 6, 0, 2),
(160, 'odi', 4, 4, 36, 216, 4, 169, 5, 33.8, 43.2, 4.69, 3, 0, 0, 0, 0, 0, 0),
(160, 't20', 99, 98, 352, 2112, 5, 2904, 116, 25.03, 18.2, 8.25, 4, 3, 0, 0, 31, 0, 3),
(160, 't20i', 5, 5, 20, 120, 0, 209, 5, 41.8, 24, 10.45, 1, 0, 0, 0, 1, 0, 0),
(160, 'test', 12, 23, 345.1, 2071, 73, 1067, 36, 29.63, 57.52, 3.09, 8, 2, 1, 0, 7, 0, 0),
(161, 'first_class', 39, 1, 3, 18, 1, 5, 0, 0, 0, 1.66, 0, 0, 0, 0, 45, 0, 2),
(161, 'list_a', 43, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 0, 4),
(161, 't20', 36, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 21, 0, 0),
(162, 'first_class', 22, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50, 12, 0),
(162, 'list_a', 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 6, 0),
(162, 't20', 35, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 33, 6, 3),
(163, 'first_class', 17, 29, 225.5, 1355, 43, 783, 33, 23.72, 41.06, 3.46, 8, 0, 1, 0, 12, 0, 0),
(163, 'list_a', 20, 13, 55.5, 335, 6, 265, 5, 53, 67, 4.74, 2, 0, 0, 0, 8, 0, 2),
(163, 't20', 89, 15, 30.5, 185, 0, 257, 8, 32.12, 23.12, 8.33, 3, 0, 0, 0, 35, 0, 5),
(163, 't20i', 6, 2, 6, 36, 0, 49, 1, 49, 36, 8.16, 1, 0, 0, 0, 1, 0, 1),
(164, 'first_class', 16, 1, 3, 18, 0, 15, 1, 15, 18, 5, 1, 0, 0, 0, 17, 0, 0),
(164, 'list_a', 27, 7, 27, 162, 0, 157, 1, 157, 162, 5.81, 1, 0, 0, 0, 19, 0, 1),
(164, 't20', 43, 1, 1, 6, 0, 8, 0, 0, 0, 8, 0, 0, 0, 0, 15, 1, 1),
(164, 't20i', 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0),
(165, 'first_class', 16, 26, 338.2, 2030, 82, 894, 45, 19.86, 45.11, 2.64, 11, 2, 1, 1, 7, 0, 0),
(165, 'list_a', 26, 26, 212, 1272, 8, 941, 24, 39.2, 53, 4.43, 3, 0, 0, 0, 7, 0, 0),
(165, 't20', 53, 45, 133, 798, 0, 926, 38, 24.36, 21, 6.96, 3, 0, 0, 0, 23, 0, 2),
(166, 'first_class', 19, 11, 52.2, 314, 4, 250, 8, 31.25, 39.25, 4.77, 3, 0, 0, 0, 24, 0, 1),
(166, 'list_a', 34, 11, 45.1, 271, 1, 274, 4, 68.5, 67.75, 6.06, 2, 0, 0, 0, 12, 0, 2),
(166, 't20', 27, 9, 17, 102, 0, 127, 2, 63.5, 51, 7.47, 1, 0, 0, 0, 19, 0, 3),
(167, 'first_class', 11, 18, 268.4, 1612, 47, 849, 45, 18.86, 35.82, 3.16, 7, 3, 1, 0, 4, 0, 0),
(167, 'list_a', 16, 16, 132.2, 794, 8, 688, 25, 27.52, 31.76, 5.19, 3, 0, 0, 0, 3, 0, 0),
(167, 't20', 27, 26, 93.5, 563, 1, 687, 31, 22.16, 18.16, 7.32, 4, 1, 0, 0, 7, 0, 1),
(169, 'first_class', 104, 142, 1465.5, 8795, 268, 4967, 162, 30.66, 54.29, 3.38, 9, 7, 2, 0, 54, 0, 3),
(169, 'list_a', 122, 97, 577.5, 3467, 12, 3119, 99, 31.5, 35.02, 5.39, 5, 3, 2, 0, 61, 0, 4),
(169, 'odi', 63, 59, 330.5, 1985, 8, 1829, 50, 36.58, 39.7, 5.52, 5, 1, 1, 0, 30, 0, 1),
(169, 't20', 143, 92, 219, 1314, 1, 1828, 70, 26.11, 18.77, 8.34, 4, 2, 0, 0, 56, 0, 4),
(169, 't20i', 36, 20, 40, 240, 0, 306, 15, 20.4, 16, 7.65, 3, 0, 0, 0, 13, 0, 0),
(169, 'test', 32, 54, 475.3, 2853, 83, 1623, 42, 38.64, 67.92, 3.41, 7, 1, 1, 0, 16, 0, 1),
(170, 'first_class', 35, 61, 837.5, 5027, 195, 2426, 91, 26.65, 55.24, 2.89, 6, 8, 1, 0, 5, 0, 5),
(170, 'list_a', 85, 84, 693.4, 4162, 37, 3464, 155, 22.34, 26.85, 4.99, 6, 4, 6, 0, 14, 0, 1),
(170, 'odi', 74, 73, 601, 3606, 26, 3098, 131, 23.64, 27.52, 5.15, 6, 3, 5, 0, 13, 0, 1),
(170, 't20', 190, 189, 691, 4146, 12, 5021, 249, 20.16, 16.65, 7.26, 5, 5, 3, 0, 36, 0, 7),
(170, 't20i', 63, 63, 225.4, 1354, 6, 1710, 87, 19.65, 15.56, 7.57, 5, 3, 1, 0, 13, 0, 0),
(170, 'test', 14, 23, 335.3, 2013, 68, 1102, 30, 36.73, 67.1, 3.28, 5, 2, 0, 0, 1, 0, 1),
(171, 'first_class', 81, 30, 107.4, 646, 20, 342, 1, 342, 646, 3.17, 1, 0, 0, 0, 65, 0, 2),
(171, 'list_a', 114, 24, 82.3, 495, 1, 458, 14, 32.71, 35.35, 5.55, 2, 0, 0, 0, 53, 0, 5),
(171, 't20', 185, 26, 50.3, 303, 0, 337, 16, 21.06, 18.93, 6.67, 3, 0, 0, 0, 68, 0, 11),
(171, 't20i', 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0),
(172, 'first_class', 69, 123, 2041.4, 12250, 422, 6462, 233, 27.73, 52.57, 3.16, 9, 11, 13, 0, 19, 0, 4),
(172, 'list_a', 78, 78, 615.5, 3695, 24, 3554, 123, 28.89, 30.04, 5.77, 4, 7, 0, 0, 20, 0, 5),
(172, 'odi', 19, 19, 151.3, 909, 4, 1004, 25, 40.16, 36.36, 6.62, 4, 2, 0, 0, 4, 0, 1),
(172, 't20', 137, 135, 472.3, 2835, 3, 4099, 156, 26.27, 18.17, 8.67, 4, 1, 0, 0, 41, 0, 4),
(172, 't20i', 25, 24, 84.2, 506, 0, 772, 33, 23.39, 15.33, 9.15, 4, 1, 0, 0, 7, 0, 0),
(172, 'test', 7, 13, 166.3, 999, 26, 547, 26, 21.03, 38.42, 3.28, 8, 1, 1, 0, 2, 0, 0),
(173, 'first_class', 60, 104, 1698.1, 10189, 369, 5575, 211, 26.42, 48.28, 3.28, 9, 12, 8, 0, 13, 0, 1),
(173, 'list_a', 45, 44, 370.1, 2221, 18, 1818, 73, 24.9, 30.42, 4.91, 4, 2, 0, 0, 10, 0, 6),
(173, 'odi', 12, 12, 102.5, 617, 2, 567, 22, 25.77, 28.04, 5.51, 4, 1, 0, 0, 2, 0, 3),
(173, 't20', 69, 69, 254, 1524, 2, 1879, 89, 21.11, 17.12, 7.39, 4, 2, 0, 0, 18, 0, 1),
(173, 't20i', 16, 16, 58.2, 350, 0, 394, 18, 21.88, 19.44, 6.75, 3, 0, 0, 0, 4, 0, 1),
(173, 'test', 12, 21, 363.4, 2182, 64, 1321, 47, 28.1, 46.42, 3.63, 8, 1, 3, 0, 4, 0, 0),
(174, 'first_class', 79, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 275, 31, 2),
(174, 'list_a', 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 61, 11, 3),
(174, 't20', 63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 11, 10),
(175, 'first_class', 26, 47, 593.5, 3563, 146, 1858, 85, 21.85, 41.91, 3.12, 9, 2, 6, 0, 11, 0, 1),
(175, 'list_a', 61, 60, 473.4, 2842, 32, 2584, 93, 27.78, 30.55, 5.45, 6, 3, 2, 0, 12, 0, 2),
(175, 'odi', 35, 35, 285, 1710, 19, 1594, 61, 26.13, 28.03, 5.59, 6, 2, 1, 0, 8, 0, 1),
(175, 't20', 85, 83, 277.1, 1663, 6, 2207, 117, 18.86, 14.21, 7.96, 4, 3, 0, 0, 17, 0, 3),
(175, 't20i', 23, 23, 78.5, 473, 0, 706, 36, 19.61, 13.13, 8.95, 4, 1, 0, 0, 3, 0, 1),
(175, 'test', 13, 25, 324.4, 1948, 84, 971, 47, 20.65, 41.44, 2.99, 8, 1, 3, 0, 6, 0, 1),
(176, 'first_class', 46, 81, 1690.1, 10141, 460, 4195, 174, 24.1, 58.28, 2.48, 11, 7, 11, 2, 22, 0, 1),
(176, 'list_a', 133, 128, 1153.1, 6919, 59, 4922, 169, 29.12, 40.94, 4.26, 6, 3, 1, 0, 54, 0, 5),
(176, 'odi', 38, 35, 318, 1908, 13, 1409, 45, 31.31, 42.4, 4.43, 3, 0, 0, 0, 15, 0, 0),
(176, 't20', 178, 177, 628.4, 3772, 4, 4320, 150, 28.8, 25.14, 6.87, 4, 1, 0, 0, 71, 0, 6),
(176, 't20i', 15, 15, 53, 318, 0, 355, 13, 27.3, 24.46, 6.69, 3, 0, 0, 0, 5, 0, 0),
(176, 'test', 6, 12, 217.5, 1307, 52, 485, 39, 12.43, 33.51, 2.22, 11, 1, 5, 1, 2, 0, 0),
(177, 'first_class', 33, 54, 1019.4, 6118, 143, 3719, 123, 30.23, 49.73, 3.64, 9, 8, 6, 0, 14, 0, 2),
(177, 'list_a', 76, 74, 673, 4038, 22, 3462, 123, 28.14, 32.82, 5.14, 6, 4, 2, 0, 11, 0, 1),
(177, 'odi', 66, 64, 588, 3528, 13, 3084, 109, 28.29, 32.36, 5.24, 6, 4, 1, 0, 9, 0, 1),
(177, 't20', 114, 111, 398.1, 2389, 2, 3047, 140, 21.76, 17.06, 7.65, 5, 5, 2, 0, 31, 0, 4),
(177, 't20i', 24, 23, 85.3, 513, 1, 605, 41, 14.75, 12.51, 7.07, 5, 1, 1, 0, 8, 0, 0),
(177, 'test', 7, 12, 177.1, 1063, 24, 620, 26, 23.84, 40.88, 3.49, 6, 2, 2, 0, 3, 0, 1),
(178, 'first_class', 54, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 134, 10, 1),
(178, 'list_a', 43, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 58, 7, 1),
(178, 'odi', 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 1, 0),
(178, 't20', 145, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 95, 20, 11),
(178, 't20i', 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 21, 6, 4),
(179, 'first_class', 22, 7, 25, 150, 0, 105, 0, 0, 0, 4.2, 0, 0, 0, 0, 15, 0, 0),
(179, 'list_a', 21, 1, 1, 6, 0, 4, 0, 0, 0, 4, 0, 0, 0, 0, 9, 0, 0),
(179, 't20', 72, 2, 1.2, 8, 0, 9, 0, 0, 0, 6.75, 0, 0, 0, 0, 28, 0, 3),
(180, 'first_class', 1, 1, 16, 96, 0, 80, 2, 40, 48, 5, 2, 0, 0, 0, 0, 0, 0),
(180, 'list_a', 13, 13, 106, 636, 2, 496, 21, 23.61, 30.28, 4.67, 4, 1, 0, 0, 4, 0, 1),
(180, 'odi', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(180, 't20', 22, 22, 62.3, 375, 0, 446, 20, 22.3, 18.75, 7.13, 4, 1, 0, 0, 14, 0, 5),
(181, 'first_class', 125, 34, 99.1, 595, 4, 455, 6, 75.83, 99.16, 4.58, 2, 0, 0, 0, 91, 0, 8),
(181, 'list_a', 177, 8, 24, 144, 0, 158, 4, 39.5, 36, 6.58, 1, 0, 0, 0, 75, 0, 13),
(181, 'odi', 128, 1, 1, 6, 0, 8, 0, 0, 0, 8, 0, 0, 0, 0, 56, 0, 6),
(181, 't20', 323, 2, 1.1, 7, 0, 15, 0, 0, 0, 12.85, 0, 0, 0, 0, 153, 0, 19),
(181, 't20i', 88, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 0, 3),
(181, 'test', 94, 19, 57, 342, 1, 269, 4, 67.25, 85.5, 4.71, 2, 0, 0, 0, 74, 0, 6),
(182, 'first_class', 6, 10, 176.5, 1061, 48, 514, 11, 46.72, 96.45, 2.9, 3, 0, 0, 0, 1, 0, 0),
(182, 'list_a', 50, 50, 390, 2340, 34, 1978, 73, 27.09, 32.05, 5.07, 4, 4, 0, 0, 8, 0, 1),
(182, 'odi', 11, 11, 80, 480, 2, 465, 15, 31, 32, 5.81, 3, 0, 0, 0, 1, 0, 0),
(182, 't20', 77, 77, 288.1, 1729, 1, 2330, 103, 22.62, 16.78, 8.08, 5, 1, 1, 0, 13, 0, 3),
(182, 't20i', 14, 14, 52, 312, 1, 459, 13, 35.3, 24, 8.82, 2, 0, 0, 0, 3, 0, 0),
(183, 'first_class', 54, 1, 2, 12, 0, 9, 1, 9, 12, 4.5, 1, 0, 0, 0, 177, 18, 1),
(183, 'list_a', 61, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 11, 2),
(183, 'odi', 24, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 19, 1, 0),
(183, 't20', 154, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 91, 26, 9),
(183, 't20i', 43, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 13, 7, 1),
(183, 'test', 30, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 107, 11, 1),
(184, 'first_class', 13, 20, 189.5, 1139, 40, 590, 25, 23.6, 45.56, 3.1, 7, 0, 1, 0, 6, 0, 0),
(184, 'list_a', 90, 45, 187.4, 1126, 4, 1119, 29, 38.58, 38.82, 5.96, 5, 0, 1, 0, 41, 0, 6),
(184, 'odi', 37, 13, 40.5, 245, 0, 243, 3, 81, 81.66, 5.95, 1, 0, 0, 0, 14, 0, 1),
(184, 't20', 122, 39, 90, 540, 0, 930, 21, 44.28, 25.71, 10.33, 2, 0, 0, 0, 72, 0, 6),
(184, 't20i', 39, 7, 14, 84, 0, 123, 4, 30.75, 21, 8.78, 2, 0, 0, 0, 18, 0, 2),
(185, 'first_class', 1, 2, 23.2, 140, 3, 93, 4, 23.25, 35, 3.98, 4, 0, 0, 0, 0, 0, 0),
(185, 'list_a', 15, 15, 103.4, 622, 2, 487, 17, 28.64, 36.58, 4.69, 3, 0, 0, 0, 3, 0, 1),
(185, 't20', 18, 17, 50.1, 301, 0, 428, 12, 35.66, 25.08, 8.53, 3, 0, 0, 0, 6, 0, 0),
(186, 'first_class', 31, 4, 6, 36, 0, 44, 0, 0, 0, 7.33, 0, 0, 0, 0, 19, 0, 2),
(186, 'list_a', 44, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 12, 0, 1),
(186, 'odi', 6, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0),
(186, 't20', 81, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 22, 0, 1),
(186, 't20i', 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0),
(186, 'test', 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 1),
(187, 'first_class', 22, 19, 89, 534, 16, 290, 3, 96.66, 178, 3.25, 2, 0, 0, 0, 14, 0, 3),
(187, 'list_a', 36, 7, 24, 144, 0, 136, 3, 45.33, 48, 5.66, 2, 0, 0, 0, 6, 0, 3),
(187, 't20', 41, 11, 26, 156, 0, 238, 7, 34, 22.28, 9.15, 3, 0, 0, 0, 15, 0, 1),
(188, 'first_class', 18, 32, 504.5, 3029, 93, 1623, 53, 30.62, 57.15, 3.21, 9, 0, 3, 0, 4, 0, 1),
(188, 'list_a', 15, 15, 131.1, 787, 10, 696, 25, 27.84, 31.48, 5.3, 5, 0, 1, 0, 6, 0, 1),
(188, 'odi', 1, 1, 8, 48, 0, 34, 2, 17, 24, 4.25, 2, 0, 0, 0, 2, 0, 0),
(188, 't20', 41, 40, 150.2, 902, 4, 1138, 54, 21.07, 16.7, 7.56, 5, 1, 1, 0, 12, 0, 2),
(188, 't20i', 2, 1, 3.4, 22, 0, 34, 1, 34, 22, 9.27, 1, 0, 0, 0, 0, 0, 0),
(189, 'list_a', 14, 3, 14, 84, 0, 82, 4, 20.5, 21, 5.85, 2, 0, 0, 0, 4, 0, 0),
(189, 't20', 21, 5, 7, 42, 0, 66, 0, 0, 0, 9.42, 0, 0, 0, 0, 7, 0, 0),
(190, 'first_class', 3, 1, 2, 12, 0, 17, 0, 0, 0, 8.5, 0, 0, 0, 0, 0, 0, 0),
(191, 'first_class', 15, 22, 257, 1542, 29, 841, 12, 70.08, 128.5, 3.27, 2, 0, 0, 0, 12, 0, 1),
(191, 'list_a', 30, 29, 215, 1290, 1, 1017, 30, 33.9, 43, 4.73, 5, 0, 1, 0, 12, 0, 1),
(191, 't20', 58, 48, 142.4, 856, 2, 1014, 36, 28.16, 23.77, 7.1, 3, 0, 0, 0, 34, 0, 8),
(192, 'first_class', 2, 3, 99, 594, 17, 284, 3, 94.66, 198, 2.86, 3, 0, 0, 0, 0, 0, 0),
(193, 'first_class', 58, 104, 1708, 10248, 335, 5418, 178, 30.43, 57.57, 3.17, 9, 9, 6, 0, 24, 0, 1),
(193, 'list_a', 56, 55, 460.5, 2765, 23, 2505, 94, 26.64, 29.41, 5.43, 5, 2, 2, 0, 10, 0, 0),
(193, 't20', 100, 99, 347.4, 2086, 3, 2667, 103, 25.89, 20.25, 7.67, 3, 0, 0, 0, 31, 0, 6),
(194, 'first_class', 122, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 313, 37, 3),
(194, 'list_a', 102, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 126, 15, 10),
(194, 'odi', 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 17, 1, 1),
(194, 't20', 216, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 121, 35, 14),
(194, 'test', 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 92, 12, 1),
(195, 'first_class', 63, 4, 8.2, 50, 0, 42, 0, 0, 0, 5.04, 0, 0, 0, 0, 73, 0, 2),
(195, 'list_a', 245, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 109, 0, 27),
(195, 'odi', 143, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 64, 0, 16),
(195, 't20', 373, 3, 3, 18, 0, 31, 0, 0, 0, 10.33, 0, 0, 0, 0, 233, 1, 25),
(195, 't20i', 95, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 70, 1, 11),
(196, 'first_class', 63, 99, 1584.4, 9508, 309, 5481, 167, 32.82, 56.93, 3.45, 8, 7, 6, 0, 12, 0, 0),
(196, 'list_a', 73, 72, 574.2, 3446, 26, 3128, 115, 27.2, 29.96, 5.44, 6, 3, 3, 0, 13, 0, 3),
(196, 'odi', 9, 9, 63.2, 380, 1, 419, 11, 38.09, 34.54, 6.61, 3, 0, 0, 0, 1, 0, 0),
(196, 't20', 89, 87, 299.5, 1799, 4, 2583, 89, 29.02, 20.21, 8.61, 3, 0, 0, 0, 13, 0, 4),
(196, 'test', 9, 14, 198.1, 1189, 12, 947, 18, 52.61, 66.05, 4.77, 3, 0, 0, 0, 1, 0, 0),
(197, 'first_class', 7, 12, 125, 750, 13, 511, 17, 30.05, 44.11, 4.08, 9, 0, 1, 0, 8, 0, 0),
(197, 'list_a', 23, 23, 165.5, 995, 4, 785, 31, 25.32, 32.09, 4.73, 3, 0, 0, 0, 11, 0, 2),
(197, 't20', 99, 80, 216.5, 1301, 0, 1642, 54, 30.4, 24.09, 7.57, 3, 0, 0, 0, 38, 0, 3),
(198, 'first_class', 48, 60, 557.5, 3347, 119, 1802, 34, 53, 98.44, 3.23, 5, 2, 0, 0, 30, 0, 9),
(198, 'list_a', 92, 76, 388, 2328, 17, 2002, 58, 34.51, 40.13, 5.15, 4, 2, 0, 0, 34, 0, 10),
(198, 'odi', 12, 9, 38.5, 233, 0, 210, 4, 52.5, 58.25, 5.4, 2, 0, 0, 0, 7, 0, 0),
(198, 't20', 115, 62, 138.2, 830, 1, 1138, 33, 34.48, 25.15, 8.22, 3, 0, 0, 0, 59, 0, 19),
(198, 't20i', 9, 6, 21, 126, 0, 191, 5, 38.2, 25.2, 9.09, 2, 0, 0, 0, 2, 0, 2),
(199, 'first_class', 83, 156, 2598.2, 15590, 532, 8438, 317, 26.61, 49.17, 3.24, 11, 16, 12, 2, 22, 0, 2),
(199, 'list_a', 110, 109, 927.2, 5564, 49, 5105, 205, 24.9, 27.14, 5.5, 5, 13, 1, 0, 41, 0, 2),
(199, 'odi', 79, 78, 674, 4044, 39, 3793, 148, 25.62, 27.32, 5.62, 5, 9, 1, 0, 28, 0, 0),
(199, 't20', 129, 129, 461.3, 2769, 4, 3821, 152, 25.13, 18.21, 8.27, 4, 1, 0, 0, 24, 0, 13),
(199, 't20i', 17, 17, 59.3, 357, 1, 568, 18, 31.55, 19.83, 9.54, 3, 0, 0, 0, 1, 0, 1),
(199, 'test', 59, 112, 1767.3, 10605, 335, 5789, 214, 27.05, 49.55, 3.27, 9, 11, 6, 0, 16, 0, 2),
(200, 'first_class', 45, 73, 1187.1, 7123, 245, 3975, 161, 24.68, 44.24, 3.34, 12, 6, 11, 1, 16, 0, 0),
(200, 'list_a', 75, 75, 641, 3846, 27, 3419, 140, 24.42, 27.47, 5.33, 6, 5, 4, 0, 20, 0, 0),
(200, 'odi', 37, 37, 326, 1956, 6, 1779, 69, 25.78, 28.34, 5.45, 5, 2, 1, 0, 10, 0, 0),
(200, 't20', 102, 102, 363.4, 2182, 3, 2793, 120, 23.27, 18.18, 7.68, 5, 4, 1, 0, 24, 0, 3),
(200, 't20i', 15, 15, 54, 324, 0, 385, 25, 15.4, 12.96, 7.12, 5, 0, 1, 0, 4, 0, 0),
(200, 'test', 1, 1, 11, 66, 1, 47, 0, 0, 0, 4.27, 0, 0, 0, 0, 0, 0, 0),
(201, 'first_class', 58, 76, 680.1, 4081, 101, 2114, 54, 39.14, 75.57, 3.1, 9, 5, 1, 0, 23, 0, 1),
(201, 'list_a', 96, 47, 238.5, 1433, 5, 1147, 33, 34.75, 43.42, 4.8, 5, 0, 1, 0, 31, 0, 6),
(201, 'odi', 3, 3, 10, 60, 0, 68, 0, 0, 0, 6.8, 0, 0, 0, 0, 1, 0, 0),
(201, 't20', 118, 19, 37, 222, 0, 262, 8, 32.75, 27.75, 7.08, 2, 0, 0, 0, 55, 3, 6),
(202, 'first_class', 29, 39, 449, 2694, 87, 1486, 48, 30.95, 56.12, 3.3, 8, 0, 3, 0, 14, 0, 3),
(202, 'list_a', 84, 72, 546.4, 3280, 11, 2967, 73, 40.64, 44.93, 5.42, 3, 0, 0, 0, 33, 0, 5),
(202, 'odi', 63, 58, 421.4, 2530, 5, 2364, 57, 41.47, 44.38, 5.6, 3, 0, 0, 0, 24, 0, 5),
(202, 't20', 186, 141, 393.3, 2361, 4, 3208, 114, 28.14, 20.71, 8.15, 4, 1, 0, 0, 99, 0, 14),
(202, 't20i', 54, 47, 139.5, 839, 1, 1151, 42, 27.4, 19.97, 8.23, 4, 1, 0, 0, 34, 0, 3),
(202, 'test', 11, 19, 156.1, 937, 19, 528, 17, 31.05, 55.11, 3.38, 6, 0, 1, 0, 7, 0, 2),
(203, 'first_class', 53, 87, 1363.2, 8180, 266, 4606, 158, 29.15, 51.77, 3.37, 8, 5, 7, 0, 22, 0, 0),
(203, 'list_a', 57, 55, 472.5, 2837, 26, 2522, 95, 26.54, 29.86, 5.33, 6, 4, 2, 0, 16, 0, 1),
(203, 'odi', 43, 42, 364.2, 2186, 15, 1971, 70, 28.15, 31.22, 5.4, 5, 4, 1, 0, 15, 0, 1),
(203, 't20', 45, 43, 151.5, 911, 1, 1354, 47, 28.8, 19.38, 8.91, 6, 1, 1, 0, 18, 0, 1),
(203, 'test', 20, 37, 576.2, 3458, 110, 1971, 50, 39.42, 69.16, 3.41, 5, 0, 0, 0, 11, 0, 0),
(204, 'first_class', 157, 26, 86.4, 520, 5, 354, 8, 44.25, 65, 4.08, 3, 0, 0, 0, 434, 21, 2),
(204, 'list_a', 181, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 192, 20, 8),
(204, 'odi', 97, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 108, 9, 3),
(204, 't20', 180, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 97, 13, 14),
(204, 't20i', 60, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 38, 4, 3),
(204, 'test', 36, 4, 5, 30, 1, 28, 0, 0, 0, 5.6, 0, 0, 0, 0, 74, 11, 1),
(205, 'first_class', 64, 99, 1708.2, 10250, 313, 5508, 173, 31.83, 59.24, 3.22, 13, 7, 8, 1, 32, 0, 4),
(205, 'list_a', 62, 58, 467.2, 2804, 24, 1893, 56, 33.8, 50.07, 4.05, 3, 0, 0, 0, 23, 0, 5),
(205, 'odi', 2, 2, 14, 84, 0, 61, 1, 61, 84, 4.35, 1, 0, 0, 0, 1, 0, 0),
(205, 't20', 73, 69, 221.4, 1330, 0, 1407, 44, 31.97, 30.22, 6.34, 4, 1, 0, 0, 34, 0, 1),
(205, 'test', 6, 12, 137.3, 825, 28, 465, 16, 29.06, 51.56, 3.38, 5, 1, 0, 0, 3, 0, 1),
(206, 'first_class', 9, 17, 452.1, 2713, 99, 1287, 69, 18.65, 39.31, 2.84, 12, 2, 8, 3, 0, 0, 0),
(206, 'list_a', 82, 78, 696.5, 4181, 29, 2909, 155, 18.76, 26.97, 4.17, 7, 5, 4, 0, 26, 0, 4),
(206, 'odi', 80, 76, 679, 4074, 28, 2821, 151, 18.68, 26.98, 4.15, 7, 5, 4, 0, 25, 0, 4),
(206, 't20', 314, 312, 1212.2, 7274, 11, 7665, 438, 17.5, 16.6, 6.32, 6, 9, 4, 0, 90, 0, 19),
(206, 't20i', 58, 58, 219.2, 1316, 1, 1357, 105, 12.92, 12.53, 6.18, 5, 4, 2, 0, 20, 0, 5),
(206, 'test', 5, 9, 255.4, 1534, 48, 760, 34, 22.35, 45.11, 2.97, 11, 1, 4, 2, 0, 0, 0),
(207, 'first_class', 20, 35, 603.4, 3622, 149, 1578, 56, 28.17, 64.67, 2.61, 6, 2, 3, 0, 8, 0, 0),
(207, 'list_a', 33, 33, 280.4, 1684, 12, 1269, 54, 23.5, 31.18, 4.52, 5, 2, 2, 0, 14, 0, 1),
(207, 't20', 39, 39, 138.5, 833, 6, 755, 45, 16.77, 18.51, 5.43, 4, 2, 0, 0, 6, 0, 1),
(208, 'first_class', 33, 2, 6, 36, 0, 31, 0, 0, 0, 5.16, 0, 0, 0, 0, 20, 0, 0),
(208, 'list_a', 59, 1, 1, 6, 0, 4, 0, 0, 0, 4, 0, 0, 0, 0, 26, 0, 4),
(208, 'odi', 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0),
(208, 't20', 85, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 35, 0, 2),
(208, 'test', 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 0),
(209, 'first_class', 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 16, 5, 0),
(209, 'list_a', 38, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 36, 7, 5),
(209, 'odi', 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 2, 2),
(209, 't20', 69, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 37, 5, 1),
(209, 't20i', 20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 1, 1),
(210, 'first_class', 1, 2, 13, 78, 1, 51, 2, 25.5, 39, 3.92, 2, 0, 0, 0, 1, 0, 0),
(210, 'list_a', 25, 25, 166.1, 997, 9, 866, 26, 33.3, 38.34, 5.21, 4, 1, 0, 0, 3, 0, 0),
(210, 't20', 24, 24, 79.1, 475, 0, 744, 23, 32.34, 20.65, 9.39, 3, 0, 0, 0, 4, 0, 1),
(210, 't20i', 5, 5, 16, 96, 0, 177, 3, 59, 32, 11.06, 1, 0, 0, 0, 0, 0, 0),
(211, 'list_a', 3, 1, 1, 6, 0, 4, 1, 4, 6, 4, 1, 0, 0, 0, 2, 0, 0),
(211, 't20', 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 1),
(212, 'first_class', 14, 26, 473.4, 2842, 86, 1452, 50, 29.04, 56.84, 3.06, 9, 5, 1, 0, 3, 0, 0),
(212, 'list_a', 14, 13, 119, 714, 12, 535, 23, 23.26, 31.04, 4.49, 5, 0, 1, 0, 3, 0, 2),
(212, 't20', 20, 20, 64, 384, 0, 502, 24, 20.91, 16, 7.84, 3, 0, 0, 0, 0, 0, 0),
(213, 'first_class', 3, 4, 39, 234, 6, 201, 1, 201, 234, 5.15, 1, 0, 0, 0, 1, 0, 0),
(213, 'list_a', 17, 17, 137, 822, 17, 743, 31, 23.96, 26.51, 5.42, 4, 1, 0, 0, 3, 0, 0),
(213, 't20', 24, 24, 80.5, 485, 1, 608, 45, 13.51, 10.77, 7.52, 5, 3, 2, 0, 6, 0, 0),
(214, 'first_class', 1, 2, 36, 216, 7, 108, 4, 27, 54, 3, 4, 0, 0, 0, 0, 0, 0),
(214, 'list_a', 8, 8, 71, 426, 6, 342, 16, 21.37, 26.62, 4.81, 4, 1, 0, 0, 2, 0, 0),
(214, 't20', 37, 37, 140.1, 841, 0, 1036, 35, 29.6, 24.02, 7.39, 3, 0, 0, 0, 14, 0, 0),
(215, 'list_a', 2, 1, 1, 6, 0, 14, 0, 0, 0, 14, 0, 0, 0, 0, 1, 0, 1),
(215, 't20', 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 6, 0, 1),
(216, 'first_class', 94, 34, 95.1, 571, 24, 244, 5, 48.8, 114.2, 2.56, 2, 0, 0, 0, 129, 0, 0),
(216, 'list_a', 173, 19, 70.2, 422, 1, 376, 8, 47, 52.75, 5.34, 3, 0, 0, 0, 97, 0, 13),
(216, 'odi', 29, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0),
(216, 't20', 280, 10, 28, 168, 0, 212, 10, 21.2, 16.8, 7.57, 4, 2, 0, 0, 142, 2, 31),
(216, 't20i', 39, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 2),
(217, 'first_class', 122, 213, 4913, 29478, 1067, 13320, 465, 28.64, 63.39, 2.71, 12, 27, 21, 6, 51, 0, 7),
(217, 'list_a', 119, 119, 1048.2, 6290, 55, 4525, 162, 27.93, 38.82, 4.31, 8, 4, 4, 0, 35, 0, 7),
(217, 't20', 140, 138, 489.3, 2937, 5, 3335, 114, 29.25, 25.76, 6.81, 3, 0, 0, 0, 26, 0, 8),
(217, 'test', 2, 4, 76.2, 458, 11, 273, 8, 34.12, 57.25, 3.57, 4, 0, 0, 0, 1, 0, 1),
(218, 'first_class', 61, 83, 830.4, 4984, 173, 2686, 66, 40.69, 75.51, 3.23, 7, 2, 0, 0, 22, 0, 3),
(218, 'list_a', 98, 82, 472.2, 2834, 7, 2669, 72, 37.06, 39.36, 5.65, 4, 2, 0, 0, 30, 0, 10),
(218, 'odi', 48, 44, 252, 1512, 2, 1538, 34, 45.23, 44.47, 6.1, 3, 0, 0, 0, 12, 0, 2),
(218, 't20', 192, 112, 262.1, 1573, 0, 2332, 82, 28.43, 19.18, 8.89, 4, 3, 0, 0, 47, 0, 4),
(218, 't20i', 41, 22, 53.2, 320, 0, 449, 11, 40.81, 29.09, 8.41, 2, 0, 0, 0, 16, 0, 0),
(219, 'first_class', 43, 62, 738.1, 4429, 212, 1948, 92, 21.17, 48.14, 2.63, 9, 3, 4, 0, 23, 0, 2),
(219, 'list_a', 59, 55, 371.4, 2230, 20, 1855, 69, 26.88, 32.31, 4.99, 4, 4, 0, 0, 19, 0, 3),
(219, 'odi', 3, 2, 9, 54, 0, 49, 1, 49, 54, 5.44, 1, 0, 0, 0, 0, 0, 0),
(219, 't20', 76, 34, 81.5, 491, 0, 651, 19, 34.26, 25.84, 7.95, 3, 0, 0, 0, 23, 0, 3),
(219, 't20i', 7, 1, 1, 6, 0, 10, 0, 0, 0, 10, 0, 0, 0, 0, 5, 0, 0),
(219, 'test', 11, 18, 161, 966, 58, 358, 20, 17.9, 48.3, 2.22, 7, 0, 1, 0, 5, 0, 2),
(220, 'first_class', 84, 1, 1, 6, 0, 9, 0, 0, 0, 9, 0, 0, 0, 0, 323, 16, 2),
(220, 'list_a', 170, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 212, 17, 3),
(220, 'odi', 129, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 174, 11, 2),
(220, 't20', 249, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 169, 43, 7),
(220, 't20i', 61, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 49, 15, 2),
(220, 'test', 54, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 221, 11, 1),
(221, 'first_class', 88, 153, 2245.4, 13474, 606, 5806, 223, 26.03, 60.42, 2.58, 11, 6, 11, 1, 82, 0, 4),
(221, 'list_a', 185, 177, 1394.1, 8365, 81, 7266, 236, 30.78, 35.44, 5.21, 5, 8, 2, 0, 79, 0, 8),
(221, 'odi', 127, 123, 977.1, 5863, 54, 5412, 146, 37.06, 40.15, 5.53, 5, 5, 2, 0, 60, 0, 5),
(221, 't20', 174, 169, 589.2, 3536, 11, 4650, 167, 27.84, 21.17, 7.89, 5, 4, 1, 0, 88, 0, 14),
(221, 't20i', 37, 34, 123.4, 742, 1, 1008, 39, 25.84, 19.02, 8.15, 5, 2, 1, 0, 19, 0, 3),
(221, 'test', 56, 98, 1584.3, 9507, 429, 3981, 142, 28.03, 66.95, 2.51, 11, 4, 8, 1, 59, 0, 4),
(222, 'first_class', 86, 9, 28, 168, 1, 83, 0, 0, 0, 2.96, 0, 0, 0, 0, 90, 0, 4),
(222, 'list_a', 94, 3, 3.3, 21, 0, 42, 1, 42, 21, 12, 1, 0, 0, 0, 61, 6, 5),
(222, 'odi', 42, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 23, 2, 3),
(222, 't20', 184, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 88, 8, 10),
(222, 't20i', 56, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20, 1, 3),
(222, 'test', 43, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50, 0, 3),
(223, 'first_class', 47, 83, 1638.2, 9830, 392, 4619, 182, 25.37, 54.01, 2.81, 14, 6, 13, 2, 14, 0, 1),
(223, 'list_a', 49, 48, 432.2, 2594, 15, 2080, 73, 28.49, 35.53, 4.81, 5, 4, 2, 0, 11, 0, 1),
(223, 'odi', 1, 1, 8, 48, 0, 49, 1, 49, 48, 6.12, 1, 0, 0, 0, 1, 0, 0),
(223, 't20', 70, 70, 221, 1326, 1, 1636, 52, 31.46, 25.5, 7.4, 4, 1, 0, 0, 22, 0, 4),
(224, 'first_class', 22, 3, 5, 30, 1, 23, 0, 0, 0, 4.6, 0, 0, 0, 0, 18, 0, 2),
(224, 'list_a', 100, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50, 0, 5),
(224, 'odi', 57, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 20, 0, 3),
(224, 't20', 196, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 59, 0, 11),
(224, 't20i', 50, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 14, 0, 3),
(225, 'first_class', 9, 17, 283.1, 1699, 68, 991, 27, 36.7, 62.92, 3.49, 6, 0, 0, 0, 1, 0, 1),
(225, 'list_a', 52, 52, 438.5, 2633, 12, 2426, 113, 21.46, 23.3, 5.52, 6, 4, 4, 0, 13, 0, 2),
(225, 'odi', 7, 7, 64.3, 387, 1, 392, 12, 32.66, 32.25, 6.07, 5, 0, 1, 0, 1, 0, 0),
(225, 't20', 185, 182, 664, 3984, 3, 5363, 253, 21.19, 15.74, 8.07, 5, 9, 2, 0, 60, 0, 7),
(225, 't20i', 32, 31, 113.5, 683, 1, 997, 47, 21.21, 14.53, 8.75, 4, 1, 0, 0, 10, 0, 0),
(226, 'first_class', 9, 12, 115.5, 695, 13, 369, 14, 26.35, 49.64, 3.18, 6, 1, 0, 0, 4, 0, 1),
(226, 'list_a', 77, 74, 575, 3450, 17, 2827, 89, 31.76, 38.76, 4.91, 6, 3, 2, 0, 24, 0, 2),
(226, 'odi', 5, 5, 38, 228, 1, 223, 2, 111.5, 114, 5.86, 1, 0, 0, 0, 1, 0, 0),
(226, 't20', 152, 146, 458.4, 2752, 2, 3341, 110, 30.37, 25.01, 7.28, 4, 2, 0, 0, 56, 0, 5),
(226, 't20i', 19, 19, 68.2, 410, 1, 554, 15, 36.93, 27.33, 8.1, 4, 1, 0, 0, 8, 0, 2),
(227, 'first_class', 46, 37, 279.5, 1679, 37, 819, 20, 40.95, 83.95, 2.92, 7, 0, 2, 0, 47, 0, 1),
(227, 'list_a', 78, 40, 218.2, 1310, 3, 973, 36, 27.02, 36.38, 4.45, 5, 0, 1, 0, 36, 0, 0),
(227, 'odi', 2, 1, 4, 24, 0, 24, 1, 24, 24, 6, 1, 0, 0, 0, 1, 0, 0),
(227, 't20', 156, 57, 124.1, 745, 0, 980, 18, 54.44, 41.38, 7.89, 3, 0, 0, 0, 66, 0, 9),
(227, 't20i', 3, 1, 3, 18, 0, 24, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0),
(228, 'first_class', 40, 4, 8, 48, 1, 27, 0, 0, 0, 3.37, 0, 0, 0, 0, 19, 0, 1),
(228, 'list_a', 57, 1, 1, 6, 0, 13, 1, 13, 6, 13, 1, 0, 0, 0, 19, 0, 8),
(228, 't20', 109, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 33, 0, 5),
(229, 'first_class', 42, 69, 886.5, 5321, 84, 3529, 97, 36.38, 54.85, 3.97, 9, 4, 3, 0, 14, 0, 1),
(229, 'list_a', 81, 75, 517, 3102, 19, 2775, 93, 29.83, 33.35, 5.36, 5, 1, 2, 0, 13, 0, 3),
(229, 'odi', 39, 38, 269.3, 1617, 12, 1449, 41, 35.34, 39.43, 5.37, 5, 0, 1, 0, 7, 0, 2),
(229, 't20', 98, 97, 341.3, 2049, 3, 2698, 98, 27.53, 20.9, 7.9, 4, 3, 0, 0, 21, 0, 2),
(229, 't20i', 47, 47, 166.3, 999, 0, 1328, 47, 28.25, 21.25, 7.97, 4, 1, 0, 0, 10, 0, 1),
(229, 'test', 12, 21, 337, 2022, 28, 1321, 32, 41.28, 63.18, 3.91, 9, 1, 1, 0, 5, 0, 0),
(230, 'first_class', 66, 115, 2074.2, 12446, 445, 6314, 227, 27.81, 54.82, 3.04, 10, 11, 8, 1, 12, 0, 5),
(230, 'list_a', 41, 40, 329.4, 1978, 35, 1550, 60, 25.83, 32.96, 4.7, 5, 1, 1, 0, 6, 0, 1),
(230, 't20', 87, 87, 291.5, 1751, 3, 2263, 105, 21.55, 16.67, 7.75, 5, 2, 3, 0, 12, 0, 4),
(231, 'first_class', 27, 47, 757.3, 4545, 171, 2342, 100, 23.42, 45.45, 3.09, 12, 6, 4, 1, 5, 0, 1),
(231, 'list_a', 22, 21, 157, 942, 14, 853, 17, 50.17, 55.41, 5.43, 3, 0, 0, 0, 7, 0, 0),
(231, 't20', 60, 60, 222.4, 1336, 3, 1742, 83, 20.98, 16.09, 7.82, 5, 2, 1, 0, 12, 0, 4),
(231, 't20i', 2, 2, 8, 48, 1, 65, 2, 32.5, 24, 8.12, 2, 0, 0, 0, 0, 0, 0),
(232, 'first_class', 1, 2, 25, 150, 5, 68, 2, 34, 75, 2.72, 2, 0, 0, 0, 0, 0, 0),
(232, 'list_a', 18, 18, 159.5, 959, 8, 832, 26, 32, 36.88, 5.2, 6, 1, 1, 0, 4, 0, 0),
(232, 't20', 32, 32, 111, 666, 2, 747, 43, 17.37, 15.48, 6.72, 4, 1, 0, 0, 7, 0, 1),
(233, 'list_a', 17, 17, 158.3, 951, 4, 870, 24, 36.25, 39.62, 5.48, 4, 1, 0, 0, 1, 0, 0),
(233, 't20', 57, 57, 218, 1308, 1, 1515, 62, 24.43, 21.09, 6.94, 4, 1, 0, 0, 20, 0, 5),
(233, 't20i', 4, 4, 16, 96, 0, 108, 4, 27, 24, 6.75, 2, 0, 0, 0, 2, 0, 0),
(234, 't20', 17, 1, 1, 6, 0, 6, 1, 6, 6, 6, 1, 0, 0, 0, 11, 0, 1),
(235, 'first_class', 3, 5, 79, 474, 12, 234, 6, 39, 79, 2.96, 3, 0, 0, 0, 1, 0, 0),
(235, 'list_a', 15, 3, 21, 126, 0, 99, 3, 33, 42, 4.71, 2, 0, 0, 0, 4, 0, 0),
(235, 't20', 11, 2, 8, 48, 0, 44, 2, 22, 24, 5.5, 2, 0, 0, 0, 0, 0, 0),
(236, 'list_a', 2, 2, 19.1, 115, 3, 118, 6, 19.66, 19.16, 6.15, 3, 0, 0, 0, 0, 0, 0);

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

--
-- Dumping data for table `tournament_category`
--

INSERT INTO `tournament_category` (`categoryId`, `categoryRadarId`, `categoryString`, `logTime`) VALUES
(1, 497, 'India', '2022-05-12 13:19:41');

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

--
-- Dumping data for table `tournament_competitor`
--

INSERT INTO `tournament_competitor` (`tournamentCompetitorId`, `tournamentId`, `competitorId`, `isPlayerArrived`) VALUES
(1, 1, 1, 0),
(2, 1, 2, 0),
(3, 1, 3, 0),
(4, 1, 4, 0),
(5, 1, 5, 0),
(6, 1, 6, 0),
(7, 1, 7, 0),
(8, 1, 8, 0),
(9, 1, 9, 0),
(10, 1, 10, 0);

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

--
-- Dumping data for table `tournament_competitor_player`
--

INSERT INTO `tournament_competitor_player` (`tournamentCompetitorPlayerId`, `tournamentCompetitorId`, `playerId`, `credit`) VALUES
(1, 1, 1, '0.0'),
(2, 1, 2, '0.0'),
(3, 1, 3, '0.0'),
(4, 1, 4, '0.0'),
(5, 1, 5, '0.0'),
(6, 1, 6, '0.0'),
(7, 1, 7, '0.0'),
(8, 1, 8, '0.0'),
(9, 1, 9, '0.0'),
(10, 1, 10, '0.0'),
(11, 1, 11, '0.0'),
(12, 1, 12, '0.0'),
(13, 1, 13, '0.0'),
(14, 1, 14, '0.0'),
(15, 1, 15, '0.0'),
(16, 1, 16, '0.0'),
(17, 1, 17, '0.0'),
(18, 1, 18, '0.0'),
(19, 1, 19, '0.0'),
(20, 1, 20, '0.0'),
(21, 1, 21, '0.0'),
(22, 1, 22, '0.0'),
(23, 1, 23, '0.0'),
(24, 2, 24, '0.0'),
(25, 2, 25, '0.0'),
(26, 2, 26, '0.0'),
(27, 2, 27, '0.0'),
(28, 2, 28, '0.0'),
(29, 2, 29, '0.0'),
(30, 2, 30, '0.0'),
(31, 2, 31, '0.0'),
(32, 2, 32, '0.0'),
(33, 2, 33, '0.0'),
(34, 2, 34, '0.0'),
(35, 2, 35, '0.0'),
(36, 2, 36, '0.0'),
(37, 2, 37, '0.0'),
(38, 2, 38, '0.0'),
(39, 2, 39, '0.0'),
(40, 2, 40, '0.0'),
(41, 2, 41, '0.0'),
(42, 2, 42, '0.0'),
(43, 2, 43, '0.0'),
(44, 2, 44, '0.0'),
(45, 2, 45, '0.0'),
(46, 2, 46, '0.0'),
(47, 2, 47, '0.0'),
(48, 2, 48, '0.0'),
(49, 3, 49, '0.0'),
(50, 3, 50, '0.0'),
(51, 3, 51, '0.0'),
(52, 3, 52, '0.0'),
(53, 3, 53, '0.0'),
(54, 3, 54, '0.0'),
(55, 3, 55, '0.0'),
(56, 3, 56, '0.0'),
(57, 3, 57, '0.0'),
(58, 3, 58, '0.0'),
(59, 3, 59, '0.0'),
(60, 3, 60, '0.0'),
(61, 3, 61, '0.0'),
(62, 3, 62, '0.0'),
(63, 3, 63, '0.0'),
(64, 3, 64, '0.0'),
(65, 3, 65, '0.0'),
(66, 3, 66, '0.0'),
(67, 3, 67, '0.0'),
(68, 3, 68, '0.0'),
(69, 3, 69, '0.0'),
(70, 3, 70, '0.0'),
(71, 3, 71, '0.0'),
(72, 3, 72, '0.0'),
(73, 3, 73, '0.0'),
(74, 4, 74, '0.0'),
(75, 4, 75, '0.0'),
(76, 4, 76, '0.0'),
(77, 4, 77, '0.0'),
(78, 4, 78, '0.0'),
(79, 4, 79, '0.0'),
(80, 4, 80, '0.0'),
(81, 4, 81, '0.0'),
(82, 4, 82, '0.0'),
(83, 4, 83, '0.0'),
(84, 4, 84, '0.0'),
(85, 4, 85, '0.0'),
(86, 4, 86, '0.0'),
(87, 4, 87, '0.0'),
(88, 4, 88, '0.0'),
(89, 4, 89, '0.0'),
(90, 4, 90, '0.0'),
(91, 4, 91, '0.0'),
(92, 4, 92, '0.0'),
(93, 4, 93, '0.0'),
(94, 4, 94, '0.0'),
(95, 4, 95, '0.0'),
(96, 4, 96, '0.0'),
(97, 4, 97, '0.0'),
(98, 4, 98, '0.0'),
(99, 5, 99, '0.0'),
(100, 5, 100, '0.0'),
(101, 5, 101, '0.0'),
(102, 5, 102, '0.0'),
(103, 5, 103, '0.0'),
(104, 5, 104, '0.0'),
(105, 5, 105, '0.0'),
(106, 5, 106, '0.0'),
(107, 5, 107, '0.0'),
(108, 5, 108, '0.0'),
(109, 5, 109, '0.0'),
(110, 5, 110, '0.0'),
(111, 5, 111, '0.0'),
(112, 5, 112, '0.0'),
(113, 5, 113, '0.0'),
(114, 5, 114, '0.0'),
(115, 5, 115, '0.0'),
(116, 5, 116, '0.0'),
(117, 5, 117, '0.0'),
(118, 5, 118, '0.0'),
(119, 5, 119, '0.0'),
(120, 5, 120, '0.0'),
(121, 5, 121, '0.0'),
(122, 5, 122, '0.0'),
(123, 6, 123, '0.0'),
(124, 6, 124, '0.0'),
(125, 6, 125, '0.0'),
(126, 6, 126, '0.0'),
(127, 6, 127, '0.0'),
(128, 6, 128, '0.0'),
(129, 6, 129, '0.0'),
(130, 6, 130, '0.0'),
(131, 6, 131, '0.0'),
(132, 6, 132, '0.0'),
(133, 6, 133, '0.0'),
(134, 6, 134, '0.0'),
(135, 6, 135, '0.0'),
(136, 6, 136, '0.0'),
(137, 6, 137, '0.0'),
(138, 6, 138, '0.0'),
(139, 6, 139, '0.0'),
(140, 6, 140, '0.0'),
(141, 6, 141, '0.0'),
(142, 6, 142, '0.0'),
(143, 6, 143, '0.0'),
(144, 6, 144, '0.0'),
(145, 6, 145, '0.0'),
(146, 6, 146, '0.0'),
(147, 7, 147, '0.0'),
(148, 7, 148, '0.0'),
(149, 7, 149, '0.0'),
(150, 7, 150, '0.0'),
(151, 7, 151, '0.0'),
(152, 7, 152, '0.0'),
(153, 7, 153, '0.0'),
(154, 7, 154, '0.0'),
(155, 7, 155, '0.0'),
(156, 7, 156, '0.0'),
(157, 7, 157, '0.0'),
(158, 7, 158, '0.0'),
(159, 7, 159, '0.0'),
(160, 7, 160, '0.0'),
(161, 7, 161, '0.0'),
(162, 7, 162, '0.0'),
(163, 7, 163, '0.0'),
(164, 7, 164, '0.0'),
(165, 7, 165, '0.0'),
(166, 7, 166, '0.0'),
(167, 7, 167, '0.0'),
(168, 7, 168, '0.0'),
(169, 8, 169, '0.0'),
(170, 8, 170, '0.0'),
(171, 8, 171, '0.0'),
(172, 8, 172, '0.0'),
(173, 8, 173, '0.0'),
(174, 8, 174, '0.0'),
(175, 8, 175, '0.0'),
(176, 8, 176, '0.0'),
(177, 8, 177, '0.0'),
(178, 8, 178, '0.0'),
(179, 8, 179, '0.0'),
(180, 8, 180, '0.0'),
(181, 8, 181, '0.0'),
(182, 8, 182, '0.0'),
(183, 8, 183, '0.0'),
(184, 8, 184, '0.0'),
(185, 8, 185, '0.0'),
(186, 8, 186, '0.0'),
(187, 8, 187, '0.0'),
(188, 8, 188, '0.0'),
(189, 8, 189, '0.0'),
(190, 8, 190, '0.0'),
(191, 8, 191, '0.0'),
(192, 8, 192, '0.0'),
(193, 9, 193, '0.0'),
(194, 9, 194, '0.0'),
(195, 9, 195, '0.0'),
(196, 9, 196, '0.0'),
(197, 9, 197, '0.0'),
(198, 9, 198, '0.0'),
(199, 9, 199, '0.0'),
(200, 9, 200, '0.0'),
(201, 9, 201, '0.0'),
(202, 9, 202, '0.0'),
(203, 9, 203, '0.0'),
(204, 9, 204, '0.0'),
(205, 9, 205, '0.0'),
(206, 9, 206, '0.0'),
(207, 9, 207, '0.0'),
(208, 9, 208, '0.0'),
(209, 9, 209, '0.0'),
(210, 9, 210, '0.0'),
(211, 9, 211, '0.0'),
(212, 9, 212, '0.0'),
(213, 9, 213, '0.0'),
(214, 9, 214, '0.0'),
(215, 9, 215, '0.0'),
(216, 10, 216, '0.0'),
(217, 10, 217, '0.0'),
(218, 10, 218, '0.0'),
(219, 10, 219, '0.0'),
(220, 10, 220, '0.0'),
(221, 10, 221, '0.0'),
(222, 10, 222, '0.0'),
(223, 10, 223, '0.0'),
(224, 10, 224, '0.0'),
(225, 10, 225, '0.0'),
(226, 10, 226, '0.0'),
(227, 10, 227, '0.0'),
(228, 10, 228, '0.0'),
(229, 10, 229, '0.0'),
(230, 10, 230, '0.0'),
(231, 10, 231, '0.0'),
(232, 10, 232, '0.0'),
(233, 10, 233, '0.0'),
(234, 10, 234, '0.0'),
(235, 10, 235, '0.0'),
(236, 10, 236, '0.0');

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

--
-- Dumping data for table `tournament_information`
--

INSERT INTO `tournament_information` (`tournamentId`, `tournamentRadarId`, `currentSeasonRadarId`, `tournamentName`, `currentSeasonName`, `seasonStartDate`, `seasonEndDate`, `tournamentMatchType`, `tournamentCategory`, `tournamentPlayersGender`, `tournamentCountry`, `tournamentCountryCode`, `isCompetitorsArrived`, `isMatchesArrived`, `logTime`) VALUES
(1, 2472, 91319, 'Indian Premier League', 'Indian Premier League 2022', '2022-03-26', '2022-05-29', 1, 1, 'men', 'India', 'IND', 1, 1, '2022-05-12 14:18:02');

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
-- Dumping data for table `tournament_matches`
--

INSERT INTO `tournament_matches` (`matchId`, `matchRadarId`, `matchTournamentId`, `matchStartTime`, `isPointsCalculated`, `competitor1`, `competitor2`, `tossWonBy`, `tossDecision`, `venueId`, `matchStatus`, `isLineUpOut`, `logTime`) VALUES
(1, 32483483, 1, '1648303200000', 0, 6, 3, NULL, NULL, 5, 1, 0, '2022-05-12 14:20:26'),
(2, 32483485, 1, '1648375200000', 0, 8, 2, NULL, NULL, 6, 1, 0, '2022-05-12 14:20:26'),
(3, 32483487, 1, '1648389600000', 0, 4, 7, NULL, NULL, 7, 1, 0, '2022-05-12 14:20:26'),
(4, 32483489, 1, '1648476000000', 0, 9, 10, NULL, NULL, 5, 1, 0, '2022-05-12 14:20:26'),
(5, 32483491, 1, '1648562400000', 0, 1, 5, NULL, NULL, 8, 1, 0, '2022-05-12 14:20:26'),
(6, 32483493, 1, '1648648800000', 0, 7, 3, NULL, NULL, 7, 1, 0, '2022-05-12 14:20:26'),
(7, 32483495, 1, '1648735200000', 0, 10, 6, NULL, NULL, 6, 1, 0, '2022-05-12 14:20:26'),
(8, 32483497, 1, '1648821600000', 0, 3, 4, NULL, NULL, 5, 1, 0, '2022-05-12 14:20:26'),
(9, 32483499, 1, '1648893600000', 0, 2, 5, NULL, NULL, 7, 1, 0, '2022-05-12 14:20:27'),
(10, 32483501, 1, '1648908000000', 0, 9, 8, NULL, NULL, 8, 1, 0, '2022-05-12 14:20:27'),
(11, 32483503, 1, '1648994400000', 0, 6, 4, NULL, NULL, 6, 1, 0, '2022-05-12 14:20:27'),
(12, 32483505, 1, '1649080800000', 0, 1, 10, NULL, NULL, 7, 1, 0, '2022-05-12 14:20:27'),
(13, 32483507, 1, '1649167200000', 0, 5, 7, NULL, NULL, 5, 1, 0, '2022-05-12 14:20:27'),
(14, 32483509, 1, '1649253600000', 0, 3, 2, NULL, NULL, 8, 1, 0, '2022-05-12 14:20:27'),
(15, 32483511, 1, '1649340000000', 0, 10, 8, NULL, NULL, 7, 1, 0, '2022-05-12 14:20:27'),
(16, 32483513, 1, '1649426400000', 0, 4, 9, NULL, NULL, 6, 1, 0, '2022-05-12 14:20:27'),
(17, 32483515, 1, '1649498400000', 0, 6, 1, NULL, NULL, 7, 1, 0, '2022-05-12 14:20:27'),
(18, 32483517, 1, '1649512800000', 0, 7, 2, NULL, NULL, 8, 1, 0, '2022-05-12 14:20:27'),
(19, 32483519, 1, '1649584800000', 0, 3, 8, NULL, NULL, 6, 1, 0, '2022-05-12 14:20:27'),
(20, 32483521, 1, '1649599200000', 0, 5, 10, NULL, NULL, 5, 1, 0, '2022-05-12 14:20:27'),
(21, 32483523, 1, '1649685600000', 0, 1, 9, NULL, NULL, 7, 1, 0, '2022-05-12 14:20:28'),
(22, 32483525, 1, '1649772000000', 0, 6, 7, NULL, NULL, 7, 1, 0, '2022-05-12 14:20:28'),
(23, 32483527, 1, '1649858400000', 0, 2, 4, NULL, NULL, 8, 1, 0, '2022-05-12 14:20:28'),
(24, 32483529, 1, '1649944800000', 0, 5, 9, NULL, NULL, 7, 1, 0, '2022-05-12 14:20:28'),
(25, 32483531, 1, '1650031200000', 0, 1, 3, NULL, NULL, 6, 1, 0, '2022-05-12 14:20:28'),
(26, 32483533, 1, '1650103200000', 0, 2, 10, NULL, NULL, 6, 1, 0, '2022-05-12 14:20:28'),
(27, 32483535, 1, '1650117600000', 0, 8, 7, NULL, NULL, 5, 1, 0, '2022-05-12 14:20:28'),
(28, 32483537, 1, '1650189600000', 0, 4, 1, NULL, NULL, 7, 1, 0, '2022-05-12 14:20:28'),
(29, 32483539, 1, '1650204000000', 0, 9, 6, NULL, NULL, 8, 1, 0, '2022-05-12 14:20:28'),
(30, 32483541, 1, '1650290400000', 0, 5, 3, NULL, NULL, 6, 1, 0, '2022-05-12 14:20:28'),
(31, 32483543, 1, '1650376800000', 0, 10, 7, NULL, NULL, 7, 1, 0, '2022-05-12 14:20:28'),
(32, 32483545, 1, '1650463200000', 0, 8, 4, NULL, NULL, 6, 1, 0, '2022-05-12 14:20:28'),
(33, 32483547, 1, '1650549600000', 0, 2, 6, NULL, NULL, 7, 1, 0, '2022-05-12 14:20:29'),
(34, 32483549, 1, '1650636000000', 0, 8, 5, NULL, NULL, 5, 1, 0, '2022-05-12 14:20:29'),
(35, 32483551, 1, '1650708000000', 0, 3, 9, NULL, NULL, 7, 1, 0, '2022-05-12 14:20:29'),
(36, 32483553, 1, '1650722400000', 0, 7, 1, NULL, NULL, 6, 1, 0, '2022-05-12 14:20:29'),
(37, 32483555, 1, '1650808800000', 0, 10, 2, NULL, NULL, 5, 1, 0, '2022-05-12 14:20:29'),
(38, 32483557, 1, '1650895200000', 0, 4, 6, NULL, NULL, 5, 1, 0, '2022-05-12 14:20:29'),
(39, 32483559, 1, '1650981600000', 0, 7, 5, NULL, NULL, 8, 1, 0, '2022-05-12 14:20:29'),
(40, 32483561, 1, '1651068000000', 0, 9, 1, NULL, NULL, 5, 1, 0, '2022-05-12 14:20:29'),
(41, 32483563, 1, '1651154400000', 0, 8, 3, NULL, NULL, 5, 1, 0, '2022-05-12 14:20:29'),
(42, 32483565, 1, '1651240800000', 0, 4, 10, NULL, NULL, 8, 1, 0, '2022-05-12 14:20:29'),
(43, 32483567, 1, '1651312800000', 0, 9, 7, NULL, NULL, 6, 1, 0, '2022-05-12 14:20:29'),
(44, 32483569, 1, '1651327200000', 0, 5, 2, NULL, NULL, 7, 1, 0, '2022-05-12 14:20:29'),
(45, 32483571, 1, '1651399200000', 0, 8, 10, NULL, NULL, 5, 1, 0, '2022-05-12 14:20:30'),
(46, 32483573, 1, '1651413600000', 0, 1, 6, NULL, NULL, 8, 1, 0, '2022-05-12 14:20:30'),
(47, 32483575, 1, '1651500000000', 0, 3, 5, NULL, NULL, 5, 1, 0, '2022-05-12 14:20:30'),
(48, 32483577, 1, '1651586400000', 0, 9, 4, NULL, NULL, 7, 1, 0, '2022-05-12 14:20:30'),
(49, 32483579, 1, '1651672800000', 0, 7, 6, NULL, NULL, 8, 1, 0, '2022-05-12 14:20:30'),
(50, 32483581, 1, '1651759200000', 0, 8, 1, NULL, NULL, 6, 1, 0, '2022-05-12 14:20:30'),
(51, 32483583, 1, '1651845600000', 0, 9, 2, NULL, NULL, 6, 1, 0, '2022-05-12 14:20:30'),
(52, 32483585, 1, '1651917600000', 0, 4, 5, NULL, NULL, 5, 1, 0, '2022-05-12 14:20:30'),
(53, 32483587, 1, '1651932000000', 0, 10, 3, NULL, NULL, 8, 1, 0, '2022-05-12 14:20:30'),
(54, 32483589, 1, '1652004000000', 0, 1, 7, NULL, NULL, 5, 1, 0, '2022-05-12 14:20:30'),
(55, 32483591, 1, '1652018400000', 0, 6, 8, NULL, NULL, 7, 1, 0, '2022-05-12 14:20:30'),
(56, 32483593, 1, '1652104800000', 0, 2, 3, NULL, NULL, 7, 1, 0, '2022-05-12 14:20:30'),
(57, 32483595, 1, '1652191200000', 0, 10, 9, NULL, NULL, 8, 1, 0, '2022-05-12 14:20:31'),
(58, 32483597, 1, '1652277600000', 0, 5, 8, NULL, NULL, 7, 1, 0, '2022-05-12 14:20:31'),
(59, 32483599, 1, '1652364000000', 0, 6, 2, NULL, NULL, 5, 3, 0, '2022-05-12 14:20:31'),
(60, 32483601, 1, '1652450400000', 0, 7, 4, NULL, NULL, 6, 2, 0, '2022-05-12 14:20:31'),
(61, 32483603, 1, '1652536800000', 0, 3, 1, NULL, NULL, 8, 2, 0, '2022-05-12 14:20:31'),
(62, 32483605, 1, '1652608800000', 0, 6, 9, NULL, NULL, 5, 2, 0, '2022-05-12 14:20:31'),
(63, 32483607, 1, '1652623200000', 0, 10, 5, NULL, NULL, 6, 2, 0, '2022-05-12 14:20:31'),
(64, 32483609, 1, '1652709600000', 0, 4, 8, NULL, NULL, 7, 2, 0, '2022-05-12 14:20:31'),
(65, 32483611, 1, '1652796000000', 0, 2, 1, NULL, NULL, 5, 2, 0, '2022-05-12 14:20:32'),
(66, 32483613, 1, '1652882400000', 0, 3, 10, NULL, NULL, 7, 2, 0, '2022-05-12 14:20:32'),
(67, 32483615, 1, '1652968800000', 0, 7, 9, NULL, NULL, 5, 2, 0, '2022-05-12 14:20:32'),
(68, 32483617, 1, '1653055200000', 0, 5, 6, NULL, NULL, 6, 2, 0, '2022-05-12 14:20:32'),
(69, 32483619, 1, '1653141600000', 0, 2, 8, NULL, NULL, 5, 2, 0, '2022-05-12 14:20:32'),
(70, 32483621, 1, '1653228000000', 0, 1, 4, NULL, NULL, 5, 2, 0, '2022-05-12 14:20:32');

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

--
-- Dumping data for table `tournament_type`
--

INSERT INTO `tournament_type` (`tournamentTypeId`, `tournamnetTypeString`, `logTime`) VALUES
(1, 't20', '2022-05-12 13:19:41');

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
,`coins` int(11)
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
  `registerTime` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`userId`, `userType`, `phoneNumber`, `email`, `coins`, `dateOfBirth`, `gender`, `displayPicture`, `firstName`, `lastName`, `address`, `city`, `pinCode`, `state`, `country`, `imageStamp`, `isVerified`, `registerTime`) VALUES
(1, 1, '9712491369', 'dhruvmaradiya0@gmail.com', 380, '2004/10/18', 'male', NULL, 'Dhruv', 'Maradiya', NULL, '', NULL, '', '', NULL, 0, '2022-05-03 04:59:14'),
(2, 1, '9662066991', '', 490, '', '', '', '', '', '', '', NULL, '', '', NULL, 0, '2022-05-03 07:26:06');

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
,`userTeamPoints` float
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

--
-- Dumping data for table `user_type`
--

INSERT INTO `user_type` (`userType`, `userTypeString`) VALUES
(2, 'EXPERT'),
(1, 'GENERAL');

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
-- Dumping data for table `venues`
--

INSERT INTO `venues` (`venueId`, `venueName`, `venueCapacity`, `venueCity`, `venueRadarId`, `venueCountry`, `venueCountryCode`, `venueMapCardinalities`, `venueEnd1`, `venueEnd2`, `logTime`) VALUES
(5, 'Wankhede Stadium', 45000, 'Mumbai', 19683, 'India', 'IND', '18.938917,72.825722', 'Garware Pavilion End', 'Tata End', '2022-05-12 13:22:14'),
(6, 'Brabourne Stadium', 25000, 'Mumbai', 24948, 'India', 'IND', '18.932222,72.824722', 'Pavilion End', 'Church Gate End', '2022-05-12 13:22:14'),
(7, 'Dr Dy Patil Sports Academy', 60000, 'Mumbai', 16754, 'India', 'IND', '19.041944,73.026667', 'Media End', 'Pavilion End', '2022-05-12 13:22:14'),
(8, 'Maharashtra Cricket Association Stadium', 55000, 'Pune', 19689, 'India', 'IND', '18.674444,73.706389', 'Pavilion End', 'Hill End', '2022-05-12 13:22:14');

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

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `allteams`  AS SELECT `competitors`.`competitorId` AS `teamId`, `competitors`.`competitorRadarId` AS `teamRadarId`, `competitors`.`competitorName` AS `name`, `competitors`.`competitorCountry` AS `countryName`, `competitors`.`competitorCountryCode` AS `countryCode`, `competitors`.`competitorDisplayName` AS `displayName` FROM `competitors`  ;

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

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `allviews`  AS SELECT `user_team_views`.`userTeamId` AS `userTeamId`, `user_team_views`.`userId` AS `userId`, `user_team_views`.`viewCount` AS `viewCount` FROM `user_team_views`  ;

-- --------------------------------------------------------

--
-- Structure for view `fulldiscussion`
--
DROP TABLE IF EXISTS `fulldiscussion`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `fulldiscussion`  AS SELECT `discussion`.`discussionId` AS `discussionId`, `discussion`.`matchId` AS `matchId`, `discussion`.`userId` AS `userId`, `discussion`.`messengerId` AS `messengerId`, `discussion`.`message` AS `message`, `discussion`.`messageTime` AS `messageTime` FROM `discussion`  ;

-- --------------------------------------------------------

--
-- Structure for view `fulllikesdetails`
--
DROP TABLE IF EXISTS `fulllikesdetails`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `fulllikesdetails`  AS SELECT `user_team_likes`.`userTeamId` AS `userTeamId`, `user_team_likes`.`userId` AS `userId` FROM `user_team_likes`  ;

-- --------------------------------------------------------

--
-- Structure for view `fullmatchdetails`
--
DROP TABLE IF EXISTS `fullmatchdetails`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `fullmatchdetails`  AS SELECT `tournament_matches`.`matchId` AS `matchId`, `tournament_matches`.`matchRadarId` AS `matchRadarId`, `tournament_matches`.`matchTournamentId` AS `matchTournamentId`, `tournament_matches`.`matchStartTime` AS `matchStartDateTime`, `tournament_matches`.`competitor1` AS `team1Id`, `tournament_matches`.`isPointsCalculated` AS `isPointsCalculated`, `tournament_matches`.`competitor2` AS `team2Id`, `tournament_matches`.`tossWonBy` AS `tossWonBy`, `tournament_matches`.`tossDecision` AS `tossDecision`, `tournament_matches`.`venueId` AS `venueId`, `venues`.`venueName` AS `venue`, `fullseriesdetails`.`tournamentMatchType` AS `matchTypeId`, `fullseriesdetails`.`tournamentTypeString` AS `matchTyprString`, `venues`.`venueCity` AS `venueCity`, `venues`.`venueCapacity` AS `venueCapacity`, `venues`.`venueCountry` AS `venuesCountry`, `venues`.`venueEnd1` AS `end2`, `venues`.`venueEnd2` AS `end1`, `tournament_matches`.`matchStatus` AS `matchStatus`, `match_status`.`statusString` AS `matchStatusString`, `fullseriesdetails`.`tournamentName` AS `seriesName`, `fullseriesdetails`.`currentSeasonName` AS `seriesDname`, `tournament_matches`.`isLineUpOut` AS `isLineUpOut`, `comp1`.`competitorName` AS `team1Name`, `comp1`.`competitorRadarId` AS `team1RadarId`, `comp1`.`competitorCountry` AS `team1Country`, `comp1`.`competitorCountryCode` AS `team1CountryCode`, `comp1`.`competitorDisplayName` AS `team1DisplayName`, `comp2`.`competitorName` AS `team2Name`, `comp2`.`competitorRadarId` AS `team2RadarId`, `comp2`.`competitorCountry` AS `team2Country`, `comp2`.`competitorCountryCode` AS `team2CountryName`, `comp2`.`competitorDisplayName` AS `team2DisplayName`, concat(`comp1`.`competitorDisplayName`,' vs ',`comp2`.`competitorDisplayName`) AS `displayName` FROM (((((`tournament_matches` join `competitors` `comp1` on(`tournament_matches`.`competitor1` = `comp1`.`competitorId`)) join `competitors` `comp2` on(`tournament_matches`.`competitor2` = `comp2`.`competitorId`)) join `fullseriesdetails` on(`fullseriesdetails`.`tournamentId` = `tournament_matches`.`matchTournamentId`)) join `match_status` on(`tournament_matches`.`matchStatus` = `match_status`.`statusId`)) join `venues` on(`tournament_matches`.`venueId` = `venues`.`venueId`))  ;

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

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `fullplayerdetails`  AS SELECT `tournament_matches`.`matchId` AS `matchId`, `tournament_matches`.`matchRadarId` AS `matchRadarId`, `match_players`.`playerId` AS `playerId`, `match_players`.`competitorId` AS `teamId`, `match_players`.`credit` AS `credits`, `match_players`.`isSelected` AS `isSelected`, `match_players`.`points` AS `points`, concat(`allplayers`.`playerFirstName`,' ',`allplayers`.`playerLastName`) AS `name`, concat(`allplayers`.`playerFirstName`,' ',`allplayers`.`playerLastName`) AS `displayName`, `allplayers`.`playerRole` AS `roleId`, ucase(`allplayers`.`roleName`) AS `roleName` FROM ((`tournament_matches` join `match_players` on(`match_players`.`matchId` = `tournament_matches`.`matchId`)) join `allplayers` on(`allplayers`.`playerId` = `match_players`.`playerId`))  ;

-- --------------------------------------------------------

--
-- Structure for view `fullseriesdetails`
--
DROP TABLE IF EXISTS `fullseriesdetails`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `fullseriesdetails`  AS SELECT `tournament_information`.`tournamentId` AS `tournamentId`, `tournament_information`.`tournamentRadarId` AS `tournamentRadarId`, `tournament_information`.`currentSeasonRadarId` AS `currentSeasonRadarId`, `tournament_information`.`tournamentName` AS `tournamentName`, `tournament_information`.`currentSeasonName` AS `currentSeasonName`, `tournament_information`.`seasonStartDate` AS `seasonStartDate`, `tournament_information`.`seasonEndDate` AS `seasonEndDate`, `tournament_information`.`tournamentMatchType` AS `tournamentMatchType`, `tournament_information`.`tournamentCategory` AS `tournamentCategory`, `tournament_information`.`tournamentPlayersGender` AS `tournamentPlayersGender`, `tournament_information`.`tournamentCountry` AS `tournamentCountry`, `tournament_information`.`tournamentCountryCode` AS `tournamentCountryCode`, `tournament_information`.`isCompetitorsArrived` AS `isCompetitorsArrived`, `tournament_information`.`isMatchesArrived` AS `isMatchesArrived`, `tournament_category`.`categoryString` AS `categoryString`, `tournament_type`.`tournamnetTypeString` AS `tournamentTypeString` FROM ((`tournament_information` join `tournament_type` on(`tournament_type`.`tournamentTypeId` = `tournament_information`.`tournamentMatchType`)) join `tournament_category` on(`tournament_category`.`categoryId` = `tournament_information`.`tournamentCategory`))  ;

-- --------------------------------------------------------

--
-- Structure for view `inningBatsmans`
--
DROP TABLE IF EXISTS `inningBatsmans`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `inningBatsmans`  AS SELECT `inning_batsmans`.`scorcardInningId` AS `scorcardInningId`, `inning_batsmans`.`playerId` AS `playerId`, `inning_batsmans`.`battingOrder` AS `battingOrder`, `inning_batsmans`.`runs` AS `runs`, `inning_batsmans`.`strikeRate` AS `strikeRate`, `inning_batsmans`.`isNotOut` AS `isNotOut`, `inning_batsmans`.`isDuck` AS `isDuck`, `inning_batsmans`.`isRetiredHurt` AS `isRetiredHurt`, `inning_batsmans`.`ballFaced` AS `ballFaced`, `inning_batsmans`.`fours` AS `fours`, `inning_batsmans`.`sixes` AS `sixes`, `inning_batsmans`.`attackIngShot` AS `attackIngShot`, `inning_batsmans`.`semiAttackingShot` AS `semiAttackingShot`, `inning_batsmans`.`defendingShot` AS `defendingShot`, `inning_batsmans`.`leaves` AS `leaves`, `inning_batsmans`.`onSideShot` AS `onSideShot`, `inning_batsmans`.`offSideShot` AS `offSideShot`, `inning_batsmans`.`squreLegShot` AS `squreLegShot`, `inning_batsmans`.`fineLegShot` AS `fineLegShot`, `inning_batsmans`.`thirdManShot` AS `thirdManShot`, `inning_batsmans`.`coverShot` AS `coverShot`, `inning_batsmans`.`pointsShot` AS `pointsShot`, `inning_batsmans`.`midOnShot` AS `midOnShot`, `inning_batsmans`.`midOffShot` AS `midOffShot`, `inning_batsmans`.`midWicketShot` AS `midWicketShot`, `inning_batsmans`.`dismissalOverBallNumber` AS `dismissalOverBallNumber`, `inning_batsmans`.`dismissalOverNumber` AS `dismissalOverNumber`, `inning_batsmans`.`dismissalBallerId` AS `dismissalBallerId`, `inning_batsmans`.`dismissalDiliveryType` AS `dismissalDiliveryType`, `inning_batsmans`.`dismissalFieldeManId` AS `dismissalFieldeManId`, `inning_batsmans`.`dismissalIsOnStrike` AS `dismissalIsOnStrike`, `inning_batsmans`.`dismissalShotType` AS `dismissalShotType`, `inning_batsmans`.`dismissalType` AS `dismissalType` FROM `inning_batsmans`  ;

-- --------------------------------------------------------

--
-- Structure for view `inningBatting`
--
DROP TABLE IF EXISTS `inningBatting`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `inningBatting`  AS SELECT `inning_batting`.`scorcardInningId` AS `scorcardInningId`, `inning_batting`.`runs` AS `runs`, `inning_batting`.`fours` AS `fours`, `inning_batting`.`sixes` AS `sixes`, `inning_batting`.`runRate` AS `runRate`, `inning_batting`.`ballFaced` AS `ballFaced` FROM `inning_batting`  ;

-- --------------------------------------------------------

--
-- Structure for view `inningBowlers`
--
DROP TABLE IF EXISTS `inningBowlers`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `inningBowlers`  AS SELECT `inning_bowlers`.`scorcardInningId` AS `scorcardInningId`, `inning_bowlers`.`playerId` AS `playerId`, `inning_bowlers`.`runsConceded` AS `runsConceded`, `inning_bowlers`.`wickets` AS `wickets`, `inning_bowlers`.`overBowled` AS `overBowled`, `inning_bowlers`.`maidensOvers` AS `maidensOvers`, `inning_bowlers`.`dotBalls` AS `dotBalls`, `inning_bowlers`.`fourConceded` AS `fourConceded`, `inning_bowlers`.`sixConceded` AS `sixConceded`, `inning_bowlers`.`noBalls` AS `noBalls`, `inning_bowlers`.`wides` AS `wides`, `inning_bowlers`.`slowerDeliveries` AS `slowerDeliveries`, `inning_bowlers`.`yorkers` AS `yorkers`, `inning_bowlers`.`economyRate` AS `economyRate`, `inning_bowlers`.`fastestBall` AS `fastestBall`, `inning_bowlers`.`slowestBall` AS `slowestBall`, `inning_bowlers`.`averageSpeed` AS `averageSpeed`, `inning_bowlers`.`overTheWicketBalls` AS `overTheWicketBalls`, `inning_bowlers`.`aroundTheWicketBalls` AS `aroundTheWicketBalls`, `inning_bowlers`.`bouncers` AS `bouncers`, `inning_bowlers`.`beatBats` AS `beatBats`, `inning_bowlers`.`edge` AS `edge` FROM `inning_bowlers`  ;

-- --------------------------------------------------------

--
-- Structure for view `inningBowling`
--
DROP TABLE IF EXISTS `inningBowling`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `inningBowling`  AS SELECT `inning_bowling`.`scorcardInningId` AS `scorcardInningId`, `inning_bowling`.`overs` AS `overs`, `inning_bowling`.`wickets` AS `wickets`, `inning_bowling`.`maidens` AS `maidens`, `inning_bowling`.`extras` AS `extras`, `inning_bowling`.`noBalls` AS `noBalls`, `inning_bowling`.`byes` AS `byes`, `inning_bowling`.`legByes` AS `legByes`, `inning_bowling`.`dotBalls` AS `dotBalls` FROM `inning_bowling`  ;

-- --------------------------------------------------------

--
-- Structure for view `scorcardDetails`
--
DROP TABLE IF EXISTS `scorcardDetails`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `scorcardDetails`  AS SELECT `scorcard_details`.`scorcardId` AS `scorcardId`, `scorcard_details`.`matchId` AS `matchId`, `scorcard_details`.`tossWonBy` AS `tossWonBy`, `scorcard_details`.`tossDecision` AS `tossDecision`, `scorcard_details`.`winnerId` AS `winnerId`, `scorcard_details`.`manOfMatch` AS `manOfMatch`, `scorcard_details`.`isPointsCalculated` AS `isPointsCalculated`, `scorcard_details`.`matchResultString` AS `matchResultString` FROM `scorcard_details`  ;

-- --------------------------------------------------------

--
-- Structure for view `scorcardInning`
--
DROP TABLE IF EXISTS `scorcardInning`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `scorcardInning`  AS SELECT `scorcard_innings`.`scorcardInningId` AS `scorcardInningId`, `scorcard_innings`.`scorcardId` AS `scorcardId`, `scorcard_innings`.`inningNumber` AS `inningNumber`, `scorcard_innings`.`battingTeam` AS `battingTeam`, `scorcard_innings`.`bowlingTeam` AS `bowlingTeam`, `scorcard_innings`.`runs` AS `runs`, `scorcard_innings`.`wickets` AS `wickets`, `scorcard_innings`.`oversPlayed` AS `oversPlayed` FROM `scorcard_innings`  ;

-- --------------------------------------------------------

--
-- Structure for view `userdetails`
--
DROP TABLE IF EXISTS `userdetails`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `userdetails`  AS SELECT `users`.`userId` AS `userId`, `users`.`userType` AS `userType`, `user_type`.`userTypeString` AS `userTypeString`, `users`.`phoneNumber` AS `phoneNumber`, `users`.`email` AS `email`, `users`.`dateOfBirth` AS `dateOfBirth`, `users`.`gender` AS `gender`, `users`.`firstName` AS `firstName`, `users`.`lastName` AS `lastName`, `users`.`address` AS `address`, `users`.`city` AS `city`, `users`.`pinCode` AS `pinCode`, `users`.`state` AS `state`, `users`.`coins` AS `coins`, `users`.`country` AS `country`, `users`.`isVerified` AS `isVerified`, `users`.`imageStamp` AS `imageStamp`, `users`.`registerTime` AS `registerTime` FROM (`users` join `user_type` on(`user_type`.`userType` = `users`.`userType`))  ;

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

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `userTeamPlayersDetails`  AS SELECT `user_team_data_new`.`userTeamId` AS `userTeamId`, `user_team_data_new`.`playerId` AS `playerId`, `user_team_data_new`.`isCaptain` AS `isCaptain`, `user_team_data_new`.`isViceCaptain` AS `isViceCaptain` FROM `user_team_data_new`  ;

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
  ADD UNIQUE KEY `userTeamId` (`userTeamId`,`playerId`);

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
  MODIFY `sourceId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `competitors`
--
ALTER TABLE `competitors`
  MODIFY `competitorId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `discussion`
--
ALTER TABLE `discussion`
  MODIFY `discussionId` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `match_status`
--
ALTER TABLE `match_status`
  MODIFY `statusId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `players`
--
ALTER TABLE `players`
  MODIFY `playerId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=237;

--
-- AUTO_INCREMENT for table `player_batting_style`
--
ALTER TABLE `player_batting_style`
  MODIFY `playerBattingStyleId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `player_bowling_style`
--
ALTER TABLE `player_bowling_style`
  MODIFY `playerBowlingStyleId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT for table `player_roles`
--
ALTER TABLE `player_roles`
  MODIFY `roleId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

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
  MODIFY `categoryId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `tournament_competitor`
--
ALTER TABLE `tournament_competitor`
  MODIFY `tournamentCompetitorId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- AUTO_INCREMENT for table `tournament_competitor_player`
--
ALTER TABLE `tournament_competitor_player`
  MODIFY `tournamentCompetitorPlayerId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=237;

--
-- AUTO_INCREMENT for table `tournament_information`
--
ALTER TABLE `tournament_information`
  MODIFY `tournamentId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `tournament_matches`
--
ALTER TABLE `tournament_matches`
  MODIFY `matchId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=71;

--
-- AUTO_INCREMENT for table `tournament_type`
--
ALTER TABLE `tournament_type`
  MODIFY `tournamentTypeId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `userId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `user_team_new`
--
ALTER TABLE `user_team_new`
  MODIFY `userTeamId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT for table `user_type`
--
ALTER TABLE `user_type`
  MODIFY `userType` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `venues`
--
ALTER TABLE `venues`
  MODIFY `venueId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

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

