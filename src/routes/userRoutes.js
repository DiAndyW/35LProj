import { Router } from 'express';
import { getUsernameById, blockAUser, makeAdmin, getBlockedUsers, unblockAUser } from '../controllers/userController.js';
import requireAuth from '../middleware/requireAuth.js';
import requireAdmin from '../middleware/requireAdmin.js';

const userRouter = Router();
userRouter.use(requireAuth);

// GET - Retrieve a user's username by their ID
userRouter.get('/:userId/username', getUsernameById);

// POST - Block a user by their ID
userRouter.post('/:userId/block', blockAUser);

// PATCH - Make a user an admin
userRouter.patch('/:userId/admin', requireAdmin, makeAdmin);

// GET /api/users/me/blocked
userRouter.get('/me/blocked', getBlockedUsers);

// POST /api/users/:userId/unblock  
userRouter.post('/:userId/unblock', unblockAUser);

export default userRouter;
