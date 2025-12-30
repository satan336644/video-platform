import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { prisma } from '../prisma';
import { UserRole } from '@prisma/client';

const SALT_ROUNDS = 10;
const ACCESS_TOKEN_EXPIRY = '15m';
const REFRESH_TOKEN_EXPIRY = '7d';

export async function registerUser(data: {
  email: string;
  username: string;
  password: string;
  role?: UserRole;
}) {
  // Normalize
  const email = data.email.toLowerCase().trim();
  const username = data.username.toLowerCase().trim();

  // Check if user exists
  const existing = await prisma.user.findFirst({
    where: {
      OR: [{ email }, { username }],
    },
  });

  if (existing) {
    if (existing.email === email) {
      throw new Error('EMAIL_EXISTS');
    }
    throw new Error('USERNAME_EXISTS');
  }

  // Validate username format (alphanumeric + underscore only, 3-20 chars)
  if (!/^[a-z0-9_]{3,20}$/.test(username)) {
    throw new Error('INVALID_USERNAME');
  }

  // Validate password
  const isValidPassword = await validatePassword(data.password);
  if (!isValidPassword) {
    throw new Error('INVALID_PASSWORD');
  }

  // Hash password
  const passwordHash = await bcrypt.hash(data.password, SALT_ROUNDS);

  // Create user + profile in transaction
  const user = await prisma.$transaction(async (tx) => {
    const newUser = await tx.user.create({
      data: {
        email,
        username,
        passwordHash,
        role: data.role || 'VIEWER',
      },
    });

    await tx.userProfile.create({
      data: {
        userId: newUser.id,
      },
    });

    return newUser;
  });

  return {
    id: user.id,
    email: user.email,
    username: user.username,
    role: user.role,
  };
}

export async function loginUser(data: { email: string; password: string }) {
  const email = data.email.toLowerCase().trim();

  const user = await prisma.user.findUnique({
    where: { email },
  });

  if (!user) {
    throw new Error('INVALID_CREDENTIALS');
  }

  const validPassword = await bcrypt.compare(data.password, user.passwordHash);
  if (!validPassword) {
    throw new Error('INVALID_CREDENTIALS');
  }

  const { accessToken, refreshToken } = await generateTokens(user.id, user.role);

  return {
    accessToken,
    refreshToken,
    user: {
      id: user.id,
      email: user.email,
      username: user.username,
      role: user.role,
    },
  };
}

export async function generateTokens(userId: string, role: UserRole) {
  const accessToken = jwt.sign(
    { userId, role },
    process.env.JWT_SECRET || 'dev-secret',
    { expiresIn: ACCESS_TOKEN_EXPIRY }
  );

  const refreshToken = jwt.sign(
    { userId },
    process.env.REFRESH_TOKEN_SECRET || 'dev-refresh-secret',
    { expiresIn: REFRESH_TOKEN_EXPIRY }
  );

  // Store refresh token
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days
  await prisma.refreshToken.create({
    data: {
      userId,
      token: refreshToken,
      expiresAt,
    },
  });

  return { accessToken, refreshToken };
}

export async function refreshAccessToken(refreshToken: string) {
  // Verify token
  try {
    jwt.verify(
      refreshToken,
      process.env.REFRESH_TOKEN_SECRET || 'dev-refresh-secret'
    );
  } catch (err) {
    throw new Error('INVALID_TOKEN');
  }

  // Check if token exists in DB
  const storedToken = await prisma.refreshToken.findUnique({
    where: { token: refreshToken },
    include: { user: true },
  });

  if (!storedToken || storedToken.expiresAt < new Date()) {
    throw new Error('INVALID_TOKEN');
  }

  // Generate new tokens
  const { accessToken, refreshToken: newRefreshToken } = await generateTokens(
    storedToken.user.id,
    storedToken.user.role
  );

  // Delete old refresh token
  await prisma.refreshToken.delete({ where: { token: refreshToken } });

  return { accessToken, refreshToken: newRefreshToken };
}

export async function logoutUser(refreshToken: string) {
  await prisma.refreshToken.deleteMany({ where: { token: refreshToken } });
}

export async function validatePassword(password: string): Promise<boolean> {
  // Min 8 chars, at least 1 uppercase, 1 lowercase, 1 number
  return /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,128}$/.test(password);
}