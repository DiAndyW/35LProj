import 'dotenv/config';
import express from 'express';
import mongoose from 'mongoose';
import checkInRouter from './routes/check-in.js';
import authRouter from './routes/auth.js';
import feedRouter from './routes/feed.js';

const app = express();
app.use(express.json());

// Mongoose connection setup
const connectMongoose = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI, {
      serverSelectionTimeoutMS: 10000, // Keep trying to connect for 10 seconds
      socketTimeoutMS: 45000,         // Close sockets after 45 seconds of inactivity
      connectTimeoutMS: 10000         // Give up initial connection after 10 seconds
    });
    console.log('Connected to MongoDB via Mongoose!');
  } catch (err) {
    console.error('Error connecting to MongoDB via Mongoose:', err);
    process.exit(1);
  }
};

// Shutdown function now handles Mongoose disconnection
const shutdown = async (server) => {
  console.log('\nShutting down...');
  if (mongoose.connection.readyState === 1) { // Check if Mongoose is connected
    await mongoose.disconnect(); // Disconnect Mongoose
    console.log('Mongoose disconnected from MongoDB');
  }
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
};

// Your existing root route
app.get('/', (req, res) => {
  res.send('Hello, David');
});

// Mounting your check-in routes
app.use('/api', checkInRouter);
console.log('Check-in routes mounted at /api');

// Mounting your feed routes
app.use('/api', feedRouter);
console.log('Feed routes mounted at /api');

// Mounting your authentication routes
app.use('/auth', authRouter);
console.log('Auth routes mounted at /auth');

const startServer = () => {
  const PORT = process.env.PORT || 3000;
  const server = app.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}`);
    console.log('Available routes:');
    console.log('  GET  / - Hello message');
    console.log('  POST /api/checkin - Create check-in');
    console.log('  GET  /api/checkin/:userId - Get user check-ins');
    console.log('  GET  /api/checkin/detail/:id - Get specific check-in');
    console.log('  DELETE /api/checkin/:id - Delete check-in');
    console.log('  POST /auth/register - Register new user');
    console.log('  POST /auth/login - User login');
    console.log('  GET  /auth/profile - Get user profile (requires auth)');
    console.log(' GET /api/feed - Get global feed check-ins');
  });

  process.on('SIGINT', () => shutdown(server));
  process.on('SIGTERM', () => shutdown(server));
};

const init = async () => {
  await connectMongoose();
  startServer();
};

init();
