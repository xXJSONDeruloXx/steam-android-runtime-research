#!/bin/sh

# SteamOS Gamepad UI expects a System.Network bridge that is not exposed by
# the Android-hosted Steam client.  Patch only the known optional network
# calls, and fail closed when the Steam UI asset changes unexpectedly.

set -u

STEAM_ROOT=${1:-/opt/nova-steam/home/.local/share/Steam}
STEAMUI_ROOT="$STEAM_ROOT/steamui"
TMP_SUFFIX=".nova-network-compat.$$"

patch_file() {
    file=$1
    old=$2
    new=$3
    label=$4

    if grep -Fq "$new" "$file"; then
        echo "steam_network_compat_${label}=already-patched file=$file"
        return 0
    fi
    if ! grep -Fq "$old" "$file"; then
        return 2
    fi

    before=$(sha256sum "$file" | awk '{print $1}')
    tmp="$file$TMP_SUFFIX"
    rm -f "$tmp"
    if ! awk -v old="$old" -v new="$new" '
        {
            line = $0
            replaced = 0
            while ((at = index(line, old)) != 0) {
                line = substr(line, 1, at - 1) new substr(line, at + length(old))
                replaced++
            }
            total += replaced
            print line
        }
        END {
            if (total == 0)
                exit 42
        }
    ' "$file" >"$tmp"; then
        rm -f "$tmp"
        echo "steam_network_compat_${label}=fail reason=replace" >&2
        return 1
    fi
    if ! cp "$tmp" "$file"; then
        rm -f "$tmp"
        echo "steam_network_compat_${label}=fail reason=install" >&2
        return 1
    fi
    rm -f "$tmp"
    if grep -Fq "$old" "$file" || ! grep -Fq "$new" "$file"; then
        echo "steam_network_compat_${label}=fail reason=verify" >&2
        return 1
    fi
    after=$(sha256sum "$file" | awk '{print $1}')
    echo "steam_network_compat_${label}=patched file=$file before=$before after=$after"
    return 0
}

if [ ! -d "$STEAMUI_ROOT" ]; then
    echo "steam_network_compat=fail reason=missing_steamui path=$STEAMUI_ROOT" >&2
    exit 1
fi

status=0
matched=0
for file in $(find "$STEAMUI_ROOT" -type f -name '*.js' -exec grep -l 'SteamClient.System.Network' {} \;); do
    if grep -Fq 'SteamClient.System.Network.RegisterForDeviceChanges(this.OnNetworkDevicesChanged)' "$file"; then
        matched=1
        patch_file "$file" \
            'SteamClient.System.Network.RegisterForDeviceChanges(this.OnNetworkDevicesChanged)' \
            'SteamClient.System.Network?.RegisterForDeviceChanges?.(this.OnNetworkDevicesChanged)' \
            register_device_changes || status=1
    fi
    if grep -Fq 'SteamClient.System.Network?.StartScanningForNetworks().then(u.rA)' "$file"; then
        matched=1
        patch_file "$file" \
            'StartScanningForNetworks(){SteamClient.System.Network?.StartScanningForNetworks().then(u.rA)}' \
            'StartScanningForNetworks(){const e=SteamClient.System.Network?.StartScanningForNetworks?.();e?.then?.(u.rA)}' \
            start_scan || status=1
    fi
    if grep -Fq 'SteamClient.System.Network?.StopScanningForNetworks().then(u.rA)' "$file"; then
        matched=1
        patch_file "$file" \
            'StopScanningForNetworks(){SteamClient.System.Network?.StopScanningForNetworks().then(u.rA)}' \
            'StopScanningForNetworks(){const e=SteamClient.System.Network?.StopScanningForNetworks?.();e?.then?.(u.rA)}' \
            stop_scan || status=1
    fi
    if grep -Fq 'SteamClient.System.Network.GetProxyInfo().then(e=>this.m_proxyInfo=e)' "$file"; then
        matched=1
        patch_file "$file" \
            'SteamClient.System.Network.GetProxyInfo().then(e=>this.m_proxyInfo=e)' \
            'SteamClient.System.Network?.GetProxyInfo?.()?.then?.(e=>this.m_proxyInfo=e)' \
            get_proxy_info || status=1
    fi
    if grep -Fq 'SteamClient.System.Network.RegisterForConnectivityTestChanges(this.OnConnectivityTestStateChanged)' "$file"; then
        matched=1
        patch_file "$file" \
            'SteamClient.System.Network.RegisterForConnectivityTestChanges(this.OnConnectivityTestStateChanged)' \
            'SteamClient.System.Network?.RegisterForConnectivityTestChanges?.(this.OnConnectivityTestStateChanged)' \
            register_connectivity_changes || status=1
    fi
    if grep -Fq 'SteamClient.System.Network?.SetProxyInfo(e.proxy_mode,e.address??"",e.port??0,e.exclude_local??!0)' "$file"; then
        matched=1
        patch_file "$file" \
            'SteamClient.System.Network?.SetProxyInfo(e.proxy_mode,e.address??"",e.port??0,e.exclude_local??!0)' \
            'SteamClient.System.Network?.SetProxyInfo?.(e.proxy_mode,e.address??"",e.port??0,e.exclude_local??!0)' \
            set_proxy_info || status=1
    fi
    if grep -Fq 'SteamClient.System.Network.ForceTestConnectivity()' "$file"; then
        matched=1
        patch_file "$file" \
            'SteamClient.System.Network.ForceTestConnectivity()' \
            'SteamClient.System.Network?.ForceTestConnectivity?.()' \
            force_test_connectivity || status=1
    fi
    if grep -Fq 'SteamClient.System.Network.SetWifiEnabled(e)' "$file"; then
        matched=1
        patch_file "$file" \
            'SteamClient.System.Network.SetWifiEnabled(e)' \
            'SteamClient.System.Network?.SetWifiEnabled?.(e)' \
            set_wifi_enabled || status=1
    fi
    if grep -Fq 'SteamClient.System.Network.SetFakeLocalSystemState(e)' "$file"; then
        matched=1
        patch_file "$file" \
            'SteamClient.System.Network.SetFakeLocalSystemState(e)' \
            'SteamClient.System.Network?.SetFakeLocalSystemState?.(e)' \
            set_fake_local_state || status=1
    fi
    if grep -Fq 'SteamClient.System.Network.RegisterForConnectionStateUpdate(t)' "$file"; then
        matched=1
        patch_file "$file" \
            'SteamClient.System.Network.RegisterForConnectionStateUpdate(t)' \
            'SteamClient.System.Network?.RegisterForConnectionStateUpdate?.(t)' \
            register_connection_state || status=1
    fi
    if grep -Fq 'SteamClient.System.Network.RegisterForAppSummaryUpdate(t)' "$file"; then
        matched=1
        patch_file "$file" \
            'SteamClient.System.Network.RegisterForAppSummaryUpdate(t)' \
            'SteamClient.System.Network?.RegisterForAppSummaryUpdate?.(t)' \
            register_app_summary || status=1
    fi
    if grep -Fq 'nl.op.SetOOBEComplete(),t(e,r)' "$file"; then
        matched=1
        patch_file "$file" \
            'nl.op.SetOOBEComplete(),t(e,r)' \
            'await nl.op.SetOOBEComplete(),t(e,r)' \
            oobe_completion_order || status=1
    fi
    if grep -Fq 'const n={};o.oy.IsDeckFactoryImage()||i==Em.ej?n.bRequireReboot=!0:n.bRequireSteamRestart=!0,console.assert(n.bRequireReboot||n.bRequireSteamRestart),t(n)' "$file"; then
        matched=1
        patch_file "$file" \
            'const n={};o.oy.IsDeckFactoryImage()||i==Em.ej?n.bRequireReboot=!0:n.bRequireSteamRestart=!0,console.assert(n.bRequireReboot||n.bRequireSteamRestart),t(n)' \
            't(void 0)' \
            oobe_no_restart || status=1
    fi
    if grep -Fq '0==l.length&&(0,i.jsx)(wm.e.Button,{rightIcons:s&&(0,i.jsx)(Tt.Spinner,{}),children:(0,ye.we)("#Login_NoNetworksFound")})' "$file"; then
        matched=1
        patch_file "$file" \
            '0==l.length&&(0,i.jsx)(wm.e.Button,{rightIcons:s&&(0,i.jsx)(Tt.Spinner,{}),children:(0,ye.we)("#Login_NoNetworksFound")})' \
            '0==l.length&&(0,i.jsx)(wm.e.Button,{onActivate:t,onClick:t,rightIcons:s&&(0,i.jsx)(Tt.Spinner,{}),children:"Continue with Android host network"})' \
            android_host_network_continue || status=1
    fi
done

if [ "$matched" -eq 0 ]; then
    for file in $(find "$STEAMUI_ROOT" -type f -name '*.js' -exec grep -l 'SteamClient.System.Network' {} \;); do
        if grep -Fq 'SteamClient.System.Network?.RegisterForDeviceChanges?.(this.OnNetworkDevicesChanged)' "$file" && \
            grep -Fq 'StartScanningForNetworks(){const e=SteamClient.System.Network?.StartScanningForNetworks?.();e?.then?.(u.rA)}' "$file" && \
            grep -Fq 'SteamClient.System.Network?.GetProxyInfo?.()?.then?.(e=>this.m_proxyInfo=e)' "$file" && \
            grep -Fq 'await nl.op.SetOOBEComplete(),t(e,r)' "$file" && \
            grep -Fq 't(void 0)' "$file" && \
            grep -Fq 'children:"Continue with Android host network"' "$file"; then
            echo "steam_network_compat=already-patched file=$file"
            matched=1
            break
        fi
    done
fi

if [ "$matched" -eq 0 ]; then
    echo "steam_network_compat=fail reason=unsupported_steamui" >&2
    exit 1
fi
if [ "$status" -ne 0 ]; then
    echo "steam_network_compat=fail reason=patch" >&2
    exit 1
fi

echo "steam_network_compat=pass root=$STEAM_ROOT"
