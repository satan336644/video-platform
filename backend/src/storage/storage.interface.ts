export interface StorageUploadResult {
  objectKey: string;
  uploadUrl: string;
}

export interface StorageProvider {
  createUploadIntent(videoId: string): Promise<StorageUploadResult>;
}
