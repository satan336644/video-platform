import express from "express";
import cors from "cors";
import healthRoute from "./routes/health.route";


const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use("/api", healthRoute);

export default app;
