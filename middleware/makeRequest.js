const axios = require("axios");
const {
  tokens: { apiTokens: api_tokens },
} = require("../tokens");

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
const makeRequestForSportRadar = (url) => {
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
                if (
                  error?.response?.data
                    ?.toString()
                    .includes("Developer Inactive")
                ) {
                  api_tokens.forEach((token) => {
                    if (token.token === apiToken) {
                      token.isDeveloperInactive = true;
                      token.isUsed = false;
                    }
                  });
                }
                selectTokenAndCall();
              }
            });
        } catch (error) {
          console.log(error, "makeRequest");
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
      console.log(error, "makeRequest");
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
              console.log(error, "makeRequest");
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

//
// creating instances for unofficial crickbuzz
//
//
//

const unofficialCrickbuzzInstance = axios.create({
  baseURL: "https://unofficial-cricbuzz.p.rapidapi.com",
  headers: {
    "X-RapidAPI-Host": "unofficial-cricbuzz.p.rapidapi.com",
    "X-RapidAPI-Key": "66b069e400mshc107d698affea10p12397ajsn817b027dfc99",
  },
});

const makeRequestForUC = (url, data) => {
  return new Promise((resolve, reject) => {
    unofficialCrickbuzzInstance
      .get(url, {
        params: {
          ...data,
        },
      })
      .then((data) => {
        resolve(data.data);
      })
      .catch((error) => {
        reject(error);
      });
  });
};

module.exports = {
  makeRequest: makeRequestForSportRadar,
  makeRequestForUC,
};
