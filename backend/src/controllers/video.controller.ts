import { Request, Response } from "express";
import { createVideo, listVideos } from "../services/video.service";

export const createVideoHandler = (req: Request, res: Response) => {
  const { title, creatorId, description } = req.body;

  if (
    typeof title !== "string" ||
    title.trim() === "" ||
    typeof creatorId !== "string" ||
    creatorId.trim() === ""
  ) {
    return res.status(400).json({
      error: "title and creatorId are required and must be non-empty strings",
    });
  }

  if (description !== undefined && typeof description !== "string") {
    return res.status(400).json({
      error: "description, if provided, must be a string",
    });
  }
  try {
    const video = createVideo(title, creatorId, description);
    return res.status(201).json(video);
  } catch (error) {
    console.error("Error creating video:", error);
    return res.status(500).json({
      error: "Failed to create video",
    });
  }
};

export const listVideosHandler = (_req: Request, res: Response) => {
  try {
    const videos = listVideos();
    return res.json(videos);
  } catch (error) {
    console.error("Error listing videos:", error);
    return res.status(500).json({
      error: "Failed to list videos",
    });
  }
};
