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
  if (userId === blockedUserId) {
    return res.status(400).json({ msg: 'You cannot block yourself' });
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

// PATCH - Make a user an admin
export const makeAdmin = async (req, res) => {
  const { userId } = req.params;

  // Validate if userId is a valid MongoDB ObjectId
  if (!mongoose.Types.ObjectId.isValid(userId)) {
    return res.status(400).json({ msg: 'Invalid User ID format' });
  }

  try {
    // Find the user by ID
    const user = await UserModel.findById(userId);

    if (!user) {
      return res.status(404).json({ msg: 'User not found' });
    }

    // Check if the user is already an admin
    if (user.isAdmin) {
      return res.status(400).json({ msg: 'User is already an admin' });
    }

    // Update the user's admin status
    user.isAdmin = true;
    await user.save();

    res.json({ msg: 'User has been made an admin', userId });
  } catch (error) {
    console.error('Error making user an admin:', error);
    res.status(500).json({ msg: 'Server error while making user an admin', details: error.message });
  }
}

// Get blocked users list
export const getBlockedUsers = async (req, res) => {
  const userId = req.user.sub;

  // Validate if userId is a valid MongoDB ObjectId
  if (!mongoose.Types.ObjectId.isValid(userId)) {
    return res.status(400).json({ msg: 'Invalid User ID format' });
  }

  try {
    const user = await UserModel.findById(userId).select('blockedUsers');

    if (!user) {
      return res.status(404).json({ msg: 'User not found' });
    }

    // Manually fetch blocked users details
    const blockedUsers = await UserModel.find(
      { _id: { $in: user.blockedUsers } },
      { username: 1, _id: 1 }
    );

    res.json({ 
      blockedUsers: blockedUsers,
      count: blockedUsers.length 
    });
  } catch (error) {
    console.error('Error fetching blocked users:', error);
    res.status(500).json({ msg: 'Server error while fetching blocked users', details: error.message });
  }
};

// Unblock a user
export const unblockAUser = async (req, res) => {
  const userId = req.user.sub;
  const unblockedUserId = req.params.userId;

  // Validate if userId and unblockedUserId are valid MongoDB ObjectIds
  if (!mongoose.Types.ObjectId.isValid(userId) || !mongoose.Types.ObjectId.isValid(unblockedUserId)) {
    return res.status(400).json({ msg: 'Invalid User ID format' });
  }

  if (userId === unblockedUserId) {
    return res.status(400).json({ msg: 'You cannot unblock yourself' });
  }

  try {
    const user = await UserModel.findById(userId);

    if (!user) {
      return res.status(404).json({ msg: 'User not found' });
    }

    // Check if the user is actually blocked
    const blockedIndex = user.blockedUsers.indexOf(unblockedUserId);
    if (blockedIndex === -1) {
      return res.status(400).json({ msg: 'User is not in your blocked list' });
    }

    // Remove the user from blocked list
    user.blockedUsers.splice(blockedIndex, 1);
    await user.save();

    res.json({ msg: 'User unblocked successfully', unblockedUserId });
  } catch (error) {
    console.error('Error unblocking user:', error);
    res.status(500).json({ msg: 'Server error while unblocking user', details: error.message });
  }
};
