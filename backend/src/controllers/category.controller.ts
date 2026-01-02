import { Request, Response } from 'express';
import { getAllCategories, getVideosByCategories } from '../services/category.service';
import { VideoCategory } from '@prisma/client';

export async function getAllCategoriesHandler(_req: Request, res: Response) {
  try {
    const categories = await getAllCategories();
    return res.json({ categories });
  } catch (err) {
    console.error('Get categories error:', err);
    return res.status(500).json({ error: 'Failed to fetch categories' });
  }
}

export async function getVideosByCategoryHandler(req: Request, res: Response) {
  try {
    const { category } = req.params;
    const { page, limit, sort } = req.query;

    const categoryEnum = category.toUpperCase().replace(/-/g, '_') as VideoCategory;

    if (!Object.values(VideoCategory).includes(categoryEnum)) {
      return res.status(400).json({ error: 'Invalid category' });
    }

    const result = await getVideosByCategories([categoryEnum], {
      page: page ? parseInt(page as string) : undefined,
      limit: limit ? parseInt(limit as string) : undefined,
      sort: sort as any,
    });

    return res.json(result);
  } catch (err) {
    console.error('Get videos by category error:', err);
    return res.status(500).json({ error: 'Failed to fetch videos' });
  }
}