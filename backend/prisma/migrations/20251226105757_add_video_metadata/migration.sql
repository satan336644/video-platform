-- CreateEnum
CREATE TYPE "VideoVisibility" AS ENUM ('PUBLIC', 'UNLISTED', 'PRIVATE');

-- AlterEnum
-- This migration adds more than one value to an enum.
-- With PostgreSQL versions 11 and earlier, this is not possible
-- in a single migration. This can be worked around by creating
-- multiple migrations, each migration adding only one value to
-- the enum.


ALTER TYPE "VideoStatus" ADD VALUE 'HIDDEN';
ALTER TYPE "VideoStatus" ADD VALUE 'FLAGGED';
ALTER TYPE "VideoStatus" ADD VALUE 'REMOVED';

-- AlterTable
ALTER TABLE "Video" ADD COLUMN     "category" TEXT,
ADD COLUMN     "tags" TEXT[],
ADD COLUMN     "visibility" "VideoVisibility" NOT NULL DEFAULT 'PUBLIC',
ALTER COLUMN "description" DROP NOT NULL;

-- CreateIndex
CREATE INDEX "Video_creatorId_idx" ON "Video"("creatorId");

-- CreateIndex
CREATE INDEX "Video_status_idx" ON "Video"("status");

-- CreateIndex
CREATE INDEX "Video_visibility_idx" ON "Video"("visibility");
