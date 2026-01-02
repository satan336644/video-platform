import { Router } from 'express';
import {
  getAllCategoriesHandler,
  getVideosByCategoryHandler,
} from '../controllers/category.controller';

const router = Router();

router.get('/categories', getAllCategoriesHandler);
router.get('/categories/:category/videos', getVideosByCategoryHandler);

export default router;