import { Request, Response } from 'express';
import {
  getPendingVideos,
  getFlaggedVideos,
  approveVideo,
  rejectVideo,
  removeVideo,
  createReport,
  getReports,
  resolveReport,
  dismissReport,
  banUser,
  unbanUser,
  createDMCATakedown,
  getModerationStats,
} from '../services/moderation.service';

export async function getPendingVideosHandler(req: Request, res: Response) {
  try {
    const { page, limit } = req.query;
    const result = await getPendingVideos({
      page: page ? parseInt(page as string) : undefined,
      limit: limit ? parseInt(limit as string) : undefined,
    });
    return res.json(result);
  } catch (err) {
    console.error('Get pending videos error:', err);
    return res.status(500).json({ error: 'Failed to fetch pending videos' });
  }
}

export async function getFlaggedVideosHandler(req: Request, res: Response) {
  try {
    const { page, limit } = req.query;
    const result = await getFlaggedVideos({
      page: page ? parseInt(page as string) : undefined,
      limit: limit ? parseInt(limit as string) : undefined,
    });
    return res.json(result);
  } catch (err) {
    console.error('Get flagged videos error:', err);
    return res.status(500).json({ error: 'Failed to fetch flagged videos' });
  }
}

export async function approveVideoHandler(req: Request, res: Response) {
  try {
    const { videoId } = req.params;
    const { notes } = req.body;
    const adminId = (req as any).user.userId;

    const video = await approveVideo(videoId, adminId, notes);
    return res.json({ video });
  } catch (err) {
    console.error('Approve video error:', err);
    return res.status(500).json({ error: 'Failed to approve video' });
  }
}

export async function rejectVideoHandler(req: Request, res: Response) {
  try {
    const { videoId } = req.params;
    const { reason } = req.body;
    const adminId = (req as any).user.userId;

    if (!reason) {
      return res.status(400).json({ error: 'Rejection reason is required' });
    }

    const video = await rejectVideo(videoId, adminId, reason);
    return res.json({ video });
  } catch (err) {
    console.error('Reject video error:', err);
    return res.status(500).json({ error: 'Failed to reject video' });
  }
}

export async function removeVideoHandler(req: Request, res: Response) {
  try {
    const { videoId } = req.params;
    const { reason } = req.body;
    const adminId = (req as any).user.userId;

    if (!reason) {
      return res.status(400).json({ error: 'Removal reason is required' });
    }

    const video = await removeVideo(videoId, adminId, reason);
    return res.json({ video });
  } catch (err) {
    console.error('Remove video error:', err);
    return res.status(500).json({ error: 'Failed to remove video' });
  }
}

export async function createReportHandler(req: Request, res: Response) {
  try {
    const { targetType, targetId, reason, description } = req.body;
    const reporterId = (req as any).user.userId;

    if (!targetType || !targetId || !reason) {
      return res.status(400).json({
        error: 'targetType, targetId, and reason are required',
      });
    }

    const report = await createReport({
      reporterId,
      targetType,
      targetId,
      reason,
      description,
    });

    return res.status(201).json({ report });
  } catch (err: any) {
    console.error('Create report error:', err);
    if (err.message === 'You have already reported this content') {
      return res.status(409).json({ error: err.message });
    }
    return res.status(500).json({ error: 'Failed to create report' });
  }
}

export async function getReportsHandler(req: Request, res: Response) {
  try {
    const { status, targetType, page, limit } = req.query;
    const result = await getReports({
      status: status as any,
      targetType: targetType as any,
      page: page ? parseInt(page as string) : undefined,
      limit: limit ? parseInt(limit as string) : undefined,
    });
    return res.json(result);
  } catch (err) {
    console.error('Get reports error:', err);
    return res.status(500).json({ error: 'Failed to fetch reports' });
  }
}

export async function resolveReportHandler(req: Request, res: Response) {
  try {
    const { reportId } = req.params;
    const { resolution } = req.body;
    const adminId = (req as any).user.userId;

    if (!resolution) {
      return res.status(400).json({ error: 'Resolution notes are required' });
    }

    const report = await resolveReport(reportId, adminId, resolution);
    return res.json({ report });
  } catch (err) {
    console.error('Resolve report error:', err);
    return res.status(500).json({ error: 'Failed to resolve report' });
  }
}

export async function dismissReportHandler(req: Request, res: Response) {
  try {
    const { reportId } = req.params;
    const { reason } = req.body;
    const adminId = (req as any).user.userId;

    if (!reason) {
      return res.status(400).json({ error: 'Dismissal reason is required' });
    }

    const report = await dismissReport(reportId, adminId, reason);
    return res.json({ report });
  } catch (err) {
    console.error('Dismiss report error:', err);
    return res.status(500).json({ error: 'Failed to dismiss report' });
  }
}

export async function banUserHandler(req: Request, res: Response) {
  try {
    const { userId } = req.params;
    const { reason, permanent, daysUntilExpire } = req.body;
    const adminId = (req as any).user.userId;

    if (!reason) {
      return res.status(400).json({ error: 'Ban reason is required' });
    }

    await banUser({
      userId,
      bannedBy: adminId,
      reason,
      permanent,
      daysUntilExpire,
    });

    return res.json({ message: 'User banned successfully' });
  } catch (err) {
    console.error('Ban user error:', err);
    return res.status(500).json({ error: 'Failed to ban user' });
  }
}

export async function unbanUserHandler(req: Request, res: Response) {
  try {
    const { userId } = req.params;

    await unbanUser(userId);

    return res.json({ message: 'User unbanned successfully' });
  } catch (err) {
    console.error('Unban user error:', err);
    return res.status(500).json({ error: 'Failed to unban user' });
  }
}

export async function createDMCATakedownHandler(req: Request, res: Response) {
  try {
    const {
      videoId,
      claimantName,
      claimantEmail,
      claimantAddress,
      copyrightWork,
      infringementUrl,
      goodFaithStatement,
      accuracyStatement,
      signature,
    } = req.body;

    if (
      !videoId ||
      !claimantName ||
      !claimantEmail ||
      !copyrightWork ||
      !infringementUrl ||
      !goodFaithStatement ||
      !accuracyStatement ||
      !signature
    ) {
      return res.status(400).json({ error: 'Missing required DMCA fields' });
    }

    const takedown = await createDMCATakedown({
      videoId,
      claimantName,
      claimantEmail,
      claimantAddress,
      copyrightWork,
      infringementUrl,
      goodFaithStatement,
      accuracyStatement,
      signature,
    });

    return res.status(201).json({ takedown });
  } catch (err) {
    console.error('DMCA takedown error:', err);
    return res.status(500).json({ error: 'Failed to process DMCA takedown' });
  }
}

export async function getModerationStatsHandler(_req: Request, res: Response) {
  try {
    const stats = await getModerationStats();
    return res.json(stats);
  } catch (err) {
    console.error('Get moderation stats error:', err);
    return res.status(500).json({ error: 'Failed to fetch moderation stats' });
  }
}