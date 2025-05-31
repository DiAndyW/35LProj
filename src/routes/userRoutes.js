import { Router } from 'express';
import { getUsernameById } from '../controllers/userController.js';

const userRouter = Router();

userRouter.get('/:userId/username', getUsernameById);

export default userRouter;
