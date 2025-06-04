import { Router } from 'express';
import { getUsernameById, blockAUser, makeAdmin } from '../controllers/userController.js';
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

export default userRouter;
