import winston from "winston";
import fs from "fs";
import { ENV } from "#config/env.js";

// Ensure logs directory exists
try {
  fs.mkdirSync("logs", { recursive: true });
} catch {}

const consoleFormat = winston.format.printf(({ level, message, timestamp, ...meta }) => {
  const metaStr = Object.keys(meta).length ? ` ${JSON.stringify(meta)}` : "";
  return `${timestamp} [${level}] ${message}${metaStr}`;
});

const logger = winston.createLogger({
  level: ENV.LOG_LEVEL || "info",
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.errors({ stack: true }),
    winston.format.json()
  ),
  defaultMeta: { service: "convo-api" },
  transports: [
    new winston.transports.File({ filename: "logs/error.log", level: "error" }),
    new winston.transports.File({ filename: "logs/combined.log" }),
  ],
});

if (ENV.NODE_ENV !== "production") {
  logger.add(
    new winston.transports.Console({
      format: winston.format.combine(
        winston.format.colorize({ all: false }),
        winston.format.timestamp(),
        consoleFormat
      ),
    })
  );
}

export default logger;
