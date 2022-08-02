const mysql = require("mysql2");
const fs = require("fs");
const path = require("path");
require("dotenv/config");

let connection;

// connectiong to database
const connectToDb = () => {
  // connect to database
  return new Promise((resolve, reject) => {
    connection.getConnection((err, connection) => {
      try {
        if (err) throw err;
        else {
          resolve(connection);
        }
      } catch (error) {
        console.log(error, "normal");
        initializeConnection();
        if (error.message.includes("ECONNREFUSED")) {
          // some email stuff goes here
        }
        reject(err);
      }
    });
    connection.on("error", (err) => {
      console.log("db error", err.code);
      setTimeout(() => {
        initializeConnection();
      }, 1000);
    });
  });

  // error handling to Database
};

// intializing connection
const initializeConnection = () => {
  try {
    connection = mysql.createPool({
      host: process.env.CLEVER_CLOUD_HOST,
      user: process.env.CLEVER_CLOUD_USER,
      password: process.env.CLEVER_CLOUD_PASSWORD,
      database: process.env.CLEVER_CLOUD_DATABASE_NAME,
      multipleStatements: true,
      connectionLimit: process.env.CONNECTION_LIMIT,
    });
  } catch (error) {
    console.log(error);
  }
};

// initialize connection and connection to db
initializeConnection();

// function to execute query
const fetchData = (query, options = []) =>
  new Promise(async (resolve, reject) => {
    try {
      const connection = await connectToDb();
      connection.query(query, options, (err, response) => {
        connection.release();
        if (err) reject(err);
        else resolve(response);
      });
    } catch (error) {
      reject(error);
    }
  });

// function to check if file exists
const imageUrl = (dir, dirFileRelation, file, server) => {
  try {
    if (file.includes(process.env.USER_IMAGE_URL)) {
      if (file.includes("null")) {
        return "";
      } else {
        return server + file;
      }
      // const imageStamp = file.slice(process.env.USER_IMAGE_URL.length);
      // const userObject = JSON.parse(atob(imageStamp));
      // file = file.replace(imageStamp, `${userObject.userId}.jpg`);
    }
    const newPath = path.join(dir, dirFileRelation, file);
    if (fs.existsSync(newPath)) return server + file;
    return "";
  } catch {
    return "";
  }
};

// exporting fetchData function
module.exports = { fetchData, imageUrl };
