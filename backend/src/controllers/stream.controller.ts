import { Request, Response } from "express";
import { prisma } from "../prisma";

const VIEW_THRESHOLD_MS = parseInt(process.env.VIEW_THRESHOLD_MS || "5000", 10);

export const getProtectedManifestHandler = async (
  req: Request,
  res: Response
) => {
  const playback = (req as any).playback;
  const videoId = playback.videoId;
  const tokenId = playback.jti;
  const issuedAtFromToken = playback.iat ? new Date(playback.iat * 1000) : new Date();

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

  // Phase 15.4: Idempotent + thresholded view count increment
  // Phase 16.2: Record watch history for authenticated users
  // Rules: PUBLIC + READY only; require playback token; increment once per token after threshold
  if (video.visibility === "PUBLIC" && video.status === "READY" && tokenId) {
    try {
      const now = new Date();
      const userId = playback.userId; // Extract userId from token if present

      // Fetch or create usage record (first stream call)
      let usage = await prisma.playbackTokenUsage.findUnique({ where: { tokenId } });
      if (!usage) {
        usage = await prisma.playbackTokenUsage.create({
          data: {
            tokenId,
            videoId,
            issuedAt: issuedAtFromToken,
            usedAt: now,
            viewCounted: false,
          },
        });
      }

      const elapsedMs = now.getTime() - usage.usedAt.getTime();

      if (!usage.viewCounted && elapsedMs >= VIEW_THRESHOLD_MS) {
        await prisma.$transaction(async (tx) => {
          // Mark counted only if still uncounted
          const result = await tx.playbackTokenUsage.updateMany({
            where: { tokenId, viewCounted: false },
            data: { viewCounted: true },
          });

          if (result.count > 0) {
            await tx.video.update({
              where: { id: videoId },
              data: { viewCount: { increment: 1 } },
            });

            // Phase 16.2: Record/update watch history for authenticated users
            if (userId) {
              await tx.watchHistory.upsert({
                where: {
                  userId_videoId: { userId, videoId },
                },
                create: {
                  userId,
                  videoId,
                  lastWatchedAt: now,
                },
                update: {
                  lastWatchedAt: now,
                },
              });
            }
          }
        });
      }
    } catch (err: any) {
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
