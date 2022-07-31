package provide NmdLog 1.0

package require sqlite3
package require Tk
package require Tktable

proc getStr {id} {
	global lang tr
	if {[info exists tr($lang,$id)]} {
		return $tr($lang,$id)
	}
	return $id
}

proc getNMDDate {} {
	
	set year [clock format [clock seconds] -format %Y]
		
	set start [clock scan ${year}-07-01]
	
	while {[clock format $start -format %w]} {
		incr start 86400
	}
	incr start 1209600
	
	return [clock format $start -format %Y%m%d]
}

proc newDatabase {} {
	global db dbdir logTable
	
	set dbfile [tk_getSaveFile -defaultextension .nmd -filetypes [list [list [getStr dbname] .nmd]]]
	if {![string length $dbfile]} { return }
	if {[file exists $dbfile]} {
		file delete $dbfile
	}
	set dbdir [file dirname $dbfile]
	sqlite3 db $dbfile
	createSchema
	array unset logTable
	array set logTable {}
	enableLog
	updateLogTable
	.nmdlog.qtcs configure -takefocus 0 -fg black
}

proc openDatabase {} {
	global db dbdir showWork qthx qthy logTable
	
	set dbfile [tk_getOpenFile -defaultextension .nmd -filetypes [list [list [getStr dbname] .nmd]]]
	if {![string length $dbfile]} { return }
	unset logTable
	set dbdir [file dirname $dbfile]
	sqlite db $dbfile
	enableLog
	updateLogTable
	updateScore
	db eval {select * from qth} {
		set qthx $x
		set qthy $y
	}
	if {$showWork == "on"} {
		updateWorked
	}
}

proc createSchema {} {
	global db qthx qthy
	db eval {create table if not exists stn \
		(call text, first text, x integer, y integer, qtc1 text, qtc2 text)}
	db eval {create table if not exists nmdlog \
		(call text, utc integer, half integer, rstr text, rsts text, \
		 qtcr text, qtcs text)}
	db eval {create table if not exists qtc \
		 (status integer, qtc text)}
	db eval {create table if not exists qth (x integer, y integer)}
	db eval {insert into qth values (0,0)}
	set qthx 0
	set qthy 0
}

proc importTxt {} {
	global db dbdir

	set txtFile [tk_getOpenFile -defaultextension .txt -filetypes [list [list [getStr txtfile] .txt]] -initialdir $dbdir]
	if {![string length $txtFile]} {return}

	if {[checkTxtFile $txtFile]} {
		set fh [open $txtFile r]
		while {![eof $fh]} {
			gets $fh line
			if {[string length $line]} {
				db eval {insert into qtc values (0,$line)}
			}
		}
		close $fh
		.mbar.log entryconfigure 0 -state disabled
	}
}

proc importStn {} {
	global db dbdir
	
	set stnFile [tk_getOpenFile -defaultextension .txt -filetypes [list [list [getStr txtfile] .txt]] -initialdir $dbdir]
	if {![string length $stnFile]} {return}

	if {[checkStnFile $stnFile]} {
		set fh [open $stnFile r]
		while {![eof $fh]} {
			gets $fh line
			if {[string length $line]} {
				set line [split $line ,]
				set call [string toupper [lindex $line 0]]
				set first [lindex $line 1]
				set x [lindex $line 2]
				set y [lindex $line 3]
				set qtc1 [lindex $line 4]
				set qtc2 [lindex $line 5]
				db eval {insert into stn values ($call,$first,$x,$y,$qtc1,$qtc2)}
			}
		}
		close $fh
		.mbar.log entryconfigure 1 -state disabled
	}	
}

proc getHalf {} {
	global half

	switch $half "first" {
		return 0
	} "second" {
		return 1
	} "auto" {
		set h [clock format [clock seconds] -gmt true -format %H]
		set h [string trimleft $h 0]
	
		if {$h >= 8 && $h <= 19} {
			return 1
		} else {
			return 0
		}
	}
}

proc checkTxtFile {txtFile} {
	set fh [open $txtFile r]
	while {![eof $fh]} {
		gets $fh line
		set otxt $line
		regsub -all " " $line "" line
		if {[string length $line] < 15 && [string length $line]>0} {
			tk_messageBox -icon error -title "[getStr error]" -message "[getStr txtTooShort]: $otxt"  -type ok
			return 0
		}
	}
	close $fh
	return 1
}

proc checkStnFile {stnFile} {
	set fh [open $stnFile r]
	set l 0
	while {![eof $fh]} {
		gets $fh line
		if {[string length $line]} {
			incr l
			set s [split $line ,]
			
			if {[llength $s] !=6} {
				tk_messageBox -icon error -title "[getStr error]" -message "[getStr wrongNumEle] ([getStr line]$l)"
				return 0
			}
			
			set yc [lindex $s 2]
			set xc [lindex $s 3]
			set qtc1 [lindex $s 4]
			set qtc2 [lindex $s 5]
			
			# if at least one coord is set -> check both
			if {[string length $xc] || [string length $yc]} {
				if {![regexp ^\[0-3\]\[0-9\]{5}\$ $xc]} {
					tk_messageBox -icon error -title "[getStr error]" -message "[getStr invalidX] $l ($xc)"
					return 0
				}
				if {![regexp ^\[4-8\]\[0-9\]{5}\$ $yc]} {
					tk_messageBox -icon error -title "[getStr error]" -message "[getStr invalidY] $l ($yc)"
					return 0
				}
			}
			# if qtc length > 0, check also if >= 15
			# puts "->[string length $qtc1]"
			if {[string length $qtc1]} {
				if {[check15 $qtc1] == 0} {
					tk_messageBox -icon error -title "[getStr error]" -message "[getStr txtShort] $l ($qtc1)"
					return 0
				}	
			}
			if {[string length $qtc2]} {
				if {[check15 $qtc2] == 0} {
					tk_messageBox -icon error -title "[getStr error]" -message "[getStr txt2Short] $l ($qtc2)"
					return 0
				}
			}
		}
	}
	close $fh
	return 1
}

proc check15 {txt} {
	regsub -all " " $txt "" txt
	regsub -all "\t" $txt "" txt
	if {[string length $txt] <15} {
		return 0
	} else {
		return 1
	}
}

proc checkTime {txt} {
	
	if {[string length $txt] ==4} {
		set h [string trimleft [string range $txt 0 1] 0]
		set m [string trimleft [string range $txt 2 3] 0]
		if {$h > 24 || $m > 59} {
			return 0
		} else {
			return 1
		}
	}
	return 0
}

proc checkTxtLen {txt field} {

	if {![check15 $txt]} {
		.nmdlog.$field configure -fg red
	} else {
		.nmdlog.$field configure -fg black
	}
	return 1
}

proc checkRST {txt action insert type} {

	if {$action == 1 && ![regexp ^\[1-9\]\$ $insert]} {
		return 0
	}
	if {[string length $txt] > 3} {
		return 0
	}
	if {![regexp ^\[1-9\]\{3\}\$ $txt]} {
		.nmdlog.$type configure -fg red
	} else {
		.nmdlog.$type configure -fg black
	}
	return 1
}

proc checkUTC {txt action insert} {

	if {$action == 1 && ![regexp ^\[0-9\]\$ $insert]} {
		return 0
	}
	if {[string length $txt] > 4} {
		return 0
	}
	if {[checkTime $txt]} {
		.nmdlog.utc configure -fg black
	} else {
		.nmdlog.utc configure -fg red
	}
	return 1
}

proc checkDupe {call} {
	global db
	
	set half [getHalf]
	set nmdstn [db eval {select count(*) from stn where call=$call}]
	if {$nmdstn} {
		set dupe [db eval \
	 	{select count(*) from nmdlog where call=$call and half=$half}]
	} else {
		set dupe [db eval \
		 {select count(*) from nmdlog where call=$call}]
	}
	return $dupe
}

proc getWorkable {} {
	global db
	set half [getHalf]
	set workable [db eval {select call from stn except select call from \
		nmdlog where half=$half}]
	return $workable
	
}

proc getWorkable.old {} {
	
	set half [getHalf]
	set worked [db eval {select stn.call from stn,nmdlog where stn.call=nmdlog.call and nmdlog.half=$half}]
	set all [db eval {select call from stn}]
	foreach w $worked {
		set pos [lsearch -exact $all $w]
		set all [lreplace $all $pos $pos]
	}
	#set unworked [db eval {select call from stn where call not in $worked}]
#	puts "Worked: $worked"
	#puts "Unwrkd: $unworked"
	return $all
}

proc getFirst {call} {
	global db
	
	set first ""
	db eval {select first from stn where call=$call} {
		if {[string length $first]} {
			.nmdlog.first configure -text $first
		}
	}
}

proc getDistance {call} {
	global db qthx qthy

	set ret "[getStr dist]: -"
	if {$qthx == 0} {
		return $ret
	}
	puts "select x,y from stn where call=$call"
	db eval {select x,y from stn where call=$call} {
		if {$x == 0 || $y ==0 || ![string length $x] || ![string length $y]} {
			puts "x=0 -> returning"
			return $ret
		}
		puts "x=$x y=$y"
		set distance [expr sqrt(pow($qthx - $x,2) + pow($qthy -$y,2))]
		set distance "[expr int($distance / 1000)] km"
		return "[getStr dist]: $distance"
	}
	return $ret
}

proc getScore {} {
	global db
	set nmd [db eval {select count(*) from nmdlog,stn where nmdlog.call=stn.call}]
	set dx [db eval {select count(*) from nmdlog where call not like 'hb9%' and call not like 'hb3%' and call not like 'he%'}]
	set tot [db eval {select count(*) from nmdlog}]
	set hb [expr $tot - $dx - $nmd]
	return "$nmd nmd / $hb hb / $dx dx"
}

proc isNMDStn {call} {
	
	if {[regexp -nocase ^hb\[93\].+/p\$ $call] || [regexp -nocase ^he.+/p\$ $call]} {
		return 1
	}
	return 0
}

proc getQtc {call} {
	global db
	
	set half [getHalf]
	#set qtc "[getStr noNMD]"
	set qtc ""
	
	if {![isNMDStn $call]} { return $qtc }
	
	if {$half} {
		set qtc [db onecolumn {select qtc2 from stn where call=$call}]
	} else {
		set qtc [db onecolumn {select qtc1 from stn where call=$call}]
	}
	if {![string length $qtc]} {
		set qtc [db onecolumn {select qtc from qtc where status=0}]
	}
	if {![string length $qtc]} {
		# no more txt available -> include qtcs in tabstops
		.nmdlog.qtcs configure -takefocus 1
		set qtc "[getStr outOfTxt]"
	}
	return $qtc
}

proc updateLogTable {} {
	global logTable
	
	set col 0

	foreach head [list [getStr UTC] [getStr call] [getStr rsts] [getStr txts] [getStr rstr] [getStr txtr]] {
		set logTable(0,$col) $head
		incr col
	}
	
	set row 1
	db eval {select utc,call,rsts,qtcs,rstr,qtcr from nmdlog order by utc desc} {
		set col 0
		foreach var [list utc call rsts qtcs rstr qtcr] {
			if {$var == "utc"} {
				set logTable($row,$col) [clock format $utc -gmt true -format %H:%M]
			} else {
				set logTable($row,$col) [set $var]
			}
			incr col
		}
		incr row
	}
	updateScore
}

proc toggleWorklist {} {
	global showWork
	
	if {$showWork == "on"} {
		workwindow
		updateWorked
	} else {
		destroy .towork 
	}
}

proc updateWorked {} {
	global showWork

	if {$showWork != "on"} { return }

	# tk_messageBox -message "updateWorked called" -type ok
	
	.towork.work configure -state normal
	.towork.work delete 1.0 end
	.towork.work insert 1.0 [join [getWorkable] \n]
	.towork.work configure -state disabled
}

proc updateScore {} {
	.nmdlog.score configure -text [getScore]
}

proc processCall {validation action new vaction} {
	global startTime

	if {$vaction == "key" && $action == 1} {
		if {[string length [.nmdlog.call get]] == 0} {
			set startTime [clock seconds]
		}
		.nmdlog.call insert insert [string toupper $new]
		after idle [list .nmdlog.call configure -validate $validation]
		return 1
	}
	if {$vaction == "focusout"} {	
	
		set call [.nmdlog.call get]
		if {![string length $call]} {return true}
		if {[checkDupe $call]} {
			.nmdlog.dup configure -text "[getStr dupe]" -fg red
		} else {
			.nmdlog.dup configure -text "[getStr newStn]" -fg blue
		}
		getFirst $call
		set qtc [getQtc $call]
		#.nmdlog.qtcs configure -state normal
		.nmdlog.qtcs delete 0 end
		.nmdlog.qtcs insert 0 [getQtc $call]
		#.nmdlog.qtcs configure -state readonly
		.nmdlog.distance configure -text [getDistance $call]
		return 1
	}
	return 1
}

proc clear {} {
	global timeEntry
	
	.nmdlog.dup configure -text ""
	.nmdlog.first configure -text ""
	.nmdlog.distance configure -text ""
	.nmdlog.utc delete 0 end
	.nmdlog.call delete 0 end
	.nmdlog.rsts delete 0 end
	.nmdlog.rstr delete 0 end
	.nmdlog.qtcr delete 0 end
	#.nmdlog.qtcs configure -state normal
	.nmdlog.qtcs delete 0 end
	#.nmdlog.qtcs configure -state readonly
	if {$timeEntry == "on"} {
		focus .nmdlog.utc
	} else {
		focus .nmdlog.call
	}
}

proc saveLog {} {
	global db showWork timeEntry startTime nmdDate
	
	# if call is empty -> don't save
	if {[string length [.nmdlog.call get]] == 0} {
		clear
		return
	}
	
	if {$timeEntry == "on"} {
		if {[checkTime [.nmdlog.utc get]]} {
			set time [clock scan "${nmdDate}T[.nmdlog.utc get]00" -gmt 1]
		} else {
			return
		}
	} else {
		set time $startTime
	}
	# normalize date to this year's NMD
	set hms [clock format $time -format %H%M%S -gmt 1]
	set time [clock scan "${nmdDate}T${hms}" -gmt 1]
	
	set call [.nmdlog.call get]
	set rsts [.nmdlog.rsts get]
	set rstr [.nmdlog.rstr get]
	set qtcs [.nmdlog.qtcs get]
	set qtcr [.nmdlog.qtcr get]
	set half [getHalf]
	
	# don't store the 'no nmd' message
	if {$qtcs == "[getStr noNMD]"} { set qtcs ""}
	
	db eval {insert into nmdlog values ($call,$time,$half,$rstr,$rsts,$qtcr,$qtcs)}
	# check if qtc has been used from generic table and mark as used if yes
	db eval {update qtc set status=1 where qtc=$qtcs}
    updateLogTable
	if {$showWork == "on"} {
		updateWorked
	}
	clear
}

proc exportCSV {} {
	global db dbdir
	
	set csvfile [tk_getSaveFile -defaultextension .csv -filetypes [list [list "[getStr cvsfile]" .csv]] -initialdir $dbdir]
	if {![string length $csvfile]} { return }
	
	set fh [open $csvfile w]
	db eval {select * from nmdlog order by call} {
	   puts $fh "=\"[clock format $utc -gmt true -format %H%M]\"\;$call\;$rsts\;$qtcs\;$rstr\;$qtcr"
	}
	close $fh
	tk_messageBox -icon info -title Success -message "[getStr csvok]"  -type ok
}

proc exportADIF {} {
	global db dbdir
	
	set adiffile [tk_getSaveFile -defaultextension .adf -filetypes [list [list [getStr adifFile] .adf]] -initialdir $dbdir]
	if {![string length $adiffile]} { return }
	
	set fh [open $adiffile w]
	puts $fh "this data was exported using TVKLog<eoh>"
	puts $fh "<adif_ver:1>2"
	
	db eval {select * from nmdlog order by utc} {
		puts -nonewline $fh "<call:[string length $call]>[string toupper $call]"
		puts -nonewline $fh "<QSO_date:8>[clock format $utc -gmt true -format %Y%m%d]"
		puts -nonewline $fh "<time_on:4>[clock format $utc -gmt true -format %H%M]"
		puts -nonewline $fh "<band:3>80m"
		puts -nonewline $fh "<mode:2>CW"
		puts -nonewline $fh "<rst_sent:[string length $rsts]>$rsts"
		puts -nonewline $fh "<rst_rcvd:[string length $rstr]>$rstr"
		puts -nonewline $fh "<stx_string:[string length $qtcs]>$qtcs"
		puts -nonewline $fh "<srx_string:[string length $qtcr]>$qtcr"
		puts $fh "<eor>"
	}
	close $fh
	tk_messageBox -icon info -title Success -message "[getStr adifOk]"  -type ok
}

proc saveCoords {} {
	global db qthx qthy
	
	grab release .coords
	
	set qthxtmp [.coords.x get]
	set qthytmp [.coords.y get]
	
	if {![regexp ^\[0-3\]\[0-9\]{5}\$ $qthytmp]} {
		tk_messageBox -icon error -title "[getStr error]" -message "[getStr invYRange]"
		destroy .coords
		return 0
	}
	if {![regexp ^\[4-8\]\[0-9\]{5}\$ $qthxtmp]} {
		tk_messageBox -icon error -title "[getStr error]" -message "[getStr invXRange]"
		destroy .coords
		return 0
	}
	set qthx [string trimleft $qthxtmp 0]
	set qthy [string trimleft $qthytmp 0]
	db eval {update qth set x=$qthx,y=$qthy}
	destroy .coords
}

proc createMenu {} {

	global half showWork
	menu .mbar

	#The Main Buttons
	.mbar add cascade -label "[getStr mFile]" -underline 0 \
		  -menu [menu .mbar.file -tearoff 0]
	.mbar add cascade -label "[getStr mLog]" \
		  -underline 0 -menu [menu .mbar.log -tearoff 0]
	.mbar add cascade -label "[getStr mExtra]" \
		  -underline 0 -menu [menu .mbar.extra -tearoff 0]
	.mbar add cascade -label "[getStr mAbout]" \
		  -underline 0 -menu [menu .mbar.about -tearoff 0]

	
	## File Menu ##
	set m .mbar.file
	$m add command -label "[getStr mNew]" -underline 0 \
		  -command { newDatabase }
	$m add command -label "[getStr mOpen]" -underline 0 \
		-command { openDatabase }
	$m add separator
	$m add command -label "[getStr mExit]" -underline 1 -command exit
	
	## Log Menu ##
	set l .mbar.log
	$l add command -label "[getStr mImportTxt]" -underline 7 \
		-command {importTxt}
	$l add command -label "[getStr mImportStn]" -underline 7 \
		-command {importStn}
	$l add separator
	$l add command -label "[getStr mExportCSV]" -underline 7 \
		-command {exportCSV}
	$l add command -label "[getStr mExportADIF]" -underline 7 \
		-command {exportADIF}
	
	## Extra Menu ##
	set half auto
	set e .mbar.extra
	$e add radiobutton -label "[getStr mAutoHalf]" -value auto -variable half -command updateWorked
	$e add radiobutton -label "[getStr mFirstHalf]" -value first -variable half -command updateWorked
	$e add radiobutton -label "[getStr mSecondHalf]" -value second -variable half -command updateWorked
	$e add separator
	$e add checkbutton -label "[getStr mShowWorklist]" -command toggleWorklist -offvalue off -onvalue on -variable showWork
	$e add separator
	$e add command -label "[getStr mSetQTH]" -command coordEntry
	$e add separator
	$e add checkbutton -label "[getStr mTimeEntry]" -command timeEntry -offvalue off -onvalue on -variable timeEntry
	
	set a .mbar.about
	$a add command -label "[getStr mAboutSub]" -underline 1 -command {aboutBox}
	
}

proc disableLog {} {
	.nmdlog.utc configure -state readonly
	.nmdlog.call configure -state readonly
	.nmdlog.rsts configure -state readonly
	.nmdlog.rstr configure -state readonly
	.nmdlog.qtcr configure -state readonly
	.mbar.log entryconfigure 0 -state disabled
	.mbar.log entryconfigure 1 -state disabled
	.mbar.log entryconfigure 3 -state disabled
	.mbar.log entryconfigure 4 -state disabled
	.mbar.extra entryconfigure 4 -state disabled
	.mbar.extra entryconfigure 6 -state disabled
}

proc enableLog {} {
	.nmdlog.utc configure -state normal
	.nmdlog.call configure -state normal
	.nmdlog.rsts configure -state normal
	.nmdlog.rstr configure -state normal
	.nmdlog.qtcr configure -state normal
	set numTxt [db eval {select count(*) from qtc}]
	if {$numTxt == 0} {
		.mbar.log entryconfigure 0 -state normal
	}
	set numStn [db eval {select count(*) from stn}]
	if {$numStn == 0} {
		.mbar.log entryconfigure 1 -state normal
	}
	.mbar.log entryconfigure 3 -state normal
	.mbar.log entryconfigure 4 -state normal
	.mbar.extra entryconfigure 4 -state normal
	.mbar.extra entryconfigure 6 -state normal
}

proc logwindow {} {
	
	global logTable

	createMenu
	
	frame .nmdlog
	wm title . "TVKLog"
	. config -menu .mbar
	
	bind . <Return> { saveLog }
	bind . <Escape> {clear}
	
	
	font create nmdbig
	#KT
	#font configure nmdbig -family Arial -size 22 -weight bold
	font configure nmdbig -family Arial -size 18 -weight bold
	font create nmdmed
	#KT
	#font configure nmdmed -family Arial -size 16 -weight bold
	font configure nmdmed -family Arial -size 14 -weight bold
	font create nmdsmall
	#KT
	#font configure nmdsmall -family Arial -size 12
	font configure nmdsmall -family Arial -size 10
	font create nmdmono 
	#KT
	#font configure nmdmono -family Courier -size 12
	font configure nmdmono -family Courier -size 10
	
	label .nmdlog.lutc -text [getStr UTC] 
	label .nmdlog.lcall -text [getStr call]
	label .nmdlog.lrsts -text [getStr rsts] -width 6
	label .nmdlog.lqtcs -text [getStr txts]
	label .nmdlog.lrstr -text [getStr rstr] -width 6
	label .nmdlog.lqtcr -text [getStr txtr]
	entry .nmdlog.utc -font nmdbig -width 4 -validatecommand {checkUTC %P %d %S} -validate key
	entry .nmdlog.call -validatecommand {processCall %v %d %S %V} -validate all -font nmdbig -width 10 -bd 1
	label .nmdlog.dup -font nmdmed
	label .nmdlog.first -font nmdmed
	label .nmdlog.distance -font nmdsmall
	#label .nmdlog.score -font nmdsmall -width 22 -anchor e -padx 0 -border 1
	label .nmdlog.score -font nmdsmall -anchor e -padx 0 -border 1
	entry .nmdlog.rsts -width 4 -font nmdbig -bd 1 -validatecommand {checkRST %P %d %S rsts} -validate key
	#entry .nmdlog.qtcs -font nmdbig -width 20 -state readonly -readonlybackground gray90 -takefocus 0 -bd 1
	entry .nmdlog.qtcs -font nmdbig -width 20 -takefocus 0 -bd 1 -validatecommand {checkTxtLen %P qtcs} -validate key
	entry .nmdlog.rstr -width 4 -font nmdbig -bd 1 -validatecommand {checkRST %P %d %S rstr} -validate key
	entry .nmdlog.qtcr -width 18 -font nmdbig -validatecommand {checkTxtLen %P qtcr} -validate key -bd 1
	

	grid .nmdlog.lcall -row 0 -column 1
	grid .nmdlog.lrsts -row 0 -column 2
	grid .nmdlog.lqtcs -row 0 -column 3
	grid .nmdlog.lrstr -row 0 -column 4
	grid .nmdlog.lqtcr -row 0 -column 5 -columnspan 2
	
	grid .nmdlog.call -row 1 -column 1
	grid .nmdlog.rsts -row 1 -column 2
	grid .nmdlog.qtcs -row 1 -column 3
	grid .nmdlog.rstr -row 1 -column 4
	grid .nmdlog.qtcr -row 1 -column 5 -columnspan 2
	
	grid .nmdlog.first -row 2 -column 1
	grid .nmdlog.dup -row 2 -column 3
	grid .nmdlog.distance -row 2 -column 5
	grid .nmdlog.score -row 2 -column 6 -sticky e
	
#	text .nmdlog.log -yscrollcommand {.nmdlog.s set} -takefocus 0
#	scrollbar .nmdlog.s -command {.nmdlog.log yview}
	array set logTable {}
	table .nmdlog.logtable -rows 200 -cols 6 -variable logTable	-titlerows 1 \
		-font nmdmono -yscrollcommand {.nmdlog.s set} -height 7 -state disabled \
		-resizeborders none -selecttype row -exportselection 0 -bd 1 -highlightthickness 0 \
		-anchor w -ipadx 5
	#KT
	#.nmdlog.logtable width 0 6 1 14 2 4 3 31 4 4 5 31
	.nmdlog.logtable width 0 6 1 14 2 4 3 32 4 4 5 32
	scrollbar .nmdlog.s -command {.nmdlog.logtable yview}
	
	bind .nmdlog.logtable <MouseWheel> {%W yview scroll [expr {-%D/120}] units}
		
	grid .nmdlog.logtable .nmdlog.s -sticky nsew -row 3 -columnspan 7
	#grid columnconfigure .nmdlog 0 -weight 1
	grid rowconfigure .nmdlog 3 -weight 1
	pack .nmdlog -fill y -expand 1 -anchor nw
	wm resizable . 0 1
	#KT
	#wm grid . 1 1 932 20
	wm title . "TVKLog"
	if {[info exists ::starkit::topdir]} {
		wm iconbitmap . -default [file join $::starkit::topdir  nmdlog.ico]
	} else {
		#wm iconbitmap . -default nmdlog.ico
	}
	focus .
}

proc closeAbout {} {
	destroy .about
}

proc aboutBox {} {
	
	toplevel .about -bg white
	wm title .about "[getStr mAbout]"
	bind .about <ButtonPress> closeAbout
	bind .about <Escape> closeAbout
	bind .about <FocusOut> closeAbout
	# get position of log window
	set geom [wm geometry .]
	regexp \\\+\(\[0-9\]+\)\\\+\(\[0-9\]+\)\$ $geom - xp yp
	incr xp 180
	incr yp 20

	wm geometry .about "+$xp+$yp"
	wm resizable .about 0 0
	
	label .about.txt1 -text "TVKLog v1.2.2" -font nmdbig -bg white
	label .about.txt2 -text "[getStr aboutDescr]" -font nmdmed -bg white
	label .about.txt3 -text "Freeware" -font nmdmed -bg white
	label .about.txt4 -text "Author: Peter Kohler / HB9TVK" -font nmdsmall -bg white
	label .about.txt5 -text "Testing and Support: Urs Hadorn / HB9ABO" -font nmdsmall -bg white

	if {[info exists ::starkit::topdir]} {
		set imgfile [file join $::starkit::topdir  tvk.pbm]
	} else {
		set imgfile tvk.pbm
	}
	
	set img [image create photo -file $imgfile]
	label .about.img -image $img
	
	grid .about.txt1 -row 0 -column 0
	grid .about.txt2 -row 1 -column 0
	grid .about.txt3 -row 2 -column 0
	grid .about.txt4 -row 3 -column 0
	grid .about.txt5 -row 4 -column 0
	grid .about.img -row 5 -column 0
	
	focus .about
	
}

proc coordEntry {} {
	
	global db qthx qthy
			
	toplevel .coords
	wm title .coords "[getStr enterQTH]"
	
	# get position of log window
	set geom [wm geometry .]
	regexp \\\+\(\[0-9\]+\)\\\+\(\[0-9\]+\)\$ $geom - xp yp
	incr xp 340
	incr yp 120
	
	wm geometry .coords "+$xp+$yp"
	
	label .coords.label -text "[getStr setQTH]" -font nmdsmall
	entry .coords.x -width 6 -font nmdsmall -bd 1
	label .coords.sep -text "/"
	entry .coords.y -width 6 -font nmdsmall -bd 1
	
	button .coords.ok -text "[getStr ok]" -command saveCoords
	button .coords.cancel -text "[getStr cancel]" -command { destroy .coords }
	
	grid .coords.label -row 0 -column 0 -columnspan 3
	grid  .coords.x -row 1 -column 0
	grid .coords.sep -row 1 -column 1
	grid .coords.y -row 1 -column 2
	grid .coords.cancel -row 2 -column 0
	grid .coords.ok -row 2 -column 2
	
	.coords.x delete 0 end
	.coords.x insert 0 [format %06d $qthx]
	.coords.y delete 0 end
	.coords.y insert 0 [format %06d $qthy]
	
	focus .coords
	grab .coords
	
}

proc timeEntry {} {
	
	global timeEntry
	
	if {$timeEntry == "on"} {
		grid .nmdlog.lutc -row 0 -column 0
		grid .nmdlog.utc -row 1 -column 0
		focus .nmdlog.utc
	} else {
		focus .nmdlog.call
		grid remove .nmdlog.lutc
		grid remove .nmdlog.utc
	}
}

proc workwindow {} {
	global showWork

	toplevel .towork
	wm title .towork "Worklist"
	bind .towork <Destroy> {set showWork "off"}
	text .towork.work -width 14 -height 30 -state disabled -font nmdsmall
	pack .towork.work
	
	set geom [wm geometry .]
	regexp \\\+\(\[0-9\]+\)\\\+\(\[0-9\]+\)\$ $geom -  xp yp
	#KT
	#incr xp 940
	wm geometry .towork "+$xp+$yp"
}


array set logTable {}

# prepare trigger for second half
set timeswitch [clock scan 1000]
if {[clock seconds] > $timeswitch} {
	set timeswitch [expr $timeswitch + 43200]
}
set timeswitch [expr ($timeswitch - [clock seconds]) * 1000]
after $timeswitch updateWorked
# tk_messageBox -message "update in $timeswitch ms" -type ok

# load language
set lang de
if {[regexp -- \-en\.exe $argv0]} {
	set lang en
}
if {[regexp -- \-fr\.exe $argv0]} {
	set lang fr
}

if {[info exists ::starkit::topdir]} {
	source [file join $::starkit::topdir text-${lang}.conf]
} else {
	source text-${lang}.conf
}

set nmdDate [getNMDDate]

logwindow
disableLog


# Todo maybe later:
# - check for dup txt in stn/qtc
# - integrated editor for stn and txt
# - drag-drop open with *.nmd file? 





