import { Router } from 'express';
import {
  createCheckIn,
  getUserCheckIns,
  getCheckInDetail,
  updateCheckIn,
  deleteCheckIn,
  updateLikes,
  addComment
} from '../controllers/checkInController.js';

const checkInRouter = Router();

// POST - Create a new check-in
checkInRouter.post('/checkin', createCheckIn);

// GET - Retrieve a user's check-ins
checkInRouter.get('/checkin/:userId', getUserCheckIns);

// GET - Retrieve a specific check-in by ID
checkInRouter.get('/checkin/detail/:id', getCheckInDetail);

// PUT - Update an existing check-in
checkInRouter.put('/checkin/:id', updateCheckIn);

// DELETE - Remove a check-in
checkInRouter.delete('/checkin/:id', deleteCheckIn);

// PATCH - Add/delete likes on a check-in
checkInRouter.patch('/checkin/:id/like', updateLikes);

// PATH - Add a comment on a check-in
checkInRouter.patch('/checkin/:id/comment', addComment);

export default checkInRouter;
