import { Router } from "express";
import { requirePlaybackToken } from "../middlewares/requirePlaybackToken";
import { getProtectedManifestHandler } from "../controllers/stream.controller";

const router = Router();

router.get(
  "/videos/:id/stream",
  requirePlaybackToken,
  getProtectedManifestHandler
);

export default router;
