# Low-Power Optimization Contest (TCL)

This repository contains the algorithm and report for a for a **group project** submitted to a low-power design contest. The goal was to write a **TCL script** to minimize leakage power in post-synthesis netlists while strictly adhering to timing constraints.

## Project Goal

The script optimizes a design by intelligently swapping logic gates with different threshold voltages (LVT, SVT, HVT). The challenge is to maximize leakage savings without violating the circuit's timing (slack).

## Methodology

The TCL script implements a heuristic-based, iterative approach:

1.  **Prioritization:** Cells are sorted by their timing slack in descending order. Only cells with positive slack are considered for swapping.
2.  **Adaptive Swapping:** The algorithm calculates the average slack and dynamically decides what percentage of cells to swap (e.g., LVT -> SVT, SVT -> HVT).
3.  **Group & Verify:** To save runtime, cells are swapped in batches. The script then checks if timing constraints (`work slack >= 0` and `maxPaths`) are still met. If a batch fails, it reverts and attempts to swap cell-by-cell.
4.  **Iteration:** The process repeats, first swapping from LVT-to-SVT and then SVT-to-HVT, to progressively reduce leakage power.

## Key Result

The algorithm was highly successful, achieving a **91.45% leakage power reduction** on the 'c1908' benchmark, far exceeding the contest goal.

## Documentation

* [**View the Full Contest Report (Report.md)**](./Report.md)
* [**View the TCL Script (optimize_leakage.tcl)**](./optimize_leakage.tcl)
