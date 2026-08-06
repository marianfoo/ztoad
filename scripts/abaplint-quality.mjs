import { spawnSync } from "node:child_process";
import { unlink, writeFile } from "node:fs/promises";
import { join } from "node:path";

const strict = process.argv.includes("--strict");
const executable = join(
  process.cwd(),
  "node_modules",
  ".bin",
  process.platform === "win32" ? "abaplint.cmd" : "abaplint",
);
const configPath = join(
  process.cwd(),
  `.abaplint-quality-${process.pid}-${Date.now()}.json`,
);

function run(arguments_) {
  return spawnSync(executable, arguments_, {
    cwd: process.cwd(),
    encoding: "utf8",
    maxBuffer: 10 * 1024 * 1024,
  });
}

const defaults = run(["--default"]);

if (defaults.error || defaults.status !== 0 || !defaults.stdout) {
  process.stderr.write(defaults.stderr || "Unable to generate the abaplint default configuration.\n");
  process.exitCode = defaults.status || 2;
} else {
  try {
    await writeFile(configPath, defaults.stdout, "utf8");

    const result = run([configPath, "--format", "json"]);
    process.stderr.write(result.stderr || "");

    if (result.error) {
      process.stderr.write(`${result.error.message}\n`);
      process.exitCode = 2;
    } else {
      const issues = JSON.parse(result.stdout || "[]");
      const counts = new Map();

      for (const issue of issues) {
        counts.set(issue.key, (counts.get(issue.key) || 0) + 1);
      }

      const ordered = [...counts.entries()].sort(
        ([leftRule, leftCount], [rightRule, rightCount]) =>
          rightCount - leftCount || leftRule.localeCompare(rightRule),
      );

      process.stdout.write(
        `abaplint quality inventory: ${issues.length} issue(s) across ${counts.size} rule(s)\n`,
      );
      for (const [rule, count] of ordered) {
        process.stdout.write(`${String(count).padStart(4)}  ${rule}\n`);
      }

      if (strict) {
        process.exitCode = result.status || 0;
      } else if (result.status !== 0 && result.status !== 1) {
        process.exitCode = result.status || 2;
      } else {
        process.stdout.write(
          "\nDiagnostic only: full quality debt is not a merge gate yet. "
            + "Run with --strict after the count reaches zero.\n",
        );
      }
    }
  } finally {
    await unlink(configPath).catch(() => undefined);
  }
}
