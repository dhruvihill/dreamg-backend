require("dotenv/config");
const express = require("express");
const bodyParser = require("body-parser");
const { fetchData: periode } = require("./cron/UpdateMatchStatus/periode");
const exception = require("./middleware/exceptionHandling");
const { logger } = require("./utils/index");

// calling periode to store periode details in db
const setIntervalImmediate = () => {
  setInterval(() => {
    periode();
  }, 60 * 60 * 1000);
  setTimeout(() => {
    periode();
  }, 2000);
};
setIntervalImmediate();

const app = express();

// Parsing body
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

// logging requests
logger(app);

// applying middleware for serving static filess
app.use("/public", express.static("public"));

// Routes
app.use("/api/v1/system", require("./routes/masterAPI"));
app.use("/api/v1/auth", require("./routes/Auth/index"));
app.use("/api/v1/user", require("./routes/user"));
app.use("/api/v1/getDashboardData", require("./routes/dashboard"));
app.use("/api/v1/userTeams", require("./routes/matchDetails"));
app.use("/api/v1/userTeams", require("./routes/userTeamDetails"));
app.use("/api/v1/notification", require("./routes/notification"));
app.use("/api/v1/matches", require("./routes/matches"));
app.use("/api/v1/coins", require("./routes/coins"));
app.get("*", (req, res) => {
  res.status(404).json({
    message: "page not found",
  });
});
app.post("*", (req, res) => {
  res.status(404).json({
    message: "page not found",
  });
});

app.use(exception);

// Listening App
try {
  app.listen(process.env.PORT || 3000, () => {
    console.log(`Listening on ports ${process.env.PORT || 3000}`);
  });
} catch (error) {
  console.log(error);
}
