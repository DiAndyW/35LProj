import { Router } from 'express';
import {
  createCheckIn,
  getUserCheckIns,
  getCheckInDetail,
  updateCheckIn,
  deleteCheckIn
} from '../controllers/checkInController.js'; // Adjust path

// If you have an authentication middleware and want to protect check-in routes:
// import requireAuth from '../middleware/requireAuth.js'; // Adjust path

const checkInRouter = Router();

// POST - Create a new check-in
// Add requireAuth if this route should be protected
checkInRouter.post('/checkin', createCheckIn);

// GET - Retrieve a user's check-ins
// Add requireAuth if this route should be protected
checkInRouter.get('/checkin/:userId', getUserCheckIns);

// GET - Retrieve a specific check-in by ID
// Add requireAuth if this route should be protected
checkInRouter.get('/checkin/detail/:id', getCheckInDetail);

// PUT - Update an existing check-in
// Add requireAuth if this route should be protected
checkInRouter.put('/checkin/:id', updateCheckIn);

// DELETE - Remove a check-in
// Add requireAuth if this route should be protected
checkInRouter.delete('/checkin/:id', deleteCheckIn);

export default checkInRouter;
