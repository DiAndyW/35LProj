import mongoose from 'mongoose';
import app from './app.js';

const PORT = process.env.PORT || 4000;
const server = app.listen(PORT, () =>
  console.log(`⚡ Auth-service running on :${PORT}`),
);

const shutdown = async signal => {
  console.log(`[sys] ${signal} received – shutting down`);
  await mongoose.disconnect();
  server.close(() => process.exit(0));
};
process.on('SIGINT',  () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));