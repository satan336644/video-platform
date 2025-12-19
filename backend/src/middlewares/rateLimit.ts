import rateLimit from "express-rate-limit";

export const playbackRateLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 60, // 60 requests per minute per IP
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: "Too many requests, please slow down.",
  },
});

export const apiRateLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 120,
});
