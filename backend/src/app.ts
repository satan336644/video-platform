import express from "express";
import cors from "cors";
import healthRoute from "./routes/health.route";
import videoRoute from "./routes/video.route";
import playbackRoute from "./routes/playback.route";
import streamRoute from "./routes/stream.route";
import authRoute from "./routes/auth.route";
import uploadRoute from "./routes/upload.route";
import { prisma } from "./prisma";

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api", healthRoute);
app.use("/api", videoRoute);
app.use("/api", playbackRoute);
app.use("/api", streamRoute);
app.use("/api", authRoute);
app.use("/api", uploadRoute);

// Test helper: Set video to READY status (for development only)
app.post("/test/videos/:id/set-ready", async (req, res) => {
  try {
    const video = await prisma.video.update({
      where: { id: req.params.id },
      data: { status: "READY", processedAt: new Date() },
    });
    res.json(video);
  } catch (error) {
    res.status(500).json({ error: "Failed to update video status" });
  }
});

export default app;
