import { strict as assert } from "node:assert";
import { readFile } from "node:fs/promises";
import { pathToFileURL } from "node:url";

const repositoryRoot = new URL("../", import.meta.url);

const repositoryObjects = [
  ["src/ztoad.prog.abap"],
  ["src/ztoad.prog.xml", 'serializer="LCL_OBJECT_PROG"'],
  ["src/ztoad.prog.screen_0010.abap"],
  ["src/ztoad.prog.screen_0100.abap"],
  ["src/ztoad.prog.screen_0200.abap"],
  ["src/ztoad.prog.screen_0300.abap"],
  ["src/ztoad.tabl.xml", 'serializer="LCL_OBJECT_TABL"'],
  ["src/ztoad.tran.xml", 'serializer="LCL_OBJECT_TRAN"'],
  ["src/ztoad_auth.suso.xml", 'serializer="LCL_OBJECT_SUSO"'],
];

const requiredScreens = [
  [
    "0010",
    ["MODULE STATUS_0010.", "CALL SUBSCREEN SUB.", "MODULE USER_COMMAND_0010."],
  ],
  ["0100", []],
  [
    "0200",
    [
      "MODULE STATUS_0200.",
      "MODULE USER_COMMAND_0200 AT EXIT-COMMAND.",
      "MODULE USER_COMMAND_0200.",
    ],
  ],
  ["0300", ["MODULE STATUS_0300.", "MODULE USER_COMMAND_0300."]],
];
const requiredStatuses = ["STATUS010", "STATUS200", "STATUS300"];

async function readRequiredFile(relativePath) {
  try {
    return await readFile(new URL(relativePath, repositoryRoot), "utf8");
  } catch (error) {
    if (error?.code === "ENOENT") {
      throw new Error(`Missing complete-installation object: ${relativePath}`);
    }
    throw error;
  }
}

export async function assertRepositoryInstallationClosure() {
  const files = new Map();

  for (const [relativePath, serializer] of repositoryObjects) {
    const contents = await readRequiredFile(relativePath);
    files.set(relativePath, contents);
    if (serializer) {
      assert.ok(
        contents.includes(serializer),
        `${relativePath} is missing its native-abapGit serializer ${serializer}`,
      );
    }
  }

  const reportSource = files.get("src/ztoad.prog.abap");
  const programXml = files.get("src/ztoad.prog.xml");

  for (const [screen, requiredFlowStatements] of requiredScreens) {
    assert.ok(
      programXml.includes(`<SCREEN>${screen}</SCREEN>`),
      `src/ztoad.prog.xml is missing required dynpro ${screen}`,
    );

    const flowPath = `src/ztoad.prog.screen_${screen}.abap`;
    const flowLogic = files.get(flowPath).toUpperCase();
    for (const statement of [
      "PROCESS BEFORE OUTPUT.",
      "PROCESS AFTER INPUT.",
      ...requiredFlowStatements,
    ]) {
      assert.ok(
        flowLogic.includes(statement),
        `${flowPath} is missing required flow-logic statement ${statement}`,
      );
    }
  }

  for (const status of requiredStatuses) {
    const serializedCodeCount = programXml.split(`<CODE>${status}</CODE>`).length - 1;
    assert.ok(
      serializedCodeCount >= 2,
      `src/ztoad.prog.xml is missing required GUI status/title ${status}`,
    );
    assert.ok(
      reportSource.includes(`SET PF-STATUS '${status}'`),
      `src/ztoad.prog.abap no longer uses serialized GUI status ${status}`,
    );
    assert.ok(
      reportSource.includes(`SET TITLEBAR '${status}'`),
      `src/ztoad.prog.abap no longer uses serialized titlebar ${status}`,
    );
  }
}

export function unwrapInactiveObjects(payload) {
  if (Array.isArray(payload?.objects)) {
    return payload.objects;
  }

  for (const item of payload?.content ?? []) {
    if (item?.type !== "text" || typeof item.text !== "string") {
      continue;
    }
    try {
      const parsed = JSON.parse(item.text);
      if (Array.isArray(parsed?.objects)) {
        return parsed.objects;
      }
    } catch {
      // Ignore non-JSON MCP text blocks and report one clear contract error below.
    }
  }

  throw new Error("Inactive-object evidence does not contain an objects array");
}

export function findInactiveZtoadProgramParts(payload) {
  return unwrapInactiveObjects(payload)
    .filter((object) => {
      const normalizedName = String(object?.name ?? "").trim().replace(/\s+/g, " ");
      const isZtoadPart = normalizedName === "ZTOAD" || /^ZTOAD \d{4}$/.test(normalizedName);
      return isZtoadPart && String(object?.type ?? "").startsWith("PROG/");
    })
    .map((object) => ({
      name: String(object.name).trim().replace(/\s+/g, " "),
      type: String(object.type),
    }))
    .sort((left, right) => `${left.type}:${left.name}`.localeCompare(`${right.type}:${right.name}`));
}

export function assertLiveInstallationClosure(payload) {
  const inactiveParts = findInactiveZtoadProgramParts(payload);
  assert.deepEqual(
    inactiveParts,
    [],
    `ZTOAD installation is incomplete; activate these composite program parts: ${inactiveParts
      .map(({ type, name }) => `${type} ${name}`)
      .join(", ")}`,
  );
}

async function main() {
  await assertRepositoryInstallationClosure();

  const evidenceOption = process.argv.indexOf("--inactive-objects");
  if (evidenceOption !== -1) {
    const evidencePath = process.argv[evidenceOption + 1];
    assert.ok(evidencePath, "--inactive-objects requires a JSON file path");
    const payload = JSON.parse(await readFile(evidencePath, "utf8"));
    assertLiveInstallationClosure(payload);
  }

  console.log("Installation contract passed: repository closure and supplied live evidence are green.");
}

if (process.argv[1] && pathToFileURL(process.argv[1]).href === import.meta.url) {
  await main();
}
