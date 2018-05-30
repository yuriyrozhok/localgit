# ---------------------------------------------------------------------------------------
# Script name:		pctime.ps1
# Created:			2017-08-09
# Author:			YRO016
# Description:		Displays the time ranges of current system's up time. Output is 
#					formatted as "start time" and "end time" for each day. This data is 
#					extracted from Windows System log, which doesn't require admin 
#					permissions of the current user. 
# Parameters:		
#					period:
#						Desc: 		fixed period for the report
#						Values:		d/D, w/W, m/M
#						Default:	D
#						Format:		one character
#						Details:
#									d/D - day (default), report only for the last day, 
#										starting from the yesterday, till today
#									w/W	- week, report for the current week only, 
#										starting from the beginning of the current week, 
#										till today
#									m/M	- month, report for the current month only, 
#										starting from the beginning of the current month, 
#										till today
#					from:
#						Desc: 		lower boundary of the arbitrary period ("from date")
#						Values:		any valid date
#						Default:	yesterday
#						Format:		YYYY-MM-DD
#					to:
#						Desc: 		upper boundary of the arbitrary period ("from date")
#						Values:		any valid date
#						Default:	today
#						Format:		YYYY-MM-DD
# Notes:			use period or from/to parameters alternatively
#					arbitrary period (explicit from/to) works only for period = D, so
#					just omit "period" parameter in this case. By providing W or M for 
#					period, you overwrite the from parameter.
# Usage example:
#					report for the last day:
# 						.\pctime.ps1
#					report for the current week:
# 						.\timesheet\pctime.ps1 w
#					report for the current month:
# 						.\timesheet\pctime.ps1 m
#					report from particular date till today:
#						.\pctime.ps1 -from 2017-08-07
#					report for arbitrary period:
#						.\pctime.ps1 -from 2017-08-07 -to 2017-08-20
# ---------------------------------------------------------------------------------------
param([string]$period = 'D', [datetime]$from = (Get-Date).Date.AddDays(-1), [datetime]$to = (Get-Date))
switch($period) {
	'W' {$from = $to.Date.AddDays(-$to.DayOfWeek.Value__ + 1)}
	'M' {$from = $to.Date.AddDays(-$to.Day + 1)}
}
$to = $to.Date.AddDays(1).AddSeconds(-1)

Write-Host("`nPeriod: {0:ddd, yyyy.MM.dd} -> {1:ddd, yyyy.MM.dd}" -f $from, $to)

Get-EventLog -After $from -Before $to -LogName System -Source Microsoft-Windows-Kernel-Power,Microsoft-Windows-Kernel-Boot,Microsoft-Windows-Kernel-General |
	Group {$_.TimeGenerated.Date} | Foreach {$_.Group | Measure-Object -Property TimeGenerated -Minimum -Maximum} |
	Format-Table @{expression={'{0:ddd, yyyy.MM.dd}' -f $_.Minimum};label='Date'+' '*12},
		@{expression={'{0:HH:mm}' -f $_.Minimum};label='Start '},
		@{expression={'{0:HH:mm}' -f $_.Maximum};label='End  '},
		@{expression={'{0:N2}' -f ($_.Maximum - $_.Minimum).TotalHours};label='Hours  ';align='right'}