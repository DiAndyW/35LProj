import UserModel from "../models/UserModel.js";
import MoodCheckIn from "../models/CheckIn.js";
import mongoose from "mongoose";

// GET /profile/summary
// req auth
export const getProfileSummary = async (req, res) => {
 try {
    const userId = req.user.sub;

    // Get user basic info (including email, excluding password)
    const user = await UserModel.findById(userId).select('username email profilePicture');
    
    // Get top mood (most frequent emotion)
    const topMood = await getTopMood(userId);

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Compile simplified profile summary
    const profileSummary = {
      username: user.username,
      email: user.email,
      profilePicture: user.profilePicture,
      topMood,
    };

    console.log(profileSummary);

    res.status(200).json({
      success: true,
      data: profileSummary
    });

  } catch (error) {
    console.error('Error fetching profile summary:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch profile summary',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
};
 
// GET /profile/emotion-trends
export const getEmotionTrends = async (req, res) => {
    res.sendStatus(200);
};

// GET /profile/recent-public-checkins
export const getRecentPublicCheckins = async (req, res) => {
    res.sendStatus(200);
};

//Helper Get Top Mood Function
const getTopMood = async (userId) => {
  try {
    const topMoodResult = await MoodCheckIn.aggregate([
      { $match: { userId: new mongoose.Types.ObjectId(userId) } },
      {
        $group: {
          _id: '$emotion.name',
          count: { $sum: 1 },
          // Get the most recent attributes for this emotion
          latestAttributes: { $last: '$emotion.attributes' }
        }
      },
      { $sort: { count: -1 } },
      { $limit: 1 }
    ]);

    if (topMoodResult.length === 0) return null;

    return {
      name: topMoodResult[0]._id,
      count: topMoodResult[0].count,
      attributes: topMoodResult[0].latestAttributes
    };
  } catch (error) {
    console.error('Error getting top mood:', error);
    return null;
  }
};
