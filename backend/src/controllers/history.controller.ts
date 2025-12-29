import { Request, Response } from "express";
import { prisma } from "../prisma";

/**
 * GET /me/history
 * Get user's watch history (auth required)
 * Returns videos sorted by lastWatchedAt DESC
 */
export async function getWatchHistoryHandler(req: Request, res: Response) {
  const userId = (req as any).user?.userId;

  if (!userId) {
    return res.status(401).json({ error: "Authentication required" });
  }

  try {
    const history = await prisma.watchHistory.findMany({
      where: { userId },
      include: {
        video: {
          select: {
            id: true,
            title: true,
            description: true,
            creatorId: true,
            status: true,
            visibility: true,
            category: true,
            viewCount: true,
            likeCount: true,
            createdAt: true,
          },
        },
      },
      orderBy: { lastWatchedAt: "desc" },
    });

    return res.json({
      history: history.map((h: typeof history[number]) => ({
        videoId: h.videoId,
        lastWatchedAt: h.lastWatchedAt,
        createdAt: h.createdAt,
        video: h.video,
      })),
    });
  } catch (error) {
    console.error("Get watch history error:", error);
    return res.status(500).json({ error: "Failed to get watch history" });
  }
}
