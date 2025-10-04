import {
  getAllContacts,
  getChats,
  getMessagesById,
  sendMessage,
} from "#src/controllers/message.controller.js";
import { protectRoute } from "#src/middleware/auth.middleware.js";
import {
  uploadMessageFile,
  handleMessageFileError,
  validateMessageFile,
} from "#src/middleware/messageUpload.middleware.js";
import express from "express";

const router = express.Router();

router.use(protectRoute);

router.get("/contacts", getAllContacts);
router.get("/chats", getChats);
router.get("/:id", getMessagesById);
router.post(
  "/send/:id",
  uploadMessageFile,
  handleMessageFileError,
  validateMessageFile,
  sendMessage
);

export default router;
