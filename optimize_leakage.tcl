# Procedure to actually swap the VT of a cell
proc swap_vt {cell vt} {

    # vt can be L, S or H

    set library_name "CORE65LP${vt}VT"
    set ref_name [get_attribute $cell ref_name]
    set ref_name_split [split $ref_name "_"]
    set current_vt [lindex $ref_name_split 1]
    set updated_vt [string replace $current_vt 1 1 $vt]
    if {$current_vt == $updated_vt} {
        return 1
    }
    lset ref_name_split 1 $updated_vt
    set new_ref_name [join $ref_name_split "_"]
    size_cell $cell "${library_name}/${new_ref_name}"

    return
}

# Try to swap a cell by changing its VT and checking the timing constraints are respected
proc try_swap_vt {cell target_vt original_vt slackThreshold maxPaths} {

    # Swap the cell
    swap_vt $cell $target_vt
    update_timing

    # Check new slack
    set slack_ok [expr {[get_attribute [get_timing_paths -nworst 1] slack] > 0.0}]
    set violating 0

    # Check the new number of violating paths
    set endpoints [add_to_collection [all_outputs] [all_registers -data_pins]]
    foreach_in_collection ep $endpoints {
        set paths [get_timing_paths -to $ep -nworst 10000 -slack_lesser_than $slackThreshold]
        if {[sizeof_collection $paths] >= $maxPaths} {
            set violating 1
            break
        }
    }

    # If the timing constraints are not met, revert back the cell
    if {!$slack_ok || $violating} {
        swap_vt $cell $original_vt
        update_timing
        return 0
    }
    return 1
}

# Check timing correctness
proc is_timing_correct {slackThreshold maxPaths} {
    update_timing -full

    # Check correctness of slack
    set slack_ok [expr {[get_attribute [get_timing_paths -nworst 1] slack] > 0.0}]
    set violating 0

    # Check whether the violating paths are less than the maximum allowed or not
    set endpoints [add_to_collection [all_outputs] [all_registers -data_pins]]
    foreach_in_collection ep $endpoints {
        set paths [get_timing_paths -to $ep -nworst 10000 -slack_lesser_than $slackThreshold]
        if {[sizeof_collection $paths] >= $maxPaths} {
            set violating 1
            break
        }
    }

    # Return accordingly
    if {!$slack_ok || $violating} {
        return 0
    }
    return 1
}


# Assign a priority to cells depending on their slack
proc prioritize_cells_by_slack {vt_group} {
    set cells [get_cells -quiet -filter "lib_cell.threshold_voltage_group == $vt_group"]
    set scored_list {}

    # Take only cells with positive slack
    foreach_in_collection cell $cells {
        set paths [get_timing_paths -through $cell]
        if {[llength $paths] == 0} { continue }
        set slack [get_attribute $paths slack]
        if {$slack >= 0.0} {
            lappend scored_list [list $cell $slack]
        }
    }
    # Sort the list in descending order
    return [lsort -real -decreasing -index 1 $scored_list]
}

# Compute the average slack on a list of cells
proc compute_average_slack {cell_list} {
    set total_slack 0.0
    set count 0
    foreach entry $cell_list {
        set slack [lindex $entry 1]
        set total_slack [expr {$total_slack + $slack}]
        incr count
    }
    if {$count == 0} { return 0.0 }
    return [expr {$total_slack / $count}]
}

# Decide the percentage of cells to swap depending on average slack and threshold
proc decide_percentage {avg_slack slackThreshold} {

    if { [expr {$avg_slack - $slackThreshold}] >= 0.20} {
        return 0.9
    } elseif {$avg_slack >= 0.10} {
        return 0.55
    } else {
        return 0.35
    }
}

# swap procedure to change a percentage of cells into another VT type
proc swap {cell_list from_vt to_vt slackThreshold maxPaths percentage} {
    set count [expr {int($percentage * [llength $cell_list])}]
    set interval_size 15
    set curr_interval_cells {}

    # Loop on the desired amount of cells
    for {set i 0} {$i < $count} {incr i} {
        set cell [lindex [lindex $cell_list $i] 0]
        swap_vt $cell $to_vt
        lappend curr_interval_cells $cell

        # Check if the group violates the timings, if so check all the cells individually
        if {[llength $curr_interval_cells] == $interval_size} {
            if {![is_timing_correct $slackThreshold $maxPaths]} {
                # Revert the group
                foreach bad_cell $curr_interval_cells {
                    swap_vt $bad_cell $from_vt
                }

                # Try to change all the cells of the last group individually
                foreach bad_cell $curr_interval_cells {
                    try_swap_vt $bad_cell $to_vt $from_vt $slackThreshold $maxPaths
                }
            }
            set curr_interval_cells {}
        }
    }

    # Final leftover group
    if {[llength $curr_interval_cells] > 0} {
        if {![is_timing_correct $slackThreshold $maxPaths]} {
            # Revert the group
            foreach bad_cell $curr_interval_cells {
                swap_vt $bad_cell $from_vt
            }

            # Try to change all the cells of the last group individually
            foreach bad_cell $curr_interval_cells {
                try_swap_vt $bad_cell $to_vt $from_vt $slackThreshold $maxPaths
            }
        }
    }
}

# MULTIVTH TCL COMMAND
proc multiVth {slackThreshold maxPaths} {
   


    # Start by changing some LVT to SVT



    # Sort LVT cells by slack
    set lvt_cells [prioritize_cells_by_slack "LVT"]

    # Calculate average slack of LVT cells
    set lvt_avg_slack [compute_average_slack $lvt_cells]

    # Calculate the percentage of cells to try to change from LVT to SVT depending on average slack and slack treshold
    set lvt_percentage [decide_percentage $lvt_avg_slack $slackThreshold]

    # Print info
    puts "LVT -> SVT optimization with percentage: $lvt_percentage"
    
    # Perform the swap of the desired percentage of cells (if this does not violate timing constraints)
    swap $lvt_cells "L" "S" $slackThreshold $maxPaths $lvt_percentage
    update_timing -full



    # Go on by changing some SVT to HVT



    # Sort SVT cells by slack
    set svt_cells [prioritize_cells_by_slack "SVT"]

    # Calculate average slack of SVT cells
    set svt_avg_slack [compute_average_slack $svt_cells]

    # Calculate the percentage of cells to try to change from SVT to HVT depending on average slack and slack treshold
    set svt_percentage [decide_percentage $svt_avg_slack $slackThreshold]

    # Print info
    puts "SVT -> HVT optimization with percentage: $svt_percentage"
    
    # Perform the swap of the desired percentage of cells (if this does not violate timing constraints)
    swap $svt_cells "S" "H" $slackThreshold $maxPaths $svt_percentage
    
    update_timing -full
    return 1
}
