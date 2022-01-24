const mysql = require("mysql");
require("dotenv/config");

// Creating Connection
const connection = mysql.createConnection({
  host: "brbogw76w7fnqwls61xz-mysql.services.clever-cloud.com",
  user: "utrcdzbg6f5vhtg0",
  password: "TaB58BF8up543Ck7rYCr",
  database: "brbogw76w7fnqwls61xz",
});

module.exports = connection;
