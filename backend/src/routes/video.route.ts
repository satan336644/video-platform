import { Router } from "express";

const router = Router();

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
