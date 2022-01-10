const express = require("express");
const router = express.Router();
const connection = require("../database/db_connection");
const verifyUser = require("../middleware/verifyUser");

router.post("/get_matches", verifyUser, async (req, res) => {
    const { userId, matchType } = req.body;
    console.log(userId)

    const getMatchData = (query, options) => (
        new Promise((resolve, reject) => {
            connection.query(query, options, (err, response) => {
                if (err) reject(err);
                else resolve(response);
            })
        })
    );
    try {
        const result = await getMatchData("SELECT (SELECT COUNT(DISTINCT userId) FROM user_team WHERE user_team.matchId = all_matches.matchId) AS totalPredictors, (SELECT COALESCE((SELECT DISTINCT userId FROM `user_team` WHERE matchId = all_matches.matchId AND userId = ?), 0)) AS isUserTeamCreated, seriesName, seriesDname, matchId,matchTypeId,matchTyprString, matchStartTimeMilliSeconds,matchStartDateTime,match_status.matchStatusString,venue, all_matches.displayName,team1.teamId AS `team1Id`,team1.name AS 'team1Name', team1.displayName AS 'team1DisplayName',team1.teamFlagUrlLocal AS 'team1FlagURL', team2.teamId AS `team2Id`,team2.name AS 'team2Name', team2.displayName AS 'team2DisplayName',team2.teamFlagUrlLocal AS 'team2FlagURL' FROM all_matches JOIN teams AS team1 ON all_matches.team1_id = team1.teamId JOIN teams AS team2 ON all_matches.team2_id = team2.teamId JOIN match_type ON match_type.matchTypeId = gameType JOIN match_status ON all_matches.matchStatus = match_status.matchStatus WHERE matchStatusString = ? ORDER BY matchStartTimeMilliSeconds LIMIT 10", [userId, matchType]);
        res.status(200).json({
            status: true,
            message: "success",
            data: {
                matches: result
            }
            
        });
    } catch (error) {
        res.status(400).json({
            status: false,
            message: error.message,
            data: {}
        })
    }
})

module.exports = router;
