import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { isUserBanned } from '../services/moderation.service';

export async function checkBanned(req: Request, res: Response, next: NextFunction) {
  let userId = (req as any).user?.userId;

  if (!userId) {
    const authHeader = req.headers.authorization;
    if (authHeader) {
      const token = authHeader.split(' ')[1];
      try {
        const payload = jwt.verify(token, process.env.JWT_SECRET || 'dev-secret') as any;
        (req as any).user = payload;
        userId = payload.userId;
      } catch {
        // ignore invalid token; requireAuth will handle
      }
    }
  }

  if (!userId) return next();

  const banned = await isUserBanned(userId);
  if (banned) {
    return res.status(403).json({ error: 'Your account has been suspended or banned' });
  }

  return next();
}