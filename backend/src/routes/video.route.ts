import { Router } from "express";
import { createVideoHandler, listVideosHandler } from "../controllers/video.controller";
import { requireAuth } from "../middlewares/requireAuth";
import { prisma } from "../prisma";

const router = Router();

/**
 * Video metadata routes
 */
router.post("/videos", requireAuth(["creator"]), createVideoHandler);
router.get("/videos", listVideosHandler);

/**
 * POC: Generate signed upload URL (mock)
 */
router.post("/videos/upload-url", (_req, res) => {
  const mockSignedUrl =
    "https://storage.example.com/upload/video-placeholder.mp4";

  res.json({
    uploadUrl: mockSignedUrl,
    expiresIn: 300
  });
});

export default router;

// Processing endpoint (mock) per Phase 8
router.post("/videos/:id/process", requireAuth(["creator"]), async (req, res) => {
  const { id } = req.params;

  const video = await prisma.video.findUnique({ where: { id } });
  if (!video) {
    return res.status(404).json({ error: "Video not found" });
  }

  if (video.status !== "UPLOADED") {
    return res.status(400).json({ error: "Invalid video state" });
  }

  await prisma.video.update({
    where: { id: video.id },
    data: {
      status: "READY",
      manifestPath: `/hls/${video.id}/index.m3u8`,
      processedAt: new Date(),
    },
  });

  return res.json({ message: "Video processed (mock)" });
});
