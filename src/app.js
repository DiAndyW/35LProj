import 'dotenv/config';
import express from 'express';
import { MongoClient, ServerApiVersion } from 'mongodb';
import checkInRouter from './routes/check-in.js';
import authRouter from './routes/auth.js';

const app = express();
app.use(express.json());

const client = new MongoClient(process.env.MONGODB_URI, {
  serverApi: {
    version: ServerApiVersion.v1,
    strict: true,
    deprecationErrors: true,
  }
});

const connectToDatabase = async () => {
  try {
    await client.connect();
    await client.db('admin').command({ ping: 1 });
    console.log('Connected to MongoDB');
  } catch (err) {
    console.error('Error connecting to MongoDB:', err);
    process.exit(1);
  }
};

const shutdown = async (server) => {
  console.log('\nShutting down...');
  await client.close();
  server.close(() => {
    console.log('Server and MongoDB connection closed');
    process.exit(0);
  });
};

app.get('/', (req, res) => {
  res.send('Hello, David');
});

app.use('/api', checkInRouter);
console.log('Check-in routes mounted at /api');

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
    console.log('  POST /auth/register - Register a new user');
    console.log('  POST /auth/login - Login user');
    console.log('  GET  /auth/profile - Get user profile (requires authentication)');
  });
  process.on('SIGINT', () => shutdown(server));
  process.on('SIGTERM', () => shutdown(server));
};

const init = async () => {
  await connectToDatabase();
  startServer();
};

init();