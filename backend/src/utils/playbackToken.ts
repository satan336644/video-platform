import jwt from "jsonwebtoken";

const PLAYBACK_TOKEN_SECRET = process.env.PLAYBACK_TOKEN_SECRET || "dev-secret";
const TOKEN_TTL_SECONDS = 60 * 5; // 5 minutes

export interface PlaybackTokenPayload {
  videoId: string;
}

export const generatePlaybackToken = (videoId: string): string => {
  const payload: PlaybackTokenPayload = { videoId };

  return jwt.sign(payload, PLAYBACK_TOKEN_SECRET, {
    expiresIn: TOKEN_TTL_SECONDS,
  });
};

export const verifyPlaybackToken = (token: string): PlaybackTokenPayload => {
  return jwt.verify(token, PLAYBACK_TOKEN_SECRET) as PlaybackTokenPayload;
};
