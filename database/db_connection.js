const mysql = require("mysql");
const fs = require("fs");
const path = require("path");
require("dotenv/config");

let connection;

// connectiong to database
const connectToDb = () => {
  let time = 0;
  // connect to database
  connection.connect((err) => {
    try {
      if (err) throw err;
      else {
        console.log("Connected Successfully normal");
        setInterval(() => {
          time++;
        }, 1000);
      }
    } catch (error) {
      console.log(error.message, "normal");
      if (error.message.includes("ECONNREFUSED")) {
        // some email stuff goes here
      }
      setTimeout(() => {
        initializeConnection();
      }, 1000);
    }
  });

  // error handling to Database
  connection.on("error", (err) => {
    console.log(time);
    time = 0;
    console.log("db error", err.code);
    setTimeout(() => {
      initializeConnection();
    }, 1000);
  });
};

// intializing connection
const initializeConnection = () => {
  try {
    connection = mysql.createConnection({
      host: process.env.CLEVER_CLOUD_HOST,
      user: process.env.CLEVER_CLOUD_USER,
      password: process.env.CLEVER_CLOUD_PASSWORD,
      database: process.env.CLEVER_CLOUD_DATABASE_NAME,
      multipleStatements: true,
    });
    connectToDb();
  } catch (error) {
    console.log(error.message);
  }
};

// initialize connection and connection to db
initializeConnection();

// function to execute query
const fetchData = (query, options = []) =>
  new Promise((resolve, reject) => {
    connection.query(query, options, (err, response) => {
      if (err) reject(err);
      else resolve(response);
    });
  });

// function to check if file exists
const imageUrl = (dir, dirFileRelation, file, server) => {
  try {
    const newPath = path.join(dir, dirFileRelation, file);
    if (fs.existsSync(newPath)) return server + file;
    return "";
  } catch {
    return "";
  }
};

// exporting fetchData function
module.exports = { fetchData, imageUrl };
