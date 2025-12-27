import { Router } from "express";
import { getWatchHistoryHandler } from "../controllers/history.controller";
import { requireAuth } from "../middlewares/requireAuth";

const router = Router();

// Get user's watch history (auth required)
router.get("/me/history", requireAuth(), getWatchHistoryHandler);

export default router;
