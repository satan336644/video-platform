import { Request, Response, NextFunction } from "express";
import { verifyPlaybackToken } from "../utils/playbackToken";

export const requirePlaybackToken = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith("Bearer ")) {
    return res.status(401).json({ error: "Missing playback token" });
  }

  const token = authHeader.split(" ")[1];

  try {
    const payload = verifyPlaybackToken(token);
    (req as any).playback = payload;
    next();
  } catch {
    return res.status(401).json({ error: "Invalid or expired playback token" });
  }
};
