import { Router } from "express";
import { followUserHandler } from "../controllers/follow.controller";
import { requireAuth } from "../middlewares/requireAuth";

const router = Router();

// Follow a user (auth required)
router.post("/users/:id/follow", requireAuth(), followUserHandler);

export default router;
