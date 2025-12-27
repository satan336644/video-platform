-- Phase 15.3: Add table to track used playback tokens for idempotent view increments
CREATE TABLE IF NOT EXISTS "PlaybackTokenUsage" (
  "tokenId" TEXT PRIMARY KEY,
  "videoId" TEXT NOT NULL,
  "usedAt" TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS "PlaybackTokenUsage_videoId_idx" ON "PlaybackTokenUsage" ("videoId");
