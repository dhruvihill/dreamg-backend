const { makeRequestForUC } = require("../../middleware/makeRequest");
const { connectToDb, database } = require("../../middleware/dbSuperUser");

class ImagePlayer {
  ucId = 0;
  name = "";
  imageId = 0;
  dateOfBirth = "";

  constructor(id) {
    this.ucId = id;
  }

  fetchPlayer() {
    return new Promise(async (resolve, reject) => {
      try {
        const player = await makeRequestForUC("/players/get-info", {
          playerId: this.ucId.toString(),
        });

        if (
          player &&
          player.id &&
          player.name &&
          player.DoBFormat &&
          player.faceImageId &&
          player.faceImageId !== "0"
        ) {
          this.name = player.name;
          this.imageId = player.faceImageId;

          let month = player.DoBFormat.split(" ")[0].toLowerCase();
          const date = player.DoBFormat.split(" ")[1].split(","[0])[0];
          const year = player.DoBFormat.split(", ")[1];

          switch (month) {
            case "january":
              month = 1 - 1;
              break;
            case "february":
              month = 2 - 1;
              break;
            case "march":
              month = 3 - 1;
              break;
            case "april":
              month = 4 - 1;
              break;
            case "may":
              month = 5 - 1;
              break;
            case "june":
              month = 6 - 1;
              break;
            case "july":
              month = 7 - 1;
              break;
            case "august":
              month = 8 - 1;
              break;
            case "september":
              month = 9 - 1;
              break;
            case "october":
              month = 10 - 1;
              break;
            case "november":
              month = 11 - 1;
              break;
            case "december":
              month = 12 - 1;
              break;
            default:
              month = 0;
              break;
          }
          const newDate = new Date(
            parseInt(year),
            parseInt(month),
            parseInt(date)
          ).getTime();
          this.dateOfBirth = newDate;
        } else {
          throw new Error("Player has no image");
        }

        resolve();
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }

  storePlayer() {
    return new Promise(async (resolve, reject) => {
      try {
        const connection = await connectToDb();

        const [{ isExists }] = await database(
          "SELECT COUNT(*) AS isExists FROM playerImages WHERE playerImages.ucPlayerId = ?;",
          [this.ucId],
          connection
        );

        if (!isExists) {
          const insertPlayer = await database(
            "INSERT INTO `playerImages`(`ucPlayerId`, `name`, `dateOfBirth`, `imageId`) VALUES (?, ?, ?, ?);",
            [this.ucId, this.name, this.dateOfBirth, this.imageId],
            connection
          );
          connection.release();
          resolve();
        } else {
          connection.release();
          resolve();
        }
      } catch (error) {
        console.log(error.message);
        reject(error);
      }
    });
  }
}

const a = async () => {
  try {
    const player = new ImagePlayer(6635);
    await player.fetchPlayer();
    await player.storePlayer();
  } catch (error) {
    console.log(error);
  }
};
