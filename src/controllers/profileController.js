import UserModel from "../models/UserModel.js";
import MoodCheckIn from "../models/CheckIn.js";
import mongoose from "mongoose";


// /profile/emotion-trends
// /profile/recent-public-checkins
// TODO: Combine these into the summary

// GET /profile/summary
// req auth
export const getProfileSummary = async (req, res) => {
 try {
    const userId = req.user.sub;
    // basic user info (including email, excluding password)
    const user = await UserModel.findById(userId).select('username email profilePicture');

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }
    
    // Get total number of check-ins for this user
    const totalCheckins = await MoodCheckIn.countDocuments({ userId });
    // Get top mood (most frequent emotion)
    const topMood = await getTopMood(userId);
    // Calculate check-in streak (consecutive days with at least one check-in)
    const checkinStreak = await calculateCheckinStreak(userId);

    // Compile simplified profile summary
    const profileSummary = {
      username: user.username,
      email: user.email,
      profilePicture: user.profilePicture,
      totalCheckins,
      checkinStreak,
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

// GET /profile/analytics
export const getMoodAnalytics = async( req, res ) => {
  res.sendStatus(205);
};

//Helper Check in Streak calculator
const calculateCheckinStreak = async (userId) => {
  try {
    // Get all check-ins sorted by date (most recent first)
    const checkins = await MoodCheckIn.find({ userId })
      .select('timestamp')
      .sort({ timestamp: -1 })
      .lean();

    if (checkins.length === 0) return 0;

    let streak = 0;
    let currentDate = new Date();
    currentDate.setHours(0, 0, 0, 0); // Start from beginning of today

    // Check if there's a check-in today or yesterday to start the streak
    const mostRecentCheckin = new Date(checkins[0].timestamp);
    mostRecentCheckin.setHours(0, 0, 0, 0);
   
    const daysDiff = Math.floor((currentDate - mostRecentCheckin) / (1000 * 60 * 60 * 24));
   
    // If most recent check-in is more than 1 day old, streak is broken
    if (daysDiff > 1) return 0;
   
    // If most recent check-in was yesterday, start from yesterday
    if (daysDiff === 1) {
      currentDate.setDate(currentDate.getDate() - 1);
    }

    // Group check-ins by date
    const checkinsByDate = {};
    checkins.forEach(checkin => {
      const dateKey = new Date(checkin.timestamp).toDateString();
      checkinsByDate[dateKey] = true;
    });

    // Count consecutive days with check-ins
    while (checkinsByDate[currentDate.toDateString()]) {
      streak++;
      currentDate.setDate(currentDate.getDate() - 1);
    }

    return streak;
  } catch (error) {
    console.error('Error calculating check-in streak:', error);
    return 0;
  }
};
