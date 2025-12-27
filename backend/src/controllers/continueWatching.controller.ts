import { Request, Response } from "express";
import { prisma } from "../prisma";

/**
 * GET /me/continue-watching
 * Returns videos from user's watch history
 * - Auth required
 * - PUBLIC + READY videos only
 * - Sorted by lastWatchedAt DESC
 * - Supports limit + pagination (page)
 */
export async function getContinueWatchingHandler(req: Request, res: Response) {
  const userId = (req as any).user?.userId;
  if (!userId) {
    return res.status(401).json({ error: "Authentication required" });
  }

  const limitRaw = req.query.limit as string | undefined;
  const pageRaw = req.query.page as string | undefined;
  const limit = Math.min(Math.max(parseInt(limitRaw || "10", 10) || 10, 1), 50);
  const page = Math.max(parseInt(pageRaw || "1", 10) || 1, 1);
  const skip = (page - 1) * limit;

  try {
    const history = await prisma.watchHistory.findMany({
      where: {
        userId,
        video: {
          is: {
            visibility: "PUBLIC",
            status: "READY",
          },
        },
      },
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
      take: limit,
      skip,
    });

    const items = history.map((h) => ({
      videoId: h.videoId,
      lastWatchedAt: h.lastWatchedAt,
      video: h.video,
      // Placeholder for future resume info (position, duration, etc.)
      resumeInfo: null,
    }));

    return res.json({
      items,
      page,
      limit,
      count: items.length,
    });
  } catch (error) {
    console.error("Continue watching error:", error);
    return res.status(500).json({ error: "Failed to fetch continue watching" });
  }
}
