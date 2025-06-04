export default function requireAdmin(req, res, next) {
    console.log('req.user in requireAdmin:', req.user);
    if (!req.user || !req.user.isAdmin) {
    return res.status(403).json({ message: 'Admin access required.' });
  }
  next();
}