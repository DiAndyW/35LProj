import { Router } from "express";
import requireAuth from "../middleware/requireAuth.js";
import { getProfileSummary, getMoodAnalytics } from '../controllers/profileController.js';


const profileRouter = Router();

profileRouter.use(requireAuth);

// GET - get the user summary
profileRouter.get('/summary', getProfileSummary);
// GET - get details user stats, optional parameter for time period
profileRouter.get('/analytics', getMoodAnalytics);

export default profileRouter;