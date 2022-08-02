const morgan = require("morgan");
const morganBody = require("morgan-body");
const path = require("path");
const rfs = require("rotating-file-stream");

const logger = (app) => {
  const accessLogStream = rfs.createStream("express.log", {
    interval: "1d", // rotate daily
    path: path.join(__dirname, "../", "logs"),
  });

  // log requests to console
  app.use(
    morgan(
      ":date[web] :method :url :status :res[content-length] - :response-time ms",
      {
        stream: accessLogStream,
      }
    )
  );

  // log requests-response to file
  morganBody(app);
};

module.exports = logger;
