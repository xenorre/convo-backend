import app from "./app.js";
import { connectDB } from "./config/db.js";
import { ENV } from "#config/env.js";

const PORT = ENV.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
  connectDB();
});
