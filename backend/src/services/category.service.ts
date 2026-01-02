import { prisma } from '../prisma';
import { VideoCategory } from '@prisma/client';

export async function getAllCategories() {
  // Get all categories with video counts
  const videos = await prisma.video.findMany({
    where: {
      status: 'READY',
      visibility: 'PUBLIC',
    },
    select: {
      categories: true,
    },
  });

  // Count videos per category
  const counts: Record<string, number> = {};
  for (const cat of Object.values(VideoCategory)) {
    counts[cat] = 0;
  }

  for (const video of videos) {
    for (const cat of video.categories) {
      counts[cat] = (counts[cat] || 0) + 1;
    }
  }

  return Object.entries(counts).map(([category, count]) => ({
    category,
    count,
    slug: category.toLowerCase().replace(/_/g, '-'),
  }));
}

export async function getVideosByCategories(
  categories: VideoCategory[],
  options: {
    page?: number;
    limit?: number;
    sort?: 'recent' | 'views' | 'likes';
  } = {}
) {
  const page = options.page || 1;
  const limit = Math.min(options.limit || 20, 50);
  const skip = (page - 1) * limit;

  const orderBy =
    options.sort === 'views' ? { viewCount: 'desc' as const } :
    options.sort === 'likes' ? { likeCount: 'desc' as const } :
    { createdAt: 'desc' as const };

  const where = {
    status: 'READY' as const,
    visibility: 'PUBLIC' as const,
    categories: { hasSome: categories },
  };

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
    },
  };
}