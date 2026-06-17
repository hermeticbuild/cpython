"""Generate CPython 3.14's target-specific sysconfig JSON file."""

import json
from pathlib import Path
import sys
import sysconfig
from sysconfig.__main__ import _get_json_data_name, _get_pybuilddir


def main() -> None:
    output_root = Path(sys.argv[1])
    pybuilddir = Path(_get_pybuilddir())
    if pybuilddir.parts[0] != "build":
        raise ValueError(f"unexpected sysconfig build directory: {pybuilddir}")

    output_dir = output_root.joinpath(*pybuilddir.parts[1:])
    output_dir.mkdir(parents=True, exist_ok=True)

    config_vars = sysconfig.get_config_vars().copy()
    config_vars["projectbase"] = config_vars["BINDIR"]
    config_vars["srcdir"] = config_vars["LIBPL"]
    config_vars.pop("userbase", None)

    output = output_dir / _get_json_data_name()
    with output.open("w", encoding="utf-8") as file:
        json.dump(config_vars, file, indent=2, sort_keys=True)
        file.write("\n")


if __name__ == "__main__":
    main()
