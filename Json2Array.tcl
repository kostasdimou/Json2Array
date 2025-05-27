#!/usr/bin/tclsh
proc json_parse {json jsonArrayName {start 0} {path {}}} {
    array set ASCII {
        blanks {20 9 10 13}
        opening {123 91 40 34}
        closing {125 93 41 34}
        quotes 34
        colon 58
        openBrace 123
        openBracket 91
        closeBrace 125
        closeBracket 93
        openParenthesis 40
        closeParenthesis 41
    }
    array set STATE {
        previousState {
            foundAscii nextState
        }
        idle {
            openBrace opening
        }
        opening {
            quotes name
            comma opening
        }
        name {
            colon value
        }
        value {
            quotes opening
        }
    }
    set state idle
    upvar $jsonArrayName JSON
    set block {}
    set match {}
    set name {}
    set value {}
    set max [string length $json]
    for {set i $start} {$i < $max} {incr i} {
        set chr [string index $json $i]
        set ascii [scan $chr %c]
        if {$ascii in $ASCII(blanks) && $match != $ASCII(quotes)} continue
        if {$ascii == $match} {
            set block [lreplace $block end end]
            set match [lindex $ASCII(closing) [lsearch $ASCII(opening) [lindex $block end]]]
        } elseif {$ascii in $ASCII(opening)} {
            lappend block $ascii
            set match [lindex $ASCII(closing) [lsearch $ASCII(opening) $ascii]]
        } else {
            puts "$state"
        }
# puts "chr = $chr - ascii = $ascii - block = $block - match = $match"
    }
} ;# proc json_parse {}

foreach filename $argv {
    set in [open $filename r]
    set size [file size $filename]
    set json [read $in $size]
    array unset JSON
    array set JSON {}
    json_parse $json JSON
    parray JSON
}
