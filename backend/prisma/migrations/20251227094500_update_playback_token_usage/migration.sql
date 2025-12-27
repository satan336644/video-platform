-- Phase 15.4: Extend playback token usage metadata
ALTER TABLE "PlaybackTokenUsage"
  ADD COLUMN IF NOT EXISTS "issuedAt" TIMESTAMP NOT NULL DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS "viewCounted" BOOLEAN NOT NULL DEFAULT FALSE,
  ALTER COLUMN "usedAt" DROP DEFAULT;

-- Backfill existing rows to keep invariants
UPDATE "PlaybackTokenUsage" SET "issuedAt" = "usedAt" WHERE "issuedAt" IS NULL;
