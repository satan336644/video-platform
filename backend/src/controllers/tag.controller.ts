import { Request, Response } from 'express';
import { searchTags, getPopularTags } from '../services/tag.service';

export async function autocompleteTagsHandler(req: Request, res: Response) {
  try {
    const { q, limit } = req.query;

    if (!q || typeof q !== 'string') {
      return res.status(400).json({ error: 'Query parameter "q" is required' });
    }

    const tags = await searchTags(q, limit ? parseInt(limit as string) : undefined);
    return res.json({ tags });
  } catch (err) {
    console.error('Tag autocomplete error:', err);
    return res.status(500).json({ error: 'Failed to search tags' });
  }
}

export async function getPopularTagsHandler(req: Request, res: Response) {
  try {
    const { limit } = req.query;
    const tags = await getPopularTags(limit ? parseInt(limit as string) : undefined);
    return res.json({ tags });
  } catch (err) {
    console.error('Get popular tags error:', err);
    return res.status(500).json({ error: 'Failed to fetch popular tags' });
  }
}