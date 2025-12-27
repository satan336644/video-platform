import { prisma } from "../prisma";
import { VideoVisibility } from "@prisma/client";

export async function createVideo(data: {
  title: string;
  creatorId: string;
  description?: string;
  category?: string;
  tags?: string[];
  visibility?: VideoVisibility;
}) {
  return prisma.video.create({
    data: {
      title: data.title,
      creatorId: data.creatorId,
      description: data.description ?? "",
      category: data.category ?? null,
      tags: data.tags ?? [],
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
