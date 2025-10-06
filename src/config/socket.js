import { Server } from "socket.io";
import http from "http";
import express from "express";
import { ENV } from "#config/env.js";
import socketAuthMiddleware from "#src/middleware/socket.auth.middleware.js";
import logger from "#config/logger.js";

const app = express();
const server = http.createServer(app);

const io = new Server(server, {
  cors: {
    origin: function (origin, callback) {
      if (!origin) return callback(null, true);
      const devAllowed = [
        /^https?:\/\/localhost:\d+$/,
        /^https?:\/\/127\.0\.0\.1:\d+$/,
        /^https?:\/\/192\.168\.\d+\.\d+:\d+$/,
      ];
      if (ENV.CLIENT_URL) devAllowed.push(ENV.CLIENT_URL);
      const isDev = ENV.NODE_ENV !== "production";
      const allowed = (
        isDev ? devAllowed : [ENV.CLIENT_URL].filter(Boolean)
      ).some((pat) =>
        typeof pat === "string" ? pat === origin : pat.test(origin)
      );
      return allowed
        ? callback(null, true)
        : callback(new Error(`Not allowed by Socket.io CORS: ${origin}`));
    },
    credentials: true,
  },
});

io.use(socketAuthMiddleware);

export function getReceiverSocketId(userId) {
  return userSocketMap[userId];
}

const userSocketMap = {};

io.on("connection", (socket) => {
  logger.info(`User connected: ${socket.user.fullName}`);

  const userId = socket.userId;
  userSocketMap[userId] = socket.id;

  io.emit("getOnlineUsers", Object.keys(userSocketMap));

  socket.on("disconnect", () => {
    logger.info(`User disconnected: ${socket.user.fullName}`);
    delete userSocketMap[userId];
    io.emit("getOnlineUsers", Object.keys(userSocketMap));
  });
});

export { io, server, app };
