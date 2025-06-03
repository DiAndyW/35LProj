import { Router } from 'express';
import {
  getFeedCheckIns
} from '../controllers/feedController.js';
import requireAuth from '../middleware/requireAuth.js';

const feedRouter = Router();

feedRouter.use(requireAuth);

// GET - Retrieve the feed of check-ins for a user
feedRouter.get('/feed', getFeedCheckIns);

export default feedRouter;
