import User from './model.js';

export const register = async (req, res) => {
  const { name, email, password } = req.body;
  try {
    const user = await User.create({ name, email, password });
    res.status(201).json({ id: user.id, name, email });
  } catch (err) {
    if (err.code === 11000) return res.status(409).json({ msg: 'Email taken' });
    res.status(500).json({ msg: 'Registration failed' });
  }
};
