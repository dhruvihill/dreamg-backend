const { storeMatchLineup } = require("./matchLineUp");
const { fetchMatches: storeScorcard } = require("./scorcard");
const { fetchData: storePoints } = require("./points/points");
const { makeRequest, connectToDb, database } = require("./makeRequest");

function updateMatchStatus(status, matchId) {
  return new Promise(async (resolve) => {
    try {
      const connection = await connectToDb();
      let matchStatus = await database(
        "SELECT statusId FROM `match_status` WHERE statusString = ?",
        [status],
        connection
      );
      if (matchStatus && matchStatus.length > 0) {
        const updateMatchStatus = await database(
          "UPDATE tournament_matches SET matchStatus = ? WHERE matchId = ?",
          [matchStatus[0].statusId, matchId],
          connection
        );
        connection.release();
        resolve(updateMatchStatus);
      } else {
        resolve(false);
      }
    } catch (error) {
      console.log(error.message);
      resolve(false);
    }
  });
}

const storeScorcardAndPoints = async (match) => {
  return new Promise(async (resolve) => {
    try {
      const storeScor = async () => {
        try {
          const scorcardDetails = await makeRequest(
            `/matches/sr:match:${match.matchRadarId}/timeline.json`
          );
          if (scorcardDetails && scorcardDetails.sport_event_status) {
            if (scorcardDetails.sport_event_status.match_status === "live") {
              if (
                scorcardDetails.sport_event.tournament?.type.includes("t20")
              ) {
                setTimeout(storeScor, 20 * 60 * 1000);
              } else if (
                scorcardDetails.sport_event.tournament?.includes("odi")
              ) {
                setTimeout(storeScor, 60 * 60 * 1000);
              } else if (
                scorcardDetails.sport_event.tournament?.includes("test")
              ) {
                setTimeout(storeScor, 180 * 60 * 1000);
              } else if (
                scorcardDetails.sport_event.tournament?.includes("t10")
              ) {
                setTimeout(storeScor, 15 * 60 * 1000);
              }
            } else if (
              scorcardDetails.sport_event_status.match_status === "closed" ||
              scorcardDetails.sport_event_status.match_status === "ended"
            ) {
              updateMatchStatus("ended", match.matchId);
              const storeScorcardRes = await storeScorcard(match.matchId);
              if (storeScorcardRes) {
                const storePointsRes = await storePoints(match.matchId);
                if (storePointsRes) {
                  resolve(true);
                } else {
                  resolve(false);
                }
              }
            } else if (
              scorcardDetails.sport_event_status.match_status === "cancelled"
            ) {
              updateMatchStatus("cancelled", match.matchId);
            } else if (
              scorcardDetails.sport_event_status.match_status === "abandoned"
            ) {
              updateMatchStatus("abandoned", match.matchId);
            } else if (
              scorcardDetails.sport_event_status.match_status === "not_started"
            ) {
              setTimeout(storeScor, 20 * 60 * 1000);
            }
          }
        } catch (error) {
          console.log(error.message, "storeScor");
        }
      };
      storeScor();
    } catch (error) {
      console.log(error.message);
    }
  });
};

const storeMatchLineUpAndStatus = async (match) => {
  try {
    const connection = await connectToDb();
    const res = await storeMatchLineup(
      match.matchId,
      match.matchRadarId,
      match,
      connection
    );
    if (res) {
      // calling function for scorcard and points
      const matchStartTime = new Date(match.matchStartTime).getTime();
      setTimeout(() => {
        storeScorcardAndPoints(match);
      }, matchStartTime - Date.now() + 5 * 60 * 1000);

      console.log("match lineup stored");
      const updateMatchStatusRes = await updateMatchStatus(
        "live",
        match.matchId
      );
      if (updateMatchStatusRes && updateMatchStatusRes.affectedRows === 1) {
        connection.release();
        console.log("match status updated");
      } else {
        connection.release();
        console.log("match status not updated");
      }
    } else {
      connection.release();
      console.log("match status not found");
    }
  } catch (error) {
    if (error.isAxiosError) {
      if (error.response.data.message === "No lineups.") {
        setTimeout(() => {
          storeMatchLineUpAndStatus(match);
        }, 2 * 60 * 1000);
      }
    } else {
      console.log(error);
    }
  }
};

const fetchData = async () => {
  try {
    const connection = await connectToDb();
    const matches = await database(
      "SELECT matchId, matchRadarId, matchTournamentId, matchStartDateTime, matchStartTimeMilliSeconds, matchTyprString, matchStatusString, team1Id, team2Id, team1RadarId, team2RadarId FROM `fullmatchdetails` WHERE matchStatusString IN ('ended') ORDER BY `fullmatchdetails`.`matchStartTimeMilliSeconds` DESC;",
      [],
      connection
    );
    connection.release();
    if (matches.length > 0) {
      const totalMatches = matches.length;
      let currentMatch = 0;

      const setTimeoutForMatches = async (match) => {
        try {
          // const connection = await connectToDb();
          const matchStartTime = new Date(
            parseInt(match.matchStartTimeMilliSeconds)
          );
          const now = new Date();
          // if (matchStartTime.getTime() > now.getTime()) {
          if (matchStartTime.getTime() < now.getTime() + 90 * 60 * 1000) {
            setTimeout(() => {
              storeMatchLineUpAndStatus(match);
            }, matchStartTime.getTime() - now.getTime() - 25 * 60 * 1000);

            currentMatch++;
            if (currentMatch !== totalMatches) {
              setTimeout(() => {
                setTimeoutForMatches(matches[currentMatch]);
              }, 0);
            } else {
              console.log("done");
            }
          } else {
            currentMatch++;
            if (currentMatch !== totalMatches) {
              setTimeout(() => {
                setTimeoutForMatches(matches[currentMatch]);
              }, 0);
            } else {
              console.log("done");
            }
          }
          // } else {
          //   // do it right now
          //   currentMatch++;
          //   if (currentMatch !== totalMatches) {
          //     setTimeout(() => {
          //       setTimeoutForMatches(matches[currentMatch]);
          //     }, 0);
          //   } else {
          //     console.log("done");
          //   }
          // }
        } catch (error) {
          console.log(error.message, "processMatch");
        }
      };
      setTimeoutForMatches(matches[currentMatch]);
      //   console.log(matches);
    } else {
      console.log("No matches to fetch");
    }
  } catch (error) {
    console.log(error.message, "fetchData");
  }
};

module.exports = {
  fetchData,
};
