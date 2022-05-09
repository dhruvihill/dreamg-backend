DELIMITER $$
CREATE PROCEDURE `getPlayers`(IN `matchId` INT, IN `userTeamId` INT)
BEGIN DECLARE teamCreatedBy INT(7) DEFAULT 0;
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
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE `getUserTeam`(IN `matchId` INT, IN `userId` INT)
BEGIN
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
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE `get_notifications`(IN `userId` INT(10))
BEGIN

/* checking user in notificatio history */
IF EXISTS(SELECT userId FROM userdetails WHERE userdetails.userId = userId) = 1 THEN

/* selecting notifications */
SELECT `notificationId`, `notificationType`, `notificationTypeString`, `notificationMessage`, `creationTime`, `haveReaded` FROM `fullnotification` WHERE fullnotification.userId = userId AND haveReaded = 0 ORDER BY creationTime DESC;

END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE `register_user`(IN `phoneNumber` VARCHAR(11))
BEGIN

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
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE `setUserTeam`(IN `matchId` INT, IN `userId` INT, IN `userTeamId` INT, IN `userTeamType` INT, IN `captain` INT, IN `viceCaptain` INT, IN `player3` INT, IN `player4` INT, IN `player5` INT, IN `player6` INT, IN `player7` INT, IN `player8` INT, IN `player9` INT, IN `player10` INT, IN `player11` INT)
BEGIN
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
SELECT EXISTS(SELECT fullmatchdetails.matchId FROM fullmatchdetails WHERE fullmatchdetails.matchId = matchId AND (fullmatchdetails.matchTyprString = "UPCOMING" AND fullmatchdetails.matchStartDateTime > (UNIX_TIMESTAMP(NOW()) * 1000)) OR TRUE) INTO validMatch;
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
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE `set_discussion`(IN `matchId` VARCHAR(10), IN `messengerId` VARCHAR(10), IN `createrId` VARCHAR(10), IN `message` VARCHAR(5000))
BEGIN

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
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE `set_isreaded`(IN `userId` INT(9), IN `notificationId` INT(9))
BEGIN
START TRANSACTION;
IF (SELECT notifications.userId = userId FROM notifications WHERE notifications.notificationId = notificationId)
THEN
UPDATE notifications SET isReaded = 1 WHERE notifications.notificationId = notificationId;
COMMIT;
ELSE 
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "invalid input";
END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE `set_mark_as_read_all`(IN `userId` INT(9))
BEGIN
START TRANSACTION;
IF EXISTS(SELECT all_users.userId FROM all_users WHERE all_users.userId = userId)
THEN
UPDATE notifications SET isReaded = 1 WHERE notifications.userId = userId;
COMMIT;
ELSE
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "invalid input";
END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE `storePoints_for_teams`(IN `matchId` INT)
BEGIN

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
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE `update_likes`(IN `teamId` INT(7), IN `userId` INT(7))
BEGIN

/* Declaring variables */
DECLARE userLiked INT DEFAULT 0;
DECLARE likeCount INT DEFAULT 0;
DECLARE userExists INT DEFAULT 0;
DECLARE teamExists INT DEFAULT 0;
DECLARE isUserLikedTeam INT DEFAULT 0;

/* checking existance of user */
SELECT EXISTS(SELECT userdetails.userId FROM userdetails WHERE userdetails.userId = userId) INTO userExists;

/* checking existance of team */
SELECT EXISTS(SELECT userTeamDetails.userTeamId FROM userTeamDetails WHERE userTeamDetails.userTeamId = teamId) INTO teamExists;

IF userExists = 1 THEN
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
ELSE SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'invalid input';

END IF;

/* sending all response */
SELECT likeCount AS likes,isUserLikedTeam AS isUserLiked;
END$$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE `update_views`(IN `teamId` VARCHAR(10), IN `viewerId` VARCHAR(10))
BEGIN

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
