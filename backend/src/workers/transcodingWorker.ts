import { prisma } from "../prisma";

const POLL_INTERVAL_MS = 5000;

async function processJobs() {
  const job = await prisma.transcodingJob.findFirst({
    where: { status: "PENDING" },
    orderBy: { createdAt: "asc" },
  });

  if (!job) {
    return;
  }

  console.log(`[WORKER] Picked job ${job.id}`);

  // Lock job
  await prisma.transcodingJob.update({
    where: { id: job.id },
    data: { status: "RUNNING" },
  });

  // Simulate processing
  await new Promise((r) => setTimeout(r, 3000));

  // Mark job complete
  await prisma.transcodingJob.update({
    where: { id: job.id },
    data: {
      status: "COMPLETED",
      completedAt: new Date(),
    },
  });

  // Update video to READY
  await prisma.video.update({
    where: { id: job.videoId },
    data: {
      status: "READY",
      manifestPath: `/processed/${job.videoId}/index.m3u8`,
      processedAt: new Date(),
    },
  });

  console.log(`[WORKER] Job ${job.id} completed`);
}

export function startTranscodingWorker() {
  console.log("[WORKER] Transcoding worker started");

  setInterval(async () => {
    try {
      await processJobs();
    } catch (err) {
      console.error("[WORKER] Error:", err);
    }
  }, POLL_INTERVAL_MS);
}
