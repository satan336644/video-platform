import { Router } from "express";
import { issuePlaybackTokenHandler } from "../controllers/playback.controller";

const router = Router();

router.post("/videos/:id/playback-token", issuePlaybackTokenHandler);

export default router;
