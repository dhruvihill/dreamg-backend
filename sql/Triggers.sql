CREATE TRIGGER `storeCreditsForPlayers` AFTER INSERT ON `tournament_matches`
 FOR EACH ROW BEGIN
CALL calculateCreditsForPlayers(NEW.matchId, 1);
END

CREATE TRIGGER `storePointsForTeamsAndCreditsForPlayers` AFTER UPDATE ON `tournament_matches`
 FOR EACH ROW BEGIN
DECLARE isMatchCancelledOrAbandoned BOOL DEFAULT 0;
IF OLD.isPointsCalculated = 1 AND NEW.isPointsCalculated = 1 THEN
	CALL storePointsForUserTeams(OLD.matchId);
	CALL calculateCreditsForPlayers(OLD.matchId, 0);
    CALL bonusToContestWinners(NEW.matchId);
ELSE
        SELECT match_status.statusString IN ('cancelled', 'abandoned') INTO isMatchCancelledOrAbandoned FROM match_status WHERE match_status.statusId = NEW.matchStatus;

        IF isMatchCancelledOrAbandoned = 1 THEN
            CALL calculateCreditsForPlayers(OLD.matchId, 0);
        END IF;
END IF;
END


