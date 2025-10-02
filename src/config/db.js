import mongoose from "mongoose";
import { ENV } from "#config/env.js";

export const connectDB = async () => {
  try {
    const conn = await mongoose.connect(ENV.DATABASE_URL);
    console.log("Connected to MongoDB", conn.connection.host);
  } catch (error) {
    console.error("Error connecting to MongoDB:", error);
    process.exit(1);
  }
};
