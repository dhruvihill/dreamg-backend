const axios = require("axios");
const mysql = require("mysql");
let connectionForCron = null;
const {
  tokens: { apiTokens: api_tokens },
} = require("../index");

const createInstance = () => {
  return axios.create({
    baseURL: "https://api.sportradar.us/cricket-t2/en/",
  });
};
let axiosInstance = createInstance();

const generateTimeOut = (token, quotaUsed, delay) => {
  setTimeout(() => {
    api_tokens.forEach((api_token) => {
      if (api_token.token === token) {
        api_token.isUsed = false;
        api_token.totalCallMade = quotaUsed;
      }
    });
  }, delay);
};

// Axios request
const makeRequest = (url) => {
  return new Promise((resolve, reject) => {
    try {
      const makeCall = (apiToken) => {
        try {
          axiosInstance
            .get(url, {
              params: {
                api_key: apiToken,
              },
            })
            .then((data) => {
              generateTimeOut(
                apiToken,
                parseInt(data.headers["x-plan-quota-current"]),
                1100
              );
              resolve(data.data);
            })
            .catch((error) => {
              if (
                (error.response &&
                  parseInt(error.response.headers["x-plan-quota-current"]) >
                    parseInt(
                      error.response.headers["x-plan-quota-allotted"]
                    )) ||
                parseInt(error.response.headers["x-plan-quota-current"]) ===
                  parseInt(error.response.headers["x-plan-quota-allotted"])
              ) {
                api_tokens.forEach((token) => {
                  if (token.token === apiToken) {
                    token.totalCallMade = parseInt(
                      error.response.headers["x-plan-quota-current"]
                    );
                  }
                });
                selectTokenAndCall();
              } else {
                console.log(error.response.data, "error");
                if (
                  error?.response?.data
                    ?.toString()
                    .includes("Developer Inactive")
                ) {
                  api_tokens.forEach((token) => {
                    if (token.token === apiToken) {
                      token.isDeveloperInactive = true;
                    }
                  });
                }
                selectTokenAndCall();
              }
            });
        } catch (error) {
          console.log(error.message, "makeRequest");
        }
      };

      const selectTokenAndCall = () => {
        const tokenObject = api_tokens.filter((token) => {
          return (
            token.isUsed === false &&
            token.totalCallMade < 1000 &&
            !token.isDeveloperInactive
          );
        });

        if (tokenObject.length > 0) {
          tokenObject[0].isUsed = true;
          makeCall(tokenObject[0].token);
        } else {
          setTimeout(() => {
            selectTokenAndCall();
          }, 200);
        }
      };
      selectTokenAndCall();
    } catch (error) {
      console.log(error.message, "makeRequest");
    }
  });
};

setInterval(() => {
  api_tokens.forEach((token) => {
    if (token.isDeveloperInactive === true || token.totalCallMade >= 1000) {
      const makeCall = (apiToken) => {
        axiosInstance
          .get(url, {
            params: {
              api_key: apiToken,
            },
          })
          .then((data) => {
            token.isDeveloperInactive = false;
            token.totalCallMade = data.headers.parseInt(
              data.headers["x-plan-quota-current"]
            );
            resolve(data.data);
          })
          .catch((error) => {
            if (
              (error.response &&
                parseInt(error.response.headers["x-plan-quota-current"]) >
                  parseInt(error.response.headers["x-plan-quota-allotted"])) ||
              parseInt(error.response.headers["x-plan-quota-current"]) ===
                parseInt(error.response.headers["x-plan-quota-allotted"])
            ) {
              token.totalCallMade = parseInt(
                error.response.headers["x-plan-quota-current"]
              );
            } else {
              console.log(error.response.data, "error");
              console.log(error.message, "makeRequest");
              if (error.response.data.includes("Developer Inactive")) {
                token.isDeveloperInactive = true;
              }
            }
          });
      };
      makeCall(token.token);
    }
  });
}, 24 * 60 * 60 * 1000);

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
              resolve(connection);
            }
          } catch (error) {
            if (error.message.includes("ECONNREFUSED")) {
              // some email stuff goes here
            }
            reject(error);
            initializeConnection();
          }
        });
      } else {
        initializeConnection();
        connectToDb()
          .then((connection) => {
            resolve(connection);
          })
          .catch((error) => {
            console.log(error.message, "connectToDb");
          });
      }
    } catch (error) {
      console.log(error, "connectToDb");
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
      connectionLimit: 0,
      host: process.env.CLEVER_CLOUD_HOST || "localhost",
      user: process.env.CLEVER_CLOUD_USER || "root",
      password: process.env.CLEVER_CLOUD_PASSWORD || "",
      database: process.env.CLEVER_CLOUD_DATABASE_NAME || "dreamg",
      multipleStatements: true,
    });
  } catch (error) {
    console.log(error.message, "initializeConnection");
  }
};
initializeConnection();

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
      console.log(error.message, "cron databse function");
    }
  });
};

module.exports = { makeRequest, connectToDb, database };
