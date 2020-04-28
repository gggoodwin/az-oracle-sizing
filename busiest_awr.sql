REM ================================================================================
REM Name:	busiest_awr.sql
REM Type:	Oracle SQL script
REM Date:	27-April 2020
REM From:	Americas Customer Engineering team (CET) - Microsoft
REM
REM Copyright and license:
REM
REM	Licensed under the Apache License, Version 2.0 (the "License"); you may
REM	not use this file except in compliance with the License.
REM
REM	You may obtain a copy of the License at
REM
REM		http://www.apache.org/licenses/LICENSE-2.0
REM
REM	Unless required by applicable law or agreed to in writing, software
REM	distributed under the License is distributed on an "AS IS" basis,
REM	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
REM
REM	See the License for the specific language governing permissions and
REM	limitations under the License.
REM
REM	Copyright (c) 2020 by Microsoft.  All rights reserved.
REM
REM Ownership and responsibility:
REM
REM	This script is offered without warranty by Microsoft Customer Engineering.
REM	Anyone using this script accepts full responsibility for use, effect,
REM	and maintenance.  Please do not contact Microsoft or Oracle support unless
REM	there is a problem with a supported SQL or SQL*Plus command.
REM
REM Description:
REM
REM	SQL*Plus script to find the top 5 busiest AWR snapshots within the horizon
REM	of all information stored within the Oracle AWR repository, based on the
REM	statistics "physical reads" (a.k.a. physical I/O or "PIO") and "CPU used
REM	by this session" (a.k.a. cumulative session-level CPU usage).
REM
REM Modifications:
REM	TGorman 27apr20 v0.1 written
REM ================================================================================
set pages 100 lines 80 verify off echo off feedback 6 timing off
define V_BUCKETS="10"
col snap_range format a20 heading 'From - To snapshots'
col pio heading 'Physical|Reads|(PIO)'
col cpu heading 'CPU used by|this session|(CPU)'
spool busiest_awr
select	snap_range, pio, cpu
from	(select snap_range, pio, cpu, row_number() over (order by sortby desc) rn
	 from	(select trim(to_char(snap_id-1))||' - '||trim(to_char(snap_id+1)) snap_range, sum(pio) pio, sum(cpu) cpu, sum(sortby) sortby
		 from	(select snap_id, pio, cpu, sortby
			 from	(select	snap_id, stat_name, value pio, 0 cpu, (value*10) sortby, ntile(&&V_BUCKETS) over (order by value) bucket
				 from	dba_hist_sysstat where stat_name = 'physical reads'
				 union all
				 select	snap_id, stat_name, 0 pio, value cpu, value sortby, ntile(&&V_BUCKETS) over (order by value) bucket
				 from	dba_hist_sysstat where stat_name = 'CPU used by this session')
			 where	bucket = &&V_BUCKETS)
		 group by snap_id))
where rn <= 5
order by rn;
spool off
