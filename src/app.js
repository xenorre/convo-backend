// imports
import express from "express";
import cookieParser from "cookie-parser";
import { ENV } from "#config/env.js";
import authRoutes from "#routes/auth.routes.js";
import userRoutes from "#routes/user.routes.js";
import { requestId } from "#src/middleware/requestId.middleware.js";
import { errorHandler } from "#src/middleware/error.middleware.js";
import logger from "#config/logger.js";
import morgan from "morgan";
import cors from "cors";
import helmet from "helmet";

const app = express();

// Core middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(helmet());

app.use(
  cors({
    origin: ENV.CLIENT_URL ? [ENV.CLIENT_URL] : true,
    credentials: true,
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

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/users", userRoutes);

app.get("/", (req, res) => {
  res.status(200).send("Welcome to Convo API!");
});

// 404
app.use((req, res) => {
  res.status(404).json({ message: "Not Found", requestId: req.requestId });
});

app.use(errorHandler);

export default app;
