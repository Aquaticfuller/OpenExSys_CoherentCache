#!/bin/env tclsh

source [file join [file dirname [file normalize [info script]]] "parse_arg.tcl"]
source [file join [file dirname [file normalize [info script]]] "assert.tcl"]

proc resolve_env path {
    regsub -all {\$\{?([^\s\/\{\}]+)\}?} $path {$::env(\1)} path
    eval "set resolved $path"
    return $resolved
}

proc file_to_list args {
    parse_arg "-fpath(path)() -col(int)(1) -prefix(string)(.) -suffix(string)(.)" $args
    if {![file isfile $fpath]} {
        error "Error: file ($fpath) is missing"
    }
    set ls [list]
    set f [open $fpath "r"]
    while {[gets $f line] >= 0} {
        set line [string trim $line]
        if {[string length $line] == 0 || [string index $line 0] == "#" || [string range $line 0 1] == "//"} {
            continue
        }
        regsub -all {\s+} $line " " line
        set ls_line [split $line " "]
        set item [lindex $ls_line [expr $col-1]]

        lappend ls $item
    }
    close $f

    if {$prefix != "."} {
        set ls_new [list]
        foreach item $ls {
            lappend ls_new "${prefix}${item}"
        }
        set ls $ls_new
    }

    if {$suffix != "."} {
        set ls_new [list]
        foreach item $ls {
            lappend ls_new "${item}${suffix}"
        }
        set ls $ls_new
    }

    return $ls
}

proc file_list_remove_duplicate {ls_fpath} {
    set ls_new [list]
    foreach fpath $ls_fpath {
        set fpath_norm [file normalize $fpath]
        if {[lsearch -exact $ls_new $fpath_norm] == -1} {
            lappend ls_new $fpath_norm
        }
    }

    return $ls_new
}

proc expand_file_list {file_list_fpath} {
    if {![file isfile $file_list_fpath]} {
        error "Error: file ($file_list_fpath) is missing"
    }

    set file_list_dpath [file dirname $file_list_fpath]

    set ls_file [list]

    set f [open $file_list_fpath "r"]
    while {[gets $f line] >= 0} {
        set line [string trim $line]
        if {[string length $line] == 0 || [string index $line 0] == "#" || [string range $line 0 1] == "//"} {
            continue
        }
        if {[string match +* $line]} {
            continue
        }
        regsub -all {\s+} $line " " line
        set ls_item [split $line " "]

        if {[llength $ls_item] == 1} {
            # single item
            set fpath [lindex $ls_item 0]
            set fpath [resolve_env $fpath]

            if {[string index $fpath 0] == "/"} {
                # absolute path
            } else {
                # relative path
                set fpath [file join $file_list_dpath $fpath]
            }
            assert_exist $fpath
            lappend ls_file $fpath

        } elseif {[llength $ls_item] == 2} {
            if {[lindex $ls_item 0] == "-f"} {
                set fpath [resolve_env [lindex $ls_item 1]]
                set nested_file_list_fpath [file join $file_list_dpath $fpath]
                set ls_file [concat $ls_file [expand_file_list $nested_file_list_fpath]]
            } elseif {[lindex $ls_item 0] == "-v"} {
                set fpath [lindex $ls_item 1]
                set fpath [resolve_env $fpath]

                if {[string index $fpath 0] == "/"} {
                    # absolute path
                } else {
                    # relative path
                    set fpath [file join $file_list_dpath $fpath]
                }

                assert_exist $fpath
                lappend ls_file $fpath
            } elseif {[lindex $ls_item 0] == "-y"} {
                set path [resolve_env [lindex $ls_item 1]]
                set ls_file [concat $ls_file [glob -nocomplain -directory $path *.sv]]
                set ls_file [concat $ls_file [glob -nocomplain -directory $path *.v]]
            } else {
                error "Error: line ($line) is not recognized"
            }
        } else {
            error "Error: line ($line) is not recognized"
        }
    }
    close $f

    return [file_list_remove_duplicate $ls_file]
}

if {[info exists argv0]} {
    if {[file tail $argv0] == [file tail [info script]]} {
        foreach fpath [expand_file_list [lindex $argv 0]] {
            puts $fpath
        }
    }
}

