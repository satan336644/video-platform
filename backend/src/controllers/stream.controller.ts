import { Request, Response } from "express";

export const getProtectedManifestHandler = (req: Request, res: Response) => {
  const playback = (req as any).playback;

  return res.json({
    message: "Access granted to protected stream",
    videoId: playback.videoId,
    manifestUrl: `/mock-hls/${playback.videoId}/index.m3u8`,
  });
};
