#!/usr/bin/tclsh
namespace eval json {
    variable quotes 34
    variable colon 58
    variable openBrace 123
    variable openBracket 91
    variable closeBrace 125
    variable closeBracket 93
    variable openParenthesis 40
    variable closeParenthesis 41
    variable escape 92
    variable space 32
    variable tab 9
    variable newLine 10
    variable carriageReturn 13
    variable dotChar .
    variable comma 44
    variable zero 48
    variable star *

    proc addBlanks {nextState} {
        puts "proc addBlanks {nextState = $nextState}"
        variable space
        variable tab
        variable newLine
        variable carriageReturn
        set pairs {}
        foreach blank [list $space $tab $newLine $carriageReturn] {
            lappend pairs $blank $nextState
        }
        return $pairs
    } ;# proc addBlanks {}

    proc addDigits {nextState} {
        puts "proc addDigits {nextState = $nextState}"
        variable zero
        set pairs {}
        for {set i 0} {$i < 10} {incr i} {
            set digit [expr $zero + $i]
            lappend pairs $digit $nextState
        }
        return $pairs
    } ;# proc addDigits {}

    # STATE(previousState) {ascii1 nextState1 ascii2 nextState2}
    array set STATE [list\
        idle        [concat $openBrace open [addBlanks idle]]\
        open        [concat $quotes nameOpen [addBlanks open]]\
        nameOpen    [concat $star nameRead]\
        nameRead    [concat $quotes nameDone]\
        nameDone    [concat $colon pair [addBlanks nameDone]]\
        pair        [concat $quotes valueOpen [addDigits valueOpen] [addBlanks pair]]\
        valueOpen   [concat $quotes star]\
        valueRead   [concat $comma open [addDigits valueNumber]]\
        valueDone   [concat $closeBrace idle $comma open [addBlanks valueDone]]\
    ]

    proc printChar {char} {
        # puts "proc printChar {char = $char}"
        set ascii [scan $char %c]
        if {[string is print $char]} {
            return $char
        }
        return $ascii
    } ;# proc printChar ()

    proc parse {json jsonArrayName {start 0} {path {}}} {
        puts "proc parse {json = $json, jsonArrayName = $jsonArrayName, start = $start, path = $path}"
        variable STATE
        variable dotChar
        upvar $jsonArrayName JSON
        set state idle
        lassign {{} {}} name value
        set max [string length $json]
        for {set i $start} {$i < $max} {incr i} {
            set char [string index $json $i]
            set ascii [scan $char %c]
puts -nonewline "[printChar $char] "
            array unset STATE_ASCII
            array set STATE_ASCII $STATE($state)
            set previousState $state
            set change 0
            if {$previousState == "nameOpen"} {
                set state "nameRead"
                set change 1
            } elseif {$previousState == "valueOpen"} {
                set state "valueRead"
                set change 1
            } else {
                foreach stateAscii [array names STATE_ASCII] {
                    if {$stateAscii == $ascii} {
                        set state $STATE_ASCII($stateAscii)
                        set change 1
                        break
                    }
                }
            }
            if {$state == "valueRead"} {
                append value $char
puts "V = $value"
            }
            if {$state == $previousState} {
                if {$state == "nameRead"} {
                    append name $char
puts "N = $name"
                } elseif {!$change} {
                    puts "ERROR: state = $state, char/ascii = [printChar $char]: invalid ascii for the current state"
                    parray STATE $state
                }
            } else {
                puts "S = $previousState --> $state"
                if {$state == "valueDone" || $previousState == "valueNumber"} {
                    set nextPath $path
                    lappend nextPath $name
                    set JSON([join $nextPath $dotChar]) $value
                    lassign {{} {}} name value
                }
            }
        }
    } ;# proc parse {}
}

foreach filename $argv {
    set in [open $filename r]
    set size [file size $filename]
    set json [read $in $size]
    array unset JSON
    array set JSON {}
    json::parse $json JSON
    parray JSON
}
