import { Request, Response } from "express";
import { createVideo, listVideos, updateVideoMetadata, getVideoById, listPublicVideos, searchVideos, getCreatorVideos, getPublicVideoDetail } from "../services/video.service";

export const createVideoHandler = async (req: Request, res: Response) => {
  const { title, creatorId, description, category, tags, visibility } = req.body;

  // Validate required fields
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

  // Validate optional string fields
  if (description !== undefined && typeof description !== "string") {
    return res.status(400).json({
      error: "description, if provided, must be a string",
    });
  }

  if (category !== undefined && typeof category !== "string") {
    return res.status(400).json({
      error: "category, if provided, must be a string",
    });
  }

  // Validate tags array
  if (tags !== undefined && (!Array.isArray(tags) || !tags.every((t) => typeof t === "string"))) {
    return res.status(400).json({
      error: "tags, if provided, must be an array of strings",
    });
  }

  // Validate visibility enum
  if (visibility !== undefined && !["PUBLIC", "UNLISTED", "PRIVATE"].includes(visibility)) {
    return res.status(400).json({
      error: "visibility must be one of: PUBLIC, UNLISTED, PRIVATE",
    });
  }

  try {
    const video = await createVideo({
      title,
      creatorId,
      description,
      category,
      tags,
      visibility: visibility || "PUBLIC",
    });
    return res.status(201).json(video);
  } catch (error) {
    console.error("Error creating video:", error);
    return res.status(500).json({
      error: "Failed to create video",
    });
  }
};

export const listVideosHandler = async (_req: Request, res: Response) => {
  try {
    const videos = await listVideos();
    return res.json(videos);
  } catch (error) {
    console.error("Error listing videos:", error);
    return res.status(500).json({
      error: "Failed to list videos",
    });
  }
};

export const updateVideoMetadataHandler = async (req: Request, res: Response) => {
  const { id } = req.params;
  const creatorId = (req as any).user?.userId; // From auth middleware
  const { title, description, category, tags, visibility } = req.body;

  if (!creatorId) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  // Validate optional fields
  if (title !== undefined && typeof title !== "string") {
    return res.status(400).json({ error: "title must be a string" });
  }

  if (description !== undefined && typeof description !== "string") {
    return res.status(400).json({ error: "description must be a string" });
  }

  if (category !== undefined && typeof category !== "string") {
    return res.status(400).json({ error: "category must be a string" });
  }

  if (tags !== undefined && (!Array.isArray(tags) || !tags.every((t) => typeof t === "string"))) {
    return res.status(400).json({ error: "tags must be an array of strings" });
  }

  if (visibility !== undefined && !["PUBLIC", "UNLISTED", "PRIVATE"].includes(visibility)) {
    return res.status(400).json({ error: "visibility must be one of: PUBLIC, UNLISTED, PRIVATE" });
  }

  try {
    const updated = await updateVideoMetadata(id, creatorId, {
      title,
      description,
      category,
      tags,
      visibility,
    });
    return res.json(updated);
  } catch (error: any) {
    if (error.message === "Video not found") {
      return res.status(404).json({ error: "Video not found" });
    }
    if (error.message.includes("Unauthorized")) {
      return res.status(403).json({ error: "Only creator can update metadata" });
    }
    console.error("Error updating video metadata:", error);
    return res.status(500).json({ error: "Failed to update video metadata" });
  }
};

export const getVideoHandler = async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const video = await getVideoById(id);
    if (!video) {
      return res.status(404).json({ error: "Video not found" });
    }
    return res.json(video);
  } catch (error) {
    console.error("Error fetching video:", error);
    return res.status(500).json({ error: "Failed to fetch video" });
  }
};

export const listPublicVideosHandler = async (req: Request, res: Response) => {
  const { tag, category } = req.query;

  // Validate query parameters
  if (tag !== undefined && typeof tag !== "string") {
    return res.status(400).json({ error: "tag must be a string" });
  }

  if (category !== undefined && typeof category !== "string") {
    return res.status(400).json({ error: "category must be a string" });
  }

  try {
    const videos = await listPublicVideos({
      tag: tag as string | undefined,
      category: category as string | undefined,
    });
    return res.json(videos);
  } catch (error) {
    console.error("Error listing public videos:", error);
    return res.status(500).json({ error: "Failed to list public videos" });
  }
};

export const searchVideosHandler = async (req: Request, res: Response) => {
  const { q } = req.query;

  if (!q || typeof q !== "string") {
    return res.status(400).json({ error: "q query parameter is required and must be a string" });
  }

  try {
    const videos = await searchVideos(q);
    return res.json(videos);
  } catch (error) {
    console.error("Error searching videos:", error);
    return res.status(500).json({ error: "Failed to search videos" });
  }
};

export const getCreatorVideosHandler = async (req: Request, res: Response) => {
  const creatorId = (req as any).user?.userId;
  const { status, visibility, page, limit } = req.query;

  if (!creatorId) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  // Validate optional query parameters
  if (status !== undefined && typeof status !== "string") {
    return res.status(400).json({ error: "status must be a string" });
  }

  if (visibility !== undefined && typeof visibility !== "string") {
    return res.status(400).json({ error: "visibility must be a string" });
  }

  const pageNum = parseInt(page as string, 10) || 1;
  const limitNum = parseInt(limit as string, 10) || 20;

  if (pageNum < 1 || limitNum < 1) {
    return res.status(400).json({ error: "page and limit must be positive integers" });
  }

  try {
    const result = await getCreatorVideos(creatorId, {
      status: status as string | undefined,
      visibility: visibility as string | undefined,
      page: pageNum,
      limit: limitNum,
    });
    return res.json(result);
  } catch (error) {
    console.error("Error fetching creator videos:", error);
    return res.status(500).json({ error: "Failed to fetch creator videos" });
  }
};

export const getPublicVideoDetailHandler = async (req: Request, res: Response) => {
  const { id } = req.params;

  try {
    const video = await getPublicVideoDetail(id);
    if (!video) {
      return res.status(404).json({ error: "Video not found" });
    }
    return res.json(video);
  } catch (error) {
    console.error("Error fetching public video detail:", error);
    return res.status(500).json({ error: "Failed to fetch public video detail" });
  }
};
