import { Request, Response } from "express";
import { generatePlaybackToken } from "../utils/playbackToken";
import { prisma } from "../prisma";

export const issuePlaybackTokenHandler = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const userId = (req as any).user?.userId; // Optional userId from auth

    const video = await prisma.video.findUnique({ where: { id } });
    if (!video) {
      return res.status(404).json({ error: "Video not found" });
    }

    if (video.status !== "READY") {
      return res.status(403).json({
        error: "Video is not ready for playback",
        status: video.status,
      });
    }

    const ttl = process.env.NODE_ENV === "development" && req.query.ttlSeconds
      ? parseInt(req.query.ttlSeconds as string, 10) || undefined
      : undefined;

    const token = generatePlaybackToken(id, userId, ttl || undefined);

    return res.json({
      playbackToken: token,
      expiresInSeconds: 300,
    });
  } catch (err) {
    console.error("Error issuing playback token:", err);
    return res.status(500).json({ error: "Failed to issue playback token" });
  }
};
