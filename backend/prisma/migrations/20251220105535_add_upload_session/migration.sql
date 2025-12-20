-- CreateEnum
CREATE TYPE "UploadStatus" AS ENUM ('PENDING', 'UPLOADING', 'COMPLETED', 'FAILED');

-- CreateTable
CREATE TABLE "UploadSession" (
    "id" TEXT NOT NULL,
    "videoId" TEXT NOT NULL,
    "creatorId" TEXT NOT NULL,
    "status" "UploadStatus" NOT NULL DEFAULT 'PENDING',
    "uploadUrl" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "UploadSession_pkey" PRIMARY KEY ("id")
);
