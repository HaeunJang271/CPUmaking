#!/usr/bin/env python3
"""Find the COM port that appears when Tang Nano 9K BL702 enters DFU mode.

Usage:
  1. python tools/dfu_find_com.py snapshot before
  2. Enter DFU (702-BOOT or test points short) + plug USB
  3. python tools/dfu_find_com.py snapshot after
  4. python tools/dfu_find_com.py diff

Or watch live:
  python tools/dfu_find_com.py watch
"""
from __future__ import annotations

import json
import sys
import time
from pathlib import Path

try:
    from serial.tools import list_ports
except ImportError:
    print("Install: python -m pip install pyserial")
    sys.exit(1)

SNAP = Path(__file__).resolve().parent / ".dfu_com_snapshot.json"


def port_map() -> dict[str, dict[str, str]]:
    out: dict[str, dict[str, str]] = {}
    for p in list_ports.comports():
        out[p.device] = {"desc": p.description, "hwid": p.hwid or ""}
    return out


def is_bad_port(info: dict[str, str]) -> str | None:
    blob = f"{info['desc']} {info['hwid']}".upper()
    if "BTHENUM" in blob or "BLUETOOTH" in blob:
        return "Bluetooth"
    if "FACTORYAIOT_PROG" in blob or "PID_6010" in blob:
        return "Gowin JTAG (FTDI)"
    return None


def save(label: str) -> None:
    data = port_map()
    SNAP.write_text(json.dumps({"label": label, "ports": data}, indent=2), encoding="utf-8")
    print(f"Saved {len(data)} ports -> {SNAP} ({label})")
    for com in sorted(data, key=lambda x: int(x.replace("COM", ""))):
        bad = is_bad_port(data[com])
        tag = f"  [{bad}]" if bad else ""
        print(f"  {com}  {data[com]['desc']}{tag}")


def diff() -> int:
    if not SNAP.exists():
        print("No snapshot. Run: python tools/dfu_find_com.py snapshot before")
        return 1
    before = json.loads(SNAP.read_text(encoding="utf-8"))
    after = port_map()
    bset = set(before["ports"])
    aset = set(after)
    new = sorted(aset - bset, key=lambda x: int(x.replace("COM", "")))
    gone = sorted(bset - aset, key=lambda x: int(x.replace("COM", "")))

    print(f"Before ({before.get('label', '?')}): {len(bset)} ports")
    print(f"After: {len(aset)} ports")
    if new:
        print("\n*** NEW ports (DFU candidate) ***")
        for com in new:
            info = after[com]
            bad = is_bad_port(info)
            if bad:
                print(f"  {com}  {info['desc']}  <- probably NOT BL702 ({bad})")
            else:
                print(f"  {com}  {info['desc']}")
                print(f"       {info['hwid'][:100]}")
                print(f"\n  Flash command:")
                print(
                    f"  python -m bflb_mcu_tool --chipname=bl702 --port={com} "
                    f"--xtal=32M --firmware=usb2uartjtag_bl702.bin"
                )
    else:
        print("\nNo new COM port. DFU mode not entered.")
        print("Retry: USB unplug -> short 702-BOOT test points -> plug USB -> run diff again")

    if gone:
        print("\nRemoved ports:", ", ".join(gone))
    return 0 if new else 1


def watch() -> int:
    print("Watching COM ports (Ctrl+C to stop). Enter DFU now...")
    seen = port_map()
    try:
        while True:
            cur = port_map()
            for com in cur:
                if com not in seen:
                    bad = is_bad_port(cur[com])
                    print(f"\n+ {com}  {cur[com]['desc']}" + (f"  [{bad}]" if bad else "  <-- try this"))
            seen = cur
            time.sleep(0.5)
    except KeyboardInterrupt:
        print("\nDone.")
        return 0


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    cmd = sys.argv[1].lower()
    if cmd == "snapshot":
        label = sys.argv[2] if len(sys.argv) > 2 else "snap"
        save(label)
        return 0
    if cmd == "diff":
        return diff()
    if cmd == "watch":
        return watch()
    print(f"Unknown command: {cmd}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
