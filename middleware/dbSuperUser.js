const mysql = require("mysql");
require("dotenv").config();
let connectionForCron = mysql.createPool({
  connectionLimit: 5,
  host: process.env.CLEVER_CLOUD_HOST || "localhost",
  user: process.env.CLEVER_CLOUD_USER || "root",
  password: process.env.CLEVER_CLOUD_PASSWORD || "",
  database: process.env.CLEVER_CLOUD_DATABASE_NAME || "dreamg-v3",
  multipleStatements: true,
});
let totalConnection = 0;
let totalConnectionAttemps = 0;
connectionForCron.on('connection', function (connection) {
  totalConnection++;
});
connectionForCron.on('release', function (connection) {
  totalConnection--;
});

const connectToDb = () => {
  // connect to database
  return new Promise((resolve, reject) => {
    try {
      if (connectionForCron) {
        connectionForCron.getConnection((err, connection) => {
          try {
            if (err) throw err;
            else {
              // console.log("Connected Successfully for cron");
              totalConnectionAttemps++;
              resolve(connection);
            }
          } catch (error) {
            if (error.message.includes("ECONNREFUSED")) {
              // some email stuff goes here
              setTimeout(async () => {
                try {
                  resolve(await connectToDb());
                } catch (error) {
                  reject(error);
                }
              }, 200);
            }
            reject(error);
          }
        });
      } else {
        initializeConnection();
        connectToDb()
          .then((connection) => {
            resolve(connection);
          })
          .catch((error) => {
            console.log(error, "connectToDb");
          });
      }
    } catch (error) {
      console.log(error, "connectToDb");
      reject(error);
    }

    // error handling to Database
    connectionForCron.on("error", (err) => {
      console.log("db error", err.code);
      setTimeout(() => {
        initializeConnection();
      }, 1000);
    });
  });
};
// intializing connection
const initializeConnection = () => {
  try {
    connectionForCron = mysql.createPool({
      connectionLimit: 5,
      host: process.env.CLEVER_CLOUD_HOST || "localhost",
      user: process.env.CLEVER_CLOUD_USER || "root",
      password: process.env.CLEVER_CLOUD_PASSWORD || "",
      database: process.env.CLEVER_CLOUD_DATABASE_NAME || "dreamg-v3",
      multipleStatements: true,
    });
  } catch (error) {
    console.log(error, "initializeConnection");
  }
};

// query to fetch, insert data
const database = (query, options, connection) => {
  return new Promise(async (resolve, reject) => {
    try {
      connection.query(query, options, (err, reponse) => {
        if (err) {
          if (err.code === "ER_DUP_ENTRY") {
            console.log(err.message);
            resolve(true);
          } else {
            reject(err);
          }
        } else resolve(reponse);
      });
    } catch (error) {
      console.log(error, "cron databse function");
    }
  });
};

module.exports = {
  connectToDb,
  database,
};
