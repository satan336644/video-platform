-- CreateEnum
CREATE TYPE "VideoStatus" AS ENUM ('CREATED', 'UPLOADED', 'PROCESSING', 'READY', 'FAILED');

-- AlterTable
ALTER TABLE "Video" ADD COLUMN     "manifestPath" TEXT,
ADD COLUMN     "processedAt" TIMESTAMP(3),
ADD COLUMN     "sourceObjectKey" TEXT,
ADD COLUMN     "status" "VideoStatus" NOT NULL DEFAULT 'CREATED';
