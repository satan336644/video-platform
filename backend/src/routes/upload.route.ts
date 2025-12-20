import { Router } from "express";
import { requireAuth } from "../middlewares/requireAuth";
import { createUploadSession } from "../services/upload.service";

const router = Router();

router.post(
  "/videos/:videoId/upload-intent",
  requireAuth(["creator"]),
  async (req, res) => {
    const { videoId } = req.params;
    const user = (req as any).user;

    const session = await createUploadSession(videoId, user.id);
    res.json(session);
  }
);

export default router;
