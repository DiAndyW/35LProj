import UserModel from "../models/UserModel.js";
import MoodCheckIn from "../models/CheckIn.js";
import mongoose from "mongoose";

// GET /profile/summary
// req auth
export const getProfileSummary = async (req, res) => {
 try {
    const userId = req.user.sub;
    // basic user info (including email, excluding password)
    const user = await UserModel.findById(userId)
      .select('username email profilePicture');

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
    // Get the 3 most recent checkins
    const recentCheckins = await MoodCheckIn.find({ userId })
      .select('emotion.name emotion.attributes timestamp')
      .sort({timestamp: -1})
      .limit(3)
      .lean();
    // Get weekly summary data
    const weeklySummary = await getWeeklySummary(userId);

    // Compile simplified profile summary
    const profileSummary = {
      username: user.username,
      email: user.email,
      profilePicture: user.profilePicture,
      totalCheckins,
      checkinStreak,
      topMood,
      recentCheckins,
      weeklySummary,
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

// GET /profile/analytics
// for stats
// average mood over past week, month, 3 months, year (DONE)
// avergae mood on each day of the week,
// average mood when doing each logged activity,
// average mood when with each logged person.,
// distribution of mood types (by attributes), (LATER)
// distribution of mood for 1-4 (LATER)
// there might be possible redundancy in the code, will overlook for now.

export const getMoodAnalytics = async (req, res) => {
  try {
    const userId = req.user.sub;
    const { period = '3months' } = req.query;

    // Calculate date range for the requested period
    const dateRange = getDateRange(period);
    if (!dateRange) {
      return res.status(400).json({
        success: false,
        message: 'Invalid period. Valid options: week, month, 3months, year, all'
      });
    }

    // Get average mood for the specific time period
    const averageMoodForPeriod = await getAverageMoodForPeriod(userId, period, dateRange);

    res.status(200).json({
      success: true,
      data: {
        period,
        dateRange: {
          start: dateRange.start,
          end: dateRange.end
        },
        averageMoodForPeriod
      }
    });

  } catch (error) {
    console.error('Error fetching mood analytics:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch mood analytics',
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

const getWeeklySummary = async (userId) => {
  try {
    //determine when the start of the week was
    const currentDate = new Date();
    const currentDay = currentDate.getDay();
    //if currentday is 0, then its sunday, return 6, otherwise return currenday-1
    const daysSinceMonday = (currentDay === 0 ? 6 : currentDay - 1);
  
    const startOfWeek = new Date(currentDate);
    startOfWeek.setDate(currentDate.getDate() - daysSinceMonday);
    startOfWeek.setHours(0, 0, 0, 0); // Start of this Monday
  
    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(startOfWeek.getDate() + 7); // next monday
    endOfWeek.setHours(0, 0, 0, 0);

    // Use aggregation pipeline to get both count and top mood for week
    const weeklyCheckins = await MoodCheckIn.aggregate([
      { $match: { 
          userId: new mongoose.Types.ObjectId(userId),
          timestamp: {
            $gte: startOfWeek,
            $lt: endOfWeek
          }
        }
      },
      {
        $facet: {
          // Get total count
          totalCount: [ { $count: "count" } ],
          // Get top emotion
          topEmotion: [
            {
              $group: {
                _id: '$emotion.name',
                count: { $sum: 1 },
              }
            },
            { $sort: { count: -1 } },
            { $limit: 1 }
          ]
        }
      }
    ]);

    const weeklyCheckinsCount = weeklyCheckins[0].totalCount[0]?.count || 0;
    const topEmotionResult = weeklyCheckins[0].topEmotion;

    if (topEmotionResult.length === 0) {
      return {
        weeklyCheckinsCount,
        weeklyTopMood: null
      };
    }

    return {
      weeklyCheckinsCount,
      weeklyTopMood: {
        name: topEmotionResult[0]._id,
        count: topEmotionResult[0].count,
      }
    };
  } catch (error) {
    console.error('Error getting weekly stats:', error);
    return {
      weeklyCheckinsCount: 0,
      weeklyTopMood: null
    };
  }
};

// Get average mood for a specific time period
// TODO: Possibly implement closest match emotion finder for avg mood, need a copy of every single mood and their values?
const getAverageMoodForPeriod = async (userId, period, dateRange) => {
  const match = {
    userId: new mongoose.Types.ObjectId(userId),
    ...(dateRange.start && { timestamp: { $gte: dateRange.start, $lt: dateRange.end } })
  };

  const avgMood = await MoodCheckIn.aggregate([
    { $match: match },
    {
      $group: {
        _id: null,
        avgPleasantness: { $avg: '$emotion.attributes.pleasantness' },
        avgIntensity: { $avg: '$emotion.attributes.intensity' },
        avgControl: { $avg: '$emotion.attributes.control' },
        avgClarity: { $avg: '$emotion.attributes.clarity' },
        totalCheckins: { $sum: 1 },
        emotions: { $push: '$emotion.name' }
      }
    }
  ]);

  if (avgMood.length === 0) {
    return {
      averageAttributes: {
        pleasantness: null,
        intensity: null,
        control: null,
        clarity: null
      },
      totalCheckins: 0,
      topEmotion: null,
      topEmotionCount: 0
    };
  }

  // Calculate most common emotion for this period
  // possibly unnecessary, included currently if Frontend needs it
  const emotionCounts = {};
  avgMood[0].emotions.forEach(emotion => {
    emotionCounts[emotion] = (emotionCounts[emotion] || 0) + 1;
  });
  
  const topEmotion = Object.entries(emotionCounts)
    .sort(([,a], [,b]) => b - a)[0];

  return {
    averageAttributes: {
      pleasantness: Math.round((avgMood[0].avgPleasantness || 0) * 100) / 100,
      intensity: Math.round((avgMood[0].avgIntensity || 0) * 100) / 100,
      control: Math.round((avgMood[0].avgControl || 0) * 100) / 100,
      clarity: Math.round((avgMood[0].avgClarity || 0) * 100) / 100
    },
    totalCheckins: avgMood[0].totalCheckins,
    topEmotion: topEmotion ? topEmotion[0] : null,
    topEmotionCount: topEmotion ? topEmotion[1] : 0
  };
};

// Helper function to calculate date ranges
const getDateRange = (period) => {
  const now = new Date();
  const end = new Date(now);
  end.setHours(23, 59, 59, 999); // EOD

  let start;
  
  switch (period) {
    case 'week':
      start = new Date(now);
      start.setDate(now.getDate() - 7);
      break;
    case 'month':
      start = new Date(now);
      start.setMonth(now.getMonth() - 1);
      break;
    case '3months':
      start = new Date(now);
      start.setMonth(now.getMonth() - 3);
      break;
    case 'year':
      start = new Date(now);
      start.setFullYear(now.getFullYear() - 1);
      break;
    case 'all':
      return { start: null, end: null }; 
    default:
      return null; // Invalid period
  }
  
  start.setHours(0, 0, 0, 0); 
  return { start, end };
};

