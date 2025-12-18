# Video Platform Backend

Backend API for the web-based video streaming platform built with Node.js, Express, and TypeScript.

## Tech Stack

- **Runtime**: Node.js (>= 18.0.0)
- **Framework**: Express.js
- **Language**: TypeScript
- **Database**: PostgreSQL
- **ORM**: Prisma
- **Authentication**: JWT

## Prerequisites

- Node.js >= 18.0.0
- npm >= 9.0.0
- PostgreSQL database

## Getting Started

### Installation

```bash
# Install dependencies
npm install
```

### Environment Setup

1. Copy the example environment file:

```bash
cp .env.example .env
```

2. Update the `.env` file with your configuration values

### Database Setup

```bash
# Generate Prisma client
npx prisma generate

# Run database migrations
npx prisma migrate dev
```

### Development

```bash
# Run in development mode with hot reload
npm run dev
```

The server will start on `http://localhost:4000` (or the PORT specified in .env)

### Build

```bash
# Build for production
npm run build

# Start production server
npm start
```

## Project Structure

```
backend/
├── src/
│   ├── app.ts              # Express app configuration
│   ├── server.ts           # Server entry point
│   ├── routes/             # API route definitions
│   ├── controllers/        # Request handlers
│   ├── services/           # Business logic
│   ├── middlewares/        # Custom middleware
│   ├── config/             # Configuration files
│   └── types/              # TypeScript type definitions
├── package.json
├── tsconfig.json
└── .env.example
```

## API Endpoints

### Health Check

- `GET /api/health` - Server health check

## Scripts

- `npm run dev` - Start development server with hot reload
- `npm run build` - Build for production
- `npm start` - Start production server
- `npm run lint` - Run ESLint
- `npm test` - Run tests

## License

ISC
