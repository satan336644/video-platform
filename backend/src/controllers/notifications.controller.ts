import { Request, Response } from "express";
import { prisma } from "../prisma";
import { Prisma } from "@prisma/client";

/**
 * GET /me/notifications
 * Auth required, paginated, ordered by createdAt DESC
 */
export async function getMyNotificationsHandler(req: Request, res: Response) {
  const userId = (req as any).user?.userId;
  if (!userId) return res.status(401).json({ error: "Authentication required" });

  const limitRaw = req.query.limit as string | undefined;
  const pageRaw = req.query.page as string | undefined;
  const limit = Math.min(Math.max(parseInt(limitRaw || "20", 10) || 20, 1), 50);
  const page = Math.max(parseInt(pageRaw || "1", 10) || 1, 1);
  const skip = (page - 1) * limit;

  try {
    const notifications = await prisma.$queryRaw<Array<{
      id: string;
      type: string;
      actorId: string;
      videoId: string | null;
      read: boolean;
      createdAt: Date;
    }>>`
      SELECT id, type, "actorId" as "actorId", "videoId" as "videoId", read, "createdAt" as "createdAt"
      FROM "Notification"
      WHERE "userId" = ${userId}
      ORDER BY "createdAt" DESC
      LIMIT ${limit} OFFSET ${skip}
    `;

    return res.json({ items: notifications, page, limit, count: notifications.length });
  } catch (error) {
    console.error("Get notifications error:", error);
    return res.status(500).json({ error: "Failed to get notifications" });
  }
}

/**
 * POST /notifications/:id/read
 * Auth required, ownership enforced
 */
export async function markNotificationReadHandler(req: Request, res: Response) {
  const userId = (req as any).user?.userId;
  if (!userId) return res.status(401).json({ error: "Authentication required" });

  const { id } = req.params;
  try {
    const notif = await prisma.$queryRaw<Array<{ id: string; userId: string; read: boolean }>>`
      SELECT id, "userId", read FROM "Notification" WHERE id = ${id}
    `;
    const n = notif[0];
    if (!n || n.userId !== userId) {
      return res.status(404).json({ error: "Notification not found" });
    }

    await prisma.$executeRaw(
      Prisma.sql`UPDATE "Notification" SET read = true WHERE id = ${id}`
    );
    return res.json({ notification: { id, read: true } });
  } catch (error) {
    console.error("Mark read error:", error);
    return res.status(500).json({ error: "Failed to mark notification as read" });
  }
}
