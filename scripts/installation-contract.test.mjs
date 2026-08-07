import { strict as assert } from "node:assert";
import test from "node:test";

import {
  assertLiveInstallationClosure,
  assertRepositoryInstallationClosure,
  findInactiveZtoadProgramParts,
  unwrapInactiveObjects,
} from "./installation-contract.mjs";

const incompleteInstallation = {
  count: 7,
  objects: [
    { name: "ZTOAD", type: "PROG/P" },
    { name: "ZTOAD", type: "PROG/PCA" },
    { name: "ZTOAD                                   0010", type: "PROG/PS" },
    { name: "ZTOAD                                   0100", type: "PROG/PS" },
    { name: "ZTOAD                                   0200", type: "PROG/PS" },
    { name: "ZTOAD                                   0300", type: "PROG/PS" },
    { name: "ZTOAD", type: "PROG/PX" },
  ],
};

test("repository serializes the complete ZTOAD installation closure", async () => {
  await assertRepositoryInstallationClosure();
});

test("live closure ignores inactive objects belonging to other programs", () => {
  assert.doesNotThrow(() =>
    assertLiveInstallationClosure({
      count: 2,
      objects: [
        { name: "ZOTHER", type: "PROG/P" },
        { name: "ZOTHER                                   0010", type: "PROG/PS" },
      ],
    }),
  );
});

test("live closure rejects inactive source, GUI status, screens, and texts", () => {
  const inactiveParts = findInactiveZtoadProgramParts(incompleteInstallation);
  assert.deepEqual(
    inactiveParts.map(({ type }) => type),
    ["PROG/P", "PROG/PCA", "PROG/PS", "PROG/PS", "PROG/PS", "PROG/PS", "PROG/PX"],
  );
  assert.throws(
    () => assertLiveInstallationClosure(incompleteInstallation),
    /activate these composite program parts.*PROG\/PCA ZTOAD.*PROG\/PS ZTOAD 0010.*PROG\/PX ZTOAD/,
  );
});

test("live closure accepts the JSON envelope emitted by the ARC-1 CLI", () => {
  const envelope = {
    content: [{ type: "text", text: JSON.stringify(incompleteInstallation) }],
  };
  assert.deepEqual(unwrapInactiveObjects(envelope), incompleteInstallation.objects);
});
