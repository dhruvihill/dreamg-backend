require("dotenv/config");
const express = require("express");
const bodyParser = require("body-parser");

const tokens = {
  apiTokens: [
    {
      token: "j3n4sedpgnvd5tx3mg6ye4v8",
      isUsed: false,
      totalCallMade: 0,
      isDeveloperInactive: false,
    },
    {
      token: "mknqt7rrrfwxqa5hevqav99q",
      isUsed: false,
      totalCallMade: 0,
      isDeveloperInactive: false,
    },
    {
      token: "fqb5sqmztc79ucjfkr83snmz",
      isUsed: false,
      totalCallMade: 0,
      isDeveloperInactive: false,
    },
    {
      token: "3frs3xa587s9uhfwa2wnkufu",
      isUsed: false,
      totalCallMade: 0,
      isDeveloperInactive: false,
    },
    {
      token: "q7te6md2rf9ez7aju72bm4gz",
      isUsed: false,
      totalCallMade: 0,
      isDeveloperInactive: false,
    },
    {
      token: "fmpwthupf2fr479np2r6dauy",
      isUsed: false,
      totalCallMade: 0,
      isDeveloperInactive: false,
    },
    {
      token: "8gvnuxmz6hhd6xp9srrffju7",
      isUsed: false,
      totalCallMade: 0,
      isDeveloperInactive: false,
    },
    {
      token: "77rga3pqmmc8a63d4qfpwdzd",
      isUsed: false,
      totalCallMade: 0,
      isDeveloperInactive: false,
    },
    {
      token: "k6bnypfa2ub5mvn8uxbc59f6",
      isUsed: false,
      totalCallMade: 0,
      isDeveloperInactive: false,
    },
    {
      token: "2jws2w6zmp4gt8zn3bv56nfy",
      isUsed: false,
      totalCallMade: 0,
      isDeveloperInactive: false,
    },
    {
      token: "cg85e68fxv6mzgnbe2sjbsx3",
      isUsed: false,
      totalCallMade: 0,
      isDeveloperInactive: false,
    },
    {
      token: "9dn2jbeu4j5ujxrxcgx6ev8k",
      isUsed: false,
      totalCallMade: 0,
      isDeveloperInactive: false,
    },
    {
      token: "tmhxaq4w74x7c2xyahuhfq9y",
      isUsed: false,
      totalCallMade: 0,
      isDeveloperInactive: false,
    },
    {
      token: "6sh4zwc43b5a8ajszjh7e79d",
      isUsed: false,
      totalCallMade: 0,
      isDeveloperInactive: false,
    },
    {
      token: "bme7zzhvyxkw2g2vvkpx8dwe",
      isUsed: false,
      totalCallMade: 0,
      isDeveloperInactive: false,
    },
    {
      token: "egb9th552ezx7ddmamtvst7w",
      isUsed: false,
      totalCallMade: 0,
      isDeveloperInactive: false,
    },
    {
      token: "js5u7mmxkcazf325xp9zchk4",
      isUsed: false,
      totalCallMade: 0,
      isDeveloperInactive: false,
    },
    {
      token: "86es3v3uadks3nxj4ts994z4",
      isUsed: false,
      totalCallMade: 0,
      isDeveloperInactive: false,
    },
    {
      token: "gej38ey64cqm4amkvcb8uezb",
      isUsed: false,
      totalCallMade: 0,
      isDeveloperInactive: false,
    },
  ],
};

// calling periode to store periode details in db
const setIntervalImmediate = () => {
  setInterval(() => {
    const { fetchData: periode } = require("./cron/oop/periode");
    periode();
  }, 60 * 60 * 1000);
  setTimeout(() => {
    const { fetchData: periode } = require("./cron/oop/periode");
    periode();
  }, 2000);
};
setIntervalImmediate();

const app = express();

// Parsing body
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

// applying middleware for serving static filess
app.use("/public", express.static("public"));

// Routes
app.use("/api/v1/auth", require("./routes/auth"));
app.use("/api/v1/user", require("./routes/user"));
app.use("/api/v1/getDashboardData", require("./routes/dashboard"));
app.use("/api/v1/userTeams", require("./routes/userTeams"));
app.use("/api/v1/notification", require("./routes/notification"));
app.use("/api/v1/matches", require("./routes/matches"));
app.get("*", (req, res) => {
  res.status(404).json({
    message: "page not found",
  });
});

// Listening App
try {
  app.listen(process.env.PORT || 3000, () => {
    console.log(`Listening on ports ${process.env.PORT || 3000}`);
  });
} catch (error) {
  console.log(error);
}

module.exports = { tokens };
