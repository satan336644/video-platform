import { prisma } from '../prisma';

export async function createOrGetTag(name: string) {
  const normalized = name.toLowerCase().trim();
  const slug = normalized.replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

  return prisma.tag.upsert({
    where: { slug },
    create: {
      name: normalized,
      slug,
      useCount: 1,
    },
    update: {
      useCount: { increment: 1 },
    },
  });
}

export async function searchTags(query: string, limit = 10) {
  return prisma.tag.findMany({
    where: {
      name: { contains: query.toLowerCase(), mode: 'insensitive' },
    },
    orderBy: [
      { useCount: 'desc' },
      { name: 'asc' },
    ],
    take: limit,
    select: {
      id: true,
      name: true,
      slug: true,
      useCount: true,
    },
  });
}

export async function getPopularTags(limit = 20) {
  return prisma.tag.findMany({
    orderBy: { useCount: 'desc' },
    take: limit,
    select: {
      id: true,
      name: true,
      slug: true,
      useCount: true,
    },
  });
}

export async function addTagsToVideo(videoId: string, tagNames: string[]) {
  const tags = await Promise.all(
    tagNames.map(name => createOrGetTag(name))
  );

  await prisma.$transaction(
    tags.map(tag =>
      prisma.videoTag.upsert({
        where: {
          videoId_tagId: { videoId, tagId: tag.id },
        },
        create: { videoId, tagId: tag.id },
        update: {},
      })
    )
  );

  return tags;
}

export async function removeTagFromVideo(videoId: string, tagId: string) {
  await prisma.videoTag.delete({
    where: {
      videoId_tagId: { videoId, tagId },
    },
  });

  // Decrement use count
  await prisma.tag.update({
    where: { id: tagId },
    data: { useCount: { decrement: 1 } },
  });
}