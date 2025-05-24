import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import User from './model/user.js';

const strongPwd = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*\W).{10,}$/;

export const register = async (req, res) => {
  const { username, email, password } = req.body;

  if (!strongPwd.test(password))
    return res.status(400).json({ msg: 'Weak password' });

  try {
    const user = await User.create({ username, email, password });
    res.status(201).json({ id: user.id, username, email });
  } catch (err) {
    if (err.code === 11000)
      return res.status(409).json({ msg: 'Email or username taken' });
    res.status(500).json({ msg: 'Registration failed' });
  }
};

export const login = async (req, res) => {
  const { email, password } = req.body;
  const user = await User.findOne({ email }).select('+password');
  if (!user) return res.status(401).json({ msg: 'Invalid credentials' });

  const ok = await bcrypt.compare(password, user.password);
  if (!ok) return res.status(401).json({ msg: 'Invalid credentials' });

  const access  = jwt.sign({ sub: user.id }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '15m' });
  const refresh = jwt.sign({ sub: user.id }, process.env.JWT_SECRET, { expiresIn: '7d' });
  res.json({ access, refresh });
};