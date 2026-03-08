import { execSync } from "node:child_process";

function run(command: string) {
  execSync(command, {
    stdio: "inherit",
    env: process.env,
  });
}

run("vite build");
run("esbuild server/index.ts --platform=node --bundle --format=esm --packages=external --define:process.env.NODE_ENV='\"production\"' --outfile=dist/index.js");
