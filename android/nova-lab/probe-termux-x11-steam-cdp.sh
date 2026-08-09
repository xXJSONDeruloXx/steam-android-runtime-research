#!/usr/bin/env bash

set -euo pipefail

ADB=${ADB:-/Users/kurt/.local/bin/adb}
ADB_SERIAL=${ADB_SERIAL:-675a2365}
RUN_ID=${NOVA_RUN_ID:?NOVA_RUN_ID is required}
RUN_DIR=${NOVA_RUN_DIR:?NOVA_RUN_DIR is required}
CDP_PORT=${NOVA_CDP_PORT:-9222}
DEVICE_CDP_PORT=${NOVA_CDP_DEVICE_PORT:-8080}

case "$RUN_ID" in
    ''|*[!A-Za-z0-9._-]*)
        echo "invalid NOVA_RUN_ID: $RUN_ID" >&2
        exit 2
        ;;
esac
case "$CDP_PORT:$DEVICE_CDP_PORT" in
    ''|*[!0-9:]*|*:*:*)
        echo "NOVA_CDP_PORT and NOVA_CDP_DEVICE_PORT must be numeric" >&2
        exit 2
        ;;
esac

mkdir -p "$RUN_DIR"
TARGETS="$RUN_DIR/cdp-targets.json"
EVALUATION="$RUN_DIR/cdp-login-state.json"
FORWARD="$RUN_DIR/adb-cdp-forward.txt"
STATUS="$RUN_DIR/cdp-probe-status.txt"

cleanup() {
    status=$?
    trap - EXIT
    remove_status=0
    "$ADB" -s "$ADB_SERIAL" forward --remove "tcp:$CDP_PORT" >>"$FORWARD" 2>&1 || remove_status=$?
    if [ "$status" -eq 0 ] && [ "$remove_status" -ne 0 ]; then
        status=$remove_status
    fi
    printf 'run_id=%s\ncdp_probe_status=%s\n' "$RUN_ID" "$([ "$status" -eq 0 ] && echo pass || echo fail)" >"$STATUS"
    exit "$status"
}
trap cleanup EXIT INT TERM

: >"$FORWARD"
"$ADB" -s "$ADB_SERIAL" forward --remove "tcp:$CDP_PORT" >>"$FORWARD" 2>&1 || true
"$ADB" -s "$ADB_SERIAL" forward "tcp:$CDP_PORT" "tcp:$DEVICE_CDP_PORT" >>"$FORWARD" 2>&1

target_status=1
for attempt in $(seq 1 45); do
    if curl --fail --silent --show-error "http://127.0.0.1:$CDP_PORT/json" >"$TARGETS" 2>/dev/null &&
        rg -q 'steamloopback\.host|Steam Big Picture' "$TARGETS"; then
        target_status=0
        break
    fi
    sleep 1
done
if [ "$target_status" -ne 0 ]; then
    echo "CDP target did not become available" >&2
    exit 1
fi

TARGETS_PATH="$TARGETS" EVALUATION_PATH="$EVALUATION" node --input-type=module <<'NODE'
import fs from "node:fs";

const targetsPath = process.env.TARGETS_PATH;
const evaluationPath = process.env.EVALUATION_PATH;
const targets = JSON.parse(fs.readFileSync(targetsPath, "utf8"));
const target = targets.find((entry) =>
  entry.type === "page" &&
  (String(entry.url).includes("steamloopback.host") ||
    String(entry.title).includes("Steam Big Picture")),
) ?? targets.find((entry) => entry.type === "page");

if (!target?.webSocketDebuggerUrl) {
  throw new Error("no CDP page target with webSocketDebuggerUrl");
}

const expression = `
(async () => {
  const steamClient = window.SteamClient;
  const user = steamClient && steamClient.User;
  const methods = {
    getStartupUserChooserState: typeof user?.GetStartupUserChooserState,
    startLogin: typeof user?.StartLogin,
    getLoginUsers: typeof user?.GetLoginUsers,
    getCurrentUser: typeof user?.GetCurrentUser,
  };
  let startupState;
  try {
    if (typeof user?.GetStartupUserChooserState !== "function") {
      startupState = { unavailable: true };
    } else {
      const value = user.GetStartupUserChooserState();
      startupState = await Promise.race([
        Promise.resolve(value),
        new Promise((resolve) => setTimeout(() => resolve({ timeout: true }), 1500)),
      ]);
    }
  } catch (error) {
    startupState = { error: String(error) };
  }
  const result = {
    href: location.href,
    title: document.title,
    body: (document.body?.innerText || "").slice(0, 1200),
    methods,
    startupState,
  };
  try {
    return JSON.stringify(result);
  } catch (error) {
    return JSON.stringify({ ...result, startupState: { unserializable: String(error) } });
  }
})()
`;

const ws = new WebSocket(target.webSocketDebuggerUrl);
let timer;
const messageId = 1;

const result = await new Promise((resolve, reject) => {
  timer = setTimeout(() => reject(new Error("CDP Runtime.evaluate timed out")), 5000);
  ws.addEventListener("open", () => {
    ws.send(JSON.stringify({
      id: messageId,
      method: "Runtime.evaluate",
      params: { expression, awaitPromise: true, returnByValue: true },
    }));
  });
  ws.addEventListener("message", (event) => {
    const message = JSON.parse(String(event.data));
    if (message.id !== messageId) return;
    if (message.error) reject(new Error(JSON.stringify(message.error)));
    else resolve(message.result?.result?.value ?? message.result);
  });
  ws.addEventListener("error", () => reject(new Error("CDP websocket error")));
});

clearTimeout(timer);
fs.writeFileSync(evaluationPath, `${JSON.stringify({ target, evaluation: JSON.parse(result) }, null, 2)}\n`);
console.log(fs.readFileSync(evaluationPath, "utf8"));
ws.close();
NODE

echo "termux_x11_cdp_probe=pass run_id=$RUN_ID"
