-- CreateTable
CREATE TABLE "StoredObject" (
    "id" TEXT NOT NULL,
    "videoId" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "objectKey" TEXT NOT NULL,
    "contentType" TEXT,
    "sizeBytes" INTEGER,
    "status" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "StoredObject_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "StoredObject_videoId_idx" ON "StoredObject"("videoId");
