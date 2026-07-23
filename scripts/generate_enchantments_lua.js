#!/usr/bin/env node
/**
 * generate_enchantments_lua.js
 *
 * Regenerates Data/EnchantmentsData.lua from enchantments.json.
 *
 * Usage:
 *   node scripts/generate_enchantments_lua.js
 *   node scripts/generate_enchantments_lua.js path/to/enchantments.json
 *
 * Expected JSON: an array of entry objects (or { entries: [...] }) with fields
 * used by EnchantData / GemData (id, itemId, categoryName, expansion, etc.).
 */

const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const DEFAULT_INPUT = path.join(ROOT, "enchantments.json");
const OUTPUT = path.join(ROOT, "Data", "EnchantmentsData.lua");
const CURRENT_EXPANSION = 11;

function loadEntries(inputPath) {
  if (!fs.existsSync(inputPath)) {
    throw new Error(
      `Missing source file: ${inputPath}\n` +
        "Place enchantments.json at the repo root (or pass a path as the first argument)."
    );
  }

  const raw = JSON.parse(fs.readFileSync(inputPath, "utf8"));
  if (Array.isArray(raw)) {
    return raw;
  }
  if (raw && Array.isArray(raw.entries)) {
    return raw.entries;
  }
  if (raw && Array.isArray(raw.ENTRIES)) {
    return raw.ENTRIES;
  }
  throw new Error("enchantments.json must be an array, or an object with an entries array.");
}

function shouldKeep(entry) {
  if (!entry || typeof entry !== "object") {
    return false;
  }
  if (entry.categoryName === "Runes") {
    return true;
  }
  return entry.expansion === CURRENT_EXPANSION;
}

function luaString(value) {
  if (value === null || value === undefined) {
    return "nil";
  }
  if (typeof value === "number") {
    return Number.isFinite(value) ? String(value) : "nil";
  }
  if (typeof value === "boolean") {
    return value ? "true" : "false";
  }
  return `"${String(value).replace(/\\/g, "\\\\").replace(/"/g, '\\"')}"`;
}

function formatEntry(entry, indent) {
  const pad = " ".repeat(indent);
  const lines = [`${pad}{`];
  const keys = Object.keys(entry);
  for (const key of keys) {
    const value = entry[key];
    if (value === null || value === undefined) {
      continue;
    }
    lines.push(`${pad}    ${key} = ${luaString(value)},`);
  }
  lines.push(`${pad}},`);
  return lines.join("\n");
}

function buildLua(entries) {
  const byCategory = {};
  for (const entry of entries) {
    const category = entry.categoryName || "Uncategorized";
    if (!byCategory[category]) {
      byCategory[category] = [];
    }
    byCategory[category].push(entry);
  }

  const categoryNames = Object.keys(byCategory).sort((a, b) => a.localeCompare(b));

  let out = "";
  out += "--[[\n";
  out += "EnchantmentsData.lua - Generated from enchantments.json\n\n";
  out += "Single source data table used by EnchantData and GemData.\n";
  out += "Do not edit manually; regenerate from enchantments.json when data updates.\n";
  out += `Contains expansion ${CURRENT_EXPANSION} data plus Death Knight runes (which have no expansion tag).\n`;
  out += "--]]\n\n";
  out += "local MrMythicalGearCheck = MrMythicalGearCheck or {}\n";
  out += "MrMythicalGearCheck.EnchantmentsData = MrMythicalGearCheck.EnchantmentsData or {}\n\n";
  out += `MrMythicalGearCheck.EnchantmentsData.CURRENT_EXPANSION = ${CURRENT_EXPANSION}\n\n`;
  out += "MrMythicalGearCheck.EnchantmentsData.BY_CATEGORY_NAME = {\n";

  for (const category of categoryNames) {
    out += `    [${luaString(category)}] = {\n`;
    for (const entry of byCategory[category]) {
      out += formatEntry(entry, 8) + "\n";
    }
    out += "    },\n";
  }

  out += "}\n\n";
  out += "MrMythicalGearCheck.EnchantmentsData.ENTRIES = {\n";
  for (const entry of entries) {
    out += formatEntry(entry, 4) + "\n";
  }
  out += "}\n\n";
  out += "_G.MrMythicalGearCheck = MrMythicalGearCheck\n";
  return out;
}

function main() {
  const inputPath = path.resolve(process.argv[2] || DEFAULT_INPUT);
  const allEntries = loadEntries(inputPath);
  const filtered = allEntries.filter(shouldKeep);

  if (filtered.length === 0) {
    throw new Error(
      `No entries kept for expansion ${CURRENT_EXPANSION} (plus Runes). Check enchantments.json.`
    );
  }

  fs.mkdirSync(path.dirname(OUTPUT), { recursive: true });
  fs.writeFileSync(OUTPUT, buildLua(filtered), "utf8");
  console.log(
    `Wrote ${filtered.length} entries (${allEntries.length} source) -> ${path.relative(ROOT, OUTPUT)}`
  );
}

main();
