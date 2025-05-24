import { Router } from 'express';
import { register, login } from './controller.js';
import requireAuth from './middleware/requireAuth.js';
import User from './model/user.js';


const router = Router();
router.post('/register', register);
router.post('/login', login);

router.get('/profile', requireAuth, async (req, res) => {
  const me = await User.findById(req.user.sub).select('-password -__v');
  if (!me) return res.sendStatus(404);
  res.json(me);
});

export default router;