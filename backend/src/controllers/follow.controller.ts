import { Request, Response } from "express";
import { prisma } from "../prisma";
import { Prisma } from "@prisma/client";
import { randomUUID } from "crypto";

/**
 * POST /users/:id/follow
 * Follow a user and emit FOLLOW notification to target
 */
export async function followUserHandler(req: Request, res: Response) {
  const { id: targetUserId } = req.params;
  const actorUserId = (req as any).user?.userId;

  if (!actorUserId) {
    return res.status(401).json({ error: "Authentication required" });
  }

  // Block self-follow
  if (actorUserId === targetUserId) {
    return res.status(400).json({ error: "Cannot follow yourself" });
  }

  try {
    // Create follow if not exists
    const followId = randomUUID();
    // Use ON CONFLICT DO NOTHING to avoid duplicates
    const rowsInserted = await prisma.$executeRaw(
      Prisma.sql`INSERT INTO "Follow" (id, "userId", "followerId") VALUES (${followId}, ${targetUserId}, ${actorUserId}) ON CONFLICT ("userId", "followerId") DO NOTHING`
    );

    const created = rowsInserted === 1;

    // Emit FOLLOW notification (only if a new follow was created)
    if (created) {
      try {
        const notifId = randomUUID();
        await prisma.$executeRaw(
          Prisma.sql`INSERT INTO "Notification" (id, "userId", type, "actorId") VALUES (${notifId}, ${targetUserId}, 'FOLLOW', ${actorUserId})`
        );
      } catch (e) {
        console.error("Follow notification error:", (e as any)?.message || e);
      }
    }

    return res.status(201).json({ followed: created, alreadyFollowing: !created });
  } catch (error) {
    console.error("Follow user error:", error);
    return res.status(500).json({ error: "Failed to follow user" });
  }
}
