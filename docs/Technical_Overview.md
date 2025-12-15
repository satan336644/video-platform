# TECHNICAL ARCHITECTURE – Web-Based Video Streaming Platform

1. Architecture Goals
The technical architecture is designed to support a globally accessible, scalable, and performance-oriented video streaming platform. The focus is on:
- Reliable video delivery with minimal buffering
- Clean separation of concerns between services
- MVP-first development with clear upgrade paths
- Maintainability and future scalability


2. Technology Stack Selection
Frontend
- Framework: React or Next.js
- Language: TypeScript
- Video Player: HLS.js
- Styling: Tailwind CSS or equivalent
- API Communication: REST over HTTPS

Backend
- Runtime: Node.js
- Framework: Express.js or NestJS
- Language: TypeScript
- Authentication: JWT-based authentication
- API Style: RESTful APIs

Database
- Primary Database: PostgreSQL
- ORM: Prisma or TypeORM
- Video Storage & Streaming
- Object Storage: S3-compatible storage (AWS S3 or equivalent)
- Video Format: HLS (HTTP Live Streaming)
- Transcoding: FFmpeg or managed transcoding service
- CDN: Cloudflare or Bunny.net

Infrastructure & DevOps
- Hosting: Cloud-based VPS or managed platform
- Containerization (Optional): Docker
- Version Control: Git (main branch protected)
- CI/CD: GitHub Actions (future phase)

3. High-Level System Design
Request Flow Overview

# User Authentication & API Requests
Client (Browser)
   → Backend API (Node.js)
      → PostgreSQL Database


Video Streaming Flow
Client (HLS Player)
   → CDN (Cloudflare / Bunny.net)
      → Object Storage (HLS segments)

This separation ensures that:

- Video traffic does not overload the backend API
- CDN handles global delivery and caching
- Backend focuses on business logic and metadata

4. Core Services Overview
Backend API Responsibilities
- User authentication and authorization
- Creator and viewer role management
- Video metadata management
- Follow relationships
- View count tracking
- Admin and moderation endpoints (future)

Frontend Responsibilities
- User interface and navigation
- Video browsing and playback
- Creator dashboards
- Interaction with backend APIs

5. Database Schema (Draft)
users
- id (UUID, PK)
- email
- password_hash
- role (creator / viewer)
- created_at
- updated_at

creators
- id (UUID, PK)
- user_id (FK → users)
- display_name
- bio

videos
- id (UUID, PK)
- creator_id (FK → creators)
- title
- description
- hls_path
- thumbnail_path
- visibility (public / private)
- created_at

follows
- follower_id (FK → users)
- creator_id (FK → creators)
- created_at

views
- id (UUID, PK)
- video_id (FK → videos)
- viewer_id (nullable)
- created_at

6. Video Upload & Streaming Pipeline (MVP)
a) Creator uploads a video via the frontend
b) Backend issues a signed upload URL to object storage
c) Video is uploaded directly to storage
d) Video is transcoded into HLS format
e) HLS segments and playlist are stored in object storage
f) CDN caches and serves HLS content globally
g) Frontend plays video using HLS.js
h) This approach minimizes backend load and maximizes streaming performance.


7. Scalability Considerations
- Stateless backend APIs allow horizontal scaling
- CDN offloads video traffic from backend servers
- Object storage supports virtually unlimited video data
- Database can be optimized with indexing and read replicas in later phases

8. Assumptions & Limitations (Phase 1)
- Moderate initial traffic volume
- Videos are pre-recorded (no live streaming)
- Basic engagement metrics only
- Manual moderation if needed

9. Future Enhancements
- Recommendation engine
- Content moderation tools
- Notification system
- Monetization and subscription features
- Analytics and reporting dashboards