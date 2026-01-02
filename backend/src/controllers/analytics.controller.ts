import { Request, Response } from 'express';
import {
  startWatchSession,
  endWatchSession,
  getCreatorAnalytics,
  getVideoAnalytics,
  getCreatorLeaderboard,
} from '../services/analytics.service';
import { prisma } from '../prisma';

export async function startWatchSessionHandler(req: Request, res: Response) {
  try {
    const { videoId } = req.body;
    const userId = (req as any).user?.userId;

    if (!videoId) {
      return res.status(400).json({ error: 'videoId is required' });
    }

    const userAgent = req.headers['user-agent'] || '';
    const deviceType = /mobile/i.test(userAgent)
      ? 'mobile'
      : /tablet/i.test(userAgent)
      ? 'tablet'
      : 'desktop';

    const ipAddress = (req.headers['x-forwarded-for'] as string)?.split(',')[0] || req.ip || '';

    const session = await startWatchSession({
      videoId,
      userId,
      deviceType,
      userAgent,
      ipAddress,
    });

    return res.json({ sessionId: session.id });
  } catch (err) {
    console.error('Start watch session error:', err);
    return res.status(500).json({ error: 'Failed to start watch session' });
  }
}

export async function endWatchSessionHandler(req: Request, res: Response) {
  try {
    const { sessionId } = req.params;
    const { watchDuration, percentWatched } = req.body;

    if (!watchDuration || percentWatched === undefined) {
      return res.status(400).json({
        error: 'watchDuration and percentWatched are required',
      });
    }

    await endWatchSession(sessionId, watchDuration, percentWatched);

    return res.json({ success: true });
  } catch (err) {
    console.error('End watch session error:', err);
    return res.status(500).json({ error: 'Failed to end watch session' });
  }
}

export async function getCreatorAnalyticsHandler(req: Request, res: Response) {
  try {
    const userId = (req as any).user?.userId;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const analytics = await getCreatorAnalytics(userId);

    return res.json(analytics);
  } catch (err) {
    console.error('Get creator analytics error:', err);
    return res.status(500).json({ error: 'Failed to fetch analytics' });
  }
}

export async function getVideoAnalyticsHandler(req: Request, res: Response) {
  try {
    const { videoId } = req.params;
    const userId = (req as any).user?.userId;

    if (!userId) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    // Verify user owns this video
    const video = await prisma.video.findUnique({
      where: { id: videoId },
      select: { creatorId: true },
    });

    if (!video) {
      return res.status(404).json({ error: 'Video not found' });
    }

    if (video.creatorId !== userId) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    const analytics = await getVideoAnalytics(videoId);

    return res.json(analytics);
  } catch (err) {
    console.error('Get video analytics error:', err);
    return res.status(500).json({ error: 'Failed to fetch video analytics' });
  }
}

export async function getLeaderboardHandler(req: Request, res: Response) {
  try {
    const { sortBy = 'views', limit = '20' } = req.query;

    if (!['views', 'engagement', 'followers'].includes(sortBy as string)) {
      return res.status(400).json({
        error: 'sortBy must be views, engagement, or followers',
      });
    }

    const leaderboard = await getCreatorLeaderboard(
      sortBy as 'views' | 'engagement' | 'followers',
      parseInt(limit as string) || 20
    );

    return res.json(leaderboard);
  } catch (err) {
    console.error('Get leaderboard error:', err);
    return res.status(500).json({ error: 'Failed to fetch leaderboard' });
  }
}