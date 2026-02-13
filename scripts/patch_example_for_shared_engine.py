#!/usr/bin/env python3
"""
Patch an HTML5 example for shared engine: inject engine_id into index.html
and make dmloader.js resolve wasm/_wasm.js via Module["locateFile"].
Usage: patch_example_for_shared_engine.py <example_dir> <engine_id>
"""
import sys
import os


SCRIPT_DIR_IIFE = """(function(){var s=document.currentScript;if(s&&s.src)window.__DM_SCRIPT_DIR__=s.src.replace(/[^/]*$/,"");})();
"""

RESOLVE_LINE = ' var _sd=window.__DM_SCRIPT_DIR__||""; if(typeof Module!=="undefined"&&Module["locateFile"]&&(src.endsWith("_wasm.js")||src.endsWith(".wasm")))src=Module["locateFile"](src,_sd);'


def patch_index_html(path: str, engine_id: str) -> None:
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    marker = 'EngineLoader.load("canvas", "AssetStore");'
    patch_js = 'var _eid="{}";if(typeof Module!=="undefined"){{Module["locateFile"]=function(p,sd){{if(p&&(p.endsWith(".wasm")||p.endsWith("_wasm.js")))return "../../../engine/"+_eid+"/"+p;return (sd||"")+p;}};}};'.format(
        engine_id
    )
    for i, line in enumerate(lines):
        if marker in line:
            indent = line[: len(line) - len(line.lstrip())]
            lines.insert(i, indent + patch_js + "\n")
            break
    else:
        return
    with open(path, "w", encoding="utf-8") as f:
        f.writelines(lines)


def patch_dmloader(path: str) -> None:
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    if "__DM_SCRIPT_DIR__" in content:
        return

    content = content.replace(
        "*/\nvar CUSTOM_PARAMETERS = {",
        "*/\n" + SCRIPT_DIR_IIFE + "var CUSTOM_PARAMETERS = {",
    )

    content = content.replace(
        "loadAndInstantiateWasmAsync: function(src, imports, successCallback) {\n        FileLoader.load(src,",
        "loadAndInstantiateWasmAsync: function(src, imports, successCallback) {" + RESOLVE_LINE + "\n        FileLoader.load(src,",
    )

    content = content.replace(
        "streamAndInstantiateWasmAsync: async function(src, imports, successCallback) {\n        // https://stackoverflow.com/a/69179454",
        "streamAndInstantiateWasmAsync: async function(src, imports, successCallback) {" + RESOLVE_LINE + "\n        // https://stackoverflow.com/a/69179454",
    )

    content = content.replace(
        "loadAndRunScriptAsync: function(src, expectedLength, expectedSHA1) {\n        FileLoader.load(src,",
        "loadAndRunScriptAsync: function(src, expectedLength, expectedSHA1) {" + RESOLVE_LINE + "\n        FileLoader.load(src,",
    )

    with open(path, "w", encoding="utf-8") as f:
        f.write(content)


def main() -> None:
    if len(sys.argv) != 3:
        print("Usage: patch_example_for_shared_engine.py <example_dir> <engine_id>", file=sys.stderr)
        sys.exit(1)
    example_dir = os.path.abspath(sys.argv[1])
    engine_id = sys.argv[2]

    index_path = os.path.join(example_dir, "index.html")
    dmloader_path = os.path.join(example_dir, "dmloader.js")

    if not os.path.isfile(index_path):
        print("Missing index.html in {}".format(example_dir), file=sys.stderr)
        sys.exit(1)
    if not os.path.isfile(dmloader_path):
        print("Missing dmloader.js in {}".format(example_dir), file=sys.stderr)
        sys.exit(1)

    patch_index_html(index_path, engine_id)
    patch_dmloader(dmloader_path)


if __name__ == "__main__":
    main()
