import { prisma } from '../prisma';

export function calculateEngagementScore(
  views: number,
  watchTimeSeconds: number,
  likes: number,
  comments: number
): number {
  return views * 1 + (watchTimeSeconds / 60) * 2 + likes * 5 + comments * 10;
}

export async function startWatchSession(params: {
  videoId: string;
  userId?: string;
  deviceType?: string;
  userAgent?: string;
  ipAddress?: string;
}) {
  return prisma.watchSession.create({
    data: {
      videoId: params.videoId,
      userId: params.userId,
      deviceType: params.deviceType,
      userAgent: params.userAgent,
      ipAddress: params.ipAddress,
    },
  });
}

export async function endWatchSession(
  sessionId: string,
  watchDuration: number,
  percentWatched: number
) {
  try {
    console.log('Ending watch session:', sessionId);
    
    const session = await prisma.watchSession.update({
      where: { id: sessionId },
      data: {
        sessionEnd: new Date(),
        watchDuration,
        percentWatched,
        completedVideo: percentWatched >= 0.9,
      },
      include: {
        video: {
          include: {
            analytics: true,
            _count: {
              select: {
                likes: true,
                comments: true,
              },
            },
          },
        },
      },
    });

    console.log('Session updated, calculating analytics...');

    const video = session.video;
    const likesCount = video._count.likes;
    const commentsCount = video._count.comments;

    // Calculate unique viewers
    const uniqueViewers = await prisma.watchSession.groupBy({
      by: ['userId'],
      where: {
        videoId: video.id,
        userId: { not: null },
      },
      _count: true,
    });

    console.log('Unique viewers calculated:', uniqueViewers.length);

    // Get aggregated session data
    const allSessions = await prisma.watchSession.aggregate({
      where: { videoId: video.id },
      _sum: { watchDuration: true },
      _avg: { watchDuration: true },
      _count: true,
    });

    const totalWatchTime = Number(allSessions._sum.watchDuration || 0);
    const averageWatchTime = allSessions._avg.watchDuration || 0;
    const totalViews = allSessions._count;

    console.log('Aggregated data:', { totalViews, totalWatchTime, averageWatchTime });

    // Calculate completion rate
    const completedSessions = await prisma.watchSession.count({
      where: {
        videoId: video.id,
        completedVideo: true,
      },
    });
    const completionRate = totalViews > 0 ? completedSessions / totalViews : 0;

    const engagementScore = calculateEngagementScore(
      totalViews,
      totalWatchTime,
      likesCount,
      commentsCount
    );

    console.log('Upserting video analytics...');

    // Update VideoAnalytics
    await prisma.videoAnalytics.upsert({
      where: { videoId: video.id },
      create: {
        videoId: video.id,
        totalViews,
        totalWatchTime: BigInt(totalWatchTime),
        averageWatchTime,
        completionRate,
        engagementScore,
        uniqueViewers: uniqueViewers.length,
      },
      update: {
        totalViews,
        totalWatchTime: BigInt(totalWatchTime),
        averageWatchTime,
        completionRate,
        engagementScore,
        uniqueViewers: uniqueViewers.length,
        updatedAt: new Date(),
      },
    });

    console.log('Video analytics updated, updating creator stats...');

    // Update creator stats
    await updateCreatorStats(video.creatorId);

    console.log('Creator stats updated successfully');

    return session;
  } catch (error) {
    console.error('Error in endWatchSession:', error);
    throw error;
  }
}

export async function updateCreatorStats(creatorId: string) {
  try {
    console.log('Updating creator stats for:', creatorId);
    
    const videos = await prisma.video.findMany({
      where: { creatorId },
      include: {
        analytics: true,
        _count: {
          select: {
            likes: true,
            comments: true,
          },
        },
      },
    });

    console.log('Found videos:', videos.length);

    const totalVideos = videos.length;
    const totalViews = videos.reduce(
      (sum, v) => sum + (v.analytics?.totalViews || 0),
      0
    );
    const totalWatchTime = videos.reduce(
      (sum, v) => sum + Number(v.analytics?.totalWatchTime || 0),
      0
    );
    const totalLikes = videos.reduce((sum, v) => sum + v._count.likes, 0);
    const totalComments = videos.reduce((sum, v) => sum + v._count.comments, 0);

    const averageEngagement =
      totalVideos > 0
        ? videos.reduce((sum, v) => sum + (v.analytics?.engagementScore || 0), 0) / totalVideos
        : 0;

    console.log('Counting followers...');

    const totalFollowers = await prisma.follow.count({
      where: { userId: creatorId },
    });

    console.log('Total followers:', totalFollowers);

    const topVideo = videos.reduce((best, current) => {
      const currentScore = current.analytics?.engagementScore || 0;
      const bestScore = best?.analytics?.engagementScore || 0;
      return currentScore > bestScore ? current : best;
    }, videos[0]);

    console.log('Upserting creator stats...');

    await prisma.creatorStats.upsert({
      where: { creatorId },
      create: {
        creatorId,
        totalVideos,
        totalViews: BigInt(totalViews),
        totalWatchTime: BigInt(totalWatchTime),
        totalLikes,
        totalComments,
        totalFollowers,
        averageEngagement,
        topVideo: topVideo?.id,
        lastActivityAt: new Date(),
      },
      update: {
        totalVideos,
        totalViews: BigInt(totalViews),
        totalWatchTime: BigInt(totalWatchTime),
        totalLikes,
        totalComments,
        totalFollowers,
        averageEngagement,
        topVideo: topVideo?.id,
        lastActivityAt: new Date(),
        updatedAt: new Date(),
      },
    });

    console.log('Creator stats updated successfully');
  } catch (error) {
    console.error('Error in updateCreatorStats:', error);
    throw error;
  }
}

export async function getCreatorAnalytics(creatorId: string) {
  const stats = await prisma.creatorStats.findUnique({
    where: { creatorId },
  });

  if (!stats) {
    // Initialize stats if they don't exist
    await updateCreatorStats(creatorId);
    return getCreatorAnalytics(creatorId);
  }

  // Get top 10 videos by engagement
  const topVideos = await prisma.video.findMany({
    where: { creatorId },
    include: {
      analytics: true,
    },
    orderBy: {
      analytics: {
        engagementScore: 'desc',
      },
    },
    take: 10,
  });

  // Get views by day for the last 30 days
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  const viewsByDay = await prisma.$queryRaw<Array<{ date: Date; views: bigint }>>`
    SELECT DATE_TRUNC('day', ws."sessionStart") as date, COUNT(*)::int as views
    FROM "WatchSession" ws
    JOIN "Video" v ON ws."videoId" = v.id
    WHERE v."creatorId" = ${creatorId}
      AND ws."sessionStart" >= ${thirtyDaysAgo}
    GROUP BY DATE_TRUNC('day', ws."sessionStart")
    ORDER BY date DESC
  `;

  return {
    overview: {
      totalVideos: stats.totalVideos,
      totalViews: Number(stats.totalViews),
      totalWatchTime: Number(stats.totalWatchTime),
      totalLikes: stats.totalLikes,
      totalComments: stats.totalComments,
      totalFollowers: stats.totalFollowers,
      averageEngagement: stats.averageEngagement,
    },
    topVideos: topVideos.map((v) => ({
      id: v.id,
      title: v.title,
      views: v.analytics?.totalViews || 0,
      watchTime: Number(v.analytics?.totalWatchTime || 0),
      engagementScore: v.analytics?.engagementScore || 0,
      completionRate: v.analytics?.completionRate || 0,
    })),
    viewsByDay: viewsByDay.map((row) => ({
      date: row.date,
      views: Number(row.views),
    })),
  };
}

export async function getVideoAnalytics(videoId: string) {
  const video = await prisma.video.findUnique({
    where: { id: videoId },
    include: {
      analytics: true,
      _count: {
        select: {
          likes: true,
          comments: true,
        },
      },
    },
  });

  if (!video) {
    throw new Error('Video not found');
  }

  // Get device breakdown
  const deviceStats = await prisma.watchSession.groupBy({
    by: ['deviceType'],
    where: { videoId },
    _count: true,
  });

  // Get watch time distribution
  const watchTimeDistribution = await prisma.watchSession.groupBy({
    by: ['percentWatched'],
    where: { videoId },
    _count: true,
  });

  return {
    video: {
      id: video.id,
      title: video.title,
    },
    analytics: {
      totalViews: video.analytics?.totalViews || 0,
      totalWatchTime: Number(video.analytics?.totalWatchTime || 0),
      averageWatchTime: video.analytics?.averageWatchTime || 0,
      completionRate: video.analytics?.completionRate || 0,
      engagementScore: video.analytics?.engagementScore || 0,
      uniqueViewers: video.analytics?.uniqueViewers || 0,
    },
    engagement: {
      likes: video._count.likes,
      comments: video._count.comments,
    },
    devices: deviceStats.map((d) => ({
      type: d.deviceType || 'unknown',
      count: d._count,
    })),
    watchTimeDistribution,
  };
}

export async function getCreatorLeaderboard(
  sortBy: 'views' | 'engagement' | 'followers' = 'views',
  limit: number = 10
) {
  const orderBy =
    sortBy === 'views'
      ? { totalViews: 'desc' as const }
      : sortBy === 'engagement'
      ? { averageEngagement: 'desc' as const }
      : { totalFollowers: 'desc' as const };

  const creators = await prisma.creatorStats.findMany({
    orderBy,
    take: limit,
    include: {
      creator: {
        select: {
          id: true,
          username: true,
          email: false,
        },
      },
    },
  });

  return {
    sortBy,
    leaderboard: creators.map((c, index) => ({
      rank: index + 1,
      creator: c.creator,
      stats: {
        totalVideos: c.totalVideos,
        totalViews: Number(c.totalViews),
        totalWatchTime: Number(c.totalWatchTime),
        averageEngagement: c.averageEngagement,
        totalFollowers: c.totalFollowers,
      },
    })),
  };
}