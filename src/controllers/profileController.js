import UserModel from "../models/UserModel.js";

// GET /profile/summary
// req auth
export const getProfileSummary = async (req, res) => {
 try {
    const userId = req.user.sub;

    // Get user basic info (including email, excluding password)
    const user = await UserModel.findById(userId).select('username email profilePicture');
    
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
      profilePicture: user.profilePicture
    };

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
