import { randomUUID } from "crypto";
import { StorageProvider } from "./storage.interface";

export class LocalStorageProvider implements StorageProvider {
  async createUploadIntent(videoId: string) {
    const objectKey = `${videoId}/${randomUUID()}.mp4`;

    return {
      objectKey,
      uploadUrl: `/mock-upload/${objectKey}`,
    };
  }
}
