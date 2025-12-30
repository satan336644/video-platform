import { Router } from 'express';
import {
  getMeHandler,
  updateMeHandler,
  getUserByUsernameHandler,
  getUserVideosHandler,
} from '../controllers/user.controller';
import { requireAuth } from '../middlewares/requireAuth';

const router = Router();

router.get('/me', requireAuth(['VIEWER', 'CREATOR', 'ADMIN']), getMeHandler);
router.patch('/me', requireAuth(['VIEWER', 'CREATOR', 'ADMIN']), updateMeHandler);
router.get('/:username', getUserByUsernameHandler);
router.get('/:username/videos', getUserVideosHandler);

export default router;