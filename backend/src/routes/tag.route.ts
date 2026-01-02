import { Router } from 'express';
import {
  autocompleteTagsHandler,
  getPopularTagsHandler,
} from '../controllers/tag.controller';

const router = Router();

router.get('/tags/autocomplete', autocompleteTagsHandler);
router.get('/tags/popular', getPopularTagsHandler);

export default router;