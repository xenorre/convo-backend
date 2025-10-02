// imports
import express from "express";
import cookieParser from "cookie-parser";
import logger from "#config/logger.js";
import morgan from "morgan";

const app = express();

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

app.use(
  morgan("combined", {
    stream: { write: (message) => logger.info(message.trim()) },
  })
);

app.get("/", (req, res) => {
  res.status(200).send("Welcome to Convo API!");
});

app.use((req, res) => {
  res.status(404).json({ message: "Not Found" });
});

export default app;
