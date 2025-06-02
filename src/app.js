import 'dotenv/config';
import express from 'express';
import mongoose from 'mongoose';
import checkInRouter from './routes/check-in.js';
import authRouter from './routes/auth.js';
import profileRouter from './routes/profile.js';
import feedRouter from './routes/feed.js';
import userRouter from './routes/userRoutes.js';
import cors from 'cors';
import mapRouter from './routes/mapRoutes.js';

const app = express();
app.use(cors());
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

// Mounting root route
app.get('/', (req, res) => {
  res.send('Hello, David');
});

// Mounting check-in routes
app.use('/api', checkInRouter);
console.log('Check-in routes mounted at /api');

app.use('/api', feedRouter);
console.log('Feed routes mounted at /api');

app.use('/auth', authRouter);
console.log('Auth routes mounted at /auth');

// Mounting profile routes
app.use('/profile', profileRouter);
console.log('Profile routes mounted at /profile');

app.use('/api/users', userRouter);
console.log('User routes mounted at /api/users');

app.use('/api/map', mapRouter);
console.log('Map routes mounted at /api/map');

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
    console.log('  PATCH /api/checkin/:id/like - Update likes on check-in');
    console.log('  PATCH /api/checkin/:id/comment - Add comment to check-in');
    console.log('  POST /auth/register - Register new user');
    console.log('  POST /auth/login - User login');
    console.log('  GET  /auth/profile - Get user profile (requires auth)');
    console.log('  GET /api/feed?skip=0&limit=20 - Get first 20 global feed check-ins');
    console.log('  GET  /api/users/:userId/username - Get username by userId');
    console.log('  GET  /api/map/locations - Get all locations');
    console.log('  POST /api/map/locations - Add new location');
    console.log('  GET  /api/map/locations/nearby/:lat/:lng - Find nearby locations');
    console.log('  POST /api/map/locations/search - Search locations');
    console.log('  POST /api/map/routes/calculate - Calculate route');
  });

  process.on('SIGINT', () => shutdown(server));
  process.on('SIGTERM', () => shutdown(server));
};

const init = async () => {
  await connectMongoose();
  startServer();
};

init();
