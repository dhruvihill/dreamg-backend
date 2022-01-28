const mysql = require("mysql");
require("dotenv/config");

// Creating Connection

// let connection;
// try {
//   connection = mysql.createConnection({
//     host: process.env.CLEVER_CLOUD_HOST,
//     user: process.env.CLEVER_CLOUD_USER,
//     password: process.env.CLEVER_CLOUD_PASSWORD,
//     database: process.env.CLEVER_CLOUD_DATABASE_NAME,
//   });
// } catch (error) {
//   console.log(error.message);
// }
// console.log(
//   process.env.CLEVER_CLOUD_HOST,
//   process.env.CLEVER_CLOUD_USER,
//   process.env.CLEVER_CLOUD_PASSWORD,
//   process.env.CLEVER_CLOUD_DATABASE_NAME
// );

let connection;
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

  // error handling to Database
  connection.on("error", (err) => {
    console.log("db error", err.code);
    setTimeout(() => {
      initializeConnection();
    }, 2000);
  });
};

// initialize connection and connection to db
initializeConnection();

const fetchData = (query, options = []) =>
  new Promise((resolve, reject) => {
    connection.query(query, options, (err, response) => {
      if (err) reject(err);
      else resolve(response);
    });
  });

const updateLikes = (userId, teamId) => {
  return new Promise((resolve, reject) => {
    connection.query(
      "CALL update_likes(?, ?);",
      [teamId, userId],
      (err, res) => {
        if (err) reject(err);
        else {
          resolve(res[0][0]);
        }
      }
    );
  });
};

module.exports = { fetchData, updateLikes };
