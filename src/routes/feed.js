import { Router } from 'express';
import {
  getFeedCheckIns
} from '../controllers/feedController.js';

const feedRouter = Router();

// GET - Retrieve the feed of check-ins for a user
feedRouter.get('/feed', getFeedCheckIns);

export default feedRouter;
