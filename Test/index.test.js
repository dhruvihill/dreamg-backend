const app = require("../index");
const request = require("supertest");

const authToken =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjp7InVzZXJJZCI6OX0sImlhdCI6MTY0MTgyNTY1N30.akM16vkGw54ENP_a26Nmae6Ilz3yib1U99s7EhTku-M";

describe("Register user", () => {
  it("Register user duplicate entry", async () => {
    const res = await request(app)
      .post("/api/v1/auth/register")
      .send({ number: "9979528598" })
      .set("Content-Type", "application/json");

    const data = JSON.parse(res.text);
    expect(res.statusCode).toEqual(400);
    expect(data.status).toEqual(false);
    expect(data.message).toEqual("Duplicate entry");
    expect(data.data).toEqual({});
  });
  it("Register user invalid entry", async () => {
    const res = await request(app)
      .post("/api/v1/auth/register")
      .send({ number: "997928598" })
      .set("Content-Type", "application/json");

    const data = JSON.parse(res.text);
    expect(res.statusCode).toEqual(400);
    expect(data.status).toEqual(false);
    expect(data.message).toEqual("invalid input");
    expect(data.data).toEqual({});
  });
  it("Register user invalid entry", async () => {
    const res = await request(app)
      .post("/api/v1/auth/register")
      .send({ number: "99792r8598" })
      .set("Content-Type", "application/json");

    const data = JSON.parse(res.text);
    expect(res.statusCode).toEqual(400);
    expect(data.status).toEqual(false);
    expect(data.message).toEqual("invalid input");
    expect(data.data).toEqual({});
  });
});

describe("Login user", () => {
  it("login with correct credential", async () => {
    const res = await request(app)
      .post("/api/v1/auth/login")
      .send({ number: "9712491369" })
      .set("Content-Type", "application/json");

    const data = JSON.parse(res.text);

    expect(res.statusCode).toEqual(200);
    expect(data.status).toEqual(true);
    expect(data.message).toEqual("success");
    expect(data.data.phoneNumber).toEqual("9712491369");
    expect(data.data.userId > 0).toEqual(true);
  });
  it("login with no user", async () => {
    const res = await request(app)
      .post("/api/v1/auth/login")
      .send({ number: "0000000000" })
      .set("Content-Type", "application/json");

    const data = JSON.parse(res.text);

    expect(res.statusCode).toEqual(400);
    expect(data.status).toEqual(false);
    expect(data.message).toEqual("user does not exists");
    expect(data.data).toEqual({});
  });
  it("login with invalid input", async () => {
    const res = await request(app)
      .post("/api/v1/auth/login")
      .send({ number: "971249136900" })
      .set("Content-Type", "application/json");

    const data = JSON.parse(res.text);

    expect(res.statusCode).toEqual(400);
    expect(data.status).toEqual(false);
    expect(data.message).toEqual("invalid input");
    expect(data.data).toEqual({});
  });
  it("login with invalid input", async () => {
    const res = await request(app)
      .post("/api/v1/auth/login")
      .send({ number: "971249136e" })
      .set("Content-Type", "application/json");

    const data = JSON.parse(res.text);

    expect(res.statusCode).toEqual(400);
    expect(data.status).toEqual(false);
    expect(data.message).toEqual("invalid input");
    expect(data.data).toEqual({});
  });
});

describe("check user", () => {
  it("check user with valid data", async () => {
    const res = await request(app).post("/api/v1/auth/check_user").send({
      phoneNumber: "9712491369",
    });

    const data = JSON.parse(res.text);

    expect(res.statusCode).toEqual(200);
    expect(data.status).toEqual(true);
    expect(data.message).toEqual("success");
    expect(data.data.userId > 0).toEqual(true);
  });
  it("check user with no user", async () => {
    const res = await request(app).post("/api/v1/auth/check_user").send({
      phoneNumber: "0000000000",
    });

    const data = JSON.parse(res.text);

    expect(res.statusCode).toEqual(400);
    expect(data.status).toEqual(false);
    expect(data.message).toEqual("user does not exists");
    expect(data.data).toEqual({});
  });
  it("check user with invalid data", async () => {
    const res = await request(app).post("/api/v1/auth/check_user").send({
      phoneNumber: "971249136900",
    });

    const data = JSON.parse(res.text);

    expect(res.statusCode).toEqual(400);
    expect(data.status).toEqual(false);
    expect(data.message).toEqual("invalid input");
    expect(data.data).toEqual({});
  });
  it("check user with invalid data", async () => {
    const res = await request(app).post("/api/v1/auth/check_user").send({
      phoneNumber: "971249136e",
    });

    const data = JSON.parse(res.text);

    expect(res.statusCode).toEqual(400);
    expect(data.status).toEqual(false);
    expect(data.message).toEqual("invalid input");
    expect(data.data).toEqual({});
  });
});

describe("get user profile", () => {
  it("user profile", async () => {
    const res = await request(app)
      .post("/api/v1/auth/getuserprofile")
      .set("Content-Type", "application/json")
      .set("authToken", authToken)
      .send({
        predictorId: 9,
      });

    const data = JSON.parse(res.text);

    expect(res.statusCode).toEqual(200);
    expect(data.status).toEqual(true);
    expect(data.message).toEqual("success");
    expect(
      data.data.hasOwnProperty("userDetails") &&
        data.data.hasOwnProperty("recentPlayed")
    ).toEqual(true);
    expect(Array.isArray(data.data["recentPlayed"])).toEqual(true);
    expect(typeof data.data.userDetails === "object").toEqual(true);
  });
});

describe("get dashboard data", () => {
  it("dashboard data", async () => {
    const res = await request(app)
      .get("/api/v1/getdashboarddata")
      .set("Content-Type", "application/json")
      .set("authToken", authToken);

    const data = JSON.parse(res.text);

    expect(res.statusCode).toEqual(200);
    expect(data.status).toEqual(true);
    expect(data.message).toEqual("success");
    expect(Array.isArray(data.data.matches)).toEqual(true);
    expect(
      data.data.matches.length > 0
        ? typeof data.data.matches[0] === "object"
        : true
    ).toEqual(true);
  });
});

describe("get matches", () => {
  it("get matches with correct data", async () => {
    const res = await request(app)
      .post("/api/v1/matches/get_matches")
      .set("Content-Type", "application/json")
      .set("authToken", authToken)
      .send({
        matchType: "UPCOMING",
      });

    const data = JSON.parse(res.text);

    const properties = [
      "totalPredictors",
      "isUserTeamCreated",
      "seriesName",
      "seriesDname",
      "matchId",
      "matchTypeId",
      "matchTyprString",
      "matchStartTimeMilliSeconds",
      "matchStartDateTime",
      "matchStatusString",
      "venue",
      "displayName",
      "team1Id",
      "team1Name",
      "team1DisplayName",
      "team1FlagURL",
      "team2Id",
      "team2Name",
      "team2DisplayName",
      "team2FlagURL",
    ];

    let objectVerified = true;

    properties.forEach((p) => {
      if (!data.data.matches[0].hasOwnProperty(p)) {
        objectVerified = false;
      }
    });

    expect(res.statusCode).toEqual(200);
    expect(data.status).toEqual(true);
    expect(objectVerified).toEqual(true);
    expect(data.message).toEqual("success");
    expect(Array.isArray(data.data.matches)).toEqual(true);
    expect(
      data.data.matches.length > 0
        ? typeof data.data.matches[0] === "object"
        : true
    ).toEqual(true);
  });
  it("get matches with correct data", async () => {
    const res = await request(app)
      .post("/api/v1/matches/get_matches")
      .set("Content-Type", "application/json")
      .set("authToken", authToken)
      .send({
        matchType: "RECENT",
      });

    const data = JSON.parse(res.text);

    const properties = [
      "totalPredictors",
      "isUserTeamCreated",
      "seriesName",
      "seriesDname",
      "matchId",
      "matchTypeId",
      "matchTyprString",
      "matchStartTimeMilliSeconds",
      "matchStartDateTime",
      "matchStatusString",
      "venue",
      "displayName",
      "team1Id",
      "team1Name",
      "team1DisplayName",
      "team1FlagURL",
      "team2Id",
      "team2Name",
      "team2DisplayName",
      "team2FlagURL",
    ];

    let objectVerified = true;

    properties.forEach((p) => {
      if (!data.data.matches[0].hasOwnProperty(p)) {
        objectVerified = false;
      }
    });

    expect(res.statusCode).toEqual(200);
    expect(data.status).toEqual(true);
    expect(objectVerified).toEqual(true);
    expect(data.message).toEqual("success");
    expect(Array.isArray(data.data.matches)).toEqual(true);
    expect(
      data.data.matches.length > 0
        ? typeof data.data.matches[0] === "object"
        : true
    ).toEqual(true);
  });
  it("get matches with correct data", async () => {
    const res = await request(app)
      .post("/api/v1/matches/get_matches")
      .set("Content-Type", "application/json")
      .set("authToken", authToken)
      .send({
        matchType: "LIVE",
      });

    const data = JSON.parse(res.text);

    const properties = [
      "totalPredictors",
      "isUserTeamCreated",
      "seriesName",
      "seriesDname",
      "matchId",
      "matchTypeId",
      "matchTyprString",
      "matchStartTimeMilliSeconds",
      "matchStartDateTime",
      "matchStatusString",
      "venue",
      "displayName",
      "team1Id",
      "team1Name",
      "team1DisplayName",
      "team1FlagURL",
      "team2Id",
      "team2Name",
      "team2DisplayName",
      "team2FlagURL",
    ];

    let objectVerified = true;

    properties.forEach((p) => {
      if (!data.data.matches[0].hasOwnProperty(p)) {
        objectVerified = false;
      }
    });

    expect(res.statusCode).toEqual(200);
    expect(data.status).toEqual(true);
    expect(objectVerified).toEqual(true);
    expect(data.message).toEqual("success");
    expect(Array.isArray(data.data.matches)).toEqual(true);
    expect(
      data.data.matches.length > 0
        ? typeof data.data.matches[0] === "object"
        : true
    ).toEqual(true);
  });
});

describe("get notification", () => {
  it("get notification with correct data", async () => {
    const res = await request(app)
      .post("/api/v1/notification/get_notifications")
      .set("Content-Type", "application/json")
      .set("authToken", authToken);

    const data = JSON.parse(res.text);

    const properties = [
      "notificationId",
      "notificationType",
      "notificationMessage",
      "haveReaded",
      "creationTime",
    ];

    let objectVerified = true;

    properties.forEach((p) => {
      if (!data.data.notifications[0].hasOwnProperty(p)) {
        objectVerified = false;
      }
    });

    expect(res.statusCode).toEqual(200);
    expect(data.status).toEqual(true);
    expect(objectVerified).toEqual(true);
    expect(data.message).toEqual("success");
    expect(Array.isArray(data.data.notifications)).toEqual(true);
  });
});

describe("get players", () => {
  it("get players with correct data", async () => {
    const res = await request(app)
      .post("/api/v1/players/getplayers")
      .set("Content-Type", "application/json")
      .set("authToken", authToken)
      .send({
        matchId: 27947,
      });

    const data = JSON.parse(res.text);

    const properties = [
      "matchId",
      "playerId",
      "playerName",
      "playerDisplayName",
      "roleName",
      "URL",
      "points",
      "credits",
      "teamName",
      "teamDisplayName",
      "selectedBy",
      "captainBy",
      "viceCaptainBy",
      "teamId",
      "roleId",
    ];

    let objectVerified = true;

    properties.forEach((p) => {
      if (!data.data.players[0].hasOwnProperty(p)) {
        objectVerified = false;
      }
    });

    expect(res.statusCode).toEqual(200);
    expect(data.status).toEqual(true);
    expect(objectVerified).toEqual(true);
    expect(data.message).toEqual("success");
    expect(Array.isArray(data.data.players)).toEqual(true);
  });
});

//   expect(res.statusCode).toEqual(200);
// });
// it("update profile", async () => {
//   const res = await request(app)
//     .post("/api/v1/auth/updateuserprofile")
//     .send({
//       firstName: "Dhruv",
//       lastName: "Maradiya",
//       email: "dhruv.maradiya@gmail.com",
//       dateOfBirth: "2004/10/18",
//       gender: "female",
//       address: "s-2/502, shyam nagar society",
//       city: "mumbai",
//       pinCode: "842309",
//       state: "maharashtra",
//       country: "india",
//     })
//     .set("Content-Type", "application/json")
//     .set("authToken", authToken);

//   expect(res.statusCode).toEqual(200);
// });
// it("check user", async () => {
//   const res = await request(app).post("/api/v1/auth/check_user").send({
//     phoneNumber: "9712491369",
//   });

//   expect(res.statusCode).toEqual(200);
// });

// describe("matches", () => {
//   it("get dashboard data", async () => {
//     const res = await request(app)
//       .get("/api/v1/getdashboarddata")
//       .set("authToken", authToken);

//     expect(res.statusCode).toEqual(200);
//   });
//   it("get players", async () => {
//     const res = await request(app)
//       .post("/api/v1/players/getplayers")
//       .send({
//         matchId: 27947,
//       })
//       .set("authToken", authToken)
//       .set("Content-Type", "application/json");

//     expect(res.statusCode).toEqual(200);
//   });
//   it("set team", async () => {
//     const res = await request(app)
//       .post("/api/v1/players/setteam")
//       .send({
//         matchId: 27947,
//         players: [
//           4582, 4566, 4352, 4350, 4349, 4345, 4343, 4341, 4185, 4028, 3437,
//         ],
//         captain: 4566,
//         viceCaptain: 3437,
//         userTeamType: 2,
//       })
//       .set(
//         "authToken",
//         "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjp7InVzZXJJZCI6MTd9LCJpYXQiOjE2NDI5NDQ5NTB9.Agm22_4s7ryFzhPUUagpVd7ul_Md0SovFywWoZG2yJ4"
//       );

//     expect(res.statusCode).toEqual(400);
//   });
//   it("get matches", async () => {
//     const res = await request(app)
//       .post("/api/v1/matches/get_matches")
//       .send({
//         matchType: "UPCOMING",
//       })
//       .set("authToken", authToken);

//     expect(res.statusCode).toEqual(200);
//   });
// });

// describe("notification", () => {
//   it("get notification", async () => {
//     const res = await request(app)
//       .post("/api/v1/notification/get_notifications")
//       .set("authToken", authToken);

//     expect(res.statusCode).toEqual(200);
//   });
// });

// describe("prediction", () => {
//   it("get all prediction", async () => {
//     const res = await request(app)
//       .post("/api/v1/prediction/get_predictions")
//       .send({
//         filter: "MOST_POPULAR",
//       })
//       .set("authToken", authToken);

//     expect(res.statusCode).toEqual(200);
//   });
//   it("get user teams by match", async () => {
//     const res = await request(app)
//       .post("/api/v1/prediction/get_user_teams")
//       .send({
//         matchId: 27947,
//       })
//       .set("authToken", authToken);

//     expect(res.statusCode).toEqual(200);
//   });
//   it("get user teams all", async () => {
//     const res = await request(app)
//       .post("/api/v1/prediction/get_user_teams_predictor")
//       .send({
//         userId: 9,
//       })
//       .set("authToken", authToken);

//     expect(res.statusCode).toEqual(200);
//   });
//   it("get user teams data", async () => {
//     const res = await request(app)
//       .post("/api/v1/prediction/get_user_teams_data")
//       .send({
//         teamId: 26,
//       })
//       .set("authToken", authToken);

//     expect(res.statusCode).toEqual(200);
//   });
//   it("update likes", async () => {
//     const res = await request(app)
//       .post("/api/v1/prediction/update_user_team_likes")
//       .send({
//         teamId: 27,
//       })
//       .set("authToken", authToken);

//     expect(res.statusCode).toEqual(400);
//   });
//   it("update views", async () => {
//     const res = await request(app)
//       .post("/api/v1/prediction/update_user_team_views")
//       .send({
//         teamId: 27,
//       })
//       .set("authToken", authToken);

//     expect(res.statusCode).toEqual(200);
//   });
//   it("set discussion", async () => {
//     const res = await request(app)
//       .post("/api/v1/prediction/set_discussion")
//       .send({
//         matchId: 27947,
//         createrId: 9,
//         message: "late",
//       })
//       .set("authToken", authToken);

//     expect(res.statusCode).toEqual(200);
//   });
//   it("get discussion", async () => {
//     const res = await request(app)
//       .post("/api/v1/prediction/get_discussion")
//       .send({
//         matchId: 27947,
//         createrId: 9,
//       })
//       .set("authToken", authToken);

//     expect(res.statusCode).toEqual(200);
//   });
//   it("get trending predictors", async () => {
//     const res = await request(app)
//       .get("/api/v1/prediction/getTrendingPredictors")
//       .set("authToken", authToken);

//     expect(res.statusCode).toEqual(200);
//   });
//   it("compare teams", async () => {
//     const res = await request(app)
//       .post("/api/v1/prediction/compare_teams")
//       .send({
//         matchId: 27947,
//       })
//       .set("authToken", authToken);

//     expect(res.statusCode).toEqual(200);
//   });
// });
