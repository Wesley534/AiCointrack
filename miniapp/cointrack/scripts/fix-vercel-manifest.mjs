import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const src = path.join(root, ".next", "server", "app", "page_client-reference-manifest.js");
const dst = path.join(root, ".next", "server", "app", "(app)", "page_client-reference-manifest.js");

try {
  if (!fs.existsSync(src)) {
    console.log("[postbuild] source manifest not found, skipping:", src);
    process.exit(0);
  }

  fs.mkdirSync(path.dirname(dst), { recursive: true });
  fs.copyFileSync(src, dst);
  console.log("[postbuild] copied client reference manifest:", dst);
} catch (error) {
  console.warn("[postbuild] failed to copy manifest:", error);
  process.exit(0);
}
