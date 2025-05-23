import 'dotenv/config';
import express from 'express';
import mongoose from 'mongoose';
import routes from './routes.js';

export async function startDB() {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      dbName: process.env.MONGO_DB || 'auth',
    });
    console.log('[db] connected');
  } catch (err) {
    console.error('[db] failed →', err.message);
    process.exit(1);
  }
}

if (process.env.NODE_ENV !== 'test') await startDB();

const app = express();
app.use(express.json());
app.use('/api/auth', routes);

export default app;
