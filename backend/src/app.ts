import express from "express";
import cors from "cors";
import healthRoute from "./routes/health.route";
import videoRoute from "./routes/video.route";
import playbackRoute from "./routes/playback.route";
import streamRoute from "./routes/stream.route";

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api", healthRoute);
app.use("/api", videoRoute);
app.use("/api", playbackRoute);
app.use("/api", streamRoute);

export default app;
