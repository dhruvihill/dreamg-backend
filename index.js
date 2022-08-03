require("dotenv/config");
const express = require("express");
const bodyParser = require("body-parser");
const { fetchData: periode } = require("./cron/UpdateMatchStatus/periode");
const exception = require("./middleware/exceptionHandling");
const { logger } = require("./utils/index");
const { NotFoundError } = require("./module/Exception");

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
app.use("/api/v1/auth", require("./routes/Auth"));
app.use("/api/v1/user", require("./routes/user"));
app.use("/api/v1/getDashboardData", require("./routes/Dashboard"));
app.use("/api/v1/userTeams", require("./routes/MatchDetails"));
app.use("/api/v1/userTeams", require("./routes/userTeamDetails"));
app.use("/api/v1/notification", require("./routes/Notification"));
app.use("/api/v1/matches", require("./routes/Matches/index"));
app.use("/api/v1/coins", require("./routes/Coins/index"));

app.all("*", (req, res, next) => {
  const error = new NotFoundError("Page not found");
  next(error);
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
