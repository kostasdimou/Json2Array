proc parse {json path index jsonArrayName} {
    upvar $jsonArrayName JSON
    set name {}
    set value {}
    while {$json != {}} {
        set next [string index $json 0]
        if {$next == "\{"} {
            incr index
            set json [string range $json [expr 1 + [parse [string range $json 1 end]]] end]
        } elseif {$next == "\""} {
            if {$name == {}} {
                set end [string first "\"" $json 1]
                if {$end == -1} {
                    return [string length $json]
                }
                set name [string range $json 1 [expr $end - 1]]
                set json [string range $json [expr $end + 1] end]
            } elseif {$value == {}} {
                set end [string first "\"" $json 1]
                if {$end == -1} {
                    return [string length $json]
                }
                set value [string range $json 1 [expr $end - 1]]
                JSON([join [list $path $name] "."]) $value
                set json [string range $json [expr $end + 1] end]
            }
        }
    }
}

array set JSON {}
set filename "sample.json"
set in [open $filename r]
set size [file size $filename]
set json [read $in $size]
parse $json {} -1 JSON
parray JSON
