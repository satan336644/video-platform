# Video Streaming Proof of Concept (POC)

## Objective
This proof of concept demonstrates the core video streaming architecture for the platform, focusing on scalable upload and playback without overloading the backend API.

---

## Architecture Overview

Upload Flow:
Client → Backend (signed URL) → Object Storage

Streaming Flow:
Client (HLS Player) → CDN → Object Storage

The backend never directly serves video files.

---

## Upload Strategy (POC)
- Backend generates a signed upload URL
- Client uploads video directly to object storage
- Backend stores video metadata only

This approach ensures scalability and performance.

---

## Streaming Strategy (POC)
- Uploaded video is converted into HLS format
- HLS playlist (.m3u8) and segments are stored in object storage
- CDN caches and delivers content globally
- Frontend plays video using HLS.js

---

## Current POC Scope
- Signed upload URL endpoint (mock or real)
- Static HLS playback example
- No automated transcoding (manual or assumed)

---

## Future Improvements
- Background transcoding jobs
- Upload validation
- DRM and content protection
- Adaptive bitrate streaming
