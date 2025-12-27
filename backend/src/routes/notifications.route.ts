import { Router } from "express";
import { getMyNotificationsHandler, markNotificationReadHandler } from "../controllers/notifications.controller";
import { requireAuth } from "../middlewares/requireAuth";

const router = Router();

router.get("/me/notifications", requireAuth(), getMyNotificationsHandler);
router.post("/notifications/:id/read", requireAuth(), markNotificationReadHandler);

export default router;
