import jwt from "jsonwebtoken";
import { Router, Request, Response } from "express";

const router = Router();

router.post("/login", (req: Request, res: Response) => {
  const { userId, role } = req.body as { userId?: string; role?: string };

  if (!userId || !role) {
    return res.status(400).json({ error: "userId and role are required" });
  }

  const token = jwt.sign(
    { userId, role },
    process.env.JWT_SECRET || "dev-secret",
    { expiresIn: "1h" }
  );

  return res.json({ token });
});

export default router;
