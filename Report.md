# **Group 2 - Low-Power Contest 24/25 Report**

## **Overview**
In our implementation we tried to perform the cell threshold voltage (Vt) optimization, which allows to reduce the leakage power but respecting the timing constraints, with the following approach: the algorithm works in two equal processes, one having an LVT to SVT substitution as target, and the other an SVT to HVT goal.
Both processes are composed of the following steps:
1. Sort the cells by descending slack (priority) - `prioritize_cells_by_slack` procedure
2. Calculate average slack for the cells - `compute_average_slack` procedure
3. Calculate the percentage of cells to try to change from one type to the other, depending on the values of the average slack and of the slack threshold (gives an approximated measure of how far away we are from our goal) - `decide_percentage` procedure
4. Perform the swap of the desired percentage of cells (if this does not violate timing constraints) - `swap` procedure

### **Procedures overview:**
- `prioritize_cells_by_slack`: assigns a priority to cells depending on their slack, taking only cells with positive slack; then the list is sorted in descending order.
- `compute_average_slack`: performs a standard average, by summing all the slack values of all the cells in the list and then dividing the total by the number of cells; also the case in which the list is empty is handled.
- `decide_percentage`: gives 3 possible percentage values, depending on whether the difference between the average slack and the slack threshold is greater than or equal to 0.20, the average slack is greater than or equal to 0.10, or not.
- `swap`: tries to change the cells into another VT type; a loop is performed, where we handle an amount of cells depending on the percentage choosen in the `decide_percentage` procedure. We decided to start by swapping an amount of cells given by the `interval_size` variable (which we set equal to 15 after a few tries), without performing intermediate timing checks and eventual reverts for each cell to save run time; after the whole group is swapped, timing constraints are checked with the `is_timing_correct` procedure: if they are respected, we go on with the next group, otherwise we revert all the cells of the current group to their original VT and then we go one by one with the `try_swap_vt` procedure, checking if the swap of that cell will cause timing violations or not and swapping accordingly.

### **Auxiliary procedures:**

- `is_timing_correct`: check timing correctness, by first checking the correctness of the slack (which must be strictly positive) and then whether the number of violating paths through endpoints are less than the maximum allowed. 
- `try_swap_vt`:  swaps a cell, then checks the consequent timing correctness (both in terms of slack and amount of violating paths) and reverts the cells back to its original VT value when the timing constraints are not met.
- `swap_vt`: performs the actual swap of the cell, by constructing both the standard cell library name to use and updating the reference name of the cell to the desired one (replacing the old XVT value to the new one); the effective swap is then performed with the `size_cell` command.

## **Results**

### **Table I:**

| Benchmark | CLK (ns) | Slack Thresh | Max Paths | Leakage Savings | Achieved Savings |
| --------- | -------- | ------------ | --------- | --------------- | ---------------- |
| c1908     | 2.0      | 0.10         | 100       | > 50%           | 91.4573647282 %  |
| c5315     | 2.0      | 0.10         | 100       | > 50%           | 90.229903042 %   |

### **Table II:**

| Benchmark | CLK (ns) | Slack Thresh | Max Paths | Leakage Savings | Achieved Savings |
| --------- | -------- | ------------ | --------- | --------------- | ---------------- |
| c1908     | 2.0      | 0.10         | 100       | > 80%           | 91.4573647282 %  |
| c1908     | 2.0      | 0.25         | 200       | > 75%           | 84.5010737781 %  |
| c1908     | 1.5      | 0.05         | 1500      | > 55%           | 59.3830066902 %  |
| c1908     | 1.5      | 0.07         | 5000      | > 55%           | 57.6676299232 %  |
| c1908     | 1.0      | 0.01         | 1000      | > 15%           | 15.2938458123 %  |
| c1908     | 1.0      | 0.02         | 3500      | > 10%           | 14.7826254326 %  |
| c5315     | 2.0      | 0.10         | 100       | > 90%           | 90.229903042 %   |
| c5315     | 2.0      | 0.20         | 200       | > 80%           | 90.1822905599 %  |
| c5315     | 1.5      | 0.05         | 300       | > 75%           | 81.0314745592 %  |
| c5315     | 1.5      | 0.07         | 700       | > 75%           | 80.8800961116 %  |
| c5315     | 1.0      | 0.01         | 500       | > 25%           | 28.2905745667 %  |
| c5315     | 1.0      | 0.02         | 1500      | > 25%           | 27.3755948742 %  |

## **Conclusion:**
The solution we decided to adopt is successful, since it allows to achieve all the requested savings for all the entries in the table.
