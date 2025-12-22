import { Router } from "express";
import { requireAuth } from "../middlewares/requireAuth";
import { prisma } from "../prisma";
import { storageProvider } from "../storage/storage.service";

const router = Router();

router.post(
  "/videos/:videoId/upload-intent",
  requireAuth(["creator"]),
  async (req, res) => {
    const { videoId } = req.params;

    const video = await prisma.video.findUnique({ where: { id: videoId } });
    if (!video) {
      return res.status(404).json({ error: "Video not found" });
    }

    const intent = await storageProvider.createUploadIntent(videoId);

    await prisma.storedObject.create({
      data: {
        videoId,
        provider: "local",
        objectKey: intent.objectKey,
        status: "PENDING",
      },
    });

    // Update video status to UPLOADED and store object key
    await prisma.video.update({
      where: { id: videoId },
      data: {
        status: "UPLOADED",
        sourceObjectKey: intent.objectKey,
      },
    });

    return res.json({
      uploadUrl: intent.uploadUrl,
      objectKey: intent.objectKey,
    });
  }
);

export default router;
