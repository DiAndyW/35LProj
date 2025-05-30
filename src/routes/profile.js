import { Router } from "express";
import requireAuth from "../middleware/requireAuth.js";
import { getProfileSummary, getEmotionTrends, getRecentPublicCheckins } from '../controllers/profileController.js';


const profileRouter = Router();

profileRouter.use(requireAuth);

profileRouter.get('/summary', getProfileSummary);
profileRouter.get('/emotion-trends', getEmotionTrends);
profileRouter.get('/recent-public-checkins', getRecentPublicCheckins);

export default profileRouter;