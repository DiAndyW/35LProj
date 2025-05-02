import { Request, Response } from 'express';

export const getHello = (req: Request, res: Response) => {
  res.json({ message: 'Hello from the MERN API!' });
};
