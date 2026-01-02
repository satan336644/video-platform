import { Router } from 'express';
import {
  startWatchSessionHandler,
  endWatchSessionHandler,
  getCreatorAnalyticsHandler,
  getVideoAnalyticsHandler,
  getLeaderboardHandler,
} from '../controllers/analytics.controller';
import { requireAuth } from '../middlewares/requireAuth';
import { optionalAuth } from '../middlewares/optionalAuth';

const router = Router();

// Watch session tracking
router.post('/analytics/watch/start', optionalAuth(), startWatchSessionHandler);
router.post('/analytics/watch/:sessionId/end', optionalAuth(), endWatchSessionHandler);

// Creator analytics
router.get(
  '/creators/me/analytics',
  requireAuth(['CREATOR', 'ADMIN']),
  getCreatorAnalyticsHandler
);

// Video analytics
router.get(
  '/videos/:videoId/analytics',
  requireAuth(['CREATOR', 'ADMIN']),
  getVideoAnalyticsHandler
);

// Public leaderboard
router.get('/analytics/leaderboard', getLeaderboardHandler);

export default router;