import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";

/**
 * Optional authentication middleware - attaches user to request if valid token present
 * Does not reject requests without auth
 */
export function optionalAuth() {
  return (req: Request, _res: Response, next: NextFunction) => {
    const authHeader = req.headers.authorization;
    
    if (!authHeader) {
      return next(); // No auth provided, continue without user
    }

    const token = authHeader.split(" ")[1];

    try {
      const payload = jwt.verify(
        token,
        process.env.JWT_SECRET || "dev-secret"
      ) as any;

      (req as any).user = payload;
    } catch {
      // Invalid token, but don't reject - just continue without user
    }

    return next();
  };
}
