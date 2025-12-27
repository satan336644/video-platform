import { Request, Response } from "express";
import { prisma } from "../prisma";
import { randomUUID } from "crypto";

/**
 * POST /videos/:id/like
 * Like a video (auth required)
 */
export async function likeVideoHandler(req: Request, res: Response) {
  const { id: videoId } = req.params;
  const userId = (req as any).user?.userId;

  if (!userId) {
    return res.status(401).json({ error: "Authentication required" });
  }

  try {
    // Check if video exists
    const video = await prisma.video.findUnique({ where: { id: videoId } });
    if (!video) {
      return res.status(404).json({ error: "Video not found" });
    }

    // Check if already liked
    const existing = await prisma.like.findUnique({
      where: {
        userId_videoId: { userId, videoId },
      },
    });

    if (existing) {
      return res.status(200).json({ message: "Already liked", like: existing });
    }

    // Create like and increment count atomically
    const [like] = await prisma.$transaction([
      prisma.like.create({
        data: { userId, videoId },
      }),
      prisma.video.update({
        where: { id: videoId },
        data: { likeCount: { increment: 1 } },
      }),
    ]);

    // Emit notification to creator (if liker is not the creator)
    if (video.creatorId !== userId) {
      try {
        const id = randomUUID();
        const user = video.creatorId;
        const actor = userId;
        const vid = videoId;
        await prisma.$executeRawUnsafe(
          `INSERT INTO "Notification" ("id", "userId", type, "actorId", "videoId") VALUES ('${id}', '${user}', 'LIKE', '${actor}', '${vid}')`
        );
      } catch (e) {
        console.error("Notification create error:", (e as any)?.message || e);
      }
    }

    return res.status(201).json({ like });
  } catch (error) {
    console.error("Like error:", error);
    return res.status(500).json({ error: "Failed to like video" });
  }
}

/**
 * DELETE /videos/:id/like
 * Unlike a video (auth required)
 */
export async function unlikeVideoHandler(req: Request, res: Response) {
  const { id: videoId } = req.params;
  const userId = (req as any).user?.userId;

  if (!userId) {
    return res.status(401).json({ error: "Authentication required" });
  }

  try {
    // Check if like exists
    const existing = await prisma.like.findUnique({
      where: {
        userId_videoId: { userId, videoId },
      },
    });

    if (!existing) {
      return res.status(404).json({ error: "Like not found" });
    }

    // Delete like and decrement count atomically
    await prisma.$transaction([
      prisma.like.delete({
        where: {
          userId_videoId: { userId, videoId },
        },
      }),
      prisma.video.update({
        where: { id: videoId },
        data: { likeCount: { decrement: 1 } },
      }),
    ]);

    return res.status(200).json({ message: "Unliked successfully" });
  } catch (error) {
    console.error("Unlike error:", error);
    return res.status(500).json({ error: "Failed to unlike video" });
  }
}

/**
 * GET /videos/:id/likes
 * Get like count and whether current user has liked (optional auth)
 */
export async function getVideoLikesHandler(req: Request, res: Response) {
  const { id: videoId } = req.params;
  const userId = (req as any).user?.userId; // Optional auth

  try {
    const video = await prisma.video.findUnique({
      where: { id: videoId },
      select: { likeCount: true },
    });

    if (!video) {
      return res.status(404).json({ error: "Video not found" });
    }

    let isLikedByUser = false;
    if (userId) {
      const like = await prisma.like.findUnique({
        where: {
          userId_videoId: { userId, videoId },
        },
      });
      isLikedByUser = !!like;
    }

    return res.json({
      videoId,
      likeCount: video.likeCount,
      isLikedByUser,
    });
  } catch (error) {
    console.error("Get likes error:", error);
    return res.status(500).json({ error: "Failed to get likes" });
  }
}
