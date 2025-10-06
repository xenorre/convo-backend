import { connectDB } from "./config/db.js";
import { ENV } from "#config/env.js";
import logger from "#config/logger.js";
import { server } from "./config/socket.js";
import "./app.js";

const PORT = ENV.PORT || 3000;

const start = async () => {
  try {
    await connectDB();
    server.listen(PORT, () => {
      logger.info(`Server is running on http://localhost:${PORT}`);
    });
  } catch (err) {
    logger.error("Failed to start server", { error: err.message });
    process.exit(1);
  }
};

start();
