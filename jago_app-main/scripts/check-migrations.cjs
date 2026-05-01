#!/usr/bin/env node
/**
 * Migration safety checker — run before deploy or in CI.
 * Ensures every CREATE INDEX / CREATE TABLE / CREATE SEQUENCE in migration
 * files uses IF NOT EXISTS so re-running migrations never crashes the server.
 *
 * Usage:  node scripts/check-migrations.cjs
 * Exit 1 if unsafe DDL found, 0 if all safe.
 */
const fs = require("fs");
const path = require("path");

const MIGRATIONS_DIR = path.join(__dirname, "..", "migrations");

const UNSAFE_PATTERNS = [
  { re: /^\s*CREATE INDEX\s+(?!IF NOT EXISTS)/im, label: "CREATE INDEX without IF NOT EXISTS" },
  { re: /^\s*CREATE UNIQUE INDEX\s+(?!IF NOT EXISTS)/im, label: "CREATE UNIQUE INDEX without IF NOT EXISTS" },
  { re: /^\s*CREATE TABLE\s+(?!IF NOT EXISTS)/im, label: "CREATE TABLE without IF NOT EXISTS" },
  { re: /^\s*CREATE SEQUENCE\s+(?!IF NOT EXISTS)/im, label: "CREATE SEQUENCE without IF NOT EXISTS" },
  { re: /^\s*CREATE TYPE\s+(?!IF NOT EXISTS)/im, label: "CREATE TYPE without IF NOT EXISTS" },
];

let failed = false;

const files = fs.readdirSync(MIGRATIONS_DIR).filter(f => f.endsWith(".sql")).sort();

for (const file of files) {
  const content = fs.readFileSync(path.join(MIGRATIONS_DIR, file), "utf8");
  const lines = content.split("\n");

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (line.trim().startsWith("--")) continue; // skip comments

    for (const { re, label } of UNSAFE_PATTERNS) {
      if (re.test(line)) {
        console.error(`UNSAFE [${file}:${i + 1}] ${label}`);
        console.error(`  > ${line.trim()}`);
        failed = true;
      }
    }
  }
}

if (failed) {
  console.error("\n❌ Migration safety check FAILED — fix the above issues before deploying.");
  process.exit(1);
} else {
  console.log(`✅ Migration safety check passed (${files.length} files checked)`);
  process.exit(0);
}
