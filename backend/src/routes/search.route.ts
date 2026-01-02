import { Router } from 'express';
import { searchVideosHandler } from '../controllers/search.controller';

const router = Router();

router.get('/search', searchVideosHandler);

export default router;