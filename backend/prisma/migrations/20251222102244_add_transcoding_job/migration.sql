-- CreateTable
CREATE TABLE "TranscodingJob" (
    "id" TEXT NOT NULL,
    "videoId" TEXT NOT NULL,
    "inputObjectKey" TEXT NOT NULL,
    "outputPrefix" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completedAt" TIMESTAMP(3),

    CONSTRAINT "TranscodingJob_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "TranscodingJob_videoId_idx" ON "TranscodingJob"("videoId");

-- AddForeignKey
ALTER TABLE "TranscodingJob" ADD CONSTRAINT "TranscodingJob_videoId_fkey" FOREIGN KEY ("videoId") REFERENCES "Video"("id") ON DELETE CASCADE ON UPDATE CASCADE;
