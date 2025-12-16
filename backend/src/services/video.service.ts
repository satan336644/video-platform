import { Video } from "../types/video";
import { randomUUID } from "crypto";

// In-memory storage (POC only)
const videos: Video[] = [];

export const createVideo = (
  title: string,
  creatorId: string,
  description?: string
): Video => {
  const video: Video = {
    id: randomUUID(),
    title,
    description,
    creatorId,
    createdAt: new Date(),
  };

  videos.push(video);
  return video;
};

export const listVideos = (): Video[] => {
  return videos;
};
