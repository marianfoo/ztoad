import { readFile } from "node:fs/promises";
import { strict as assert } from "node:assert";

const transactionPath = new URL("../src/ztoad.tran.xml", import.meta.url);
const tablePath = new URL("../src/ztoad.tabl.xml", import.meta.url);
const reportPath = new URL("../src/ztoad.prog.abap", import.meta.url);
const qualityWorkflowPath = new URL("../.github/workflows/quality.yml", import.meta.url);
const releaseWorkflowPath = new URL("../.github/workflows/release-please.yml", import.meta.url);

const currentBranchGuidancePaths = [
  "../AGENTS.md",
  "../CONTRIBUTING.md",
  "../.github/pull_request_template.md",
  "../docs/development.md",
  "../docs/test-strategy.md",
  "../docs/setup-evaluation.md",
  "../docs/plans/abaplint-zero-findings.md",
];

let transactionXml;
let tableXml;
let reportSource;

try {
  transactionXml = await readFile(transactionPath, "utf8");
} catch (error) {
  if (error?.code === "ENOENT") {
    throw new Error("Missing native-abapGit transaction object: src/ztoad.tran.xml");
  }
  throw error;
}

try {
  tableXml = await readFile(tablePath, "utf8");
} catch (error) {
  if (error?.code === "ENOENT") {
    throw new Error("Missing native-abapGit table object: src/ztoad.tabl.xml");
  }
  throw error;
}

reportSource = await readFile(reportPath, "utf8");

const [qualityWorkflow, releaseWorkflow] = await Promise.all([
  readFile(qualityWorkflowPath, "utf8"),
  readFile(releaseWorkflowPath, "utf8"),
]);

const currentBranchGuidance = await Promise.all(
  currentBranchGuidancePaths.map(async (path) => ({
    path,
    text: await readFile(new URL(path, import.meta.url), "utf8"),
  })),
);

const expectedFragments = [
  'serializer="LCL_OBJECT_TRAN"',
  "<TCODE>ZTOAD</TCODE>",
  "<PGMNA>ZTOAD</PGMNA>",
  "<DYPNO>1000</DYPNO>",
  "<CINFO>gA==</CINFO>",
  "<SPRSL>E</SPRSL>",
  "<TTEXT>ZTOAD SQL query tool</TTEXT>",
  "<S_WEBGUI>1</S_WEBGUI>",
  "<S_WIN32>X</S_WIN32>",
];

for (const fragment of expectedFragments) {
  assert.ok(
    transactionXml.includes(fragment),
    `src/ztoad.tran.xml is missing required launcher metadata: ${fragment}`,
  );
}

assert.ok(
  tableXml.includes("<EXCLASS>1</EXCLASS>"),
  "src/ztoad.tabl.xml must serialize TABL ZTOAD as #NOT_EXTENSIBLE (DD02V-EXCLASS 1)",
);

assert.ok(
  !reportSource.includes("C_DB_EXECUTE"),
  "Unsupported native SQL kernel call C_DB_EXECUTE must not exist in src/ztoad.prog.abap",
);

assert.match(
  qualityWorkflow,
  /push:\s*\n\s*branches:\s*\n\s*- main/m,
  "Quality must run for pushes to the main branch",
);
assert.match(
  releaseWorkflow,
  /push:\s*\n\s*branches:\s*\n\s*- main/m,
  "Release Please must run for pushes to the main branch",
);
assert.match(
  releaseWorkflow,
  /target-branch:\s*main/,
  "Release Please must target the main branch explicitly",
);
assert.match(
  releaseWorkflow,
  /group:\s*release-please-main/,
  "Release Please concurrency must use the main branch name",
);

for (const { path, text } of currentBranchGuidance) {
  assert.ok(
    !/(?:`master`|refs\/heads\/master|origin\/master)/.test(text),
    `${path} contains an obsolete operational master-branch reference`,
  );
}

console.log(
  "Repository contract passed: launcher, table, default-branch, and forbidden-kernel-call checks are green.",
);
