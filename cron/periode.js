const { storeMatchLineup } = require("./matchLineUp");
const { fetchMatches: storeScorcard } = require("./scorcard");
const { fetchData: storePoints } = require("./points/points");
const { makeRequest, connectToDb, database } = require("./makeRequest");
const log = require("log-to-file");

const onGoingMatches = [];

const updateMatchStatus = (status, matchId) => {
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
};

const storeScorcardAndPoints = async (match) => {
  try {
    const storeScor = async () => {
      try {
        const scorcardDetails = await makeRequest(
          `/matches/sr:match:${match.matchRadarId}/timeline.json`
        );
        if (scorcardDetails && scorcardDetails.sport_event_status) {
          if (scorcardDetails.sport_event_status.status === "live") {
            log(`match status is live ${match.matchId}`);
            if (scorcardDetails.sport_event.tournament?.type.includes("t20")) {
              updateMatchStatus("live", match.matchId);
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
            scorcardDetails.sport_event_status.status === "closed" ||
            scorcardDetails.sport_event_status.status === "ended"
          ) {
            log(`match status is closed ${match.matchId}`);
            log("matchStatus update to ended for " + match.matchId);
            updateMatchStatus("ended", match.matchId);
            const storeScorcardRes = await storeScorcard(match.matchId);
            if (storeScorcardRes) {
              log(`scorcard stored for ${match.matchId}`);
              const storePointsRes = await storePoints(match.matchId);
              if (storePointsRes) {
                onGoingMatches.splice(
                  onGoingMatches.findIndex(
                    (onGoingMatche) => match.matchId === onGoingMatche.matchId
                  ),
                  1
                );
                log("Points stored for " + match.matchId);
              } else {
                log(`points can't be for ${match.matchId}`);
              }
            } else {
              log(`scorcard nor stored for ${match.matchId}`);
            }
          } else if (
            scorcardDetails.sport_event_status.status === "cancelled"
          ) {
            log(`match status is cancelled ${match.matchId}`);
            updateMatchStatus("cancelled", match.matchId);
          } else if (
            scorcardDetails.sport_event_status.status === "abandoned"
          ) {
            log(`match status is abandoned ${match.matchId}`);
            updateMatchStatus("abandoned", match.matchId);
          } else if (
            scorcardDetails.sport_event_status.status === "not_started"
          ) {
            log(`match status is not_started ${match.matchId}`);
            setTimeout(storeScor, 2 * 60 * 1000);
          } else {
            log(
              `match status is ${scorcardDetails.sport_event_status.status} for ${match.matchId}`
            );
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
};

// const storeMatchLineUpAndStatus = async (match) => {
//   return new Promise(async (resolve) => {
//     try {
//       const connection = await connectToDb();
//       const res = await storeMatchLineup(
//         match.matchId,
//         match.matchRadarId,
//         match,
//         connection
//       );
//       if (res) {
//         // calling function for scorcard and points
//         const matchStartTime = new Date(
//           parseInt(match.matchStartTimeMilliSeconds)
//         ).getTime();
//         setTimeout(async () => {
//           const storeScorcardAndPointsRes = await storeScorcardAndPoints(match);
//           if (storeScorcardAndPointsRes) {
//             resolve(true);
//           } else {
//             resolve(false);
//           }
//         }, matchStartTime - Date.now());
//         connection.release();
//         resolve(true);
//       } else {
//         connection.release();
//         setTimeout(async () => {
//           const storeMatchLineUpAndStatusRes = await storeMatchLineUpAndStatus(
//             match
//           );
//           if (storeMatchLineUpAndStatusRes) {
//             resolve(true);
//           } else {
//             resolve(false);
//           }
//         }, 2 * 60 * 1000);
//       }
//     } catch (error) {
//       if (error.isAxiosError) {
//         if (error.response.data.message === "No lineups.") {
//           setTimeout(async () => {
//             const storeMatchLineUpAndStatusRes =
//               await storeMatchLineUpAndStatus(match);
//             if (storeMatchLineUpAndStatusRes) {
//               resolve(true);
//             } else {
//               resolve(false);
//             }
//           }, 2 * 60 * 1000);
//         }
//       } else {
//         console.log(error);
//         resolve(false);
//       }
//     }
//   });
// };

const handleMatchLineUp = async (match) => {
  try {
    let handleMatchLineUpStoreCalledTimes = 0;
    const handleMatchLineUpStore = async () => {
      handleMatchLineUpStoreCalledTimes++;

      log(`storeMatchLineup function stored called ${match.matchId}`);
      const storeMatchLineupRes = await storeMatchLineup(
        match.matchId,
        match.matchRadarId,
        match
      );
      if (storeMatchLineupRes) {
        log(`match lineup stored for ${match.matchId}`);
        onGoingMatches.forEach((onGoingMatche) => {
          if (match.matchId === onGoingMatche.matchId) {
            onGoingMatche.isLineUpStored = true;
          }
        });
      } else {
        setTimeout(async () => {
          if (handleMatchLineUpStoreCalledTimes < 10) {
            handleMatchLineUpStore();
          } else {
            log(
              `match lineup can't be stored and function ${handleMatchLineUpStoreCalledTimes} times called for ${match.matchId}`
            );
          }
          handleMatchLineUpStore();
        }, 2 * 60 * 1000);
      }
    };
    handleMatchLineUpStore();
  } catch (error) {
    console.log(error.message);
    resolve(false);
  }
};

const fetchData = async () => {
  return new Promise(async (resolve) => {
    try {
      const connection = await connectToDb();
      const matches = await database(
        "SELECT matchId, matchRadarId, matchTournamentId, matchStartDateTime, matchStartTimeMilliSeconds, matchTyprString, matchStatusString, team1Id, team2Id, team1RadarId, team2RadarId FROM `fullmatchdetails` WHERE matchStatusString IN ('not_started') ORDER BY `fullmatchdetails`.`matchStartTimeMilliSeconds` DESC;",
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
            if (
              matchStartTime.getTime() > now.getTime() ||
              match.matchId === 33
            ) {
              if (matchStartTime.getTime() < now.getTime() + 90 * 60 * 1000) {
                log(
                  `Started to proceed match for scorcard, lineups and points for ${match.matchId}`
                );

                // need to check that object does not pushed in array second time
                onGoingMatches.push(match);
                setTimeout(async () => {
                  log(`match lineup function called for ${match.matchId}`);
                  handleMatchLineUp(match);
                }, matchStartTime.getTime() - now.getTime() - 25 * 60 * 1000);
                setTimeout(async () => {
                  log(`match scorcard function called for ${match.matchId}`);
                  storeScorcardAndPoints(match);
                }, matchStartTime.getTime() - now.getTime());

                currentMatch++;
                if (currentMatch !== totalMatches) {
                  setTimeout(() => {
                    setTimeoutForMatches(matches[currentMatch]);
                  }, 0);
                } else {
                  resolve(true);
                }
              } else {
                currentMatch++;
                if (currentMatch !== totalMatches) {
                  setTimeout(() => {
                    setTimeoutForMatches(matches[currentMatch]);
                  }, 0);
                } else {
                  resolve(true);
                }
              }
            } else {
              // do it right now
              currentMatch++;
              if (currentMatch !== totalMatches) {
                setTimeout(() => {
                  setTimeoutForMatches(matches[currentMatch]);
                }, 0);
              } else {
              }
            }
          } catch (error) {
            console.log(error.message, "processMatch");
            currentMatch++;
            if (currentMatch !== totalMatches) {
              setTimeout(() => {
                setTimeoutForMatches(matches[currentMatch]);
              }, 0);
            } else {
              resolve(true);
            }
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
  });
};

module.exports = {
  fetchData,
};
