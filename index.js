require("dotenv/config");
const express = require("express");
const bodyParser = require("body-parser");
const connection = require("./database/db_connection");
const path = require("path");
// const fetchAndStore = require("./cron/index");

const app = express();

// creates Cron job
// fetchAndStore();

// Connection to Database
connection.connect((err) => {
  try {
    if (err) throw err;
    else console.log("Connected Successfully");
  } catch (error) {
    console.log(error.message);
  }
});

// Parsing body
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

// applying middleware for serving static filess
app.use("/public", express.static(path.join(__dirname, "public")));

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
  console.log(`Listening on port ${process.env.PORT || 3000}`);
});

module.exports = app;
