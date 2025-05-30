import MoodCheckIn from "../models/CheckIn";
import user from "../models/user";

// GET /profile/summary
export const getProfileSummary = async (req, res) => {
  res.json({
    totalCheckins: 0,
    lastCheckin: null,
    streak: 0,
  });
};

// GET /profile/emotion-trends
export const getEmotionTrends = async (req, res) => {
    res.sendStatus(200);
};

// GET /profile/recent-public-checkins
export const getRecentPublicCheckins = async (req, res) => {
    res.sendStatus(200);
};