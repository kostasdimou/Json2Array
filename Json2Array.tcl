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
  variable space 20
  variable tab 9
  variable newLine 10
  variable carriageReturn 13
  variable dot 14

  proc blanks {state} {
    puts "proc blanks {state = $state}"
    variable space
    variable tab
    variable newLine
    variable carriageReturn
    set nextState {}
    foreach blank [list $space $tab $newLine $carriageReturn] {
      lappend nextState [list $blank $nextState]
    }
    return $nextState
  }
    
  # STATE(previousState) {ascii1 nextState1 ascii2 nextState2}
  array set STATE [list\
    idle [list\
      [list $openBrace open]\
      [blanks idle]\
    ]\
    open [list\
      [list $quotes nameRead]\
      [blanks open]\
    ]\
    nameRead [list\
      [list $quotes nameDone]\
    ]\
    nameDone [list\
      [list $colon pair]\
      [blanks nameDone]\
    ]\
    pair [list\
      [list $quotes valueRead]\
      [blanks pair]\
    ]\
    valueRead [list\
      [list $quotes valueDone]\
    ]\
    valueDone [list\
      [list $closeBrace idle]\
      [blanks valueDone]\
    ]\
  ]
  
  proc parse {json jsonArrayName {start 0} {path {}}} {
    puts "proc parse {json = $json, jsonArrayName = $jsonArrayName, start = $start, path = $path}"
    variable STATE
    variable dot
      upvar $jsonArrayName JSON
      set state idle
      set name {}
      set value {}
      set max [string length $json]
      for {set i $start} {$i < $max} {incr i} {
          set char [string index $json $i]
          set ascii [scan char %c]
          puts "1 char = char - ascii = $ascii - path = path - state = $state"
          array unset ASCII
          array set ASCII $STATE($state)
          set previousState $state
          foreach ascii [array names ASCII]
            if {$char == ascii {
              set state $ASCII($ascii)
              break
            }
          }
          if {$state != $previousState} {
            if {$state == nameRead} {
              append name $char
            }
            if {$state == valueRead} {
              append value $char
            }
          } else {
            if {$state == valueDone} {
              set JSON([join [list $path $name] $dot])
            }
          }
          puts "2 path = path - state = $state"
      }
  } ;# proc json_parse {}
}

foreach filename $argv {
    # set in [open $filename r]
    # set size [file size $filename]
    # set json [read $in $size]
    array unset JSON
    array set JSON {}
    json::parse "{ "name": "John Doe" }" JSON
    parray JSON
}
