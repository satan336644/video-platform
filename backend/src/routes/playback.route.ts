import { Router } from "express";
import { issuePlaybackTokenHandler } from "../controllers/playback.controller";
import { playbackRateLimiter } from "../middlewares/rateLimit";
import { abuseLogger } from "../middlewares/abuseLogger";

const router = Router();

router.post(
	"/videos/:id/playback-token",
	playbackRateLimiter,
	abuseLogger,
	issuePlaybackTokenHandler
);

export default router;
