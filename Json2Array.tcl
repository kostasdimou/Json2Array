#!/usr/bin/tclsh
namespace eval json {
    variable carriageReturn 13
    variable closeBrace 125
    variable closeBracket 93
    variable closeParenthesis 41
    variable colon 58
    variable comma 44
    variable dotChar .
    variable escape 92
    variable newLine 10
    variable openBrace 123
    variable openBracket 91
    variable openParenthesis 40
    variable quotes 34
    variable space 32
    variable star *
    variable tab 9
    variable zero 48

    proc blanks {nextState} {
        puts "proc blanks {nextState = $nextState}"
        variable space
        variable tab
        variable newLine
        variable carriageReturn
        set pairs {}
        foreach blank [list $space $tab $newLine $carriageReturn] {
            lappend pairs $blank $nextState
        }
        return $pairs
    } ;# proc blanks {}

    proc digits {nextState} {
        puts "proc digits {nextState = $nextState}"
        variable zero
        set pairs {}
        for {set i 0} {$i < 10} {incr i} {
            set digit [expr $zero + $i]
            lappend pairs $digit $nextState
        }
        return $pairs
    } ;# proc digits {}

    # STATE(previousState) {ascii1 nextState1 ascii2 nextState2}
    array set STATE [list\
        idle        [concat $openBrace open [blanks idle]]\
        open        [concat $quotes nameOpen [blanks open]]\
        nameOpen    [concat $star nameRead]\
        nameRead    [concat $quotes nameDone]\
        nameDone    [concat $colon pair [blanks nameDone]]\
        pair        [concat $quotes valueOpen [digits valueOpen] [blanks pair]]\
        valueOpen   [concat $quotes star]\
        valueRead   [concat $comma open [digits valueNumber] $quotes valueDone]\
        valueDone   [concat $closeBrace idle $comma open [blanks valueDone]]\
    ]

    proc print {char} {
        # puts "proc print {char = $char}"
        set ascii [scan $char %c]
        if {[string is print $char]} {
            return $char
        }
        return {?}
    } ;# proc print ()

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
            array unset STATE_ASCII
            array set STATE_ASCII $STATE($state)
            set previousState $state
            set change 0
            if {$previousState == {nameOpen}} {
                set state {nameRead}
                set change 1
            } elseif {$previousState == {valueOpen}} {
                set state {valueRead}
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
            if {$state == {nameRead}} {
                append name $char
            }
            if {$state == {valueRead}} {
                append value $char
            }
if {[string length $name]} {puts "$name = $value"}
            if {$state == $previousState} {
                if {$state ni {idle open nameRead nameDone pair valueRead valueDone}} {
                    puts "ERROR: state = $state, char/ascii = [print $char]/$ascii: invalid ascii for the current state"
                    parray STATE $state
                }
            } else {
                puts "INFO: state = $previousState --> $state"
                parray STATE $state
                if {$state == {valueDone} || $previousState == {valueNumber}} {
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
