import { Router } from "express";
import {
  createVideoHandler,
  listVideosHandler,
} from "../controllers/video.controller";

const router = Router();

/**
 * Video metadata routes
 */
router.post("/videos", createVideoHandler);
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
