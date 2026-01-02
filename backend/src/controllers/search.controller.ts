import { Request, Response } from 'express';
import { searchVideos } from '../services/search.service';
import { VideoCategory } from '@prisma/client';

export async function searchVideosHandler(req: Request, res: Response) {
  try {
    const {
      q,
      categories,
      tags,
      creator,
      minDate,
      maxDate,
      sort,
      page,
      limit,
    } = req.query;

    const params: any = {
      query: q as string | undefined,
      sort: (sort as any) || 'relevance',
      page: page ? parseInt(page as string) : 1,
      limit: limit ? parseInt(limit as string) : 20,
    };

    if (categories) {
      const cats = Array.isArray(categories) ? categories : [categories];
      params.categories = cats
        .map(c => (c as string).toUpperCase().replace(/-/g, '_'))
        .filter(c => Object.values(VideoCategory).includes(c as VideoCategory));
    }

    if (tags) {
      params.tags = Array.isArray(tags) ? tags : [tags];
    }

    if (creator) {
      params.creatorId = creator as string;
    }

    if (minDate) {
      params.minDate = new Date(minDate as string);
    }

    if (maxDate) {
      params.maxDate = new Date(maxDate as string);
    }

    const result = await searchVideos(params);
    return res.json(result);
  } catch (err) {
    console.error('Search error:', err);
    return res.status(500).json({ error: 'Search failed' });
  }
}