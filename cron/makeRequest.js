const axios = require("axios");

const api_tokens = [
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
];

const createInstance = () => {
  return axios.create({
    baseURL: "https://api.sportradar.us/cricket-t2/en/",
  });
};
let axiosInstance = createInstance();

const generateTimeOut = (token, quotaUsed, delay) => {
  console.log("called");
  setTimeout(() => {
    api_tokens.forEach((api_token) => {
      if (api_token.token === token) {
        api_token.isUsed = false;
        api_token.totalCallMade = quotaUsed;
        console.log(api_tokens);
      }
    });
  }, delay);
};

// Axios request
const makeRequest = (url) => {
  return new Promise((resolve, reject) => {
    try {
      const makeCall = (apiToken) => {
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
                  parseInt(error.response.headers["x-plan-quota-allotted"])) ||
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
              console.log(error.message, "makeRequest");
              if (error.response.data.includes("Developer Inactive")) {
                api_tokens.forEach((token) => {
                  if (token.token === apiToken) {
                    token.isDeveloperInactive = true;
                  }
                });
              }
              selectTokenAndCall();
            }
          });
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

module.exports = makeRequest;
