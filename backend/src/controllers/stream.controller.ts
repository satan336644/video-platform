import { Request, Response } from "express";
import { prisma } from "../prisma";

export const getProtectedManifestHandler = async (
  req: Request,
  res: Response
) => {
  const playback = (req as any).playback;
  const videoId = playback.videoId;
  const tokenId = playback.jti;

  // Fetch video to check status and manifestPath
  const video = await prisma.video.findUnique({
    where: { id: videoId },
    select: {
      id: true,
      status: true,
      visibility: true,
      manifestPath: true,
    },
  });

  if (!video) {
    return res.status(404).json({ error: "Video not found" });
  }

  // Enforce READY-only playback
  if (video.status !== "READY") {
    return res.status(403).json({
      error: "Video is not ready for playback",
      status: video.status,
    });
  }

  if (!video.manifestPath) {
    return res.status(500).json({
      error: "Manifest path not available",
    });
  }

  // Resolve playback URL from storage (always return absolute URL)
  const publicBaseUrl = process.env.R2_PUBLIC_URL || process.env.CDN_URL;
  
  if (!publicBaseUrl) {
    return res.status(500).json({
      error: "Public storage URL not configured",
    });
  }

  const manifestUrl = `${publicBaseUrl}${video.manifestPath}`;

  // Phase 15.3: Idempotent view count increment
  // Only for PUBLIC + READY videos, and only once per playback token
  if (video.visibility === "PUBLIC" && video.status === "READY" && tokenId) {
    try {
      await prisma.$transaction(async (tx) => {
        // Create usage record; if duplicate, transaction will fail and we won't increment
        await tx.playbackTokenUsage.create({
          data: { tokenId: tokenId, videoId: videoId },
        });
        await tx.video.update({
          where: { id: videoId },
          data: { viewCount: { increment: 1 } },
        });
      });
    } catch (err: any) {
      // Unique violation or other error -> do not increment again
      // Optional: log only unexpected errors
      if (process.env.LOG_LEVEL === "debug") {
        console.debug("View increment skipped or failed:", err?.message || err);
      }
    }
  }

  return res.json({
    message: "Access granted to protected stream",
    videoId: video.id,
    manifestUrl,
  });
};
