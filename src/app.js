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

import authRoutes from "#routes/auth.routes.js";
import userRoutes from "#routes/user.routes.js";
import messageRoutes from "#routes/message.routes.js";
import securityMiddleware from "#src/middleware/security.middleware.js";

const app = express();

// Core middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(helmet());

app.use(
  cors({
    origin: function (origin, callback) {
      // Allow requests with no origin (mobile apps, Postman, etc.)
      if (!origin) return callback(null, true);

      // Development: allow all localhost and VS Code dev tunnels
      if (ENV.NODE_ENV === "development") {
        const allowedOrigins = [
          /^https?:\/\/localhost:\d+$/, // localhost:any_port
          /^https?:\/\/127\.0\.0\.1:\d+$/, // 127.0.0.1:any_port
          /^https?:\/\/192\.168\.\d+\.\d+:\d+$/, // Local network IPs
          /^https:\/\/.*\.devtunnels\.ms$/, // VS Code dev tunnels
          /^https:\/\/.*\.github\.dev$/, // GitHub Codespaces
        ];

        // Check CLIENT_URL if provided
        if (ENV.CLIENT_URL) {
          allowedOrigins.push(ENV.CLIENT_URL);
        }

        const isAllowed = allowedOrigins.some((pattern) =>
          typeof pattern === "string"
            ? pattern === origin
            : pattern.test(origin)
        );

        if (isAllowed) {
          return callback(null, true);
        }
      }

      // Production: only allow CLIENT_URL
      if (ENV.NODE_ENV === "production" && ENV.CLIENT_URL === origin) {
        return callback(null, true);
      }

      callback(new Error("Not allowed by CORS"));
    },
    credentials: true,
    optionsSuccessStatus: 200, // Support legacy browsers
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
