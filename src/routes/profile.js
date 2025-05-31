import { Router } from "express";
import requireAuth from "../middleware/requireAuth.js";
import { getProfileSummary, getMoodAnalytics } from '../controllers/profileController.js';


const profileRouter = Router();

profileRouter.use(requireAuth);

profileRouter.get('/summary', getProfileSummary);
// profileRouter.get('/emotion-trends', getEmotionTrends);
// profileRouter.get('/recent-public-checkins', getRecentPublicCheckins);
profileRouter.get('/analytics', getMoodAnalytics);

export default profileRouter;