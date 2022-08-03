const yup = require("yup");

const matchTypes = ["UPCOMING", "LIVE", "RECENT", "CANCELED"];

const getMatchesReqBodySchema = yup.object().shape({
  userId: yup.number("userId number must be a valid id").nullable().strict(),
  pageNumber: yup
    .number("page number must be a number")
    .min(1, "page number can not be zero of negative")
    .strict(),
  matchType: yup.string().oneOf(matchTypes, "match type is invalid").strict(),
});

const recentPlayedReqBodySchema = yup.object().shape({
  predictorId: yup
    .number("predictorId number must be a valid id")
    .nullable()
    .strict(),
  pageNumber: yup
    .number("page number must be a number")
    .min(1, "page number can not be zero of negative")
    .strict(),
});

const currentPlayedReqBodySchema = yup.object().shape({
  predictorId: yup
    .number("predictorId number must be a valid id")
    .nullable()
    .strict(),
  pageNumber: yup
    .number("page number must be a number")
    .min(1, "page number can not be zero of negative")
    .strict(),
});

module.exports = {
  getMatchesReqBodySchema,
  recentPlayedReqBodySchema,
  currentPlayedReqBodySchema,
};
