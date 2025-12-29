import { Request, Response } from "express";
import { prisma } from "../prisma";
import { Prisma } from "@prisma/client";
import { randomUUID } from "crypto";

/**
 * POST /videos/:id/comments
 * Create a comment and emit COMMENT notification to creator
 */
export async function createCommentHandler(req: Request, res: Response) {
  const { id: videoId } = req.params;
  const userId = (req as any).user?.userId;
  const { content } = req.body as { content?: string };

  if (!userId) {
    return res.status(401).json({ error: "Authentication required" });
  }

  if (content !== undefined && typeof content !== "string") {
    return res.status(400).json({ error: "content must be a string" });
  }

  try {
    const video = await prisma.video.findUnique({ where: { id: videoId }, select: { id: true, creatorId: true } });
    if (!video) {
      return res.status(404).json({ error: "Video not found" });
    }

    // Insert comment via raw SQL to avoid client generation issues
    const commentId = randomUUID();
    await prisma.$executeRaw(
      Prisma.sql`INSERT INTO "Comment" (id, "videoId", "userId", content) VALUES (${commentId}, ${videoId}, ${userId}, ${content ?? null})`
    );

    // Emit COMMENT notification to creator (avoid self-notify)
    if (video.creatorId !== userId) {
      try {
        const notifId = randomUUID();
        await prisma.$executeRaw(
          Prisma.sql`INSERT INTO "Notification" (id, "userId", type, "actorId", "videoId") VALUES (${notifId}, ${video.creatorId}, 'COMMENT', ${userId}, ${videoId})`
        );
      } catch (e) {
        console.error("Comment notification error:", (e as any)?.message || e);
      }
    }

    return res.status(201).json({ id: commentId, videoId, userId, content: content ?? null });
  } catch (error) {
    console.error("Create comment error:", error);
    return res.status(500).json({ error: "Failed to create comment" });
  }
}
