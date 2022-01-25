const mysql = require("mysql");
require("dotenv/config");

// Creating Connection
const connection = mysql.createConnection({
  host: process.env.DATABASE_HOST || process.env.CLEVER_CLOUD_HOST,
  user: process.env.DATABASE_USER || process.env.CLEVER_CLOUD_USER,
  password: process.env.DATABASE_PASSWORD || process.env.CLEVER_CLOUD_PASSWORD,
  database: process.env.DATABASE_NAME || CLEVER_CLOUD_DATABASE_NAME,
});
console.log(
  process.env.DATABASE_HOST || process.env.CLEVER_CLOUD_HOST,
  process.env.DATABASE_USER || process.env.CLEVER_CLOUD_USER,
  process.env.DATABASE_PASSWORD || process.env.CLEVER_CLOUD_PASSWORD,
  process.env.DATABASE_NAME || CLEVER_CLOUD_DATABASE_NAME
);
module.exports = connection;
