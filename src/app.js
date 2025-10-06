// imports
import express from "express";
import cookieParser from "cookie-parser";
import logger from "#config/logger.js";
import morgan from "morgan";
import cors from "cors";
import helmet from "helmet";

import { ENV } from "#config/env.js";

import { requestId } from "#src/middleware/requestId.middleware.js";
import { errorHandler } from "#src/middleware/error.middleware.js";
import { app } from "./config/socket.js";

import authRoutes from "#routes/auth.routes.js";
import userRoutes from "#routes/user.routes.js";
import messageRoutes from "#routes/message.routes.js";
import securityMiddleware from "#src/middleware/security.middleware.js";

// Core middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(helmet());

app.use(
  cors({
    origin: function (origin, callback) {
      // Allow requests with no origin (mobile apps, curl, Postman)
      if (!origin) return callback(null, true);

      const devAllowed = [
        /^https?:\/\/localhost:\d+$/, // localhost:any
        /^https?:\/\/127\.0\.0\.1:\d+$/, // 127.0.0.1:any
        /^https?:\/\/192\.168\.\d+\.\d+:\d+$/, // local LAN
      ];

      // Include CLIENT_URL if provided
      if (ENV.CLIENT_URL) devAllowed.push(ENV.CLIENT_URL);

      const isDev = ENV.NODE_ENV !== "production";
      const isAllowed = (
        isDev ? devAllowed : [ENV.CLIENT_URL].filter(Boolean)
      ).some((pat) =>
        typeof pat === "string" ? pat === origin : pat.test(origin)
      );

      if (isAllowed) return callback(null, true);
      return callback(new Error(`Not allowed by CORS: ${origin}`));
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization", "Cookie"],
    optionsSuccessStatus: 200,
  })
);

app.use(requestId);

morgan.token("id", (req) => req.requestId);

app.use(
  morgan(
    ":id :remote-addr - :method :url :status :res[content-length] - :response-time ms",
    {
      stream: { write: (message) => logger.info(message.trim()) },
    }
  )
);

// Preflight: cors() above handles OPTIONS automatically in Express 5

// app.use(securityMiddleware);

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);
app.use("/api/messages", messageRoutes);

app.get("/", (req, res) => {
  res.status(200).send("Welcome to Convo API!");
});

// 404
app.use((req, res) => {
  res.status(404).json({ message: "Not Found", requestId: req.requestId });
});

app.use(errorHandler);

export default app;
