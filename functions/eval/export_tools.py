#!/usr/bin/env python3
"""Regenerates eval/coach_tools.json from the Dart kCoachAgentTools literal
so the bake-off runner uses exactly the tool definitions the app sends.
Run from functions/: python3 eval/export_tools.py"""
import pathlib, re, json
src = pathlib.Path(__file__).resolve().parents[2] / 'lib/features/ai_assistant/application/ai_operating_layer_client.dart'
text = src.read_text()
m = re.search(r"^const List<Map<String, dynamic>> kCoachAgentTools = (\[.*?^\]);", text, re.S | re.M)
block = re.sub(r"^\s*//.*$", "", m.group(1), flags=re.M)
block = re.sub(r"'\s*\n\s*'", "", block)
block = re.sub(r"'((?:[^'\\]|\\.)*)'", lambda mm: json.dumps(mm.group(1).replace('\\"', '"').replace("\\'", "'")), block)
block = re.sub(r",(\s*[\]\}])", r"\1", block)
tools = json.loads(block)
out = pathlib.Path(__file__).resolve().parent / 'coach_tools.json'
out.write_text(json.dumps(tools, indent=2) + "\n")
print(f'wrote {out} ({[t["function"]["name"] for t in tools]})')
