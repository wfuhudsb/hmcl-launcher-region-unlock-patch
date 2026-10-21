# HMCL Launcher Region Unlock Patch

A small, source-reproducible patch for
[Hello Minecraft! Launcher (HMCL)](https://github.com/HMCL-dev/HMCL)
that re-enables the built-in **game / mod download pages** which upstream
disabled for mainland-China regions.

> **DISCLAIMER** — This project is for **personal study and research only**.
> It modifies an open-source program that you are already licensed to use
> (GNU GPLv3). It is not affiliated with, endorsed by, or supported by the
> HMCL project or Mojang / Microsoft. You use it entirely at your own risk,
> and you are responsible for complying with all laws and regulations that
> apply to you. If you want the officially supported experience, use official
> channels.

## Background

On 2026-10-20 HMCL merged [PR #7017](https://github.com/HMCL-dev/HMCL/pull/7017)
("在中国大陆地区禁用游戏下载功能"). Starting with v3.17.0.362, the launcher
detects mainland-China regions (system timezone / locale / geo-IP via
`ipwho.is`) and replaces the game version list and the mod list pages with a
warning pane, effectively disabling downloads inside the launcher.

## What this patch does

It replaces exactly **one class** — `org.jackhuang.hmcl.util.RegionUtils` —
with a recompiled version whose four region-detection methods always return
`false`:

| method | after patch |
|---|---|
| `checkMachineIsChinaMainland()` | `return false;` |
| `isIsChinaMainlandMachine()` | `return false;` |
| `checkChinaMainlandNetwork()` | `return false;` |
| `isIsChinaMainlandNetwork()` | `return false;` |

A full scan of the jar confirms every region gate in v3.17.x funnels through
`RegionUtils` (the older `LocaleUtils.IS_CHINA_MAINLAND` is referenced by
nothing else), so this single substitution restores all gated download pages
while leaving every other behavior of the official release untouched.

## Build

Requirements: any JDK ≥ 17, `bash`, `curl`.

```bash
./scripts/build.sh                # downloads official HMCL-3.17.0.362.jar, patches it
./scripts/build.sh 3.17.0.362     # explicit version
HMCL_JAR=/path/to/HMCL-x.y.z.jar ./scripts/build.sh x.y.z   # build from a local jar
```

Output: `dist/HMCL-<version>-patched.jar` (plus its SHA-256 printed at the end).

The script verifies its own output: zip integrity, and `javap` inspection of
the patched class inside the final jar.

### Verified test matrix

- patched class disassembles to `iconst_0; ireturn` for all four methods
- `unzip -t` passes on the produced jar
- reflection smoke test: `isIsChinaMainlandMachine()` / `isIsChinaMainlandNetwork()` → `false`
- runtime requirement: Java ≥ 17 (class file major version 61)

## Use

1. Download the patched jar from the latest **Releases** of this repository (or build it yourself — recommended if you don't trust binary artifacts).
2. Double-click it (needs Java ≥ 17). Your existing `.hmcl` config and game directories work as-is.
3. **Turn off in-app auto-update**, or a future official update will overwrite the patch.

## How it works (details)

- `patches/RegionUtils.java` is the original upstream file (copyright header
  preserved, with a modification notice as required by GPLv3 §5a) with the
  method bodies stubbed out.
- It is compiled with `--release 17` against the official jar itself as the
  classpath, so the bytecode links against exactly the same dependency
  versions the release ships.
- The compiled class is written into a copy of the official jar with `jar uf`,
  replacing the original entry. No other entry is modified.

## License

GPLv3 (same as HMCL). See [LICENSE](LICENSE). The patch source retains the
original HMCL copyright notice.

## Legal note

Removing a region restriction may violate the *terms of use of the content
providers* (e.g. Mojang's EULA restricts offline redistribution of game
assets) and the regulations of your jurisdiction even though modifying the
launcher itself is your right under GPLv3. Know your local law. This
repository exists as a technical study of how the restriction is implemented
and how single-class Java binary patching works.
