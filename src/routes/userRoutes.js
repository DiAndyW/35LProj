import { Router } from 'express';
import { getUsernameById, blockAUser } from '../controllers/userController.js';
import requireAuth from '../middleware/requireAuth.js';

const userRouter = Router();
userRouter.use(requireAuth);

// GET - Retrieve a user's username by their ID
userRouter.get('/:userId/username', getUsernameById);

// POST - Block a user by their ID
userRouter.post('/:userId/block', blockAUser);

export default userRouter;
