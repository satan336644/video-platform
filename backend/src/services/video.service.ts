import { prisma } from "../prisma";
import { VideoVisibility, VideoCategory } from "@prisma/client";

export async function createVideo(data: {
  title: string;
  creatorId: string;
  description?: string;
  category?: string;
  tags?: string[];
  categories?: VideoCategory[];
  visibility?: VideoVisibility;
}) {
  return prisma.video.create({
    data: {
      title: data.title,
      creatorId: data.creatorId,
      description: data.description ?? "",
      category: data.category ?? null, // Old format (backward compatibility)
      tags: data.tags ?? [], // Old format (backward compatibility)
      categories: data.categories ?? [], // New Phase 19 format
      visibility: data.visibility ?? "PUBLIC",
    },
  });
}

export async function listVideos() {
  return prisma.video.findMany({
    orderBy: { createdAt: "desc" },
  });
}

export async function getVideoById(videoId: string) {
  return prisma.video.findUnique({
    where: { id: videoId },
  });
}

export async function updateVideoMetadata(
  videoId: string,
  creatorId: string,
  data: {
    title?: string;
    description?: string;
    category?: string;
    tags?: string[];
    visibility?: VideoVisibility;
  }
) {
  // Verify creator owns this video
  const video = await prisma.video.findUnique({
    where: { id: videoId },
    select: { creatorId: true },
  });

  if (!video) {
    throw new Error("Video not found");
  }

  if (video.creatorId !== creatorId) {
    throw new Error("Unauthorized: only creator can update metadata");
  }

  // Update only provided fields
  return prisma.video.update({
    where: { id: videoId },
    data: {
      ...(data.title && { title: data.title }),
      ...(data.description && { description: data.description }),
      ...(data.category !== undefined && { category: data.category }),
      ...(data.tags && { tags: data.tags }),
      ...(data.visibility && { visibility: data.visibility }),
    },
  });
}

export async function listPublicVideos(filters?: {
  tag?: string;
  category?: string;
}) {
  const where: any = {
    status: "READY",
    visibility: "PUBLIC",
  };

  if (filters?.tag) {
    where.tags = { has: filters.tag };
  }

  if (filters?.category) {
    where.category = filters.category;
  }

  return prisma.video.findMany({
    where,
    orderBy: { createdAt: "desc" },
  });
}

export async function searchVideos(query: string) {
  return prisma.video.findMany({
    where: {
      status: "READY",
      visibility: "PUBLIC",
      OR: [
        { title: { contains: query, mode: "insensitive" } },
        { description: { contains: query, mode: "insensitive" } },
        { tags: { has: query } },
      ],
    },
    orderBy: { createdAt: "desc" },
  });
}

export async function getCreatorVideos(
  creatorId: string,
  filters?: {
    status?: string;
    visibility?: string;
    page?: number;
    limit?: number;
  }
) {
  const page = filters?.page ?? 1;
  const limit = filters?.limit ?? 20;
  const skip = (page - 1) * limit;

  const where: any = { creatorId };

  if (filters?.status) {
    where.status = filters.status;
  }

  if (filters?.visibility) {
    where.visibility = filters.visibility;
  }

  const [videos, total] = await Promise.all([
    prisma.video.findMany({
      where,
      skip,
      take: limit,
      orderBy: { createdAt: "desc" },
    }),
    prisma.video.count({ where }),
  ]);

  return {
    videos,
    pagination: {
      page,
      limit,
      total,
      pages: Math.ceil(total / limit),
    },
  };
}

export async function getPublicVideoDetail(videoId: string) {
  const video = await prisma.video.findUnique({
    where: { id: videoId },
  });

  if (!video) {
    return null;
  }

  // Only return if PUBLIC and READY
  if (video.visibility !== "PUBLIC" || video.status !== "READY") {
    return null;
  }

  // Increment view count asynchronously (fire-and-forget)
  prisma.video
    .update({
      where: { id: videoId },
      data: { viewCount: { increment: 1 } },
    })
    .catch((error) => {
      console.error("Failed to increment view count:", error);
    });

  return {
    id: video.id,
    title: video.title,
    description: video.description,
    category: video.category,
    tags: video.tags,
    visibility: video.visibility,
    status: video.status,
    viewCount: video.viewCount,
    createdAt: video.createdAt,
    creator: {
      id: video.creatorId,
    },
    playback: {
      manifestUrl: `${process.env.R2_PUBLIC_URL}/processed/${video.id}/index.m3u8`,
    },
  };
}

export async function getPopularVideos(limit: number = 20) {
  return prisma.video.findMany({
    where: {
      status: "READY",
      visibility: "PUBLIC",
    },
    orderBy: [
      { viewCount: "desc" },
      { createdAt: "desc" },
    ],
    take: limit,
  });
}

export async function getTrendingVideos(limit: number = 20) {
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

  return prisma.video.findMany({
    where: {
      status: "READY",
      visibility: "PUBLIC",
      createdAt: {
        gte: sevenDaysAgo,
      },
    },
    orderBy: [
      { viewCount: "desc" },
      { createdAt: "desc" },
    ],
    take: limit,
  });
}

// Phase 15.2: Creator Stats & Analytics (Foundation)
export async function getCreatorAggregateStats(creatorId: string) {
  const [totalVideos, readyVideos, publicVideos, viewsAgg] = await Promise.all([
    prisma.video.count({ where: { creatorId } }),
    prisma.video.count({ where: { creatorId, status: "READY" } }),
    prisma.video.count({ where: { creatorId, visibility: "PUBLIC" } }),
    prisma.video.aggregate({ where: { creatorId }, _sum: { viewCount: true } }),
  ]);

  return {
    totalVideos,
    readyVideos,
    totalViews: viewsAgg._sum.viewCount || 0,
    publicVideos,
  };
}

export async function getCreatorVideoStats(creatorId: string) {
  return prisma.video.findMany({
    where: { creatorId },
    select: {
      id: true,
      title: true,
      status: true,
      visibility: true,
      viewCount: true,
      createdAt: true,
    },
    orderBy: { createdAt: "desc" },
  });
}
