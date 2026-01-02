import { Request, Response } from 'express';
import {
  registerUser,
  loginUser,
  refreshAccessToken,
  logoutUser,
  validatePassword,
} from '../services/auth.service';

export async function registerHandler(req: Request, res: Response) {
  try {
    const { email, username, password, role } = req.body;

    // Validation
    if (!email || !username || !password) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    if (typeof email !== 'string' || typeof username !== 'string' || typeof password !== 'string') {
      return res.status(400).json({ error: 'Invalid field types' });
    }

    const isValidPassword = await validatePassword(password);
    if (!isValidPassword) {
      return res.status(400).json({
        error: 'Password must be 8-128 characters with uppercase, lowercase, and number',
      });
    }

    const user = await registerUser({ email, username, password, role });
    return res.status(201).json(user);
  } catch (err: any) {
    if (err.message === 'EMAIL_EXISTS') {
      return res.status(409).json({ error: 'Email already registered' });
    }
    if (err.message === 'USERNAME_EXISTS') {
      return res.status(409).json({ error: 'Username already taken' });
    }
    if (err.message === 'INVALID_USERNAME') {
      return res.status(400).json({
        error: 'Username must be 3-20 characters, alphanumeric and underscore only',
      });
    }
    if (err.message === 'INVALID_PASSWORD') {
      return res.status(400).json({
        error: 'Password must be 8-128 characters with uppercase, lowercase, and number',
      });
    }
    console.error('Registration error:', err);
    return res.status(500).json({ error: 'Registration failed' });
  }
}

export async function loginHandler(req: Request, res: Response) {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    if (typeof email !== 'string' || typeof password !== 'string') {
      return res.status(400).json({ error: 'Invalid field types' });
    }

    const result = await loginUser({ email, password });
    return res.json(result);
  } catch (err: any) {
    if (err.message === 'INVALID_CREDENTIALS') {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    console.error('Login error:', err);
    return res.status(500).json({ error: 'Login failed' });
  }
}

export async function refreshHandler(req: Request, res: Response) {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token required' });
    }

    if (typeof refreshToken !== 'string') {
      return res.status(400).json({ error: 'Invalid refresh token' });
    }

    const tokens = await refreshAccessToken(refreshToken);
    return res.json(tokens);
  } catch (err: any) {
    if (err.message === 'INVALID_TOKEN') {
      return res.status(401).json({ error: 'Invalid or expired refresh token' });
    }
    console.error('Refresh error:', err);
    return res.status(500).json({ error: 'Token refresh failed' });
  }
}

export async function logoutHandler(req: Request, res: Response) {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token required' });
    }

    if (typeof refreshToken !== 'string') {
      return res.status(400).json({ error: 'Invalid refresh token' });
    }

    await logoutUser(refreshToken);
    return res.json({ message: 'Logged out successfully' });
  } catch (err) {
    console.error('Logout error:', err);
    return res.status(500).json({ error: 'Logout failed' });
  }
}