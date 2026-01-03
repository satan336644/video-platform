import express from "express";
import cors from "cors";
import healthRoute from "./routes/health.route";
import videoRoute from "./routes/video.route";
import playbackRoute from "./routes/playback.route";
import streamRoute from "./routes/stream.route";
import authRoute from "./routes/auth.route";
import userRoute from "./routes/user.route";
import uploadRoute from "./routes/upload.route";
import likeRoute from "./routes/like.route";
import historyRoute from "./routes/history.route";
import continueWatchingRoute from "./routes/continueWatching.route";
import recommendedRoute from "./routes/recommended.route";
import notificationsRoute from "./routes/notifications.route";
import commentRoute from "./routes/comment.route";
import followRoute from "./routes/follow.route";
import categoryRoute from './routes/category.route';
import tagRoute from './routes/tag.route';
import searchRoute from './routes/search.route';
import analyticsRoute from './routes/analytics.route';
import moderationRoute from "./routes/moderation.route";
import { checkBanned } from "./middlewares/checkBanned";
import { prisma } from "./prisma";


const app = express();

app.use(cors());
app.use(express.json());

app.use("/api", healthRoute);
// Register specific feeds before generic video routes to avoid /videos/:id capturing them
app.use("/api", recommendedRoute);
app.use("/api", continueWatchingRoute);
app.use("/api", notificationsRoute);
app.use("/api", videoRoute);
app.use("/api", playbackRoute);
app.use("/api", streamRoute);
app.use("/api/auth", authRoute);
app.use("/api/users", userRoute);
app.use("/api", uploadRoute);
app.use("/api", likeRoute);
app.use("/api", commentRoute);
app.use("/api", followRoute);
app.use("/api", historyRoute);
app.use('/api', categoryRoute);
app.use('/api', tagRoute);
app.use('/api', searchRoute);
app.use('/api', analyticsRoute);
app.use("/api", checkBanned);
app.use("/api", moderationRoute);


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

// Test helper: Set video view count (for development only)
app.post("/test/videos/:id/set-views", async (req, res) => {
  try {
    const { viewCount } = req.body;
    const video = await prisma.video.update({
      where: { id: req.params.id },
      data: { viewCount: viewCount || 0 },
    });
    res.json(video);
  } catch (error) {
    res.status(500).json({ error: "Failed to update view count" });
  }
});

// Test helper: Set video manifest path (for development only)
app.post("/test/videos/:id/set-manifest", async (req, res) => {
  try {
    const { manifestPath } = req.body as { manifestPath?: string };
    const video = await prisma.video.update({
      where: { id: req.params.id },
      data: { manifestPath: manifestPath ?? `/processed/${req.params.id}/index.m3u8` },
    });
    res.json(video);
  } catch (error) {
    res.status(500).json({ error: "Failed to update manifest path" });
  }
});

// Test helper: Reset a user's watch history (for development only)
app.post("/test/users/:userId/reset-history", async (req, res) => {
  try {
    const { userId } = req.params;
    const deleted = await prisma.watchHistory.deleteMany({ where: { userId } });
    res.json({ deletedCount: deleted.count });
  } catch (error) {
    res.status(500).json({ error: "Failed to reset user watch history" });
  }
});

export default app;