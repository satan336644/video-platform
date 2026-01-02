import { prisma } from '../prisma';

export async function getRelatedVideos(videoId: string, limit = 10) {
  const video = await prisma.video.findUnique({
    where: { id: videoId },
    select: {
      categories: true,
      creatorId: true,
      videoTags: {
        select: { tagId: true },
      },
    },
  });

  if (!video) {
    throw new Error('Video not found');
  }

  const tagIds = video.videoTags.map(vt => vt.tagId);

  // Find videos with overlapping categories or tags, or same creator
  const related = await prisma.video.findMany({
    where: {
      id: { not: videoId },
      status: 'READY',
      visibility: 'PUBLIC',
      OR: [
        video.categories.length > 0 ? { categories: { hasSome: video.categories } } : {},
        tagIds.length > 0 ? { videoTags: { some: { tagId: { in: tagIds } } } } : {},
        { creatorId: video.creatorId },
      ].filter(clause => Object.keys(clause).length > 0),
    },
    orderBy: [
      { viewCount: 'desc' },
      { createdAt: 'desc' },
    ],
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
  });

  return related.map(v => ({
    ...v,
    tags: v.videoTags.map(vt => vt.tag),
  }));
}