import { Router } from "express";
import { getContinueWatchingHandler } from "../controllers/continueWatching.controller";
import { requireAuth } from "../middlewares/requireAuth";

const router = Router();

router.get("/me/continue-watching", requireAuth(), getContinueWatchingHandler);

export default router;
