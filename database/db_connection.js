const mysql = require("mysql");
require("dotenv/config");

// Creating Connection
const connection = mysql.createConnection({
  host:
    process.env.HOST || "brbogw76w7fnqwls61xz-mysql.services.clever-cloud.com",
  user: process.env.USER || "utrcdzbg6f5vhtg0",
  password: process.env.PASSWORD || "TaB58BF8up543Ck7rYCr",
  database: process.env.DATABASE || "brbogw76w7fnqwls61xz",
});
console.log(
  process.env.HOST || "brbogw76w7fnqwls61xz-mysql.services.clever-cloud.com",
  process.env.USER || "utrcdzbg6f5vhtg0",
  process.env.PASSWORD || "TaB58BF8up543Ck7rYCr",
  process.env.DATABASE || "brbogw76w7fnqwls61xz"
);
module.exports = connection;
