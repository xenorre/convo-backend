import express from "express";

const router = express.Router();

router.post("/send", (req, res) => {
  res.status(200).send("Message sent!");
});

export default router;
