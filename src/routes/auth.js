import { Router } from 'express';
import { register, login } from '../controllers/authController.js';
import requireAuth from '../middleware/requireAuth.js';
import UserModel from '../models/UserModel.js';

const authRouter = Router();

authRouter.post('/register', register);
authRouter.post('/login', login);
authRouter.get('/profile', requireAuth, async (req, res) => {
  const me = await UserModel.findById(req.user.sub).select('-password -__v');
  if (!me) return res.sendStatus(404);
  res.json(me);
});

export default authRouter;