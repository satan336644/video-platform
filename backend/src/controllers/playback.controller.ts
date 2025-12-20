import { Request, Response } from "express";
import { generatePlaybackToken } from "../utils/playbackToken";
import { listVideos } from "../services/video.service";

export const issuePlaybackTokenHandler = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    const videos = await listVideos();
    const videoExists = videos.some((v: any) => v.id === id);
    if (!videoExists) {
      return res.status(404).json({ error: "Video not found" });
    }

    const token = generatePlaybackToken(id);

    return res.json({
      playbackToken: token,
      expiresInSeconds: 300,
    });
  } catch (err) {
    console.error("Error issuing playback token:", err);
    return res.status(500).json({ error: "Failed to issue playback token" });
  }
};
