import jwt from 'jsonwebtoken';

export default function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token  = header.startsWith('Bearer ') ? header.split(' ')[1] : null;
  if (!token) return res.status(401).json({ msg: 'Missing token' });

  try {
    req.user = jwt.verify(token, process.env.JWT_SECRET); // { sub, iat, exp }
    next();
  } catch {
    return res.status(401).json({ msg: 'Invalid / expired token' });
  }
}