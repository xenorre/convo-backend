import mongoose from "mongoose";

const messages = new mongoose.Schema(
  {
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    receiverId: {
      type: mongoose.Schema.Types.ObjectId,
      required: true,
    },
    text: {
      type: String,
    },
    image: {
      type: String, // This field will store file URLs (images, documents, etc.)
    },
  },
  { timestamps: true }
);

const Message = mongoose.model("Message", messages);

export default Message;
