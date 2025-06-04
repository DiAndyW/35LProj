import UserModel from '../models/UserModel.js';
import mongoose from 'mongoose';

export const getUsernameById = async (req, res) => {
  const { userId } = req.params;

  // Validate if userId is a valid MongoDB ObjectId
  if (!mongoose.Types.ObjectId.isValid(userId)) {
    return res.status(400).json({ msg: 'Invalid User ID format' });
  }

  try {
    // Find the user by ID and select only the username field
    const user = await UserModel.findById(userId).select('username');

    if (!user) {
      return res.status(404).json({ msg: 'User not found' });
    }

    // Return the username
    res.json({ username: user.username });
  } catch (error) {
    console.error('Error fetching username by ID:', error);
    res.status(500).json({ msg: 'Server error while fetching username', details: error.message });
  }
};

export const blockAUser = async (req, res) => {
  const userId = req.user.sub;
  const blockedUserId = req.params.userId;

  // Validate if userId and blockedUserId are valid MongoDB ObjectIds
  if (!mongoose.Types.ObjectId.isValid(userId) || !mongoose.Types.ObjectId.isValid(blockedUserId)) {
    return res.status(400).json({ msg: 'Invalid User ID format' });
  }

  try {

    const user = await UserModel.findById(userId);

    if (!user) {
      return res.status(404).json({ msg: 'User not found' });
    }

    user.blockedUsers.push(blockedUserId);
    await user.save(); 

    res.json({ msg: 'User blocked successfully', blockedUserId });
  } catch (error) {
    console.error('Error blocking user:', error);
    res.status(500).json({ msg: 'Server error while blocking user', details: error.message });
  }
}