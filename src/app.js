require('dotenv').config();
const express = require('express');
const { MongoClient, ServerApiVersion } = require('mongodb');

const app = express();
app.use(express.json());

const client = new MongoClient(process.env.MONGODB_URI, {
  serverApi: {
    version: ServerApiVersion.v1,
    strict: true,
    deprecationErrors: true,
  }
});

// Middleware for MongoDB connection check
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

// Graceful shutdown logic
const shutdown = async (server) => {
  console.log('\nShutting down...');
  await client.close();
  server.close(() => {
    console.log('Server and MongoDB connection closed');
    process.exit(0);
  });
};

// Define routes
app.get('/', (req, res) => {
  res.send('Hello, David');
});

// Start Express server
const startServer = () => {
  const PORT = process.env.PORT || 3000;
  const server = app.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}`);
  });

  // Listen for termination signals to gracefully shut down
  process.on('SIGINT', () => shutdown(server));
  process.on('SIGTERM', () => shutdown(server));
};

const init = async () => {
  await connectToDatabase();  // Establish MongoDB connection
  startServer();              // Start Express server
};

init();