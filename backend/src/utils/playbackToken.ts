import jwt from "jsonwebtoken";
import { randomUUID } from "crypto";

const PLAYBACK_TOKEN_SECRET = process.env.PLAYBACK_TOKEN_SECRET || "dev-secret";
const TOKEN_TTL_SECONDS = 60 * 5; // 5 minutes

export interface PlaybackTokenPayload {
  videoId: string;
  jti: string; // unique token id for idempotency
}

export const generatePlaybackToken = (videoId: string): string => {
  const payload: PlaybackTokenPayload = { videoId, jti: randomUUID() };

  return jwt.sign(payload, PLAYBACK_TOKEN_SECRET, {
    expiresIn: TOKEN_TTL_SECONDS,
  });
};

export const verifyPlaybackToken = (token: string): PlaybackTokenPayload => {
  return jwt.verify(token, PLAYBACK_TOKEN_SECRET) as PlaybackTokenPayload;
};
