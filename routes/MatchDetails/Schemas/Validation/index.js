const yup = require("yup");

const filterTypes = ["MOST_VIEWED", "MOST_LIKED", "MOST_POPULAR"];

const getPredictionsReqBodySchema = yup.object().shape({
  matchId: yup.number("matchId must be a valid id").nullable(),
  filter: yup
    .string("filter must be a string")
    .nullable()
    .oneOf(filterTypes, "filter must be a valid filter"),
  pageNumber: yup
    .number("pageNumber must be a number")
    .min(1, "page number can not be zero or negative")
    .required(),
});

const getExpertPredictorBodySchema = yup.object().shape({
  matchId: yup.number("matchId must be a valid id").required().strict(),
});

const compareTeamsBodySchema = yup.object().shape({
  matchId: yup.number("matchId must be a valid id").required().strict(),
});

const getPlayersBodySchema = yup.object().shape({
  matchId: yup.number("matchId must be a valid id").required().strict(),
  userTeamId: yup.number("teamId must be a valid id").default(0).strict(),
});

module.exports = {
  getPredictionsReqBodySchema,
  getExpertPredictorBodySchema,
  compareTeamsBodySchema,
  getPlayersBodySchema,
};
