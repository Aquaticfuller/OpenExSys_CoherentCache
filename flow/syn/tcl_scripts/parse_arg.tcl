#!/bin/env tclsh
################################################################
# prase_arg
#   ls_arg_definition
#       one expected argument = "-${arg_name}(type)(default_value)"
#           arg_name will be defined in up-level proc.
#               To match defined arguments, we support shortcuts like Synopsys DC/PT/ICC
#           type = <int|float|string|path|bool>
#           default is the default value if it's not given in ls_arg.
#               if default is empty, then this is a must-have argument.
#   ls_arg can be $args for a proc or $argv for command line script
################################################################

proc parse_arg { ls_arg_definition ls_arg } {
    # parse ls_arg_definition
    set arg(name) {}
    set usage "usage:\n"
    foreach arg_def $ls_arg_definition {
        if {[regexp {^-([_0-9a-zA-Z]+)\(([a-z]+)\)\((.*)\)$} $arg_def match arg_name arg_type default_value]} {
            if {$default_value == ""} {
                set default_value "NULL"
                set optional "Must-have"
            } else {
                set optional "Optional"
            }
            set arg(name) [lappend arg(name) $arg_name]
            set arg($arg_name,arg_type) $arg_type
            set arg($arg_name,value) $default_value
            uplevel set $arg_name $arg($arg_name,value)
            # usage
            set usage "$usage  -$arg_name ($optional) TYPE=$arg_type; DEFAULT=$default_value\n"
        } else {
            error "Error: arg_definition ($arg_def) is not recognized"
        }
    }

    # parse ls_arg
    if {$ls_arg == "-help"} {
        puts $usage
        uplevel exit
    }
    if {$ls_arg == ""} {
        set expect_arg_name -1
    } else {
        set expect_arg_name 1
    }
    while {$expect_arg_name >= 0} {
        set input [lindex $ls_arg 0]
        set ls_arg [lrange $ls_arg 1 end]

        if {$expect_arg_name} {
            # parse arg name
            if {[regexp {^-([_0-9a-zA-Z]+)$} $input match input_arg_name]} {
                set num_match 0
                set match_arg_name ""
                foreach arg_name $arg(name) {
                    if {[string match "${input_arg_name}*" $arg_name]} {
                        incr num_match 1
                        set match_arg_name $arg_name
                    }
                }
                if {$num_match == 0} {
                    # no match found
                    error "Error: argument ($input_arg_name) is not defined in ($ls_arg_definition)."
                } elseif {$num_match > 1} {
                    # multi matches found
                    error "Error: argument ($input_arg_name) is too ambiguouse. $num_match matches are found."
                } else {
                    # 1 match found
                    if {$arg($match_arg_name,arg_type) == "bool"} {
                        set arg($match_arg_name,value) 1
                        set expect_arg_name 1
                    } else {
                        set arg($match_arg_name,value) "NULL"
                        set expect_arg_name 0
                    }
                }
            } else {
                error "Error: expecting argument name at ($input)"
            }
        } else {
            # parse arg value
            if {($arg($match_arg_name,arg_type) == "int" && ![regexp {^[0-9]+$} $input]) \
                || ($arg($match_arg_name,arg_type) == "float" && ![regexp {^[0-9]+\.[0-9]+} $input]) \
            } {
                error "Error: argument type is wrong. Expecting $arg($match_arg_name,arg_type) for $match_arg_name at ($input)"
        } elseif {$arg($match_arg_name,arg_type) == "string"} {
            regsub -all {\$} $input {\\$} input
            regsub -all "\n" $input "\\n" input
            regsub -all "\t" $input "\\t" input
            regsub -all "\"" $input "\\\"" input
            set arg($match_arg_name,value) "\"$input\""
        } else {
            set arg($match_arg_name,value) $input
        }
        set expect_arg_name 1
    }

    if {[llength $ls_arg] == 0} {
        break
    }
}

foreach arg_name $arg(name) {
    if {$arg($arg_name,value) == "NULL"} {
        error "Error: argument ($arg_name) has no value defined"
    }
    uplevel set $arg_name $arg($arg_name,value)
}
}

# test
if {[info exists argv0]} {
    if {[file tail $argv0] == [file tail [info script]]} {

        proc test_parse_arg args {
            parse_arg "-num(int)(100) -input_file(path)() -output_file(path)() -is_cool(bool)(0) -some_string(string)(.)" $args
            puts $num
            puts $input_file
            puts $output_file
            puts $is_cool
            puts "($some_string)"
        }

        test_parse_arg -num 123 -in ./input -out ../output -is_cool
        test_parse_arg -num 123 -in ./input -out ../output

    }
}

