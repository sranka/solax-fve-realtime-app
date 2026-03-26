# Network Scanner for Solax Dongles

## Goal

Allow users to discover Solax dongles on the local network without knowing the IP address. A "Scan Network" button appears above "Add Connection" in connection settings.

## How it works

1. **Determine subnet**: Get the phone's local IP and WiFi subnet mask to derive the scan range (typically /24 = 254 addresses)
2. **Parallel TCP scan on port 502**: Open Modbus TCP connections to all IPs in the subnet concurrently (with a short timeout, e.g. 500ms)
3. **Verify with Modbus request**: For each IP that accepts the connection, send a Modbus read request for a known Solax register (e.g. inverter serial number, function code 0x04) to confirm it's a Solax device
4. **Report progressively**: Show each confirmed dongle immediately in the list with its IP and serial number

## UX flow

- Connection settings screen shows **"Scan Network"** button above **"Add Connection"**
- Tapping it opens a scanning view with a progress indicator (e.g. "Scanning... 45/254")
- Discovered dongles appear in a list as they're found (IP + serial/model if available)
- User taps a dongle -> scanning stops, connection is added automatically
- A "Stop" button to cancel if nothing is found
- Scan completes naturally after all IPs are checked

## Platform notes

- **Android**: Use `WifiManager` to get IP/subnet, plain `Socket` with timeout for TCP scan
- **iOS**: Use `getifaddrs` for network info, `NWConnection` for TCP probing
- **PWA**: Not possible (browsers cannot do raw TCP)

## Scope

- Scan only the current WiFi subnet (no custom ranges)
- Modbus TCP (port 502) only
