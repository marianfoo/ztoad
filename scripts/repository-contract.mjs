import { readFile } from "node:fs/promises";
import { strict as assert } from "node:assert";

const transactionPath = new URL("../src/ztoad.tran.xml", import.meta.url);
const reportPath = new URL("../src/ztoad.prog.abap", import.meta.url);

let transactionXml;
let reportSource;

try {
  transactionXml = await readFile(transactionPath, "utf8");
} catch (error) {
  if (error?.code === "ENOENT") {
    throw new Error("Missing native-abapGit transaction object: src/ztoad.tran.xml");
  }
  throw error;
}

reportSource = await readFile(reportPath, "utf8");

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
  !reportSource.includes("C_DB_EXECUTE"),
  "Unsupported native SQL kernel call C_DB_EXECUTE must not exist in src/ztoad.prog.abap",
);

console.log("Repository contract passed: launcher metadata and forbidden-kernel-call checks are green.");
