import { Router } from "express";
import { requirePlaybackToken } from "../middlewares/requirePlaybackToken";
import { getProtectedManifestHandler } from "../controllers/stream.controller";
import { playbackRateLimiter } from "../middlewares/rateLimit";
import { abuseLogger } from "../middlewares/abuseLogger";

const router = Router();

router.get(
  "/videos/:id/stream",
  playbackRateLimiter,
  abuseLogger,
  requirePlaybackToken,
  getProtectedManifestHandler
);

export default router;
