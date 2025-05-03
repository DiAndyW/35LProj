import 'dotenv/config';
import express from 'express';
import mongoose from 'mongoose';
import routes from './routes.js';

await mongoose.connect(/*insert the link here*/);
console.log('MongoDB connected');

const app = express();
app.use(express.json());
app.use('/api/auth', routes);

export default app;
