import { readFile } from "node:fs/promises";
import { strict as assert } from "node:assert";

const transactionPath = new URL("../src/ztoad.tran.xml", import.meta.url);

let transactionXml;

try {
  transactionXml = await readFile(transactionPath, "utf8");
} catch (error) {
  if (error?.code === "ENOENT") {
    throw new Error("Missing native-abapGit transaction object: src/ztoad.tran.xml");
  }
  throw error;
}

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

console.log("Repository contract passed: TRAN ZTOAD is serialized for report, WebGUI, and Windows startup.");
