require("dotenv/config");
const express = require("express");
const bodyParser = require("body-parser");
const mysql = require("mysql");
const path = require("path");
// const fetchAndStore = require("./cron/index");

const app = express();
let connection;
const initializeConnection = () => {
  try {
    connection = mysql.createConnection({
      host: process.env.CLEVER_CLOUD_HOST,
      user: process.env.CLEVER_CLOUD_USER,
      password: process.env.CLEVER_CLOUD_PASSWORD,
      database: process.env.CLEVER_CLOUD_DATABASE_NAME,
    });
    connectToDb();
  } catch (error) {
    console.log(error.message);
  }
};
connectToDb = () => {
  connection.connect((err) => {
    try {
      if (err) throw err;
      else console.log("Connected Successfully");
    } catch (error) {
      console.log(error.message);
      if (error.message.includes("ECONNREFUSED")) {
        // some email stuff goes here
      }
      setTimeout(() => {
        initializeConnection();
      }, 3000);
    }
  });
};

// initialize connection and connection to db
initializeConnection();

// error handling to Database
connection.on("error", (err) => {
  console.log("db error", err.code);
  if (err.code === "ECONNRESET") {
    setTimeout(() => {
      initializeConnection();
    }, 2000);
  }
});

// creates Cron job
// fetchAndStore();

// Parsing body
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

// applying middleware for serving static filess
app.use("/public", express.static(path.join(process.cwd(), "/public")));

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
