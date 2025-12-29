import { Router } from "express";
import { createCommentHandler } from "../controllers/comment.controller";
import { requireAuth } from "../middlewares/requireAuth";

const router = Router();

// Create comment on a video (auth required)
router.post("/videos/:id/comments", requireAuth(), createCommentHandler);

export default router;
