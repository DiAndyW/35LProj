require('dotenv').config();
const express = require('express');
const { MongoClient, ServerApiVersion } = require('mongodb');

const app = express();

const client = new MongoClient(process.env.MONGODB_URI, {
  serverApi: {
    version: ServerApiVersion.v1,
    strict: true,
    deprecationErrors: true,
  }
});

async function startServer() {
  try {
    // Connect to MongoDB
    await client.connect();
    await client.db('admin').command({ ping: 1 });
    console.log('Connected to MongoDB');

    // Express route
    app.get('/', (req, res) => {
      const userIP = req.ip;
      res.send(`Hello, world`);
    });

    // Start Express server
    const PORT = process.env.PORT || 3000;
    const server = app.listen(PORT, () => {
      console.log(`Server running at http://localhost:${PORT}`);
    });

    // Handle graceful shutdown
    const shutdown = async () => {
      console.log('\nShutting down...');
      await client.close();
      server.close(() => {
        console.log('Server closed, MongoDB connection closed');
        process.exit(0);
      });
    };

    process.on('SIGINT', shutdown);
    process.on('SIGTERM', shutdown);
  } catch (err) {
    console.error('Error starting app:', err);
    process.exit(1);
  }
}

startServer();