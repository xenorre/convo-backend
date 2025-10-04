import { v4 as uuidv4 } from "uuid";

export const requestId = (req, res, next) => {
  const id = req.headers["x-request-id"] || uuidv4();
  req.requestId = String(id);
  res.setHeader("x-request-id", String(id));
  next();
};