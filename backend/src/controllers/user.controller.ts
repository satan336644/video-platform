import { Request, Response } from 'express';
import { prisma } from '../prisma';

export async function getMeHandler(req: Request, res: Response) {
  try {
    const userId = (req as any).user.userId;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        username: true,
        role: true,
        emailVerified: true,
        createdAt: true,
        profile: {
          select: {
            displayName: true,
            bio: true,
            avatarUrl: true,
            bannerUrl: true,
            socialLinks: true,
            isPublic: true,
          },
        },
      },
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    return res.json(user);
  } catch (err) {
    console.error('Get me error:', err);
    return res.status(500).json({ error: 'Failed to fetch user data' });
  }
}

export async function updateMeHandler(req: Request, res: Response) {
  try {
    const userId = (req as any).user.userId;
    const { displayName, bio, avatarUrl, bannerUrl, socialLinks, isPublic } = req.body;

    // Validate bio length
    if (bio && typeof bio === 'string' && bio.length > 500) {
      return res.status(400).json({ error: 'Bio must be 500 characters or less' });
    }

    await prisma.userProfile.update({
      where: { userId },
      data: {
        ...(displayName !== undefined && { displayName }),
        ...(bio !== undefined && { bio }),
        ...(avatarUrl !== undefined && { avatarUrl }),
        ...(bannerUrl !== undefined && { bannerUrl }),
        ...(socialLinks !== undefined && { socialLinks }),
        ...(isPublic !== undefined && { isPublic }),
      },
    });

    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        username: true,
        role: true,
        profile: true,
      },
    });

    return res.json(user);
  } catch (err) {
    console.error('Update me error:', err);
    return res.status(500).json({ error: 'Failed to update profile' });
  }
}

export async function getUserByUsernameHandler(req: Request, res: Response) {
  try {
    const { username } = req.params;
    const requestingUserId = (req as any).user?.userId;

    const user = await prisma.user.findUnique({
      where: { username: username.toLowerCase() },
      select: {
        id: true,
        username: true,
        role: true,
        createdAt: true,
        profile: {
          select: {
            displayName: true,
            bio: true,
            avatarUrl: true,
            bannerUrl: true,
            socialLinks: true,
            isPublic: true,
          },
        },
      },
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check privacy
    if (!user.profile?.isPublic && user.id !== requestingUserId) {
      return res.status(403).json({ error: 'Profile is private' });
    }

    return res.json(user);
  } catch (err) {
    console.error('Get user error:', err);
    return res.status(500).json({ error: 'Failed to fetch user' });
  }
}

export async function getUserVideosHandler(req: Request, res: Response) {
  try {
    const { username } = req.params;
    const { page = '1', limit = '20' } = req.query;

    const user = await prisma.user.findUnique({
      where: { username: username.toLowerCase() },
      select: { id: true },
    });

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    const pageNum = Math.max(parseInt(page as string) || 1, 1);
    const limitNum = Math.min(Math.max(parseInt(limit as string) || 20, 1), 100);

    const where: any = {
      creatorId: user.id,
      status: 'READY',
      visibility: 'PUBLIC',
    };

    const skip = (pageNum - 1) * limitNum;

    const [videos, total] = await Promise.all([
      prisma.video.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        take: limitNum,
        skip,
        select: {
          id: true,
          title: true,
          description: true,
          category: true,
          tags: true,
          viewCount: true,
          likeCount: true,
          createdAt: true,
        },
      }),
      prisma.video.count({ where }),
    ]);

    return res.json({
      videos,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages: Math.ceil(total / limitNum),
      },
    });
  } catch (err) {
    console.error('Get user videos error:', err);
    return res.status(500).json({ error: 'Failed to fetch videos' });
  }
}