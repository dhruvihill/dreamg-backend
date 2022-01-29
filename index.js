require("dotenv/config");
const express = require("express");
const bodyParser = require("body-parser");
const path = require("path");

const app = express();

// creates Cron job
// fetchAndStore();

// Parsing body
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

// applying middleware for serving static filess
app.use("/public", express.static("public"));

// Routes
app.use("/api/v1/auth", require("./routes/auth"));
app.use("/api/v1/getdashboarddata", require("./routes/dashboard"));
app.use("/api/v1/players", require("./routes/players"));
app.use("/api/v1/prediction", require("./routes/prediction"));
app.use("/api/v1/notification", require("./routes/notification"));
app.use("/api/v1/matches", require("./routes/matches"));
app.get("*", (req, res) => {
  res.status(404).json({
    message: "page not found",
  });
});

// Listening App
app.listen(process.env.PORT || 3000, () => {
  console.log(`Listening on ports ${process.env.PORT || 3000}`);
});

module.exports = app;
