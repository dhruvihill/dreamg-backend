const mysql = require("mysql");
require("dotenv/config");

// Creating Connection

let connection;
try {
  connection = mysql.createConnection({
    host: process.env.CLEVER_CLOUD_HOST,
    user: process.env.CLEVER_CLOUD_USER,
    password: process.env.CLEVER_CLOUD_PASSWORD,
    database: process.env.CLEVER_CLOUD_DATABASE_NAME,
  });
} catch (error) {
  console.log(error.message);
}
console.log(
  process.env.CLEVER_CLOUD_HOST,
  process.env.CLEVER_CLOUD_USER,
  process.env.CLEVER_CLOUD_PASSWORD,
  process.env.CLEVER_CLOUD_DATABASE_NAME
);
module.exports = connection;
