const app = require("../index");
const request = require("supertest");

const authToken =
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjp7InVzZXJJZCI6OX0sImlhdCI6MTY0MTgyNTY1N30.akM16vkGw54ENP_a26Nmae6Ilz3yib1U99s7EhTku-M";

describe("auth flow", () => {
  it("Register user", async () => {
    const res = await request(app)
      .post("/api/v1/auth/register")
      .send({ number: "9979528598" })
      .set("Content-Type", "application/json");

    expect(res.statusCode).toEqual(400);
  });
  it("Login user", async () => {
    const res = await request(app)
      .post("/api/v1/auth/login")
      .send({ number: "9712491369" })
      .set("Content-Type", "application/json");

    expect(res.statusCode).toEqual(200);
  });
  it("user profile", async () => {
    const res = await request(app)
      .post("/api/v1/auth/getuserprofile")
      .set("Content-Type", "application/json")
      .set("authToken", authToken);

    expect(res.statusCode).toEqual(200);
  });
  it("update profile", async () => {
    const res = await request(app)
      .post("/api/v1/auth/updateuserprofile")
      .send({
        firstName: "Dhruv",
        lastName: "Maradiya",
        email: "dhruv.maradiya@gmail.com",
        dateOfBirth: "2004/10/18",
        gender: "female",
        address: "s-2/502, shyam nagar society",
        city: "mumbai",
        pinCode: "842309",
        state: "maharashtra",
        country: "india",
      })
      .set("Content-Type", "application/json")
      .set("authToken", authToken);

    expect(res.statusCode).toEqual(200);
  });
  it("check user", async () => {
    const res = await request(app).post("/api/v1/auth/check_user").send({
      phoneNumber: "9712491369",
    });

    expect(res.statusCode).toEqual(200);
  });
});

describe("matches", () => {
  it("get dashboard data", async () => {
    const res = await request(app)
      .get("/api/v1/getdashboarddata")
      .set("authToken", authToken);

    expect(res.statusCode).toEqual(200);
  });
  it("get players", async () => {
    const res = await request(app)
      .post("/api/v1/players/getplayers")
      .send({
        matchId: 27947,
      })
      .set("authToken", authToken)
      .set("Content-Type", "application/json");

    expect(res.statusCode).toEqual(200);
  });
  it("set team", async () => {
    const res = await request(app)
      .post("/api/v1/players/setteam")
      .send({
        matchId: 27947,
        players: [
          4582, 4566, 4352, 4350, 4349, 4345, 4343, 4341, 4185, 4028, 3437,
        ],
        captain: 4566,
        viceCaptain: 3437,
        userTeamType: 2,
      })
      .set(
        "authToken",
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjp7InVzZXJJZCI6MTd9LCJpYXQiOjE2NDI5NDQ5NTB9.Agm22_4s7ryFzhPUUagpVd7ul_Md0SovFywWoZG2yJ4"
      );

    expect(res.statusCode).toEqual(400);
  });
  it("get matches", async () => {
    const res = await request(app)
      .post("/api/v1/matches/get_matches")
      .send({
        matchType: "UPCOMING",
      })
      .set("authToken", authToken);

    expect(res.statusCode).toEqual(200);
  });
});

describe("notification", () => {
  it("get notification", async () => {
    const res = await request(app)
      .post("/api/v1/notification/get_notifications")
      .set("authToken", authToken);

    expect(res.statusCode).toEqual(200);
  });
});

describe("prediction", () => {
  it("get all prediction", async () => {
    const res = await request(app)
      .post("/api/v1/prediction/get_predictions")
      .send({
        filter: "MOST_POPULAR",
      })
      .set("authToken", authToken);

    expect(res.statusCode).toEqual(200);
  });
  it("get user teams by match", async () => {
    const res = await request(app)
      .post("/api/v1/prediction/get_user_teams")
      .send({
        matchId: 27947,
      })
      .set("authToken", authToken);

    expect(res.statusCode).toEqual(200);
  });
  it("get user teams all", async () => {
    const res = await request(app)
      .post("/api/v1/prediction/get_user_teams_predictor")
      .send({
        userId: 9,
      })
      .set("authToken", authToken);

    expect(res.statusCode).toEqual(200);
  });
  it("get user teams data", async () => {
    const res = await request(app)
      .post("/api/v1/prediction/get_user_teams_data")
      .send({
        teamId: 26,
      })
      .set("authToken", authToken);

    expect(res.statusCode).toEqual(200);
  });
  it("update likes", async () => {
    const res = await request(app)
      .post("/api/v1/prediction/update_user_team_likes")
      .send({
        teamId: 27,
      })
      .set("authToken", authToken);

    expect(res.statusCode).toEqual(400);
  });
  it("update views", async () => {
    const res = await request(app)
      .post("/api/v1/prediction/update_user_team_views")
      .send({
        teamId: 27,
      })
      .set("authToken", authToken);

    expect(res.statusCode).toEqual(200);
  });
  it("set discussion", async () => {
    const res = await request(app)
      .post("/api/v1/prediction/set_discussion")
      .send({
        matchId: 27947,
        createrId: 9,
        message: "late",
      })
      .set("authToken", authToken);

    expect(res.statusCode).toEqual(200);
  });
  it("get discussion", async () => {
    const res = await request(app)
      .post("/api/v1/prediction/get_discussion")
      .send({
        matchId: 27947,
        createrId: 9,
      })
      .set("authToken", authToken);

    expect(res.statusCode).toEqual(200);
  });
  it("get trending predictors", async () => {
    const res = await request(app)
      .get("/api/v1/prediction/getTrendingPredictors")
      .set("authToken", authToken);

    expect(res.statusCode).toEqual(200);
  });
  it("compare teams", async () => {
    const res = await request(app)
      .post("/api/v1/prediction/compare_teams")
      .send({
        matchId: 27947,
      })
      .set("authToken", authToken);

    expect(res.statusCode).toEqual(200);
  });
});
