const fs = require('fs');
const path = require('path');

const repoRoot = process.cwd();
const jsonPath = path.join(repoRoot, 'enchantments.json');
const outPath = path.join(repoRoot, 'Data', 'EnchantmentsData.lua');
const CURRENT_EXPANSION = 11;

const src = JSON.parse(fs.readFileSync(jsonPath, 'utf8'));

function esc(str) {
    return String(str)
        .replace(/\\/g, '\\\\')
        .replace(/"/g, '\\"')
        .replace(/\n/g, '\\n')
        .replace(/\r/g, '');
}

function inferCategoryName(entry) {
    if (entry.categoryName) {
        return entry.categoryName;
    }

    const req = entry.equipRequirements;
    if (
        req &&
        req.itemClass === 4 &&
        req.itemSubClassMask === 30 &&
        req.invTypeMask === 128
    ) {
        return 'Leg Enchants';
    }

    return entry.categoryName;
}

const entries = src
    .filter((e) =>
        e &&
        typeof e === 'object' &&
        (e.id || e.itemId) &&
        (e.expansion === CURRENT_EXPANSION || e.categoryName === 'Runes')
    )
    .map((e) => ({
        statCount: Array.isArray(e.stats) ? e.stats.length : undefined,
        hasPrimaryStat: Array.isArray(e.stats)
            ? e.stats.some((s) => s && s.type === 'stragiint')
            : undefined,
        id: e.id,
        itemId: e.itemId,
        spellId: e.spellId,
        displayName: e.displayName,
        itemName: e.itemName,
        itemIcon: e.itemIcon,
        tokenizedName: e.tokenizedName,
        categoryName: inferCategoryName(e),
        expansion: e.expansion,
        craftingQuality: e.craftingQuality,
        quality: e.quality,
        slot: e.slot,
        socketType: e.socketType,
    }));

const byCategoryName = {};
const bySlot = {};

for (const entry of entries) {
    if (entry.categoryName) {
        byCategoryName[entry.categoryName] = byCategoryName[entry.categoryName] || [];
        byCategoryName[entry.categoryName].push(entry);
    }

    if (entry.slot) {
        bySlot[entry.slot] = bySlot[entry.slot] || [];
        bySlot[entry.slot].push(entry);
    }
}

function sortedKeys(obj) {
    return Object.keys(obj).sort((a, b) => a.localeCompare(b));
}

function writeEntryBlock(e) {
    let block = '';
    block += '        {\n';
    if (e.statCount != null) block += `            statCount = ${e.statCount},\n`;
    if (e.hasPrimaryStat != null) block += `            hasPrimaryStat = ${e.hasPrimaryStat ? 'true' : 'false'},\n`;
    if (e.id != null) block += `            id = ${e.id},\n`;
    if (e.itemId != null) block += `            itemId = ${e.itemId},\n`;
    if (e.spellId != null) block += `            spellId = ${e.spellId},\n`;
    if (e.displayName != null) block += `            displayName = "${esc(e.displayName)}",\n`;
    if (e.itemName != null) block += `            itemName = "${esc(e.itemName)}",\n`;
    if (e.itemIcon != null) block += `            itemIcon = "${esc(e.itemIcon)}",\n`;
    if (e.tokenizedName != null) block += `            tokenizedName = "${esc(e.tokenizedName)}",\n`;
    if (e.categoryName != null) block += `            categoryName = "${esc(e.categoryName)}",\n`;
    if (e.expansion != null) block += `            expansion = ${e.expansion},\n`;
    if (e.craftingQuality != null) block += `            craftingQuality = ${e.craftingQuality},\n`;
    if (e.quality != null) block += `            quality = ${e.quality},\n`;
    if (e.slot != null) block += `            slot = "${esc(e.slot)}",\n`;
    if (e.socketType != null) block += `            socketType = "${esc(e.socketType)}",\n`;
    block += '        },\n';
    return block;
}

function writeGroupedTable(name, grouped) {
    let block = `MrMythicalGearCheck.EnchantmentsData.${name} = {\n`;

    for (const key of sortedKeys(grouped)) {
        block += `    ["${esc(key)}"] = {\n`;
        for (const entry of grouped[key]) {
            block += writeEntryBlock(entry);
        }
        block += '    },\n';
    }

    block += '}\n\n';
    return block;
}

let out = '';
out += '--[[\n';
out += 'EnchantmentsData.lua - Generated from enchantments.json\n\n';
out += 'Single source data table used by EnchantData and GemData.\n';
out += 'Do not edit manually; regenerate from enchantments.json when data updates.\n';
out += `Contains expansion ${CURRENT_EXPANSION} data plus Death Knight runes (which have no expansion tag).\n`;
out += '--]]\n\n';
out += 'local MrMythicalGearCheck = MrMythicalGearCheck or {}\n';
out += 'MrMythicalGearCheck.EnchantmentsData = MrMythicalGearCheck.EnchantmentsData or {}\n\n';
out += `MrMythicalGearCheck.EnchantmentsData.CURRENT_EXPANSION = ${CURRENT_EXPANSION}\n\n`;
out += writeGroupedTable('BY_CATEGORY_NAME', byCategoryName);
out += writeGroupedTable('BY_SLOT', bySlot);
out += 'MrMythicalGearCheck.EnchantmentsData.ENTRIES = {\n';
for (const e of entries) {
    out += '    {\n';
    if (e.statCount != null) out += `        statCount = ${e.statCount},\n`;
    if (e.hasPrimaryStat != null) out += `        hasPrimaryStat = ${e.hasPrimaryStat ? 'true' : 'false'},\n`;
    if (e.id != null) out += `        id = ${e.id},\n`;
    if (e.itemId != null) out += `        itemId = ${e.itemId},\n`;
    if (e.spellId != null) out += `        spellId = ${e.spellId},\n`;
    if (e.displayName != null) out += `        displayName = "${esc(e.displayName)}",\n`;
    if (e.itemName != null) out += `        itemName = "${esc(e.itemName)}",\n`;
    if (e.itemIcon != null) out += `        itemIcon = "${esc(e.itemIcon)}",\n`;
    if (e.tokenizedName != null) out += `        tokenizedName = "${esc(e.tokenizedName)}",\n`;
    if (e.categoryName != null) out += `        categoryName = "${esc(e.categoryName)}",\n`;
    if (e.expansion != null) out += `        expansion = ${e.expansion},\n`;
    if (e.craftingQuality != null) out += `        craftingQuality = ${e.craftingQuality},\n`;
    if (e.quality != null) out += `        quality = ${e.quality},\n`;
    if (e.slot != null) out += `        slot = "${esc(e.slot)}",\n`;
    if (e.socketType != null) out += `        socketType = "${esc(e.socketType)}",\n`;
    out += '    },\n';
}
out += '}\n\n';
out += '_G.MrMythicalGearCheck = MrMythicalGearCheck\n';

fs.writeFileSync(outPath, out, 'utf8');
console.log(`Generated ${path.relative(repoRoot, outPath)} with ${entries.length} entries.`);
