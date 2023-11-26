proc assert {cond {msg ""}} {
    if {![uplevel 1 expr $cond]} {
        return -code error "$msg\n  assertion failed: $cond"
    }
}

proc assert_is_file { fpath } {
    global ours
    if {![file isfile $fpath]} {
        error "Error: file ($fpath) not found"
#         if {$ours(tcl_check_only) == "false"} {
#             uplevel suspend
#         } else {
#             error ""
#         }
    }
}

proc assert_is_dir { dpath } {
    global ours
    if {![file isdirectory $dpath]} {
        error "Error: dir ($dpath) not found"
#         if {$ours(tcl_check_only) == "false"} {
#             uplevel suspend
#         } else {
#             error ""
#         }
    }
}

proc assert_exist { dpath } {
    global ours
    if {![file exists $dpath]} {
        error "Error: dir ($dpath) not found"
#         if {$ours(tcl_check_only) == "false"} {
#             uplevel suspend
#         } else {
#             error ""
#         }
    }
}

proc assert_is_file_list { ls_fpath } {
    foreach fpath $ls_fpath {
        assert_is_file $fpath
    }
}

proc assert_is_dir_list { ls_dpath } {
    foreach dpath $ls_dpath {
        assert_is_dir $dpath
    }
}
