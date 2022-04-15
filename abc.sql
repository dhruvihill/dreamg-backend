BEGIN
DECLARE validPlayers INT DEFAULT 0;
DECLARE validUser INT DEFAULT 0;
DECLARE validMatch INT DEFAULT 0;
DECLARE lastInsertId INT DEFAULT 0;

/* error handling for duplicate entry */
DECLARE EXIT HANDLER FOR 1062
BEGIN
IF lastInsertId != 0 THEN
/* what to do in duplicate entry */
SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Duplicate entry';
END IF;
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
SELECT EXISTS(SELECT fullmatchdetails.matchId FROM fullmatchdetails WHERE fullmatchdetails.matchId = matchId AND (fullmatchdetails.matchTyprString = "UPCOMING" AND fullmatchdetails.matchStartTimeMilliSeconds > (UNIX_TIMESTAMP(NOW()) * 1000)) OR True) INTO validMatch;
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
IF insertTeamInUserTeamDataNew(userTeamId, captain, viceCaptain, player3, player4, player5, player6, player7, player8, player9, player10, player11) THEN
SELECT "success" AS message;
COMMIT;
ELSE 
ROLLBACK TO SAVEPOINT beforeInsertOrUpdate;
END IF;
SELECT "success" AS message;

COMMIT;
ELSE
INSERT INTO user_team_new (user_team_new.matchId, user_team_new.userId, user_team_new.userTeamType) VALUES (matchId, userId, userTeamType);
SELECT LAST_INSERT_ID() INTO lastInsertId;
IF insertTeamInUserTeamDataNew(lastInsertId, captain, viceCaptain, player3, player4, player5, player6, player7, player8, player9, player10, player11) THEN
SELECT "success" AS message;
COMMIT;
ELSE 
ROLLBACK TO SAVEPOINT beforeInsertOrUpdate;
END IF;
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
END;