const express = require("express");
const router = express.Router();
const verifyUser = require("../middleware/verifyUser");
const verifyProfile = require("../middleware/verifyProfile");
const upload = require("express-fileupload");
const { convertToYYYYMMDD } = require("../middleware/convertTimeZone");
const User = require("../module/User/User");
const UserBank = require("../module/User/UserBank");
const UserPan = require("../module/User/UserPan");

// fetching user data
router.post("/userProfile", verifyUser, async (req, res) => {
  try {
    const { predictorId } = req.body;
    const serverAddress = `${req.protocol}://${req.headers.host}`;
    const timeZone = req.headers.timezone;

    if (!/[^0-9]/g.test(predictorId)) {
      const newUser = new User(predictorId);
      await newUser.fetchUserDetails(serverAddress);
      await newUser.fetchUserPointDetails();
      await newUser.fetchUserMatchesDetails(serverAddress, timeZone);
      await newUser.fetchUserApplications();

      delete newUser.userDetails.imageStamp;
      res.status(200).json({
        status: true,
        message: "success",
        data: {
          userDetails: {
            userId: newUser.id,
            ...newUser.userDetails,
            ...newUser.userPointsDetails,
          },
          applications: {
            userApplication: newUser.userApplications,
            applicationStatus: newUser.applicationStatus,
          },
          recentPlayed: newUser.userMatchDetails.recentMatches,
          currentPlayed: newUser.userMatchDetails.currentMatch,
        },
      });
    } else {
      throw { message: "invalid input" };
    }
  } catch (error) {
    res.status(200).json({
      status: false,
      message: error.message,
      data: {},
    });
  }
});

// Inserting firstname lastname in user
router.post("/updateProfile", verifyUser, verifyProfile, async (req, res) => {
  const body = req.body;

  try {
    const newUser = new User(body.userId);
    await newUser.updateUserDetails(body);

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        ...this.userDetails,
        ...this.userPointsDetails,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: false,
      message: error.message,
      data: {},
    });
  }
});

router.post("/uploadProfilePicture", upload(), verifyUser, async (req, res) => {
  const { userId } = req.body;

  try {
    if (!req.files) {
      throw { message: "no file found" };
    }

    const newUser = new User(userId);
    await newUser.uploadProfileImage(req.files.profilePicture.data);

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        profilePicture: `${req.protocol}://${req.headers.host}${process.env.USER_IMAGE_URL}${newUser.userDetails.imageStamp}.jpg`,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: false,
      message: "some error occured",
      data: {},
    });
  }
});

router.post("/uploadPanDetails", upload(), verifyUser, async (req, res) => {
  try {
    const { userId, userPanFullName, userPanNumber, userDateOfBirth } =
      req.body;

    if (!req.files) {
      throw { message: "no file found" };
    }

    const panProofImage = req.files.panProofImage.data;

    const panUser = new UserPan(userId);
    await panUser.InsertUserPanDetails(
      userPanFullName,
      userPanNumber,
      convertToYYYYMMDD(userDateOfBirth),
      panProofImage
    );

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        status: panUser.defaulteStatus,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: false,
      message:
        error.code === "ER_DUP_ENTRY" ? "Duplicate Entry" : error.message,
      data: {},
    });
  }
});

router.post("/uploadBankDetails", upload(), verifyUser, async (req, res) => {
  try {
    const {
      userId,
      userBankName,
      userBankAccountNumber,
      userBankIFSC,
      userFullName,
      userUPI,
    } = req.body;

    if (!req.files) {
      throw { message: "no file found" };
    }

    const bankProofImage = req.files.bankProofImage.data;

    const bankUser = new UserBank(userId);
    await bankUser.InsertUserBankDetails(
      userBankName,
      userBankAccountNumber,
      userBankIFSC,
      userFullName,
      userUPI,
      bankProofImage
    );

    res.status(200).json({
      status: true,
      message: "success",
      data: {
        status: bankUser.defaulteStatus,
      },
    });
  } catch (error) {
    res.status(400).json({
      status: false,
      message:
        error.code === "ER_DUP_ENTRY" ? "Duplicate Entry" : error.message,
      data: {},
    });
  }
});

// exporting router
module.exports = router;
