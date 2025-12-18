import { Request, Response } from "express";
import { generatePlaybackToken } from "../utils/playbackToken";
import { listVideos } from "../services/video.service";

export const issuePlaybackTokenHandler = (req: Request, res: Response) => {
  const { id } = req.params;

  const videoExists = listVideos().some((v) => v.id === id);
  if (!videoExists) {
    return res.status(404).json({ error: "Video not found" });
  }

  const token = generatePlaybackToken(id);

  return res.json({
    playbackToken: token,
    expiresInSeconds: 300,
  });
};
