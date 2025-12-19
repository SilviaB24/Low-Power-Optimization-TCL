# Slack-Aware Leakage Power Optimizer

This repository hosts a **TCL automation tool** designed to minimize leakage power in post-synthesis netlists using **Synopsys Design Compiler**.
The algorithm intelligently swaps logic gates with High-Vt (Low Leakage) variants while strictly maintaining timing constraints (Zero Slack Violation).

## 🚀 Key Results
Tested on ISCAS-85 benchmarks (`c1908`), the tool achieved:
* **Leakage Reduction:** **91.45%** (vs. baseline)
* **Timing Violations:** **0** (Clean timing closure)
* **Runtime:** Optimized via heuristic batch processing.

## ⚙️ Algorithm: Batch & Revert Heuristic
Unlike standard greedy algorithms that update timing after every single cell swap (computationally expensive), this engine implements a **Batch & Revert** strategy:

1.  **Slack Sorting:** Cells are prioritized based on positive timing slack (`prioritize_cells_by_slack`).
2.  **Adaptive Percentage:** The tool dynamically calculates how aggressive the optimization should be based on the average slack available (`decide_percentage`).
3.  **Batch Execution:** Cells are swapped in batches (default: 15 cells). Timing is updated only once per batch to minimize runtime overhead.
4.  **Smart Revert:** If a batch violates constraints, the engine automatically rolls back and switches to a fine-grained "cell-by-cell" mode for that specific cluster to maximize savings without breaking timing.

## 🛠️ Usage
This script is designed to be sourced within the **Synopsys Design Compiler (dc_shell)** environment.

```tcl
# Source the script in dc_shell
source optimize_leakage.tcl

# Run the optimization command
# Syntax: multiVth <slack_threshold> <max_violating_paths>
multiVth 0.1 100
```

## 📊 Detailed Performance

| Benchmark | Clock (ns) | Slack Threshold | Leakage Savings |
| --- | --- | --- | --- |
| **c1908** | 2.0 | 0.10 | **91.45%** |
| **c5315** | 2.0 | 0.10 | **90.22%** |
| **c1908** | 1.0 (High Perf) | 0.01 | 15.29% |

## 📂 File Structure

* `optimize_leakage.tcl`: The core TCL algorithm containing the `multiVth` procedure and `swap` logic.
* `Report.md`: Technical documentation detailing the heuristic approach and full benchmark tables.