import { Request, Response } from "express";
import { prisma } from "../prisma";

export const getProtectedManifestHandler = async (
  req: Request,
  res: Response
) => {
  const playback = (req as any).playback;
  const videoId = playback.videoId;

  // Fetch video to check status and manifestPath
  const video = await prisma.video.findUnique({
    where: { id: videoId },
    select: {
      id: true,
      status: true,
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

  return res.json({
    message: "Access granted to protected stream",
    videoId: video.id,
    manifestUrl,
  });
};
