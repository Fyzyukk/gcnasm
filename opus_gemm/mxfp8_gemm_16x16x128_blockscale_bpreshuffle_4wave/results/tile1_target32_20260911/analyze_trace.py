#!/usr/bin/env python3
"""Summarize actual instruction gaps; ATT durations are diagnostic only."""
from pathlib import Path
import json
import statistics
import sys

here = Path(__file__).resolve().parent
for name in sys.argv[1:]:
    dest = here / "profiles_gpu2" / name
    command = json.loads((dest / "command.json").read_text())
    raw = Path(command["raw_profile"])
    ui = next(raw.glob("ui_output*"))
    code = json.loads((ui / "code.json").read_text())["code"]
    summary = []
    for file in sorted(ui.glob("se*_wv*.json")):
        data = json.loads(file.read_text())
        inst = data["wave"]["instructions"]
        mfmas = [x for x in inst if code[x[4]][0].startswith("v_mfma")]
        assert len(mfmas) == 4096, (file, len(mfmas))
        # Exclude initial tiles and the final direct-store epilogue.
        gaps = {j + 1: statistics.mean(mfmas[t * 64 + j + 1][0] - mfmas[t * 64 + j][0]
                                      for t in range(2, 61)) for j in range(64)}
        cycles = statistics.mean(mfmas[(t + 1) * 64][0] - mfmas[t * 64][0] for t in range(2, 61))
        summary.append(dict(wave=file.name, duration=data["duration"], steady_tile_cycles=cycles,
                            gap_after_mfma=gaps, prologue_cycles=mfmas[0][0] - data["wave"]["begin"],
                            epilogue_cycles=data["wave"]["end"] - mfmas[-64][0]))
    assert len(summary) == 16
    (dest / "trace_summary.json").write_text(json.dumps(summary, indent=2) + "\n")
    totals = dict(median_steady_tile_cycles=statistics.median(x["steady_tile_cycles"] for x in summary),
                  median_prologue_cycles=statistics.median(x["prologue_cycles"] for x in summary),
                  median_epilogue_cycles=statistics.median(x["epilogue_cycles"] for x in summary),
                  mean_gap_after_mfma={j: statistics.mean(x["gap_after_mfma"][j] for x in summary)
                                       for j in range(1, 65)})
    (dest / "aggregate.json").write_text(json.dumps(totals, indent=2) + "\n")
    (dest / "status.json").write_text(json.dumps(dict(returncode=0, decoded_isa_rows=len(code),
                                                     usable_instruction_trace=True, wave_count=len(summary)), indent=2) + "\n")
    print(name, "tile cycles", round(totals["median_steady_tile_cycles"], 1),
          "prologue", totals["median_prologue_cycles"], "epilogue", totals["median_epilogue_cycles"],
          "largest mean gaps", [(j, round(v, 1)) for j, v in sorted(totals["mean_gap_after_mfma"].items(),
                                                                 key=lambda item: item[1], reverse=True)[:8]])
