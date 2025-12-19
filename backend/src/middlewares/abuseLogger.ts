import { Request, Response, NextFunction } from "express";

export const abuseLogger = (
  req: Request,
  _res: Response,
  next: NextFunction
) => {
  console.log(`[ABUSE-CHECK] ${req.ip} ${req.method} ${req.originalUrl}`);
  next();
};
