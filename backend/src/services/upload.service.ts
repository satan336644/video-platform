import { PrismaClient } from "@prisma/client";
import { v4 as uuid } from "uuid";

const prisma = new PrismaClient();

export async function createUploadSession(videoId: string, creatorId: string) {
  const uploadId = uuid();
  const uploadUrl = `/mock-upload/${uploadId}`;

  return prisma.uploadSession.create({
    data: {
      videoId,
      creatorId,
      uploadUrl,
      status: "PENDING",
    },
  });
}
