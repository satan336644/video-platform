import { prisma } from "../prisma";

export async function createVideo(data: {
  title: string;
  description?: string;
  creatorId: string;
}) {
  return prisma.video.create({
    data: {
      title: data.title,
      description: data.description ?? "",
      creatorId: data.creatorId,
    },
  });
}

export async function listVideos() {
  return prisma.video.findMany({
    orderBy: { createdAt: "desc" },
  });
}
