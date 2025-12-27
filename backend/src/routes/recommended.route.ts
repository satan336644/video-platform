import { Router } from "express";
import { getRecommendedHandler } from "../controllers/recommended.controller";
import { optionalAuth } from "../middlewares/optionalAuth";

const router = Router();

router.get("/videos/recommended", optionalAuth(), getRecommendedHandler);

export default router;
