import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import UserModel from '../models/UserModel.js';
import crypto from 'crypto';
import nodemailer from 'nodemailer';
import MoodCheckIn from '../models/CheckIn.js';
import mongoose from 'mongoose';

const strongPwd = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*\W).{10,}$/;

export const register = async (req, res) => {
  const { username, email, password } = req.body;

  if (!strongPwd.test(password)) {
    return res.status(400).json({ msg: 'Weak password' });
  }

  try {
    console.log('Attempting to create user with:', { username, email }); // Log before create
    const user = await UserModel.create({ username, email, password });
    console.log('User created successfully:', user.id); // Log after successful create
    res.status(201).json({ id: user.id, username, email });
  } catch (err) {
    console.error('Registration error details:', err);
    if (err.code === 11000) {
      return res.status(409).json({ msg: 'Email or username taken' });
    }
    res.status(500).json({ msg: 'Registration failed', details: err.message || 'Unknown error' });
  }
};

export const login = async (req, res) => {
  const { email, password } = req.body;
  const user = await UserModel.findOne({ email }).select('+password');
  console.log('User found:', !!user);
  if (user) console.log('User ID:', user._id);
  if (!user) return res.status(401).json({ msg: 'Invalid credentials' });

  console.log('Stored hash:', user.password);
  console.log('Plain password:', password);

  const ok = await bcrypt.compare(password, user.password);
  if (!ok) return res.status(401).json({ msg: 'Invalid credentials' });
  console.log('Password match:', ok);

  const access = jwt.sign({ sub: user.id, isAdmin: user.isAdmin }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '365d' });
  const refresh = jwt.sign({ sub: user.id, isAdmin: user.isAdmin }, process.env.JWT_SECRET, { expiresIn: '7d' });
  res.json({ access, refresh });
};

export const refreshToken = async (req, res) => {
  try {
    const authHeader = req.headers.authorization;
    const token = authHeader?.split(' ')[1];

    if (!token) {
      return res.status(401).json({ msg: 'No refresh token provided' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Check if user exists and is active
    const user = await User.findById(decoded.sub);
    if (!user || !user.isActive) {
      return res.status(401).json({ msg: 'User not found or inactive' });
    }

    // Update last activity
    user.lastLogin = new Date();
    await user.save();

    // Generate new tokens
    const access = jwt.sign(
      { sub: user.id, isAdmin: user.isAdmin },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
    );

    // Refresh token gets renewed each time it's used
    const refresh = jwt.sign(
      { sub: user.id, isAdmin: user.isAdmin },
      process.env.JWT_SECRET,
      { expiresIn: '30d' } // 30 days from NOW
    );

    res.json({ access, refresh });
  } catch (err) {
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ msg: 'Refresh token expired' });
    }
    if (err.name === 'JsonWebTokenError') {
      return res.status(401).json({ msg: 'Invalid refresh token' });
    }
    console.error('Token refresh error:', err);
    res.status(500).json({ msg: 'Server error during token refresh' });
  }
};

export const logout = async (req, res) => {
  // Simple logout for now
  // In production, you might want to blacklist the token or remove it from a whitelist
  res.json({ msg: 'Logged out successfully' });
};

// Update your authController.js

export const forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email: email.toLowerCase() });

    if (!user) {
      console.log(`[Forgot PW] Attempt to reset for non-existent or case-mismatched email: ${email}`);
      return res.json({
        msg: 'If an account exists with this email, you will receive a verification code.'
      });
    }

    const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
    const hashedCode = crypto
      .createHash('sha256')
      .update(resetCode) // Hashing the PLAIN code
      .digest('hex');

    user.passwordResetToken = hashedCode;
    user.passwordResetExpires = Date.now() + 900000; // 15 minutes
    await user.save();

    console.log(`[Forgot PW] User: ${user.email}`);
    console.log(`[Forgot PW] Generated Plain Code (emailed): ${resetCode}`);
    console.log(`[Forgot PW] Stored Hashed Code: ${user.passwordResetToken}`);
    console.log(`[Forgot PW] Stored Expiry: ${user.passwordResetExpires} (Current Time for ref: ${Date.now()})`);

    // Email configuration (ensure EMAIL_USER and EMAIL_PASS are correctly set in .env)
    const transporter = nodemailer.createTransport({
      service: 'gmail', // Or your email provider
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
      }
    });

    const mailOptions = {
      from: `"Morii Support" <${process.env.EMAIL_USER}>`,
      to: email,
      subject: 'Password Reset Code - Morii',
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2 style="color: #333;">Password Reset Code</h2>
          <p>Hi ${user.username || 'there'},</p>
          <p>Your password reset code is:</p>
          <div style="background: #f5f5f5; padding: 30px; text-align: center; margin: 30px 0; border-radius: 10px;">
            <span style="font-size: 36px; letter-spacing: 8px; font-weight: bold; color: #333;">
              ${resetCode}
            </span>
          </div>
          <p>Enter this code in the Morii app to reset your password.</p>
          <p><strong>This code expires in 15 minutes.</strong></p>
          <p>If you didn't request this code, please ignore this email.</p>
        </div>
      `
    };

    await transporter.sendMail(mailOptions);
    res.json({
      msg: 'If an account exists with this email, you will receive a verification code.'
    });

  } catch (error) {
    console.error('[Forgot PW] Error:', error);
    res.status(500).json({ msg: 'Error processing password reset request' });
  }
};

export const resetPasswordWithCode = async (req, res) => {
  try {
    const { email, code, newPassword } = req.body;

    console.log(`[Reset PW] Attempt for email: ${email ? email.toLowerCase() : 'undefined'}`);
    console.log(`[Reset PW] Received Plain Code from Client: "${code}"`); // Log code to see its exact form

    if (!email || !code || !newPassword) {
      console.log('[Reset PW] Missing email, code, or newPassword in request body');
      return res.status(400).json({ msg: 'Missing required fields' });
    }

    // Validate password strength
    if (!strongPwd.test(newPassword)) {
      console.log('[Reset PW] Weak password attempt.');
      return res.status(400).json({ msg: 'Weak password. Password must be at least 10 characters long and include uppercase, lowercase, digit, and special character.' });
    }

    // Hash the provided code from client
    // Ensure `code` is a string, which it should be from JSON parsing a string value
    const hashedCodeFromClientInput = crypto
      .createHash('sha256')
      .update(String(code)) // Explicitly ensure it's a string, though likely already is
      .digest('hex');
    console.log(`[Reset PW] Hashed code from client input: ${hashedCodeFromClientInput}`);
    const currentTime = Date.now();
    console.log(`[Reset PW] Current Time for Expiry Check: ${currentTime}`);

    // Find user with valid, non-expired reset code
    const user = await User.findOne({
      email: email.toLowerCase(),
      passwordResetToken: hashedCodeFromClientInput,
      passwordResetExpires: { $gt: currentTime }
    });

    if (!user) {
      console.log(`[Reset PW] User not found with matching code/expiry. Query Params:`);
      console.log(`[Reset PW]   - Email: ${email.toLowerCase()}`);
      console.log(`[Reset PW]   - Hashed Code from Client: ${hashedCodeFromClientInput}`);
      console.log(`[Reset PW]   - Expiry Condition: > ${currentTime}`);

      // Further debugging: Check if user exists but token/expiry is the issue
      const existingUser = await User.findOne({ email: email.toLowerCase() });
      if (existingUser) {
        console.log(`[Reset PW] User ${email.toLowerCase()} DOES exist. Checking token/expiry details:`);
        console.log(`[Reset PW]   - Stored Token: ${existingUser.passwordResetToken || 'Not set'}`);
        console.log(`[Reset PW]   - Stored Expiry: ${existingUser.passwordResetExpires || 'Not set'} (${existingUser.passwordResetExpires ? (existingUser.passwordResetExpires > currentTime ? 'VALID' : 'EXPIRED') : 'N/A'})`);
        if (existingUser.passwordResetToken !== hashedCodeFromClientInput) {
          console.error(`[Reset PW] CRITICAL: HASH MISMATCH!`);
          console.error(`[Reset PW]   Client Hashed: ${hashedCodeFromClientInput}`);
          console.error(`[Reset PW]   Stored Hashed: ${existingUser.passwordResetToken}`);
        }
      } else {
        console.log(`[Reset PW] User with email ${email.toLowerCase()} does not exist at all.`);
      }
      return res.status(400).json({ msg: 'Invalid or expired code' });
    }

    // Update password
    user.password = newPassword; // Mongoose pre-save hook in User model should hash this
    user.passwordResetToken = undefined; // Clear the token
    user.passwordResetExpires = undefined; // Clear the expiry
    user.lastLogin = new Date(); // Optional: update last login or password change date
    await user.save();

    console.log(`[Reset PW] Password reset successful for ${user.email}`);
    res.json({ msg: 'Password reset successful' });

  } catch (error) {
    console.error('[Reset PW] Error:', error);
    res.status(500).json({ msg: 'Error resetting password' });
  }
};

export const deleteAccount = async (req, res) => {
  const session = await mongoose.startSession();
  try {
    await session.withTransaction(async () => {
      const userId = req.user.sub;
      const delAccount = await UserModel.deleteOne({ _id: userId }, { session });
      const delCheckins = await MoodCheckIn.deleteMany({ userId }, { session });
      
      if (delAccount.deletedCount === 0) {
        throw new Error('User not found');
      }
      
      const response = {
        delAccount,
        delCheckins
      };

      res.status(200).json({
        success: true,
        data: response,
        message: 'Account successfully deleted'
      });
    });
  } catch (error) {
    console.error('Error deleting account:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete account',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  } finally {
    await session.endSession();
  }
};

export const updateNotificationPreferences = async (req, res) => {
  const userId = req.user.sub;

  if (!userId) {
    return res.status(401).json({ msg: 'User not authenticated and no testing ID provided.' });
  }

  const {
    pushNotificationsEnabled,
    notificationHourPST,
    notificationMinutePST
  } = req.body;

  if (typeof pushNotificationsEnabled !== 'boolean') {
    return res.status(400).json({ msg: 'Invalid value for pushNotificationsEnabled. Must be true or false.' });
  }
  if (notificationHourPST !== undefined && (typeof notificationHourPST !== 'number' || notificationHourPST < 0 || notificationHourPST > 23)) {
    return res.status(400).json({ msg: 'Invalid value for notificationHourPST. Must be a number between 0 and 23.' });
  }
  if (notificationMinutePST !== undefined && (typeof notificationMinutePST !== 'number' || notificationMinutePST < 0 || notificationMinutePST > 59)) {
    return res.status(400).json({ msg: 'Invalid value for notificationMinutePST. Must be a number between 0 and 59.' });
  }

  try {
    const user = await UserModel.findById(userId);

    if (!user) {
      return res.status(404).json({ msg: 'User not found' });
    }

    user.preferences.pushNotificationsEnabled = pushNotificationsEnabled;

    if (pushNotificationsEnabled) {
      user.preferences.notificationHourPST = notificationHourPST !== undefined ? notificationHourPST : user.preferences.notificationHourPST;
      user.preferences.notificationMinutePST = notificationMinutePST !== undefined ? notificationMinutePST : user.preferences.notificationMinutePST;
    }

    await user.save();

    res.json({
      msg: 'Notification preferences updated successfully',
      preferences: user.preferences
    });

  } catch (error) {
    console.error('Error updating notification preferences:', error);
    res.status(500).json({ msg: 'Server error while updating preferences', details: error.message });
  }
};

export const updateFCMToken = async (req, res) => {
  const userId = req.user.sub;

  if (!userId) {
    return res.status(401).json({ msg: 'User not authenticated and no testing ID provided.' });
  }

  const { fcmToken } = req.body;

  if (!fcmToken || typeof fcmToken !== 'string' || fcmToken.trim() === '') {
    return res.status(400).json({ msg: 'fcmToken is required and must be a non-empty string.' });
  }

  try {
    const updatedUser = await UserModel.findByIdAndUpdate(
      userId,
      { $set: { fcmToken: fcmToken.trim() } },
      { new: true, runValidators: true }
    ).select('username email fcmToken');

    if (!updatedUser) {
      return res.status(404).json({ msg: 'User not found' });
    }

    res.json({
      msg: 'FCM token updated successfully',
      fcmToken: updatedUser.fcmToken
    });

  } catch (error) {
    console.error('Error updating FCM token:', error);
    res.status(500).json({ msg: 'Server error while updating FCM token', details: error.message });
  }
};

// Add these endpoints to your authController.js

export const changeUsername = async (req, res) => {
  const userId = req.user.sub;
  const { newUsername, currentPassword } = req.body;

  if (!newUsername || !currentPassword) {
    return res.status(400).json({ msg: 'New username and current password are required' });
  }

  if (newUsername.trim().length < 3) {
    return res.status(400).json({ msg: 'Username must be at least 3 characters long' });
  }

  try {
    // Get user with password for verification
    const user = await UserModel.findById(userId).select('+password');
    if (!user) {
      return res.status(404).json({ msg: 'User not found' });
    }

    // Verify current password
    const passwordMatch = await bcrypt.compare(currentPassword, user.password);
    if (!passwordMatch) {
      return res.status(401).json({ msg: 'Current password is incorrect' });
    }

    // Check if username is already taken
    const existingUser = await UserModel.findOne({ 
      username: newUsername.trim(),
      _id: { $ne: userId } // Exclude current user
    });
    
    if (existingUser) {
      return res.status(409).json({ msg: 'Username is already taken' });
    }

    // Update username
    user.username = newUsername.trim();
    await user.save();

    res.json({
      msg: 'Username updated successfully',
      username: user.username
    });

  } catch (error) {
    console.error('Error updating username:', error);
    if (error.code === 11000) {
      return res.status(409).json({ msg: 'Username is already taken' });
    }
    res.status(500).json({ msg: 'Server error while updating username' });
  }
};

export const changePassword = async (req, res) => {
  const userId = req.user.sub;
  const { currentPassword, newPassword } = req.body;

  if (!currentPassword || !newPassword) {
    return res.status(400).json({ msg: 'Current password and new password are required' });
  }

  if (!strongPwd.test(newPassword)) {
    return res.status(400).json({ 
      msg: 'New password must be at least 10 characters long and include uppercase, lowercase, digit, and special character' 
    });
  }

  try {
    // Get user with password for verification
    const user = await UserModel.findById(userId).select('+password');
    if (!user) {
      return res.status(404).json({ msg: 'User not found' });
    }

    // Verify current password
    const passwordMatch = await bcrypt.compare(currentPassword, user.password);
    if (!passwordMatch) {
      return res.status(401).json({ msg: 'Current password is incorrect' });
    }

    // Check if new password is same as current
    const samePassword = await bcrypt.compare(newPassword, user.password);
    if (samePassword) {
      return res.status(400).json({ msg: 'New password must be different from current password' });
    }

    // Update password (pre-save hook will hash it)
    user.password = newPassword;
    user.lastLogin = new Date();
    await user.save();

    res.json({
      msg: 'Password updated successfully'
    });

  } catch (error) {
    console.error('Error updating password:', error);
    res.status(500).json({ msg: 'Server error while updating password' });
  }
};