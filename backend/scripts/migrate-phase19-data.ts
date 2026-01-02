import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function migrateCategories() {
  console.log('Migrating old categories to new system...');

  const videos = await prisma.video.findMany({
    select: { id: true, category: true },
  });

  let migrated = 0;

  for (const video of videos) {
    if (video.category) {
      const normalized = video.category.toUpperCase().replace(/\s+/g, '_').replace(/-/g, '_');

      // Check if it's a valid category
      const isValid = [
        'TRANSGENDER', 'SM_BDSM', 'FOOT_FETISH', 'AMATEUR', 'PROFESSIONAL',
        'SOLO', 'COUPLE', 'GROUP', 'COSPLAY', 'ROLEPLAY', 'VINTAGE', 'POV',
        'COMPILATION', 'INSTRUCTIONAL', 'OTHER',
      ].includes(normalized);

      const categories = isValid ? [normalized] : ['OTHER'];

      await prisma.video.update({
        where: { id: video.id },
        data: { categories: categories as any },
      });

      migrated++;
    }
  }

  console.log(`✓ Migrated ${migrated} video categories`);
}

async function migrateTags() {
  console.log('Migrating old tags to new system...');

  const videos = await prisma.video.findMany({
    select: { id: true, tags: true },
  });

  let tagsCreated = 0;
  let tagRelationsCreated = 0;

  for (const video of videos) {
    if (video.tags && video.tags.length > 0) {
      for (const tagName of video.tags) {
        try {
          const slug = tagName
            .toLowerCase()
            .trim()
            .replace(/[^a-z0-9]+/g, '-')
            .replace(/^-|-$/g, '');

          const tag = await prisma.tag.upsert({
            where: { slug },
            create: {
              name: tagName.toLowerCase().trim(),
              slug,
              useCount: 1,
            },
            update: {
              useCount: { increment: 1 },
            },
          });

          await prisma.videoTag.upsert({
            where: {
              videoId_tagId: { videoId: video.id, tagId: tag.id },
            },
            create: { videoId: video.id, tagId: tag.id },
            update: {},
          });

          tagRelationsCreated++;
          if (tag.createdAt.getTime() === tag.updatedAt.getTime()) {
            tagsCreated++;
          }
        } catch (err: any) {
          console.error(`Failed to create/link tag "${tagName}":`, err.message);
        }
      }
    }
  }

  console.log(`✓ Created ${tagsCreated} new tags`);
  console.log(`✓ Created ${tagRelationsCreated} tag relationships`);
}

async function main() {
  try {
    await migrateCategories();
    await migrateTags();
    console.log('\n✅ Phase 19 data migration complete!');
  } catch (err) {
    console.error('❌ Migration failed:', err);
    process.exit(1);
  }
}

main().finally(() => prisma.$disconnect());