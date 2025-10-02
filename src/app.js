import express from "express";
import cookieParser from "cookie-parser";

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());

app.get("/", (req, res) => {
  res.status(200).send("Welcome to Convo API!");
});

app.use((req, res) => {
  res.status(404).json({ message: "Not Found" });
});

export default app;
