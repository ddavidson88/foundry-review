# Parser checks (EMULATED)

Run from the review bundle root:

```sh
python -m pip install -r tests/requirements.txt
python tests/test_rxp_parser.py
```

The harness executes the original upstream `RegisterGuide`, `ParseGuide`,
`ParseLine`, group/class filtering, and the tag parsers used by the guide in
Lua 5.1 through Lupa. It also checks manual objective semantics and the
Era/Night Elf/Hardcore/season loader guards.

`upstream/parser-excerpts.lua` contains verbatim excerpts from the public
[RestedXP/RXPGuides source](https://github.com/RestedXP/RXPGuides/tree/9536b5a9ee7e55745618a57dad43df2c4312ea16),
pinned to commit `9536b5a9ee7e55745618a57dad43df2c4312ea16` (2026-10-22).
The source files were read from a clean checkout. See `PROVENANCE.json` for
source and excerpt hashes; its excerpt hash is checked before execution.
The upstream GPL-3.0 license is included. No commercial guide content is
included.

WoW APIs, map lookup, hashing, and the final guide storage operation are
small emulated adapters. Tag event handlers are present in the source
excerpts but are not exercised. These checks establish parser compatibility
with that commit; they do not establish native client behavior or verify
the owner's installed RXPGuides v4.11.27. In-game registration, arrows,
quest progress, manual checkboxes, and transitions still need a smoke test.
