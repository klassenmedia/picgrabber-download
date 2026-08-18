#!/bin/bash
# PicGrabber — wird per curl ausgefuehrt, daher ohne Gatekeeper-Dialog.
#
# Ueber curl geladene Dateien bekommen kein Quarantaene-Flag. Genau deshalb
# gibt es diesen Weg: ein aus dem Browser geladenes .app oder .command wird
# auf aktuellem macOS blockiert, und seit macOS 15 hilft auch der
# Rechtsklick-Trick nicht mehr.

set -euo pipefail

ZIEL="$HOME/PicGrabber"
QUELLE="https://klassenmedia.github.io/picgrabber-download/PicGrabber.zip"

clear 2>/dev/null || true
cat <<'BANNER'

  ==============================================
     PicGrabber
     Bilder aus deinen Videos
  ==============================================

BANNER

abbruch() {
  echo ""
  echo "  ❌ $1"
  echo ""
  [[ -n "${2:-}" ]] && { echo "     $2"; echo ""; }
  echo "     Bitte diesen Text abfotografieren"
  echo "     und an Andreas schicken."
  echo ""
  exit 1
}

# ── Passt der Rechner? ────────────────────────────
[[ "$(uname -s)" == "Darwin" ]] || abbruch "Das läuft nur auf einem Mac."

MACOS_MAJOR=$(sw_vers -productVersion 2>/dev/null | cut -d. -f1)
[[ -n "$MACOS_MAJOR" && "$MACOS_MAJOR" -lt 11 ]] && \
  abbruch "Dein macOS ist zu alt." "Nötig ist macOS 11 oder neuer."

# ── Herunterladen ─────────────────────────────────
echo "  Wird geladen …"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

curl -fsSL -o "$TMP/pg.zip" "$QUELLE" \
  || abbruch "Der Download hat nicht geklappt." "Ist das Internet erreichbar?"

rm -rf "$ZIEL"
mkdir -p "$ZIEL"
# ditto keeps the bundle and permissions intact; unzip can mangle both.
ditto -x -k "$TMP/pg.zip" "$TMP/entpackt" \
  || abbruch "Die Datei ließ sich nicht entpacken."

# Der Inhalt liegt eine Ebene tief im Ordner "PicGrabber".
if [[ -d "$TMP/entpackt/PicGrabber" ]]; then
  cp -R "$TMP/entpackt/PicGrabber/." "$ZIEL/"
else
  cp -R "$TMP/entpackt/." "$ZIEL/"
fi

[[ -f "$ZIEL/programm/sichtung.py" ]] || abbruch "Das Paket ist unvollständig."

# Nothing here came through a browser, but strip the attribute anyway so a
# later double-click on the app keeps working.
xattr -dr com.apple.quarantine "$ZIEL" 2>/dev/null || true
chmod +x "$ZIEL/programm/start.sh" 2>/dev/null || true
[[ -f "$ZIEL/START HIER.app/Contents/MacOS/start" ]] && \
  chmod +x "$ZIEL/START HIER.app/Contents/MacOS/start" 2>/dev/null || true

echo "  ✅ Fertig installiert in: $ZIEL"
echo ""

# ── Starten ───────────────────────────────────────
exec bash "$ZIEL/programm/start.sh"
