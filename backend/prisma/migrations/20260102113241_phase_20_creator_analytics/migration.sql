-- CreateTable
CREATE TABLE "VideoAnalytics" (
    "id" TEXT NOT NULL,
    "videoId" TEXT NOT NULL,
    "totalViews" INTEGER NOT NULL DEFAULT 0,
    "totalWatchTime" BIGINT NOT NULL DEFAULT 0,
    "averageWatchTime" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "completionRate" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "engagementScore" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "uniqueViewers" INTEGER NOT NULL DEFAULT 0,
    "peakViewerTime" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "VideoAnalytics_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "WatchSession" (
    "id" TEXT NOT NULL,
    "userId" TEXT,
    "videoId" TEXT NOT NULL,
    "sessionStart" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "sessionEnd" TIMESTAMP(3),
    "watchDuration" INTEGER NOT NULL DEFAULT 0,
    "percentWatched" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "completedVideo" BOOLEAN NOT NULL DEFAULT false,
    "deviceType" TEXT,
    "userAgent" TEXT,
    "ipAddress" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "WatchSession_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "CreatorStats" (
    "id" TEXT NOT NULL,
    "creatorId" TEXT NOT NULL,
    "totalVideos" INTEGER NOT NULL DEFAULT 0,
    "totalViews" BIGINT NOT NULL DEFAULT 0,
    "totalWatchTime" BIGINT NOT NULL DEFAULT 0,
    "totalLikes" INTEGER NOT NULL DEFAULT 0,
    "totalComments" INTEGER NOT NULL DEFAULT 0,
    "totalFollowers" INTEGER NOT NULL DEFAULT 0,
    "averageEngagement" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "topVideo" TEXT,
    "lastActivityAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "CreatorStats_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "VideoAnalytics_videoId_key" ON "VideoAnalytics"("videoId");

-- CreateIndex
CREATE INDEX "VideoAnalytics_videoId_idx" ON "VideoAnalytics"("videoId");

-- CreateIndex
CREATE INDEX "VideoAnalytics_engagementScore_idx" ON "VideoAnalytics"("engagementScore");

-- CreateIndex
CREATE INDEX "VideoAnalytics_totalViews_idx" ON "VideoAnalytics"("totalViews");

-- CreateIndex
CREATE INDEX "VideoAnalytics_updatedAt_idx" ON "VideoAnalytics"("updatedAt");

-- CreateIndex
CREATE INDEX "WatchSession_videoId_idx" ON "WatchSession"("videoId");

-- CreateIndex
CREATE INDEX "WatchSession_userId_idx" ON "WatchSession"("userId");

-- CreateIndex
CREATE INDEX "WatchSession_sessionStart_idx" ON "WatchSession"("sessionStart");

-- CreateIndex
CREATE INDEX "WatchSession_completedVideo_idx" ON "WatchSession"("completedVideo");

-- CreateIndex
CREATE UNIQUE INDEX "CreatorStats_creatorId_key" ON "CreatorStats"("creatorId");

-- CreateIndex
CREATE INDEX "CreatorStats_creatorId_idx" ON "CreatorStats"("creatorId");

-- CreateIndex
CREATE INDEX "CreatorStats_totalViews_idx" ON "CreatorStats"("totalViews");

-- CreateIndex
CREATE INDEX "CreatorStats_averageEngagement_idx" ON "CreatorStats"("averageEngagement");

-- AddForeignKey
ALTER TABLE "VideoAnalytics" ADD CONSTRAINT "VideoAnalytics_videoId_fkey" FOREIGN KEY ("videoId") REFERENCES "Video"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WatchSession" ADD CONSTRAINT "WatchSession_videoId_fkey" FOREIGN KEY ("videoId") REFERENCES "Video"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "WatchSession" ADD CONSTRAINT "WatchSession_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CreatorStats" ADD CONSTRAINT "CreatorStats_creatorId_fkey" FOREIGN KEY ("creatorId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
