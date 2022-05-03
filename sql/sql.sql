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
          WHERE 
            innerFullMatchDetails.matchTournamentId = fullmatchdetails.matchTournamentId
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
ELSE SIGNAL SQLSTATE '45000' 
SET 
  MESSAGE_TEXT = 'invalid userTeamId';
END IF;
ELSE 
SELECT 
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
            innerFullMatchDetails.matchTournamentId = fullmatchdetails.matchTournamentId
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
ELSE SIGNAL SQLSTATE '45000' 
SET 
  MESSAGE_TEXT = 'invalid matchId';
END IF;
END
