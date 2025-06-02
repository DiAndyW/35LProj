import jwt from 'jsonwebtoken';

export default function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.split(' ')[1] : null;
  
  console.log('=== AUTH MIDDLEWARE DEBUG ===');
  console.log('Authorization header:', header);
  console.log('Extracted token:', token);
  console.log('JWT_SECRET in middleware:', process.env.JWT_SECRET);
  
  if (!token) return res.status(401).json({ msg: 'Missing token' });

  try {
    // Decode without verification to see payload
    const decoded = jwt.decode(token);
    console.log('Decoded payload (unverified):', decoded);
    
    // Check if token is expired manually
    if (decoded && decoded.exp) {
      const now = Math.floor(Date.now() / 1000);
      const timeUntilExpiry = decoded.exp - now;
      console.log('Current time:', now);
      console.log('Token expires at:', decoded.exp);
      console.log('Time until expiry (seconds):', timeUntilExpiry);
      console.log('Token expired?', timeUntilExpiry <= 0);
    }
    
    // Now verify
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    console.log('Verified user:', req.user);
    console.log('=== AUTH SUCCESS ===');
    next();
  } catch (error) {
    console.log('JWT verification error:', error.message);
    console.log('Error name:', error.name);
    console.log('=== AUTH FAILED ===');
    return res.status(401).json({ msg: 'Invalid / expired token' });
  }
}