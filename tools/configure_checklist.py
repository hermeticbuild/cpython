#!/usr/bin/env python3
"""Generate a CPython configure-to-rules_cc_autoconf audit checklist.

This program reads checked-out CPython sources. It does not execute configure.
"""

from __future__ import annotations

import argparse
import ast
import collections
import dataclasses
import json
import pathlib
import re
import sys
from collections.abc import Iterable, Sequence


_SYMBOL_PATTERN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")
_TEMPLATE_UNDEF_PATTERN = re.compile(
    r"^\s*#\s*undef\s+([A-Za-z_][A-Za-z0-9_]*)\b",
    re.MULTILINE,
)
_EXPLICIT_DEFINE_PATTERN = re.compile(
    r"(?:\bdefine\s*=|\bAC_(?:DEFINE|FAIL)\s*\()\s*[\"']"
    r"([A-Za-z_][A-Za-z0-9_]*)[\"']",
)
_QUOTED_STRING_PATTERN = re.compile(r"[\"']([^\"']+)[\"']")


@dataclasses.dataclass(frozen=True)
class SourceVersion:
    version: str
    release: str
    root: pathlib.Path
    configure_words: dict[str, tuple[int, ...]]
    template_symbols: frozenset[str]


@dataclasses.dataclass(frozen=True)
class GeneratedConfig:
    version: str
    platform: str
    header: pathlib.Path
    manifest: pathlib.Path
    values: dict[str, str | None]
    producers: frozenset[str]


@dataclasses.dataclass(frozen=True)
class Disposition:
    classification: str
    justification: str


@dataclasses.dataclass(frozen=True)
class ConfigureDecision:
    name: str
    classification: str
    implementation: str
    justification: str


def _line_number(text: str, offset: int) -> int:
    return text.count("\n", 0, offset) + 1


def _parse_string_list(text: str, variable: str) -> list[tuple[str, int]]:
    match = re.search(
        rf"(?m)^{re.escape(variable)}\s*=\s*\[(.*?)^\]",
        text,
        re.DOTALL,
    )
    if match is None:
        raise ValueError(f"{variable} list not found in pyconfig.bzl")

    result = []
    for string_match in _QUOTED_STRING_PATTERN.finditer(match.group(1)):
        value = string_match.group(1)
        if "\\" in value:
            value = ast.literal_eval(repr(value))
        result.append(
            (
                value,
                _line_number(text, match.start(1) + string_match.start()),
            )
        )
    return result


def _parse_prefixed_string_lists(
    text: str,
    prefix: str,
) -> list[tuple[str, int]]:
    variables = re.findall(
        rf"(?m)^({re.escape(prefix)}(?:_[A-Za-z0-9_]+)?)\s*=\s*\[",
        text,
    )
    if not variables:
        raise ValueError(f"no {prefix} lists found in pyconfig.bzl")
    return [item for variable in variables for item in _parse_string_list(text, variable)]


def _configure_symbol_token(symbol: str) -> str | None:
    for prefix in ("HAVE_DECL_", "HAVE_", "SIZEOF_", "ALIGNOF_"):
        if symbol.startswith(prefix):
            token = symbol[len(prefix) :].lower()
            if token:
                return token
    return None


def _word_line_index(text: str) -> dict[str, tuple[int, ...]]:
    result: dict[str, list[int]] = {}
    for line_number, line in enumerate(text.splitlines(), start=1):
        for word in re.findall(r"\b[A-Za-z_][A-Za-z0-9_]*\b", line):
            lines = result.setdefault(word, [])
            if not lines or lines[-1] != line_number:
                lines.append(line_number)
    return {word: tuple(lines) for word, lines in result.items()}


def _configure_evidence(
    symbol: str,
    configure_words: dict[str, tuple[int, ...]],
) -> str:
    exact = configure_words.get(symbol, ())
    if exact:
        locations = ", ".join(f"L{line}" for line in exact[:4])
        if len(exact) > 4:
            locations += f", +{len(exact) - 4}"
        return locations

    token = _configure_symbol_token(symbol)
    if token is None:
        return "—"
    token_matches = configure_words.get(token, ())
    if not token_matches:
        return "—"
    locations = ", ".join(f"L{line}" for line in token_matches[:4])
    if len(token_matches) > 4:
        locations += f", +{len(token_matches) - 4}"
    return f"`{token}`: {locations}"


def _autoconf_name(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9]", "_", value).upper()


def _record(
    evidence: dict[str, set[str]],
    symbol: str,
    description: str,
) -> None:
    if not _SYMBOL_PATTERN.fullmatch(symbol):
        raise ValueError(f"invalid pyconfig symbol {symbol!r}")
    evidence.setdefault(symbol, set()).add(description)


def _pyconfig_evidence(path: pathlib.Path) -> dict[str, set[str]]:
    text = path.read_text(encoding="utf-8")
    evidence: dict[str, set[str]] = {}

    for match in _EXPLICIT_DEFINE_PATTERN.finditer(text):
        symbol = match.group(1)
        line = _line_number(text, match.start(1))
        _record(evidence, symbol, f"L{line} explicit")

    for header, line in _parse_prefixed_string_lists(text, "_HEADERS"):
        _record(
            evidence,
            f"HAVE_{_autoconf_name(header)}",
            f"L{line} `_HEADERS`: `{header}`",
        )

    for function, line in _parse_prefixed_string_lists(text, "_FUNCTIONS"):
        _record(
            evidence,
            f"HAVE_{_autoconf_name(function)}",
            f"L{line} `_FUNCTIONS`: `{function}`",
        )

    for call in re.finditer(
        r"macros\.AC_CHECK_DECLS\s*\(\s*\[(.*?)\]",
        text,
        re.DOTALL,
    ):
        for declaration in _QUOTED_STRING_PATTERN.finditer(call.group(1)):
            value = declaration.group(1)
            line = _line_number(text, call.start(1) + declaration.start())
            _record(
                evidence,
                f"HAVE_DECL_{_autoconf_name(value)}",
                f"L{line} `AC_CHECK_DECLS`: `{value}`",
            )

    return evidence


def _load_source_version(specification: str) -> SourceVersion:
    try:
        version, root_text = specification.split("=", 1)
    except ValueError as error:
        raise ValueError(
            f"invalid --source {specification!r}; expected VERSION=PATH"
        ) from error

    root = pathlib.Path(root_text).resolve()
    configure_path = root / "configure.ac"
    template_path = root / "pyconfig.h.in"
    patchlevel_path = root / "Include" / "patchlevel.h"
    if not configure_path.is_file():
        raise ValueError(f"CPython {version} configure.ac not found: {configure_path}")
    if not template_path.is_file():
        raise ValueError(f"CPython {version} pyconfig.h.in not found: {template_path}")
    if not patchlevel_path.is_file():
        raise ValueError(f"CPython {version} patchlevel.h not found: {patchlevel_path}")

    configure_text = configure_path.read_text(encoding="utf-8")
    template_text = template_path.read_text(encoding="utf-8")
    patchlevel_text = patchlevel_path.read_text(encoding="utf-8")
    release_match = re.search(
        r'^#define\s+PY_VERSION\s+"([^"]+)"',
        patchlevel_text,
        re.MULTILINE,
    )
    if release_match is None:
        raise ValueError(f"CPython {version} patchlevel.h has no PY_VERSION")
    release = release_match.group(1)
    if not release.startswith(f"{version}."):
        raise ValueError(
            f"--source version {version!r} does not match PY_VERSION {release!r}"
        )
    template_symbols = frozenset(_TEMPLATE_UNDEF_PATTERN.findall(template_text))
    if not template_symbols:
        raise ValueError(f"CPython {version} pyconfig.h.in contains no #undef symbols")

    return SourceVersion(
        version=version,
        release=release,
        root=root,
        configure_words=_word_line_index(configure_text),
        template_symbols=template_symbols,
    )


def _load_generated_config(specification: str) -> GeneratedConfig:
    try:
        name, header_text, manifest_text = specification.split("=", 2)
        version, platform = name.split(":", 1)
    except ValueError as error:
        raise ValueError(
            f"invalid --generated {specification!r}; expected "
            "VERSION:PLATFORM=HEADER=MANIFEST"
        ) from error

    header = pathlib.Path(header_text).resolve()
    manifest = pathlib.Path(manifest_text).resolve()
    header_content = header.read_text(encoding="utf-8")
    manifest_data = json.loads(manifest.read_text(encoding="utf-8"))
    if not isinstance(manifest_data, dict) or not isinstance(
        manifest_data.get("defines"), dict
    ):
        raise ValueError(f"invalid rules_cc_autoconf manifest: {manifest}")

    values: dict[str, str | None] = {}
    for line in header_content.splitlines():
        define_match = re.match(
            r"^\s*#\s*define\s+([A-Za-z_][A-Za-z0-9_]*)(?:\s+(.*?))?\s*$",
            line,
        )
        undef_match = re.match(
            r"^\s*/\*\s*#\s*undef\s+([A-Za-z_][A-Za-z0-9_]*)\s*\*/\s*$",
            line,
        )
        if define_match:
            symbol = define_match.group(1)
            value = define_match.group(2) or "defined"
        elif undef_match:
            symbol = undef_match.group(1)
            value = None
        else:
            continue
        # The last occurrence is the rendered pyconfig.h.in placeholder. Earlier
        # occurrences can be conditional compatibility definitions in the template.
        values[symbol] = value

    return GeneratedConfig(
        version=version,
        platform=platform,
        header=header,
        manifest=manifest,
        values=values,
        producers=frozenset(manifest_data["defines"]),
    )


def _load_dispositions(
    path: pathlib.Path | None,
) -> tuple[
    dict[str, Disposition],
    dict[str, Disposition],
    tuple[ConfigureDecision, ...],
]:
    if path is None:
        return {}, {}, ()
    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("schema_version") != 1:
        raise ValueError(f"unsupported disposition schema in {path}")

    overrides = {}
    for symbol, item in data.get("overrides", {}).items():
        if not _SYMBOL_PATTERN.fullmatch(symbol):
            raise ValueError(f"invalid disposition symbol {symbol!r}")
        overrides[symbol] = Disposition(
            classification=item["classification"],
            justification=item["justification"],
        )
    reviewed_undefined = {}
    justifications = {
        "EXPECTED_FALSE": "The configure result is false on Linux arm64 and Darwin arm64.",
        "HEADER_DERIVED": (
            "CPython headers derive this value; pyconfig.h intentionally leaves it "
            "undefined."
        ),
        "UNSUPPORTED_BUILD_MODE": (
            "The symbol belongs to a build mode not offered by this Bazel module."
        ),
        "UNSUPPORTED_DEPENDENCY": (
            "The symbol belongs to an optional dependency not declared by this Bazel "
            "module."
        ),
        "UNSUPPORTED_PLATFORM": (
            "The symbol belongs to a platform outside Linux arm64 and Darwin arm64."
        ),
    }
    for classification, symbols in data.get("reviewed_undefined", {}).items():
        if classification not in justifications:
            raise ValueError(
                f"unknown reviewed undefined classification {classification!r}"
            )
        for symbol in symbols:
            if symbol in reviewed_undefined:
                raise ValueError(f"duplicate reviewed undefined symbol {symbol}")
            reviewed_undefined[symbol] = Disposition(
                classification=classification,
                justification=justifications[classification],
            )
    invalid = sorted(
        symbol for symbol in reviewed_undefined if not _SYMBOL_PATTERN.fullmatch(symbol)
    )
    if invalid:
        raise ValueError(f"invalid reviewed undefined symbols: {', '.join(invalid)}")
    decisions = tuple(
        ConfigureDecision(
            name=item["name"],
            classification=item["classification"],
            implementation=item["implementation"],
            justification=item["justification"],
        )
        for item in data.get("configure_decisions", [])
    )
    if len({item.name for item in decisions}) != len(decisions):
        raise ValueError("duplicate configure decision name")
    return overrides, reviewed_undefined, decisions


def _markdown_cell(value: str) -> str:
    return value.replace("|", "\\|").replace("\n", " ")


def _format_evidence(items: Iterable[str]) -> str:
    values = sorted(items)
    return "<br>".join(values) if values else "—"


def _render_checklist(
    sources: Sequence[SourceVersion],
    pyconfig_display: str,
    implementation: dict[str, set[str]],
    generated: Sequence[GeneratedConfig],
    overrides: dict[str, Disposition],
    reviewed_undefined: dict[str, Disposition],
    decisions: Sequence[ConfigureDecision],
) -> str:
    symbols = sorted(set().union(*(source.template_symbols for source in sources)))
    manifest_producers = (
        set().union(*(item.producers for item in generated)) if generated else set()
    )

    classifications: dict[str, Disposition] = {}
    for symbol in symbols:
        if symbol in overrides:
            classifications[symbol] = overrides[symbol]
        elif symbol in manifest_producers or (not generated and symbol in implementation):
            classifications[symbol] = Disposition(
                classification="PROBE",
                justification="Generated by a rules_cc_autoconf producer.",
            )
        elif symbol in reviewed_undefined:
            classifications[symbol] = reviewed_undefined[symbol]
        else:
            classifications[symbol] = Disposition(
                classification="UNCLASSIFIED",
                justification="No producer or reviewed undefined disposition.",
            )

    counts = collections.Counter(
        disposition.classification for disposition in classifications.values()
    )
    lines = [
        "<!-- Generated by tools/configure_checklist.py; do not edit. -->",
        "# CPython configure check audit",
        "",
        "This checklist compares each pinned CPython `pyconfig.h.in` symbol with "
        "`python/private/pyconfig.bzl` and generated `rules_cc_autoconf` manifests. "
        "The generator reads `configure.ac`; it does not execute `configure`.",
        "",
        "A checked row has a producer or an explicit reviewed disposition. An unchecked "
        "row is not audited and makes `--require-classified` fail.",
        "",
        "## Inputs",
        "",
    ]
    for source in sources:
        lines.append(
            f"- CPython {source.release}: `configure.ac` and `pyconfig.h.in` "
            f"({len(source.template_symbols)} symbols)"
        )
    lines.extend(
        [
            f"- rules_cc_autoconf implementation: `{pyconfig_display}`",
        ]
    )
    for item in generated:
        lines.append(
            f"- CPython {item.version} {item.platform}: generated header and manifest"
        )
    lines.extend(
        [
            "",
            "Run `tools/configure_checklist.py --help` for the regeneration command "
            "arguments. Use `--check --require-classified` in validation.",
            "",
            "## Summary",
            "",
            "| Classification | Symbols |",
            "|---|---:|",
        ]
    )
    for classification, count in sorted(counts.items()):
        lines.append(f"| `{classification}` | {count} |")

    lines.extend(
        [
            "",
            "`PROBE` is the default for a generated manifest producer. The disposition "
            "file overrides `PROBE` for fixed target facts, build policy, dependency "
            "contracts, and intentional undefined values.",
        ]
    )

    for source in sources:
        unclassified = sum(
            classifications[symbol].classification == "UNCLASSIFIED"
            for symbol in source.template_symbols
        )
        if unclassified:
            lines.append(
                f"- CPython {source.version} has {unclassified} unclassified symbols."
            )

    header = ["Status", "Symbol", "Classification"]
    header.extend(f"CPython {source.version} `configure.ac`" for source in sources)
    header.extend(
        f"{item.version} {item.platform} generated" for item in generated
    )
    header.extend(["`python/private/pyconfig.bzl`", "Justification"])
    lines.extend(
        [
            "",
            "## Symbol checklist",
            "",
            "| " + " | ".join(header) + " |",
            "|" + "|".join("---" for _ in header) + "|",
        ]
    )

    for symbol in symbols:
        disposition = classifications[symbol]
        row = [
            "[ ]" if disposition.classification == "UNCLASSIFIED" else "[x]",
            f"`{symbol}`",
            f"`{disposition.classification}`",
        ]
        for source in sources:
            if symbol not in source.template_symbols:
                row.append("—")
            else:
                row.append(_configure_evidence(symbol, source.configure_words))
        for item in generated:
            if symbol not in item.values:
                row.append("not in header")
            elif item.values[symbol] is None:
                producer = "producer" if symbol in item.producers else "no producer"
                row.append(f"undefined ({producer})")
            else:
                row.append(f"`{item.values[symbol]}`")
        evidence = set(implementation.get(symbol, ()))
        if symbol in manifest_producers:
            evidence.add("generated manifest producer")
        row.append(_format_evidence(evidence))
        row.append(disposition.justification)
        lines.append("| " + " | ".join(_markdown_cell(cell) for cell in row) + " |")

    lines.extend(
        [
            "",
            "## Configure decisions outside pyconfig.h.in",
            "",
            "| Decision | Classification | Implementation | Justification |",
            "|---|---|---|---|",
        ]
    )
    for item in decisions:
        row = [
            f"`{item.name}`",
            f"`{item.classification}`",
            item.implementation,
            item.justification,
        ]
        lines.append("| " + " | ".join(_markdown_cell(cell) for cell in row) + " |")

    lines.append("")
    return "\n".join(lines)


def _parse_arguments(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source",
        action="append",
        required=True,
        metavar="VERSION=PATH",
        help="CPython source root; repeat once per pinned version",
    )
    parser.add_argument(
        "--pyconfig",
        type=pathlib.Path,
        required=True,
        help="path to python/private/pyconfig.bzl",
    )
    parser.add_argument(
        "--generated",
        action="append",
        default=[],
        metavar="VERSION:PLATFORM=HEADER=MANIFEST",
        help="generated pyconfig.h and rules_cc_autoconf manifest",
    )
    parser.add_argument(
        "--dispositions",
        type=pathlib.Path,
        help="JSON file containing audited classification overrides",
    )
    parser.add_argument(
        "--output",
        type=pathlib.Path,
        help="write Markdown to this path instead of standard output",
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="fail if --output does not already contain the generated Markdown",
    )
    parser.add_argument(
        "--require-classified",
        action="store_true",
        help="fail if a template symbol has no producer or reviewed disposition",
    )
    return parser.parse_args(argv)


def main(argv: Sequence[str]) -> int:
    arguments = _parse_arguments(argv)
    if arguments.check and arguments.output is None:
        print("configure_checklist.py: --check requires --output", file=sys.stderr)
        return 1
    try:
        sources = sorted(
            (_load_source_version(value) for value in arguments.source),
            key=lambda source: source.version,
        )
        pyconfig_display = arguments.pyconfig.as_posix()
        pyconfig_path = arguments.pyconfig.resolve()
        implementation = _pyconfig_evidence(pyconfig_path)
        generated = sorted(
            (_load_generated_config(value) for value in arguments.generated),
            key=lambda item: (item.version, item.platform),
        )
        overrides, reviewed_undefined, decisions = _load_dispositions(
            arguments.dispositions
        )
        symbols = set().union(*(source.template_symbols for source in sources))
        unknown_dispositions = sorted(
            (set(overrides) | set(reviewed_undefined)) - symbols
        )
        if unknown_dispositions:
            raise ValueError(
                "dispositions name symbols absent from the pinned templates: "
                + ", ".join(unknown_dispositions)
            )
        source_by_version = {source.version: source for source in sources}
        generated_keys: set[tuple[str, str]] = set()
        for item in generated:
            key = (item.version, item.platform)
            if key in generated_keys:
                raise ValueError(f"duplicate generated configuration: {key}")
            generated_keys.add(key)
            if item.version not in source_by_version:
                raise ValueError(
                    f"generated configuration has unknown version {item.version}"
                )
            missing_values = sorted(
                source_by_version[item.version].template_symbols - item.values.keys()
            )
            if missing_values:
                raise ValueError(
                    f"generated {item.version} {item.platform} header omits "
                    f"{len(missing_values)} template symbols: "
                    + ", ".join(missing_values[:20])
                )
        markdown = _render_checklist(
            sources,
            pyconfig_display,
            implementation,
            generated,
            overrides,
            reviewed_undefined,
            decisions,
        )
        producers = set().union(*(item.producers for item in generated)) if generated else set()
        unclassified = sorted(
            symbol
            for symbol in symbols
            if symbol not in producers
            and (generated or symbol not in implementation)
            and symbol not in overrides
            and symbol not in reviewed_undefined
        )
        if arguments.require_classified and unclassified:
            raise ValueError(
                f"{len(unclassified)} symbols are unclassified: "
                + ", ".join(unclassified[:20])
            )
    except (json.JSONDecodeError, OSError, ValueError) as error:
        print(f"configure_checklist.py: {error}", file=sys.stderr)
        return 1

    if arguments.output is None:
        sys.stdout.write(markdown)
    elif arguments.check:
        try:
            current = arguments.output.read_text(encoding="utf-8")
        except OSError as error:
            print(f"configure_checklist.py: {error}", file=sys.stderr)
            return 1
        if current != markdown:
            print(
                f"configure_checklist.py: {arguments.output} is stale; regenerate it",
                file=sys.stderr,
            )
            return 1
    else:
        arguments.output.parent.mkdir(parents=True, exist_ok=True)
        arguments.output.write_text(markdown, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
