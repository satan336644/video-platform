import { Request, Response } from "express";
import { prisma } from "../prisma";

const RECOMMEND_CANDIDATE_SIZE = parseInt(process.env.RECOMMEND_CANDIDATE_SIZE || "200", 10);
const RECOMMEND_RECENT_DAYS = parseInt(process.env.RECOMMEND_RECENT_DAYS || "7", 10);

function daysBetween(a: Date, b: Date) {
  return Math.max(0, Math.floor((a.getTime() - b.getTime()) / (24 * 60 * 60 * 1000)));
}

export async function getRecommendedHandler(req: Request, res: Response) {
  const userId = (req as any).user?.userId as string | undefined;
  const limitRaw = req.query.limit as string | undefined;
  const pageRaw = req.query.page as string | undefined;
  const excludeOwnRaw = req.query.excludeOwn as string | undefined;
  const limit = Math.min(Math.max(parseInt(limitRaw || "20", 10) || 20, 1), 50);
  const page = Math.max(parseInt(pageRaw || "1", 10) || 1, 1);
  const skip = (page - 1) * limit;
  const excludeOwn = excludeOwnRaw ? excludeOwnRaw !== "false" : true;

  try {
    const now = new Date();
    const recentCutoff = new Date(now.getTime() - RECOMMEND_RECENT_DAYS * 24 * 60 * 60 * 1000);

    // Fallback: popular if no auth
    if (!userId) {
      const popular = await prisma.video.findMany({
        where: { visibility: "PUBLIC", status: "READY" },
        orderBy: [{ viewCount: "desc" }, { createdAt: "desc" }],
        take: limit,
        skip,
        select: {
          id: true,
          title: true,
          description: true,
          creatorId: true,
          status: true,
          visibility: true,
          category: true,
          tags: true,
          viewCount: true,
          likeCount: true,
          createdAt: true,
        },
      });

      const items = popular.map((v) => ({ video: v, score: v.viewCount * 0.2 + v.likeCount * 0.5 }));
      return res.json({ items, page, limit, count: items.length });
    }

    // Build preference signals from user's likes and watch history
    const [likedIds, watchedHist] = await Promise.all([
      prisma.like.findMany({ where: { userId }, select: { videoId: true } }),
      prisma.watchHistory.findMany({ where: { userId }, select: { videoId: true, lastWatchedAt: true } }),
    ]);

    const watchedRecentSet = new Set(
      watchedHist.filter((h) => h.lastWatchedAt >= recentCutoff).map((h) => h.videoId)
    );

    const preferenceVideoIds = Array.from(
      new Set([...
        likedIds.map((l) => l.videoId),
        ...watchedHist.map((h) => h.videoId),
      ])
    );

    const prefVideos = preferenceVideoIds.length
      ? await prisma.video.findMany({
          where: { id: { in: preferenceVideoIds } },
          select: { id: true, tags: true, category: true },
        })
      : [];

    const prefTags = new Set<string>();
    const prefCategories = new Set<string>();
    for (const pv of prefVideos) {
      (pv.tags || []).forEach((t) => prefTags.add(t));
      if (pv.category) prefCategories.add(pv.category);
    }

    // Candidate pools: recent and popular
    const [recentPool, popularPool] = await Promise.all([
      prisma.video.findMany({
        where: {
          visibility: "PUBLIC",
          status: "READY",
          id: { notIn: Array.from(watchedRecentSet) },
          ...(excludeOwn ? { creatorId: { not: userId } } : {}),
        },
        orderBy: { createdAt: "desc" },
        take: RECOMMEND_CANDIDATE_SIZE,
        select: {
          id: true,
          title: true,
          description: true,
          creatorId: true,
          status: true,
          visibility: true,
          category: true,
          tags: true,
          viewCount: true,
          likeCount: true,
          createdAt: true,
        },
      }),
      prisma.video.findMany({
        where: {
          visibility: "PUBLIC",
          status: "READY",
          id: { notIn: Array.from(watchedRecentSet) },
          ...(excludeOwn ? { creatorId: { not: userId } } : {}),
        },
        orderBy: [{ viewCount: "desc" }, { likeCount: "desc" }],
        take: RECOMMEND_CANDIDATE_SIZE,
        select: {
          id: true,
          title: true,
          description: true,
          creatorId: true,
          status: true,
          visibility: true,
          category: true,
          tags: true,
          viewCount: true,
          likeCount: true,
          createdAt: true,
        },
      }),
    ]);

    const candidateMap = new Map<string, typeof recentPool[number]>();
    for (const v of [...recentPool, ...popularPool]) {
      candidateMap.set(v.id, v);
    }

    const candidates = Array.from(candidateMap.values());

    const scored = candidates.map((v) => {
      const tagMatchCount = (v.tags || []).filter((t) => prefTags.has(t)).length;
      const categoryMatch = v.category ? prefCategories.has(v.category) : false;
      const days = daysBetween(now, v.createdAt);
      const recencyScore = 1 / (1 + days);
      const score = v.viewCount * 0.2 + v.likeCount * 0.5 + tagMatchCount * 2 + (categoryMatch ? 3 : 0) + recencyScore * 10;
      return { video: v, score, tagMatchCount, categoryMatch };
    });

    scored.sort((a, b) => {
      if (b.score !== a.score) return b.score - a.score;
      if (b.video.createdAt.getTime() !== a.video.createdAt.getTime()) return b.video.createdAt.getTime() - a.video.createdAt.getTime();
      return a.video.id.localeCompare(b.video.id);
    });

    const items = scored.slice(skip, skip + limit);
    return res.json({ items, page, limit, count: items.length });
  } catch (error) {
    console.error("Recommended error:", error);
    return res.status(500).json({ error: "Failed to fetch recommended videos" });
  }
}
