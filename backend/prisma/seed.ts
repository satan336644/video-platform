const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcrypt');

const prisma = new PrismaClient();
const SALT_ROUNDS = 10;

async function main() {
  console.log('🌱 Starting database seed...');

  // Create test users
  const testUsers = [
    {
      email: 'creator1@example.com',
      username: 'hotcreator69',
      password: 'SecurePass123',
      role: 'CREATOR',
      profile: {
        displayName: 'Hot Creator 69',
        bio: 'Professional adult content creator',
        socialLinks: { twitter: 'hotcreator69', instagram: 'hotcreator69' },
      },
    },
    {
      email: 'creator2@example.com',
      username: 'sultry_videos',
      password: 'CreatorPass456',
      role: 'CREATOR',
      profile: {
        displayName: 'Sultry Videos',
        bio: 'Premium exclusive content',
        socialLinks: { twitter: 'sultry_videos' },
      },
    },
    {
      email: 'viewer1@example.com',
      username: 'viewer_fan',
      password: 'ViewerPass789',
      role: 'VIEWER',
      profile: {
        displayName: 'Viewer Fan',
        bio: 'Just here to enjoy great content',
        socialLinks: undefined,
      },
    },
    {
      email: 'admin@example.com',
      username: 'admin_user',
      password: 'AdminPass999',
      role: 'ADMIN',
      profile: {
        displayName: 'Admin',
        bio: 'Platform administrator',
        socialLinks: undefined,
        isPublic: false,
      },
    },
  ];

  for (const testUser of testUsers) {
    try {
      const existingUser = await prisma.user.findUnique({
        where: { email: testUser.email },
      });

      if (existingUser) {
        console.log(`✓ User ${testUser.username} already exists`);
        continue;
      }

      const passwordHash = await bcrypt.hash(testUser.password, SALT_ROUNDS);

      const user = await prisma.user.create({
        data: {
          email: testUser.email,
          username: testUser.username,
          passwordHash,
          role: testUser.role,
          profile: {
            create: {
              displayName: testUser.profile.displayName,
              bio: testUser.profile.bio || undefined,
              socialLinks: testUser.profile.socialLinks || undefined,
              isPublic: testUser.profile.isPublic !== false,
            },
          },
        },
        include: { profile: true },
      });

      console.log(`✓ Created user: ${user.username} (${user.role})`);
    } catch (error) {
      console.error(`✗ Failed to create user:`, error);
    }
  }

  console.log('✅ Seed completed!');
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });