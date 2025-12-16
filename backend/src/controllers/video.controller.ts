import { Request, Response } from "express";
import { createVideo, listVideos } from "../services/video.service";

export const createVideoHandler = (req: Request, res: Response) => {
  const { title, creatorId, description } = req.body;

  if (!title || !creatorId) {
    return res.status(400).json({
      error: "title and creatorId are required",
    });
  }

  const video = createVideo(title, creatorId, description);
  return res.status(201).json(video);
};

export const listVideosHandler = (_req: Request, res: Response) => {
  const videos = listVideos();
  return res.json(videos);
};
