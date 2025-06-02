import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import User from '../models/user.js';

const strongPwd = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*\W).{10,}$/;

export const register = async (req, res) => {
  const { username, email, password } = req.body;

  if (!strongPwd.test(password)) {
    return res.status(400).json({ msg: 'Weak password' });
  }

  try {
    console.log('Attempting to create user with:', { username, email }); // Log before create
    const user = await User.create({ username, email, password });
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
  const user = await User.findOne({ email }).select('+password');
  if (!user) return res.status(401).json({ msg: 'Invalid credentials' });

  const ok = await bcrypt.compare(password, user.password);
  if (!ok) return res.status(401).json({ msg: 'Invalid credentials' });

  const access = jwt.sign({ sub: user.id }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '15m' });
  const refresh = jwt.sign({ sub: user.id }, process.env.JWT_SECRET, { expiresIn: '7d' });
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
      { sub: user.id }, 
      process.env.JWT_SECRET, 
      { expiresIn: process.env.JWT_EXPIRES_IN || '15m' }
    );
    
    // Refresh token gets renewed each time it's used
    const refresh = jwt.sign(
      { sub: user.id }, 
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