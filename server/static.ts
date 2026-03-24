import express, { type Express } from "express";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export function serveStatic(app: Express) {
  const distPath = path.resolve(__dirname, "public");
  if (!fs.existsSync(distPath)) {
    throw new Error(
      `Could not find the build directory: ${distPath}, make sure to build the client first`,
    );
  }

  app.use(express.static(distPath));

  // fall through to index.html if the file doesn't exist - BUT ONLY FOR NON-API ROUTES
  // no-cache on index.html to prevent stale asset hash references
  // IMPORTANT: Skip /api routes - let them 404 naturally if not handled by API routes
  app.use("/{*path}", (req, res) => {
    // Don't serve index.html for /api or /v* paths (API endpoints)
    if (req.path.startsWith("/api") || req.path.startsWith("/v1") || req.path.startsWith("/v2")) {
      return res.status(404).json({ message: "API endpoint not found" });
    }
    
    res.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    res.setHeader("Pragma", "no-cache");
    res.setHeader("Expires", "0");
    res.sendFile(path.resolve(distPath, "index.html"));
  });
}
