export type VideoStatus =
  | "CREATED"
  | "UPLOADED"
  | "PROCESSING"
  | "READY"
  | "FAILED";

// Optional helper interface if needed elsewhere
export interface Video {
  id: string;
  title: string;
  description?: string;
  creatorId: string;
  status: VideoStatus;
  createdAt: Date;
  processedAt?: Date | null;
}
