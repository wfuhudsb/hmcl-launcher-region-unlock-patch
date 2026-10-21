#!/usr/bin/env bash
# Build a region-unlocked HMCL jar from the official upstream release.
#
# Usage:  ./scripts/build.sh [HMCL_VERSION]        (default: 3.17.0.362)
# Output: dist/HMCL-<version>-patched.jar
#
# Requirements: bash, curl, a JDK >= 17 (javac/jar/javap on PATH).
#
# Optional: HMCL_JAR=/path/to/HMCL-<version>.jar builds from an already
# downloaded official jar instead of fetching from GitHub (useful on slow
# networks). The file is sanity-checked to be a real HMCL jar first.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_VERSION="$(cat "$REPO_DIR/HMCL_VERSION" 2>/dev/null | tr -d '[:space:]')"
VERSION="${1:-${DEFAULT_VERSION:-3.17.0.362}}"
BUILD_DIR="$REPO_DIR/build/$VERSION"
DIST_DIR="$REPO_DIR/dist"
UPSTREAM_JAR="HMCL-$VERSION.jar"
PATCHED_JAR="HMCL-$VERSION-patched.jar"
TARGET_CLASS="org/jackhuang/hmcl/util/RegionUtils.class"

# The patched class is compiled with the same --release as upstream HMCL
# currently targets (Java 17), so it runs on any Java >= 17.
JAVAC_RELEASE=17

echo "==> HMCL version: $VERSION"

# ---------------------------------------------------------------- locate JDK
if [[ -n "${JAVA_HOME:-}" && -x "$JAVA_HOME/bin/javac" ]]; then
  JBIN="$JAVA_HOME/bin"
elif command -v javac >/dev/null 2>&1; then
  JBIN="$(dirname "$(command -v javac)")"
else
  echo "ERROR: no JDK found. Install JDK >= 17 or set JAVA_HOME." >&2
  exit 1
fi
echo "==> Using JDK at: $JBIN"

# ------------------------------------------------------------- get upstream
mkdir -p "$BUILD_DIR" "$DIST_DIR"

jar_is_valid() {
  [[ -s "$1" ]] && "$JBIN/jar" tf "$1" 2>/dev/null | grep -q "^$TARGET_CLASS$"
}

# drop a truncated/corrupted cache left behind by an interrupted download
if [[ -f "$BUILD_DIR/$UPSTREAM_JAR" ]] && ! jar_is_valid "$BUILD_DIR/$UPSTREAM_JAR"; then
  echo "==> Discarding invalid cached jar"
  rm -f "$BUILD_DIR/$UPSTREAM_JAR"
fi

if [[ -f "$BUILD_DIR/$UPSTREAM_JAR" ]]; then
  echo "==> Using cached official jar"
elif [[ -n "${HMCL_JAR:-}" ]]; then
  echo "==> Using local jar: $HMCL_JAR"
  [[ -f "$HMCL_JAR" ]] || { echo "ERROR: HMCL_JAR not found: $HMCL_JAR" >&2; exit 1; }
  jar_is_valid "$HMCL_JAR" \
    || { echo "ERROR: $HMCL_JAR is not a valid HMCL jar (missing $TARGET_CLASS)" >&2; exit 1; }
  cp "$HMCL_JAR" "$BUILD_DIR/$UPSTREAM_JAR"
else
  echo "==> Downloading official $UPSTREAM_JAR ..."
  curl -fL --retry 3 --max-time 600 \
    -o "$BUILD_DIR/$UPSTREAM_JAR.part" \
    "https://github.com/HMCL-dev/HMCL/releases/download/v$VERSION/$UPSTREAM_JAR"
  mv "$BUILD_DIR/$UPSTREAM_JAR.part" "$BUILD_DIR/$UPSTREAM_JAR"
fi

# ---------------------------------------------------- compile patched class
# The upstream jar itself is used as the classpath so the patched source
# resolves against the exact same dependency versions as the release.
echo "==> Compiling patched RegionUtils.java ..."
rm -rf "$BUILD_DIR/classes"
mkdir -p "$BUILD_DIR/classes"
"$JBIN/javac" --release "$JAVAC_RELEASE" -encoding UTF-8 \
  -cp "$BUILD_DIR/$UPSTREAM_JAR" \
  -d "$BUILD_DIR/classes" \
  "$REPO_DIR/patches/RegionUtils.java"

# ----------------------------------------------------------- patch the jar
echo "==> Writing patched class into the jar ..."
cp "$BUILD_DIR/$UPSTREAM_JAR" "$DIST_DIR/$PATCHED_JAR"
(cd "$BUILD_DIR/classes" && "$JBIN/jar" uf "$DIST_DIR/$PATCHED_JAR" "$TARGET_CLASS")

# --------------------------------------------------------------- verify
echo "==> Verifying ..."
if command -v unzip >/dev/null 2>&1; then
  unzip -tq "$DIST_DIR/$PATCHED_JAR" >/dev/null \
    || { echo "ERROR: jar integrity check failed" >&2; exit 1; }
else
  "$JBIN/jar" tf "$DIST_DIR/$PATCHED_JAR" >/dev/null \
    || { echo "ERROR: jar is not readable" >&2; exit 1; }
fi

if ! "$JBIN/javap" -p -c -cp "$DIST_DIR/$PATCHED_JAR" \
      org.jackhuang.hmcl.util.RegionUtils \
      | grep -A2 'isIsChinaMainlandNetwork()' | grep -q 'iconst_0'; then
  echo "ERROR: patched method body not found in jar" >&2
  exit 1
fi

echo "==> OK: $DIST_DIR/$PATCHED_JAR"
echo "==> SHA-256:"
shasum -a 256 "$DIST_DIR/$PATCHED_JAR" 2>/dev/null \
  || sha256sum "$DIST_DIR/$PATCHED_JAR"
