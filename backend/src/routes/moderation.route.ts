import { Router } from 'express';
import {
  getPendingVideosHandler,
  getFlaggedVideosHandler,
  approveVideoHandler,
  rejectVideoHandler,
  removeVideoHandler,
  createReportHandler,
  getReportsHandler,
  resolveReportHandler,
  dismissReportHandler,
  banUserHandler,
  unbanUserHandler,
  createDMCATakedownHandler,
  getModerationStatsHandler,
} from '../controllers/moderation.controller';
import { requireAuth } from '../middlewares/requireAuth';

const router = Router();

router.get('/admin/moderation/pending', requireAuth(['ADMIN']), getPendingVideosHandler);
router.get('/admin/moderation/flagged', requireAuth(['ADMIN']), getFlaggedVideosHandler);
router.post('/admin/moderation/videos/:videoId/approve', requireAuth(['ADMIN']), approveVideoHandler);
router.post('/admin/moderation/videos/:videoId/reject', requireAuth(['ADMIN']), rejectVideoHandler);
router.post('/admin/moderation/videos/:videoId/remove', requireAuth(['ADMIN']), removeVideoHandler);

router.get('/admin/moderation/reports', requireAuth(['ADMIN']), getReportsHandler);
router.post('/admin/moderation/reports/:reportId/resolve', requireAuth(['ADMIN']), resolveReportHandler);
router.post('/admin/moderation/reports/:reportId/dismiss', requireAuth(['ADMIN']), dismissReportHandler);

router.post('/admin/moderation/users/:userId/ban', requireAuth(['ADMIN']), banUserHandler);
router.post('/admin/moderation/users/:userId/unban', requireAuth(['ADMIN']), unbanUserHandler);

router.get('/admin/moderation/stats', requireAuth(['ADMIN']), getModerationStatsHandler);

router.post('/reports', requireAuth(), createReportHandler);
router.post('/dmca/takedown', createDMCATakedownHandler);

export default router;