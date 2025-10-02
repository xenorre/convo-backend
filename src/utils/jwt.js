import logger from "#config/logger.js";
import jwt from "jsonwebtoken";

const JWT_SECRET =
  process.env.JWT_SECRET || "your-secret-key-please-change-it-in-production";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "1d";

export const jwttoken = {
  sign: (payload) => {
    try {
      const token = jwt.sign(payload, JWT_SECRET, {
        expiresIn: JWT_EXPIRES_IN,
      });
      return token;
    } catch (e) {
      logger.error("Failed to authenticate JWT:", e);
      throw new Error("Failed to authenticate JWT");
    }
  },
  verify: (token) => {
    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      return decoded;
    } catch (error) {
      logger.error("Failed to verify JWT:", error);
      throw new Error("Failed to verify JWT");
    }
  },
};
