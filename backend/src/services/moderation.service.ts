import { prisma } from '../prisma';
import { ModerationStatus, ReportTarget, ReportReason, ReportStatus } from '@prisma/client';

export async function getPendingVideos(params: { page?: number; limit?: number }) {
  const page = params.page || 1;
  const limit = Math.min(params.limit || 20, 50);
  const skip = (page - 1) * limit;

  const [videos, total] = await Promise.all([
    prisma.video.findMany({
      where: { moderationStatus: ModerationStatus.PENDING_REVIEW },
      orderBy: { createdAt: 'asc' },
      skip,
      take: limit,
      include: {
        creator: {
          select: {
            id: true,
            username: true,
            profile: { select: { displayName: true, avatarUrl: true } },
          },
        },
      },
    }),
    prisma.video.count({ where: { moderationStatus: ModerationStatus.PENDING_REVIEW } }),
  ]);

  return {
    videos,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  };
}

export async function getFlaggedVideos(params: { page?: number; limit?: number }) {
  const page = params.page || 1;
  const limit = Math.min(params.limit || 20, 50);
  const skip = (page - 1) * limit;

  const [videos, total] = await Promise.all([
    prisma.video.findMany({
      where: { moderationStatus: ModerationStatus.FLAGGED },
      orderBy: { updatedAt: 'desc' },
      skip,
      take: limit,
      include: {
        creator: {
          select: {
            id: true,
            username: true,
            profile: { select: { displayName: true } },
          },
        },
        reports: {
          where: { status: ReportStatus.PENDING },
          orderBy: { createdAt: 'desc' },
          take: 5,
          include: { reporter: { select: { id: true, username: true } } },
        },
      },
    }),
    prisma.video.count({ where: { moderationStatus: ModerationStatus.FLAGGED } }),
  ]);

  return {
    videos,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  };
}

export async function approveVideo(videoId: string, adminId: string, notes?: string) {
  return prisma.video.update({
    where: { id: videoId },
    data: {
      moderationStatus: ModerationStatus.APPROVED,
      moderatedBy: adminId,
      moderatedAt: new Date(),
      moderationNotes: notes,
    },
  });
}

export async function rejectVideo(videoId: string, adminId: string, reason: string) {
  return prisma.video.update({
    where: { id: videoId },
    data: {
      moderationStatus: ModerationStatus.REJECTED,
      moderatedBy: adminId,
      moderatedAt: new Date(),
      moderationNotes: reason,
    },
  });
}

export async function removeVideo(videoId: string, adminId: string, reason: string) {
  return prisma.video.update({
    where: { id: videoId },
    data: {
      moderationStatus: ModerationStatus.REMOVED,
      moderatedBy: adminId,
      moderatedAt: new Date(),
      moderationNotes: reason,
    },
  });
}

export async function createReport(params: {
  reporterId: string;
  targetType: ReportTarget;
  targetId: string;
  reason: ReportReason;
  description?: string;
}) {
  // Check for any existing report from this user on this target (regardless of status)
  const existing = await prisma.report.findFirst({
    where: {
      reporterId: params.reporterId,
      targetType: params.targetType,
      targetId: params.targetId,
    },
  });

  if (existing) {
    throw new Error('You have already reported this content');
  }

  const report = await prisma.report.create({
    data: {
      reporterId: params.reporterId,
      targetType: params.targetType,
      targetId: params.targetId,
      reason: params.reason,
      description: params.description,
    },
  });

  if (params.targetType === ReportTarget.VIDEO) {
    const reportCount = await prisma.report.count({
      where: {
        targetType: ReportTarget.VIDEO,
        targetId: params.targetId,
        status: ReportStatus.PENDING,
      },
    });

    if (reportCount >= 3) {
      await prisma.video.update({
        where: { id: params.targetId },
        data: { moderationStatus: ModerationStatus.FLAGGED },
      });
    }
  }

  return report;
}

export async function getReports(params: {
  status?: ReportStatus;
  targetType?: ReportTarget;
  page?: number;
  limit?: number;
}) {
  const page = params.page || 1;
  const limit = Math.min(params.limit || 20, 50);
  const skip = (page - 1) * limit;

  const where: any = {};
  if (params.status) where.status = params.status;
  if (params.targetType) where.targetType = params.targetType;

  const [reports, total] = await Promise.all([
    prisma.report.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
      include: {
        reporter: { select: { id: true, username: true } },
        video: {
          select: {
            id: true,
            title: true,
            creator: { select: { username: true } },
          },
        },
      },
    }),
    prisma.report.count({ where }),
  ]);

  return {
    reports,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  };
}

export async function resolveReport(reportId: string, adminId: string, resolution: string) {
  return prisma.report.update({
    where: { id: reportId },
    data: {
      status: ReportStatus.RESOLVED,
      reviewedBy: adminId,
      reviewedAt: new Date(),
      resolution,
    },
  });
}

export async function dismissReport(reportId: string, adminId: string, reason: string) {
  return prisma.report.update({
    where: { id: reportId },
    data: {
      status: ReportStatus.DISMISSED,
      reviewedBy: adminId,
      reviewedAt: new Date(),
      resolution: reason,
    },
  });
}

export async function banUser(params: {
  userId: string;
  bannedBy: string;
  reason: string;
  permanent?: boolean;
  daysUntilExpire?: number;
}) {
  const expiresAt = params.permanent
    ? null
    : new Date(Date.now() + (params.daysUntilExpire ?? 7) * 24 * 60 * 60 * 1000);

  await prisma.userBan.create({
    data: {
      userId: params.userId,
      bannedBy: params.bannedBy,
      reason: params.reason,
      permanent: params.permanent ?? false,
      expiresAt,
    },
  });

  await prisma.user.update({
    where: { id: params.userId },
    data: {
      isBanned: true,
      suspendedUntil: expiresAt,
    },
  });

  await prisma.video.updateMany({
    where: { creatorId: params.userId },
    data: { moderationStatus: ModerationStatus.REMOVED },
  });
}

export async function unbanUser(userId: string) {
  await prisma.user.update({
    where: { id: userId },
    data: {
      isBanned: false,
      suspendedUntil: null,
    },
  });
}

export async function isUserBanned(userId: string): Promise<boolean> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      isBanned: true,
      suspendedUntil: true,
    },
  });

  if (!user) return false;
  if (!user.isBanned) return false;

  if (user.suspendedUntil && user.suspendedUntil < new Date()) {
    await unbanUser(userId);
    return false;
  }

  return true;
}

export async function createDMCATakedown(params: {
  videoId: string;
  claimantName: string;
  claimantEmail: string;
  claimantAddress?: string;
  copyrightWork: string;
  infringementUrl: string;
  goodFaithStatement: boolean;
  accuracyStatement: boolean;
  signature: string;
}) {
  const takedown = await prisma.dMCATakedown.create({ data: params });

  await prisma.video.update({
    where: { id: params.videoId },
    data: { moderationStatus: ModerationStatus.REMOVED },
  });

  return takedown;
}

export async function getModerationStats() {
  const [pending, flagged, reports, recentBans] = await Promise.all([
    prisma.video.count({ where: { moderationStatus: ModerationStatus.PENDING_REVIEW } }),
    prisma.video.count({ where: { moderationStatus: ModerationStatus.FLAGGED } }),
    prisma.report.count({ where: { status: ReportStatus.PENDING } }),
    prisma.userBan.count({
      where: { createdAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } },
    }),
  ]);

  return {
    pendingVideos: pending,
    flaggedVideos: flagged,
    pendingReports: reports,
    recentBans,
  };
}