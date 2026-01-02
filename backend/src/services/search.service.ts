import { prisma } from '../prisma';
import { VideoCategory, Prisma } from '@prisma/client';

export async function searchVideos(params: {
  query?: string;
  categories?: VideoCategory[];
  tags?: string[];
  creatorId?: string;
  minDate?: Date;
  maxDate?: Date;
  sort?: 'relevance' | 'views' | 'likes' | 'recent';
  page?: number;
  limit?: number;
}) {
  const page = params.page || 1;
  const limit = Math.min(params.limit || 20, 50);
  const skip = (page - 1) * limit;

  // Build where clause
  const where: Prisma.VideoWhereInput = {
    status: 'READY',
    visibility: 'PUBLIC',
  };

  // Text search
  if (params.query) {
    where.OR = [
      { title: { contains: params.query, mode: 'insensitive' } },
      { description: { contains: params.query, mode: 'insensitive' } },
    ];
  }

  // Category filter
  if (params.categories && params.categories.length > 0) {
    where.categories = { hasSome: params.categories };
  }

  // Tag filter
  if (params.tags && params.tags.length > 0) {
    where.videoTags = {
      some: {
        tag: {
          slug: { in: params.tags },
        },
      },
    };
  }

  // Creator filter
  if (params.creatorId) {
    where.creatorId = params.creatorId;
  }

  // Date range
  if (params.minDate || params.maxDate) {
    where.createdAt = {};
    if (params.minDate) (where.createdAt as any).gte = params.minDate;
    if (params.maxDate) (where.createdAt as any).lte = params.maxDate;
  }

  // Sort order
  const orderBy =
    params.sort === 'views' ? { viewCount: 'desc' as const } :
    params.sort === 'likes' ? { likeCount: 'desc' as const } :
    params.sort === 'recent' ? { createdAt: 'desc' as const } :
    [{ viewCount: 'desc' as const }, { createdAt: 'desc' as const }];

  const [videos, total] = await Promise.all([
    prisma.video.findMany({
      where,
      orderBy,
      skip,
      take: limit,
      select: {
        id: true,
        title: true,
        description: true,
        categories: true,
        viewCount: true,
        likeCount: true,
        createdAt: true,
        creator: {
          select: {
            id: true,
            username: true,
            profile: {
              select: { displayName: true, avatarUrl: true },
            },
          },
        },
        videoTags: {
          select: {
            tag: { select: { name: true, slug: true } },
          },
        },
      },
    }),
    prisma.video.count({ where }),
  ]);

  return {
    videos: videos.map(v => ({
      ...v,
      tags: v.videoTags.map(vt => vt.tag),
    })),
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
      hasMore: skip + videos.length < total,
    },
  };
}