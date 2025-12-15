import express from "express";
import cors from "cors";
import healthRoute from "./routes/health.route";
import videoRoute from "./routes/video.route";


const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use("/api", healthRoute);
app.use("/api", videoRoute);

export default app;
