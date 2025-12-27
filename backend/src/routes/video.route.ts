import { Router } from "express";
import { createVideoHandler, listVideosHandler, updateVideoMetadataHandler, getVideoHandler, listPublicVideosHandler, searchVideosHandler, getCreatorVideosHandler, getPublicVideoDetailHandler, getPopularVideosHandler, getTrendingVideosHandler } from "../controllers/video.controller";
import { requireAuth } from "../middlewares/requireAuth";
import { prisma } from "../prisma";
import { createTranscodingJob } from "../services/transcoding.service";

const router = Router();

/**
 * Video metadata routes
 */
router.post("/videos", requireAuth(["creator"]), createVideoHandler);
router.get("/videos", listVideosHandler);
router.get("/videos/public", listPublicVideosHandler);
router.get("/videos/popular", getPopularVideosHandler);
router.get("/videos/trending", getTrendingVideosHandler);
router.get("/videos/search", searchVideosHandler);
router.get("/creator/videos", requireAuth(["creator"]), getCreatorVideosHandler);
router.get("/videos/:id/public", getPublicVideoDetailHandler);
router.get("/videos/:id", getVideoHandler);
router.patch("/videos/:id/metadata", requireAuth(["creator"]), updateVideoMetadataHandler);

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

router.get("/videos/:id/status", async (req, res) => {
  const video = await prisma.video.findUnique({
    where: { id: req.params.id },
    select: {
      id: true,
      status: true,
      processedAt: true,
      createdAt: true,
    },
  });

  if (!video) {
    return res.status(404).json({ error: "Video not found" });
  }

  return res.json(video);
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

  // Create a transcoding job entry (mock, pending real worker)
  await createTranscodingJob({
    videoId: video.id,
    inputObjectKey: video.sourceObjectKey!,
  });

  await prisma.video.update({
    where: { id: video.id },
    data: {
      status: "PROCESSING",
    },
  });

  return res.json({ message: "Video processing started (mock)" });
});
