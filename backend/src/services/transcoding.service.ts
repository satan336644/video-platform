import { prisma } from "../prisma";

export type TranscodingStatus = "PENDING" | "RUNNING" | "COMPLETED" | "FAILED";

export async function createTranscodingJob(params: {
  videoId: string;
  inputObjectKey: string;
}) {
  const { videoId, inputObjectKey } = params;

  return prisma.transcodingJob.create({
    data: {
      videoId,
      inputObjectKey,
      outputPrefix: `processed/${videoId}`,
      status: "PENDING",
    },
  });
}

export async function markJobRunning(jobId: string) {
  return prisma.transcodingJob.update({
    where: { id: jobId },
    data: { status: "RUNNING" },
  });
}

export async function markJobCompleted(jobId: string) {
  return prisma.transcodingJob.update({
    where: { id: jobId },
    data: {
      status: "COMPLETED",
      completedAt: new Date(),
    },
  });
}

export async function markJobFailed(jobId: string) {
  return prisma.transcodingJob.update({
    where: { id: jobId },
    data: { status: "FAILED" },
  });
}
