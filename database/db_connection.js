const mysql = require("mysql");
require("dotenv/config");

// Creating Connection
const connection = mysql.createConnection({
  host: process.env.CLEVER_CLOUD_HOST,
  user: process.env.CLEVER_CLOUD_USER,
  password: process.env.CLEVER_CLOUD_PASSWORD,
  database: process.env.CLEVER_CLOUD_DATABASE_NAME,
});

module.exports = connection;
