import { Router } from "express";
import { likeVideoHandler, unlikeVideoHandler, getVideoLikesHandler } from "../controllers/like.controller";
import { requireAuth } from "../middlewares/requireAuth";
import { optionalAuth } from "../middlewares/optionalAuth";

const router = Router();

// Like/Unlike (auth required)
router.post("/videos/:id/like", requireAuth(), likeVideoHandler);
router.delete("/videos/:id/like", requireAuth(), unlikeVideoHandler);

// Get likes (optional auth to check if current user liked)
router.get("/videos/:id/likes", optionalAuth(), getVideoLikesHandler);

export default router;
