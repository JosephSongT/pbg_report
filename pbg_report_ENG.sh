#------------------------------------------------------------------------------------
#   Copyright [2018] [Parkbyunggyu as pbg]
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#------------------------------------------------------------------------------------

ERSE=`stty -a | grep erase | head -n 1 | awk -F 'erase = ' {'print $2'} | cut -c 2`
if [ "$ERSE" == "?" ]; then
	stty erase ^H
fi
TODAY=`date +%Y%m%d%H%M%S`

#------------------------------------------------------------------------------------

GBN(){
DAN=`echo $1|sed 's/^.*[0-9]//g'`
GAB=`echo $1|sed 's/'${DAN}'//g' 2>/dev/null` 
DAN=`echo $DAN | tr '[a-z]' '[A-Z]'`
if [ "$2" == "G" ]; then
	SCAL=1
elif [ "$2" == "M" ]; then
	SCAL=1024
elif [ "$2" == "B" ]; then
	SCAL=1073741824
fi
if [ "$DAN" == "" ] || [ "$DAN" == "B" ] 
then
	DAN=`echo "1073741824 $SCAL"|awk '{printf "%.11f", $1 / $2}'`
	GAB=$1
elif [ "$DAN" == "KB" ];then
	DAN=`echo "1048576 $SCAL"|awk '{printf "%.11f", $1 / $2}'`
elif [ "$DAN" == "MB" ];then
	DAN=`echo "1024 $SCAL"|awk '{printf "%.11f", $1 / $2}'`
elif [ "$DAN" == "GB" ];then
	DAN=`echo "1 $SCAL"|awk '{printf "%.11f", $1 / $2}'`
fi
a=`echo "$GAB $DAN"|awk '{printf "%.3f", $1 / $2}'`
echo $(printf %.3f $a)
}

#------------------------------------------------------------------------------------

GKN(){
DAN=`echo $1|sed 's/^.*[0-9]//g'`
GAB=`echo $1|sed 's/'${DAN}'//g' 2>/dev/null` 
DAN=`echo $DAN | tr '[a-z]' '[A-Z]'`
if [ "$DAN" == "" ] || [ "$DAN" == "KB" ] 
then
	DAN=1048576
	GAB=$1
elif [ "$DAN" == "MB" ];then
	DAN=1024
elif [ "$DAN" == "GB" ];then
	DAN=1
fi
a=`echo "$GAB $DAN"|awk '{printf "%.3f", $1 / $2}'`
echo $(printf %.0f $a)
}

#------------------------------------------------------------------------------------

bkf(){
temp_par=`cat $1/postgresql.auto.conf | grep -v "#" | grep -w $2 | tail -n 1`
if [ "$temp_par" == "" ]; then
	temp_par=`cat $1/postgresql.conf | grep -v "#" | grep -w $2 | tail -n 1`
fi
result_par=`echo ${temp_par#*=}|sed "s/'//g"`
echo "$result_par"
}

#------------------------------------------------------------------------------------

BIGYO(){
		if [ "$1" == "$2" ]; then
			echo "O K     "
		else
			echo "Need CHK"
		fi
}

#------------------------------------------------------------------------------------

YON(){
DEF=$2
echo -e "$1 \c"
read YN
echo ""
echo ""
if [ "$YN" == "q" ] || [ "$YN" == "Q" ] 
then
	exit 0
elif [ "$YN" == "" ]; then
	YN=$DEF
fi
while [ "$YN" != "Y" ] && [ "$YN" != "y" ] && [ "$YN" != "N" ] && [ "$YN" != "n" ]
do
		echo "You entered wrong. Please enter y or n."
		echo -e "$1 \c"
		read YN
		echo ""
		echo ""
		if [ "$YN" == "q" ] || [ "$YN" == "Q" ] 
		then
			exit 0
		elif [ "$YN" == "" ]; then
			YN=$DEF
		fi
done
echo $YN > ./pbg_YN.file
}

#------------------------------------------------------------------------------------

CHGI(){
NUM=1
RW=`$2 2>/dev/null| awk {'print $'${NUM}''} | head -n 1`
while [ "$RW" != "$1" ];
do
	NUM=`echo "$NUM 1"|awk '{printf "%.0f", $1 + $2 }'`
	RW=`$2 2>/dev/null| awk {'print $'${NUM}''} | head -n 1`
done
echo $NUM
}

#------------------------------------------------------------------------------------

BYHW() {
CHOI=`echo "$1 1048576"|awk '{printf "%.1f", $1 / $2}'`
if [ 1 -eq `echo "1 $CHOI"|awk '{ if($1>$2) print 1; else print 0; }'` ]; then
	CHOI=`echo "$1 1024"|awk '{printf "%.0f", $1 / $2}'`
	P1=1
	if [ 1 -eq `echo "1 $CHOI"|awk '{ if($1>$2) print 1; else print 0; }'` ]; then
		CHOI=`echo "$1"|awk '{printf "%.0f", $1 }'`
		P2=1
	fi
fi
if [ "$P1" == "" ] && [ "$P2" == "" ]
then
	CHOI=`echo $CHOI"GB"`
elif [ "$P1" == "1" ] && [ "$P2" == "" ]
then
	CHOI=`echo $CHOI"MB"`
elif [ "$P1" == "1" ] && [ "$P2" == "1" ]
then
	CHOI=`echo $CHOI"KB"`
fi
echo $CHOI
}

#------------------------------------------------------------------------------------





YON "Is This Server Database Server? [Y/n]  [q is quit]:" Y
NS=`cat pbg_YN.file`
if [ "$NS" == "Y" ] || [ "$NS" == "y" ]
then
	echo "" >> ./pbg_ser${TODAY}.log
	echo "---------------------------------------------------------------------------" >> ./pbg_ser${TODAY}.log
	echo "                                SERVER SPEC" >> ./pbg_ser${TODAY}.log
	echo "---------------------------------------------------------------------------" >> ./pbg_ser${TODAY}.log
	echo "SEVER ver    :" `cat /etc/redhat-release` >> ./pbg_ser${TODAY}.log
	NS=1
	echo -e "Please enter the FULL PATH to the DATA location of DATABASE [q is quit]: \c"
	read DATA_DIR
	echo ""
	echo ""
	if [ "$DATA_DIR" == "q" ] || [ "$DATA_DIR" == "Q" ] 
	then
		exit 0
	fi
	HY=`ps -ef | grep postgres | grep -v "color=auto" | grep "postgres: checkpointer process"`
	if [ "$HY" != "" ]; then
		HY=`ps -ef | grep postgres | grep -v "color=auto" | grep "postgres: writer process"`
		if [ "$HY" != "" ]; then
			HY=`ps -ef | grep postgres | grep -v "color=auto" | grep "postgres: wal writer process"`
			if [ "$HY" != "" ]; then
				HY=`ps -ef | grep postgres | grep -v "color=auto" | grep "postgres: autovacuum launcher process"`
				if [ "$HY" != "" ]; then
					NF=Y
				else
					NF=N
					HU=1
				fi
			else
				NF=N
				HU=1
			fi
		else
			NF=N
			HU=1
		fi
	else
		NF=N
		HU=1
	fi
	if [ "$NF" == "Y" ] ; then
		PID=`cat $DATA_DIR/postmaster.pid 2>/dev/null| head -n 1`
		if [ "$PID" != "" ]; then
			OUSER=`ps -ef | grep postgres 2>/dev/null | grep bin 2>/dev/null | grep $PID 2>/dev/null | awk '{ print $1}'`
			R=`ps -ef | grep postgres 2>/dev/null | grep bin 2>/dev/null | grep $PID 2>/dev/null | awk '{ num=1; while (index($num,"bin")==0) num=num+1; print num ;}'`
			BINHOME=`ps -ef | grep postgres 2>/dev/null | grep bin 2>/dev/null| grep $PID 2>/dev/null | awk {'print $'${R}''} 2>/dev/null`
			if [ "$BINHOME" == "" ]; then
				echo "DATABASE at the location you specify is not currently running."
				exit 0
			fi
			BINHOME=`echo ${BINHOME%\/bin*}`
			TBINHOME=$BINHOME
			PORT=`cat $DATA_DIR/postmaster.pid | head -n 4 | tail -n 1`
			NF=Y
		elif [ "$PID" == "" ]; then
			YON "Database Server is running? [Y/n]  [q is quit]:" Y
			NF=`cat pbg_YN.file`
			if [ "$NF" == "Y" ] || [ "$NF" == "y" ]
			then
				echo -e "DATABASE at the DATA location of the DATABASE you selected is not running. \nIs the directory of the data you chose really correct? [ You choose : $DATA_DIR ] \n\n\nPlease enter the FULL PATH to the DATA location of DATABASE you want to check. \n[q is quit / p is pass]: \c"
				read DATA_DIR
				echo ""
				echo ""
				if [ "$DATA_DIR" == "q" ] || [ "$DATA_DIR" == "Q" ]
				then
					exit 0
				elif [ "$DATA_DIR" == "p" ] || [ "$DATA_DIR" == "P" ]
				then
					PID=temppid
				else
					PID=`cat $DATA_DIR/postmaster.pid 2>/dev/null| head -n 1`
					OUSER=`ps -ef | grep postgres 2>/dev/null | grep bin 2>/dev/null | grep $PID 2>/dev/null | awk '{ print $1}'`
					R=`ps -ef | grep postgres 2>/dev/null | grep bin 2>/dev/null | grep $PID 2>/dev/null | awk '{ num=1; while (index($num,"bin")==0) num=num+1; print num ;}'`
					BINHOME=`ps -ef | grep postgres 2>/dev/null | grep bin 2>/dev/null | grep $PID 2>/dev/null | awk {'print $'${R}''} 2>/dev/null`
					if [ "$BINHOME" == "" ]; then
						PID=""
					fi
					BINHOME=`echo ${BINHOME%\/bin*}`
					TBINHOME=$BINHOME
					PORT=`cat $DATA_DIR/postmaster.pid | head -n 4 | tail -n 1`
				fi	
			fi
			while [ "$NF" == "Y" ] || [ "$NF" == "y"  ] && [ "$PID" == "" ]
			do
				YON "Database Server is running? [Y/n]  [q is quit]:" Y
				NF=`cat pbg_YN.file`
				if [ "$NF" == "Y" ] || [ "$NF" == "y" ]
				then
					echo -e "DATABASE at the DATA location of the DATABASE you selected is not running. \nIs the directory of the data you chose really correct? [ You choose : $DATA_DIR ] \n\n\nPlease enter the FULL PATH to the DATA location of DATABASE you want to check. \n[q is quit / p is pass]: \c"
					read DATA_DIR
					echo ""
					echo ""
					if [ "$DATA_DIR" == "q" ] || [ "$DATA_DIR" == "Q" ]
					then
						exit 0
					elif [ "$DATA_DIR" == "p" ] || [ "$DATA_DIR" == "P" ]
					then
						PID=temppid
					else
						PID=`cat $DATA_DIR/postmaster.pid 2>/dev/null| head -n 1`
						OUSER=`ps -ef | grep postgres 2>/dev/null | grep bin 2>/dev/null | grep $PID 2>/dev/null | awk '{ print $1}'`
						R=`ps -ef | grep postgres 2>/dev/null | grep bin 2>/dev/null | grep $PID 2>/dev/null | awk '{ num=1; while (index($num,"bin")==0) num=num+1; print num ;}'`
						BINHOME=`ps -ef | grep postgres 2>/dev/null | grep bin 2>/dev/null | grep $PID 2>/dev/null | awk {'print $'${R}''} 2>/dev/null`
						if [ "$BINHOME" == "" ]; then
							PID=""
						fi
						BINHOME=`echo ${BINHOME%\/bin*}`
						TBINHOME=$BINHOME
						PORT=`cat $DATA_DIR/postmaster.pid | head -n 4 | tail -n 1`
					fi	
				fi	
			done
		fi
	fi
	if [ "$NF" == "N" ] || [ "$NF" == "n" ]
	then
		if [ "$HU" != "1" ]; then
			echo -e "Please enter the FULL PATH to the DATA location of DATABASE you want to check. \n[q is quit / p is pass]: \c"
	                read DATA_DIR
	                if [ "$DATA_DIR" == "q" ] || [ "$DATA_DIR" == "Q" ]
	                then
	                	exit 0
	                elif [ "$DATA_DIR" == "p" ] || [ "$DATA_DIR" == "P" ]
	                then
	                        PID=temppid
	                fi
		fi
		ls -ld $DATA_DIR/postgresql.conf &>/dev/null
		WRIT=`echo $?`
		while [ "$WRIT" != "0" ];
		do
			echo -e "\n\nIs the DATA directory of the database correct? \nIs the directory of the data you chose really correct? [ You choose : $DATA_DIR ] \n\n\nPlease enter the FULL PATH to the DATA location of DATABASE you want to check. \n[q is quit / p is pass]: \c"
			read DATA_DIR
			if [ "$DATA_DIR" == "q" ] || [ "$DATA_DIR" == "Q" ] 
			then
				exit 0
			elif [ "$DATA_DIR" == "p" ] || [ "$DATA_DIR" == "P" ]
			then
				PID=temppid
			fi
			ls -ld $DATA_DIR/postgresql.conf  &>/dev/null
			WRIT=`echo $?`
		done
	fi
	if [ "$NF" == "Y" ] || [ "$NF" == "y" ] && [ "$PID" != "temppid" ]
	then
		NS=1
		psql -w -c "\! true" &>/dev/null
		WRIT=`echo $?`
		if [ "$WRIT" == "0" ]; then
			NOP=1
			OPT=""
			psql $OPT -t -c "select  'Database ver : ' ||version() limit 1;" |sed 's/^.//g'|sed 's/on.*$//g'|head -n 1 >> ./pbg_ser${TODAY}.log
			VER=`psql $OPT -t -c "select version() limit 1;" |sed 's/^.//g'|sed 's/on.*$//g'|head -n 1`
			TVER=`echo ${VER%%.*}|rev|cut -c 1`
			if [ "$TVER" == "9" ]; then
				VER=`echo "9.\`echo ${VER#*.} | cut -c 1\`"`
			else
				VER=`echo ${VER%%.*}|rev|cut -c 1-2|rev`
			fi
			SPATH=""
			WRE=`cat $DATA_DIR/pg_hba.conf | grep -v "#" | grep local | head -n 1 | awk {'print $NF'}`
			if [ "$WRE" != "trust" ]; then
				DB=$PGDATABASE
				USER=`cat ~/.pgpass | grep $DB | grep $PORT | grep -v "#" | head -n 1 | awk -F ':' {'print $4'}`
				PWD=`cat ~/.pgpass | grep $DB | grep $PORT | grep -v "#" | head -n 1 | awk -F ':' {'print $NF'}`
			fi
		elif [ "$WRIT" != "0" ]; then
			NOP=0
		fi
		if [ "$NOP" == "0" ]; then
			LC=0
			ls -ld ~/pg*_env.sh &>/dev/null
			WRIT=`echo $?`
			if [ "$WRIT" == "0" ]; then
				ENV_FILE=`ls ~/pg*_env.sh | head -n 1`
				source $ENV_FILE
				DB=$PGDATABASE
				USER=$PGUSER
			fi
			if [ "$DB" == "" ] || [ "$USER" == "" ]
			then
				CHC=1
			fi
			if [ "$CHC" == "1" ]; then
				echo -e "Enter the name of the DATABASE you want to check [q is quit]: \c" 
				read DB
				echo ""
				echo ""
				if [ "$DB" == "q" ] || [ "$DB" == "Q" ] 
				then
					exit 0
				fi
				echo -e "Please enter the SUPER USER NAME [q is quit]: \c" 
				read USER
				echo ""
				echo ""
				if [ "$USER" == "q" ] || [ "$USER" == "Q" ] 
				then
					exit 0
				fi
			fi
			echo -e "Please enter the DB USER( $USER ) PASSWORD : \c" 
			read PWD
			echo ""
			echo ""
			BINHOME=$TBINHOME
			PORT=`cat $DATA_DIR/postmaster.pid | head -n 4 | tail -n 1`
			OPT="-w -U $USER -d $DB -p $PORT"
			chmod 600 ~/.pgpass
			cat >> ~/.pgpass <<EOFF
localhost:$PORT:$DB:$USER:$PWD
EOFF
			chmod 400 ~/.pgpass
			$BINHOME/bin/psql $OPT -t -c "\! true" &>/dev/null
			IS=`echo "$?"`
			chmod 600 ~/.pgpass
			sed -i '$d' ~/.pgpass
			chmod 400 ~/.pgpass
			while [ "$IS" != "0" ];
			do
				echo "There is can not check DATABASE by the following information you entered."
				echo "connect Database   : $DB"
				echo "connect SUPER USER : $USER"
				echo "connect PASSWD     : If all of the above information is correct, you have mistyped the PASSWORD of SUPER USER. "
				echo -e "Enter the name of the DATABASE you want to check [q is quit]: \c" 
				read DB
				echo ""
				echo ""
				if [ "$DB" == "q" ] || [ "$DB" == "Q" ] 
				then
					exit 0
				fi
				echo -e "Please enter the SUPER USER NAME [q is quit]: \c" 
				read USER
				echo ""
				echo ""
				if [ "$USER" == "q" ] || [ "$USER" == "Q" ] 
				then
					exit 0
				fi
				echo -e "Please enter the SUPER USER PASSWORD : \c" 
				read PWD
				echo ""
				echo ""
				chmod 600 ~/.pgpass
				cat >> ~/.pgpass <<EOFF
localhost:$PORT:$DB:$USER:$PWD
EOFF
				chmod 400 ~/.pgpass
				OPT="-w -U $USER -d $DB -p $PORT"
				$BINHOME/bin/psql $OPT -t -c "\! true" &>/dev/null
				IS=`echo "$?"`
				echo $IS
				chmod 600 ~/.pgpass
				sed -i '$d' ~/.pgpass
			done
			chmod 600 ~/.pgpass
			cat >> ~/.pgpass <<EOFF
localhost:$PORT:$DB:$USER:$PWD
EOFF
			$BINHOME/bin/psql $OPT -t -c "select  'Database ver : ' ||version() limit 1;" |sed 's/^.//g'|sed 's/on.*$//g'|head -n 1 >> ./pbg_ser${TODAY}.log
			VER=`$BINHOME/bin/psql $OPT -t -c "select version() limit 1;" |sed 's/^.//g'|sed 's/on.*$//g'|head -n 1`
			TVER=`echo ${VER%%.*}|rev|cut -c 1`
			if [ "$TVER" == "9" ];	then
				VER=`echo "9.\`echo ${VER#*.} | cut -c 1\`"`
			else
				VER=`echo ${VER%%.*}|rev|cut -c 1-2|rev`
			fi
			SPATH="$BINHOME/bin/"
		fi
		
		echo "Core         : "`cat /proc/cpuinfo | grep "processor" | sed 's/^.*://g' |head -n 1|awk '{printf "%.0f", $1 + 1}'` >> ./pbg_ser${TODAY}.log
		echo "Memory       :" `free -m | head -n 2 | tail -n 1 | awk '{printf "%.0f", $2 / 1000}'`"GB" >> ./pbg_ser${TODAY}.log
		UU=`top -d 1 | head -n 1 | awk -F ',' '{ num=1; while (index($num,"load")==0) num=num+1; print num }'`
	        LDA=`top -b -d 1 | head -n 1 | awk -F ',' {'print $'${UU}''} | sed 's/^  //g'| sed 's/load average://'|sed 's/ //'` 
		echo "load average : ""$LDA">> ./pbg_ser$TODAY.log
		CPUIO=`top -b -d 1 | head -n 3 | tail -n 1 | awk -F ',' {'print $5'} | sed 's/wa//'|sed 's/%//'|sed 's/ //'`
		echo "CPU utilization rate for Disk I/O :""$CPUIO""%" >> ./pbg_ser$TODAY.log
		echo "" >> ./pbg_ser${TODAY}.log
		shared_buffers=`"$SPATH"psql $OPT -t -c "show shared_buffers"`
		work_mem=`"$SPATH"psql $OPT -t -c "show work_mem"`
		maintenance_work_mem=`"$SPATH"psql $OPT -t -c "show maintenance_work_mem"`
		listen_addresses=`"$SPATH"psql $OPT -t -c "show listen_addresses"`
		max_connections=`"$SPATH"psql $OPT -t -c "show max_connections"`
		listen_addresses=`"$SPATH"psql $OPT -t -c "show listen_addresses"`
		connection_count=`"$SPATH"psql $OPT -t -c "select count(*) from pg_stat_activity;"`
		if [ "$VER" == "9.3" ] || [ "$VER" == "9.4" ]
		then
			checkpoint_segments=`"$SPATH"psql $OPT -t -c "show checkpoint_segments" 2>/dev/null`
		else
			max_wal_size=`"$SPATH"psql $OPT -t -c "show max_wal_size" 2> /dev/null`
			min_wal_size=`"$SPATH"psql $OPT -t -c "show min_wal_size" 2> /dev/null`
		fi
		synchronous_commit=`"$SPATH"psql $OPT -t -c "show synchronous_commit"`
		checkpoint_completion_target=`"$SPATH"psql $OPT -t -c "show checkpoint_completion_target"`
		synchronous_commit=`"$SPATH"psql $OPT -t -c "show synchronous_commit"`
		archive_mode=`"$SPATH"psql $OPT -t -c "show archive_mode"`
		archive_command=`"$SPATH"psql $OPT -t -c "show archive_command"`
		max_wal_senders=`"$SPATH"psql $OPT -t -c "show max_wal_senders"`
		random_page_cost=`"$SPATH"psql $OPT -t -c "show random_page_cost"`
		effective_cache_size=`"$SPATH"psql $OPT -t -c "show effective_cache_size"`
		logging_collector=`"$SPATH"psql $OPT -t -c "show logging_collector"`
		client_min_messages=`"$SPATH"psql $OPT -t -c "show client_min_messages"`
		log_min_messages=`"$SPATH"psql $OPT -t -c "show log_min_messages"`
		log_min_error_statement=`"$SPATH"psql $OPT -t -c "show log_min_error_statement"`
		log_min_duration_statement=`"$SPATH"psql $OPT -t -c "show log_min_duration_statement"`
		log_min_duration_statement=`echo $log_min_duration_statement`
		log_temp_files=`"$SPATH"psql $OPT -t -c "show log_temp_files"`
		log_temp_files=`echo $log_temp_files`
		log_lock_waits=`"$SPATH"psql $OPT -t -c "show log_lock_waits"`
	elif [ "$NF" == "N" ] || [ "$NF" == "n" ] && [ "$PID" != "temppid" ]
	then
		NS=0
		echo "Database ver :" `cat $DATA_DIR/PG_VERSION` >> ./pbg_ser${TODAY}.log
		VER=`cat $DATA_DIR/PG_VERSION`
		echo "Core         : "`cat /proc/cpuinfo | grep "processor" | sed 's/^.*://g' |head -n 1|awk '{printf "%.0f", $1 + 1}'` >> ./pbg_ser${TODAY}.log
		echo "Memory       :" `free -m | head -n 2 | tail -n 1 | awk '{printf "%.0f", $2 / 1000}'`"GB" >> ./pbg_ser${TODAY}.log
		UU=`top -d 1 | head -n 1 | awk -F ',' '{ num=1; while (index($num,"load")==0) num=num+1; print num }'`
	        LDA=`top -b -d 1 | head -n 1 | awk -F ',' {'print $'${UU}''} | sed 's/^  //g'| sed 's/load average://'|sed 's/ //'` 
		echo "load average : ""$LDA">> ./pbg_ser$TODAY.log
		CPUIO=`top -b -d 1 | head -n 3 | tail -n 1 | awk -F ',' {'print $5'} | sed 's/wa//'|sed 's/%//'|sed 's/ //'`
		echo "CPU utilization rate for Disk I/O :""$CPUIO""%" >> ./pbg_ser$TODAY.log
		echo "" >> ./pbg_ser${TODAY}.log
		archive_command=`cat $DATA_DIR/postgresql.auto.conf | grep -v "#" | grep archive_command | tail -n 1`
		ARCH_DIR=`echo ${archive_command#*cp %p}`
		ARCH_DIR=`echo ${ARCH_DIR%%%f*}`
		if [ "$ARCH_DIR" == "" ]; then
			archive_command=`cat $DATA_DIR/postgresql.auto.conf | grep -v "#" | grep archive_command | tail -n 1`
			if [ "$archive_command" == "" ]; then
				archive_command=`cat $DATA_DIR/postgresql.conf | grep -v "#" | grep archive_command | tail -n 1`
			fi
			ARCH_DIR=`echo ${archive_command#*cp %p}`
			ARCH_DIR=`echo ${ARCH_DIR%%%f*}`
		fi
                shared_buffers=`bkf $DATA_DIR shared_buffers`
                work_mem=`bkf $DATA_DIR work_mem`
                maintenance_work_mem=`bkf $DATA_DIR maintenance_work_mem`
                listen_addresses=`bkf $DATA_DIR listen_addresses`
                max_connections=`bkf $DATA_DIR max_connections`
                listen_addresses=`bkf $DATA_DIR listen_addresses`
		if [ "$VER" == "9.3" ] || [ "$VER" == "9.4" ]
		then
                	checkpoint_segments=`bkf $DATA_DIR checkpoint_segments`
		else
                	max_wal_size=`bkf $DATA_DIR max_wal_size`
	                min_wal_size=`bkf $DATA_DIR min_wal_size`
		fi
                synchronous_commit=`bkf $DATA_DIR synchronous_commit`
                checkpoint_completion_target=`bkf $DATA_DIR checkpoint_completion_target`
                synchronous_commit=`bkf $DATA_DIR synchronous_commit`
                archive_mode=`bkf $DATA_DIR archive_mode`
                archive_command=`bkf $DATA_DIR archive_command`
                max_wal_senders=`bkf $DATA_DIR max_wal_senders`
                random_page_cost=`bkf $DATA_DIR random_page_cost`
                effective_cache_size=`bkf $DATA_DIR effective_cache_size`
                logging_collector=`bkf $DATA_DIR logging_collector`
                client_min_messages=`bkf $DATA_DIR client_min_messages`
                log_min_messages=`bkf $DATA_DIR log_min_messages`
                log_min_error_statement=`bkf $DATA_DIR log_min_error_statement`
                log_min_duration_statement=`bkf $DATA_DIR log_min_duration_statement`
		log_min_duration_statement=`echo $log_min_duration_statement`
                log_temp_files=`bkf $DATA_DIR log_temp_files`
		log_temp_files=`echo $log_temp_files`
                log_lock_waits=`bkf $DATA_DIR log_lock_waits`
		if [ "$shared_buffers" == "" ]; then
			shared_buffers=128MB
		fi
		if [ "$work_mem" == "" ]; then
			if [ "$VER" == "9.3" ]; then
				work_mem=1MB
			else
				work_mem=4MB
			fi
		fi
		if [ "$maintenance_work_mem" == "" ]; then
			if [ "$VER" == "9.3" ]; then
				maintenance_work_mem=16MB
			else
				maintenance_work_mem=64MB
			fi
		fi
		if [ "$listen_addresses" == "" ]; then
			listen_addresses=localhost
		fi
		if [ "$max_connections" == "" ]; then
			max_connections=100
		fi
		if [ "$checkpoint_completion_target" == "" ]; then
			checkpoint_completion_target=0.5
		fi
		if [ "$synchronous_commit" == "" ]; then
			synchronous_commit=on
		fi
		if [ "$max_wal_size" == "" ]; then
			max_wal_size=1GB
		fi
		if [ "$min_wal_size" == "" ]; then
			min_wal_size=80MB
		fi
		if [ "$check_point_segments" == "" ]; then
			check_point_segments=3
		fi
		if [ "archive_mode" == "" ]; then
			archive_mode=off
		fi
		if [ "max_wal_senders" == "" ]; then
			if [ "$VER" == "9.3" ] || [ "$VER" == "9.4" ] || [ "$VER" == "9.5" ] || [ "$VER" == "9.6" ]
			then
				max_wal_senders=0
			else
				max_wal_senders=10
			fi
		fi
		if [ "$random_page_cost" == "" ]; then
			random_page_cost=4.0
		fi
		if [ "$effective_cache_size" == "" ]; then
			if [ "$VER" == "9.3" ]; then
				effective_cache_size=128MB
			else
				effective_cache_size=4GB
			fi
		fi
		if [ "$logging_collector" == "" ]; then
			logging_collector=on
		fi
		if [ "$client_min_messages" == "" ]; then
			client_min_messages=notice
		fi
		if [ "$log_min_messages" == "" ]; then
			log_min_messages=warning
		fi
		if [ "$log_min_error_statement" == "" ]; then
			log_min_error_statement=error
		fi
		if [ "$log_min_duration_statement" == "" ]; then
			log_min_duration_statement="-1"
		fi
		if [ "$log_lock_waits" == "" ]; then
			log_lock_waits=off
		fi
		if [ "$log_temp_files" == "" ]; then
			log_temp_files="-1"
		fi
	fi	
	if [ "$PID" != "temppid" ]; then
		AWKN=`CHGI Mounted "df -P -h"`
		SWKN=`CHGI Size "df -P -h"`
		FKG=1
		DD=`df -P $DATA_DIR 2>/dev/null|awk {'print $'${AWKN}''}|tail -n 1`
		DT=`df -P $DATA_DIR 2>/dev/null|awk {'print $'${SWKN}''}|tail -n 1`
		DS=`du -sk $DATA_DIR 2>/dev/null |awk {'print $1'}|tail -n 1`
		DY=`echo "$DS 100 $DT %"|awk '{printf "%.0f", $1 * $2 / $3; print $4}'`
		TDD=`echo "$DT 1048576"|awk '{printf "%.1f", $1 / $2}'`
		TDD=`echo $(printf %.0f $TDD)GB`
		TDS=`BYHW $DS`
		if [ "$VER" == "10" ] || [ "$VER" == "11" ]
		then
			WAL_NAME=wal
		else
			WAL_NAME=xlog
		fi
		W=`ls -ld $DATA_DIR/pg_${WAL_NAME} | cut -c 1`
		if [ "$W" == "d" ]; then
			WAL_DIR=`ls -d $DATA_DIR/pg_${WAL_NAME}`
		elif [ "$W" == "l" ]; then
			WAL_DIR=`ls -ld $DATA_DIR/pg_${WAL_NAME} |awk -F '>' {'print $2'}`
		fi
		WD=`df -P $WAL_DIR 2>/dev/null|awk {'print $'${AWKN}''}|tail -n 1`
		WT=`df -P $WAL_DIR 2>/dev/null|awk {'print $'${SWKN}''}|tail -n 1`
		WS=`du -sk $WAL_DIR 2>/dev/null |awk {'print $1'}|tail -n 1`
		WY=`echo "$WS 100 $WT %"|awk '{printf "%.0f", $1 * $2 / $3; print $4}'`
		TWD=`echo "$WT 1048576"|awk '{printf "%.1f", $1 / $2}'`
		TWD=`echo $(printf %.0f $TWD)GB`
		TWS=`BYHW $WS`
		ARCH_DIR=`echo ${archive_command#*cp %p}`
		ARCH_DIR=`echo ${ARCH_DIR%%%f*}`
		AD=`df -P $ARCH_DIR 2>/dev/null|awk {'print $'${AWKN}''}|tail -n 1`
		AT=`df -P $ARCH_DIR 2>/dev/null|awk {'print $'${SWKN}''}|tail -n 1`
		AS=`du -sk $ARCH_DIR 2>/dev/null |awk {'print $1'}|tail -n 1`
		AY=`echo "$AS 100 $AT %"|awk '{printf "%.0f", $1 * $2 / $3; print $4}' 2>/dev/null`
		TAD=`echo "$AT 1048576"|awk '{printf "%.1f", $1 / $2}' 2>/dev/null`
		TAD=`echo $(printf %.0f $TAD)GB`
		TAS=`BYHW $AS 2>/dev/null`
		echo "---------------------------------------------------------------------------" >> ./pbg_ser${TODAY}.log
		echo "                                 PARTITION USAGE" >> ./pbg_ser${TODAY}.log
		echo "---------------------------------------------------------------------------" >> ./pbg_ser${TODAY}.log
		echo "DATA PARTITION : $DD" >> ./pbg_ser${TODAY}.log
		echo "TOTAL  : $TDD" >> ./pbg_ser${TODAY}.log
		echo "USAGE  : $TDS ($DY)" >> ./pbg_ser${TODAY}.log
		echo "" >> ./pbg_ser${TODAY}.log
		echo "XLOG PARTITION : $WD" >> ./pbg_ser${TODAY}.log
		echo "TOTAL  : $TWD" >> ./pbg_ser${TODAY}.log
		echo "USAGE  : $TWS ($WY)" >> ./pbg_ser${TODAY}.log
		echo "" >> ./pbg_ser${TODAY}.log
		if [ "$AT" == "" ]; then
			echo "ARCH PARTITION : No Archiving" >> ./pbg_ser${TODAY}.log
			echo "TOTAL  : No Archiving" >> ./pbg_ser${TODAY}.log
			echo "USAGE  : No Archiving" >> ./pbg_ser${TODAY}.log
		else
			echo "ARCH PARTITION : $AD" >> ./pbg_ser${TODAY}.log
			echo "TOTAL  : $TAD" >> ./pbg_ser${TODAY}.log
			echo "USAGE  : $TAS ($AY)" >> ./pbg_ser${TODAY}.log
		fi
		echo "" >> ./pbg_ser${TODAY}.log
		BKB=`ls -l $DATA_DIR/pg_tblspc/ | grep -w '\->'`
		CNT=`ls -l $DATA_DIR/pg_tblspc/ | grep -w '\->' | awk -F '> ' {'print $2'} | xargs du -sk 2>/dev/null| awk '{print $1}' | wc -l`
		if [ "$CNT" != "0" ] && [ "$BKB" != "" ];
		then
			K=1
			PWKN=1
		        PW=`ls -l $DATA_DIR/pg_tblspc/ | awk -F '> ' {'print $2'} | sort | xargs df -P 2>/dev/null| awk {'print $'${PWKN}''} | head -n 1`
		        while [ "$PW" != "Mounted" ];
		        do
		                PWKN=`echo "$PWKN 1"|awk '{printf "%.0f", $1 + $2 }'`
		                PW=`ls -l $DATA_DIR/pg_tblspc/ | awk -F '> ' {'print $2'} | sort | xargs df -P 2>/dev/null| awk {'print $'${PWKN}''} | head -n 1`
		        done
			PARTITION=`echo \`ls -l $DATA_DIR/pg_tblspc/ | awk -F '> ' {'print $2'} | sort | xargs df -P -h 2>/dev/null| awk '$'${PWKN}'' | head -n 1\``
			VWKN=`CHGI Size "echo $PARTITION"`
			TOT=0
			for (( i=1 ; i <= $CNT; i++ ))  
			do   
				BPARTITION=$PARTITION
				PARTITION=`echo \`ls -l $DATA_DIR/pg_tblspc/ | awk -F '> ' {'print $2'} | sort | xargs df -P 2>/dev/null| awk '{print $'${PWKN}'}' | grep -vw "Mounted"| head -n $i | tail -n 1\``	
				if [ "$BPARTITION" != "$PARTITION" ]; then
					if [ "$i" != "1" ]; then
						NAMK=`du -sk $BPARTITION 2>/dev/null| awk {'print $1'}`
						PPER=`echo "$NAMK 100 $TT %"|awk '{printf "%.0f", $1 * $2 / $3; print $4}'`
						TYAS=`BYHW $NAMK`
						CHGE=`echo "USE    : $TYAS ($PPER)"`
						CLIN=`grep -n pbg_sayong ./pbg_ser${TODAY}.log | cut -d: -f1`
						sed -i "${CLIN}s/.*/$CHGE/g" ./pbg_ser${TODAY}.log
						NAM=`echo "$NAMK $TOT"|awk '{printf "%.0f", $1 - $2}'`
						NPER=`echo "$NAM 100 $TT %"|awk '{printf "%.0f", $1 * $2 / $3; print $4}'`
						NYAS=`BYHW $NAM`
						echo "  -ETC : $NYAS ($NPER)" >> ./pbg_ser${TODAY}.log
						if [ "$BPARTITION" == "$DD" ]; then
							echo "   ETC Usage includes DATA Usage          " >> ./pbg_ser${TODAY}.log
						elif [ "$BPARTITION" == "$WD" ]; then
							echo "   ETC Usage includes WAL Usage           " >> ./pbg_ser${TODAY}.log
						elif [ "$BPARTITION" == "$AD" ]; then 
							echo "   ETC Usage includes ARCHIVE Usage       " >> ./pbg_ser${TODAY}.log
						fi
						TOT=0
					fi
					echo "" >> ./pbg_ser${TODAY}.log
					echo "TABLESPACE PARTITION$K : $PARTITION" >> ./pbg_ser${TODAY}.log
					TT=`df -P -k $PARTITION | awk {'print $'${VWKN}''} | grep -vw "blocks"`
					TTA=`echo "$TT 1048576"|awk '{printf "%.1f", $1 / $2}'`
					TTA=`echo $(printf %.0f $TTA)GB`
					echo "TOTAL  : $TTA" >> ./pbg_ser${TODAY}.log
					echo "pbg_sayong" >> ./pbg_ser${TODAY}.log
					K=`echo "$K 1"|awk '{printf "%.0f", $1 + $2 }'`
				fi
				YANG=`ls -l $DATA_DIR/pg_tblspc/ | awk -F '> ' {'print $2'} | sort | xargs du -sk 2>/dev/null| awk '{print $1}' | head -n $i | tail -n 1`
				YAS=`BYHW $YANG`
				YAP=`echo "$YANG 100 $TT"|awk '{printf "%.0f", $1 * $2 / $3}'`
				echo "  -OID: "`ls -l $DATA_DIR/pg_tblspc/ | awk -F ' ->' {'print $1'} | sort | awk {'print $NF'} | grep -vw "0" | head -n $i | tail -n 1`" ( $YAS $YAP""% )" >> ./pbg_ser${TODAY}.log
				echo "  -DIR: "`ls -l $DATA_DIR/pg_tblspc/ | awk -F '-> ' {'print $2'} | sort | awk {'print $NF'}| sed '/^$/d' | head -n $i | tail -n 1` >> ./pbg_ser${TODAY}.log
				TOT=`echo "$TOT $YANG"|awk '{printf "%.0f", $1 + $2 }'`
				echo "" >> ./pbg_ser${TODAY}.log
			done
			BPARTITION=$PARTITION
			NAMK=`du -sk $BPARTITION 2>/dev/null| awk {'print $1'}`
			PPER=`echo "$NAMK 100 $TT %"|awk '{printf "%.0f", $1 * $2 / $3; print $4}'`
			TYAS=`BYHW $NAMK`
			CHGE=`echo "USAGE  : $TYAS ($PPER)"`
			CLIN=`grep -n pbg_sayong ./pbg_ser${TODAY}.log | cut -d: -f1`
			sed -i "${CLIN}s/.*/$CHGE/g" ./pbg_ser${TODAY}.log
			NAM=`echo "$NAMK $TOT"|awk '{printf "%.0f", $1 - $2}'`
			NPER=`echo "$NAM 100 $TT %"|awk '{printf "%.0f", $1 * $2 / $3; print $4}'`
			NYAS=`BYHW $NAM`
			echo "  -ETC : $NYAS ($NPER)" >> ./pbg_ser${TODAY}.log
			if [ "$BPARTITION" == "$DD" ]; then
				echo "   ETC Usage includes DATA Usage" >> ./pbg_ser${TODAY}.log
			elif [ "$BPARTITION" == "$WD" ]; then
				echo "   ETC Usage includes WAL Usage" >> ./pbg_ser${TODAY}.log
			elif [ "$BPARTITION" == "$AD" ]; then 
				echo "   ETC Usage includes ARCHIVE Usage" >> ./pbg_ser${TODAY}.log
			fi
			TOT=0
			echo "" >> ./pbg_ser${TODAY}.log
			echo "" >> ./pbg_ser${TODAY}.log
		fi
		
		memory=`free | head -n 2 | tail -n 1 | awk {'print $2'}`
		memory=`GKN $memory`
		CC=`echo "$memory 4"|awk '{printf "%.3f", $1 / $2}'`
		CR=`echo "$memory 4"|awk '{printf "%.0f", $1 / $2}'`
		T=`GBN $shared_buffers G`
		j_shared_buffers=`BIGYO $CC $T`
		c_shared_buffers=`echo $CR"GB"`
		c_shared_buffers=`echo | awk -v temp="$c_shared_buffers" '{printf("%-11s",temp);}'`
		
		T=`GBN $maintenance_work_mem B`
		if [ "$memory" -ge "16" ];then
		        C=1073741824
		elif [ "$memory" -ge "8" ] && [ "16" -gt "$memory" ]
		then
		        C=536870912
		elif [ "8" -gt "$memory" ]; then
		        C=268435456
		fi
		T=`echo $(printf %.0f $T)`
		CCC=`echo "$C 1048576"|awk '{printf "%.0f", $1 / $2}'`
		TT=`echo "$T 1048576"|awk '{printf "%.0f", $1 / $2}'`
		CCC=`echo $(printf %.0f $CCC)`
		TT=`echo $(printf %.0f $TT)`
		j_maintenance_work_mem=`BIGYO $CCC $TT`
		c_maintenance_work_mem=`GBN $C M`
		c_maintenance_work_mem=`echo $(printf %.0f $c_maintenance_work_mem)`
		c_maintenance_work_mem=`echo ${c_maintenance_work_mem}MB`
		c_maintenance_work_mem=`echo | awk -v temp="$c_maintenance_work_mem" '{printf("%-11s",temp);}'`
	
		t_shared_buffers=`GBN $shared_buffers M`
		C=`echo "$memory 1024 $CC 1024 $C 1048576 $max_connections"|awk '{printf "%.0f", ( ( $1 * $2 ) - ( $3 * $4 ) - ( $5 / $6 ) ) / $7}'`
		
		if [ "$C" -ge "128" ]
		then
		        C=134217728
		elif [ "128" -gt "$C" ] && [ "$C" -ge "64" ]
		then
		        C=67108864
		elif [ "64" -gt "$C" ] && [ "$C" -ge "32" ]
		then
		        C=33554432
		elif [ "32" -gt "$C" ] && [ "$C" -ge "16" ]
		then
		        C=16777216
		elif [ "16" -gt "$C" ] && [ "$C" -ge "8" ]
		then
		        C=8338608
		elif [ "8" -gt "$C" ] && [ "$C" -ge "4" ]
		then
		        C=4194304
		elif [ "4" -gt "$C" ]
		then
		        C=2097152
		fi
		T=`GBN $work_mem B`
		T=`echo $(printf %.0f $T)`
		CCC=`echo "$C 1048576"|awk '{printf "%.1f", $1 / $2}'`
		TT=`echo "$T 1048576"|awk '{printf "%.1f", $1 / $2}'`
		CCC=`echo $(printf %.0f $CCC)`
		TT=`echo $(printf %.0f $TT)`
		j_work_mem=`BIGYO $CCC $TT`
		c_work_mem=`GBN $C M`
		c_work_mem=`echo $(printf %.0f $c_work_mem)`
		c_work_mem=`echo ${c_work_mem}MB`
		c_work_mem=`echo | awk -v temp="$c_work_mem" '{printf("%-11s",temp);}'`
		
		TY=`echo \\\\\\\\"${listen_addresses}"|sed 's/ //g'`
		j_listen_addresses=`BIGYO $TY \\\\\\\*`
		c_listen_addresses=" *          "
		CC=`echo "$memory 3 4"|awk '{printf "%.3f", $1 * $2 / $3}'`
		CR=`echo "$memory 3 4"|awk '{printf "%.0f", $1 * $2 / $3}'`
		T=`GBN $effective_cache_size G`
		j_effective_cache_size=`BIGYO $CC $T`
		c_effective_cache_size=`echo $CR"GB"`
		c_effective_cache_size=`echo | awk -v temp="$c_effective_cache_size" '{printf("%-11s",temp);}'`
		
		if [ "$NF" == "N" ] || [ "$NF" == "n" ]
		then
			Y=1	
			j_connection_count="Need CHK"
		elif [ "$NF" == "Y" ] || [ "$NF" == "y" ]
		then
			CC=`echo "$connection_count 100 $max_connections"|awk '{printf "%.0f", $1 * $2 / $3}'`
			if [ "80" -ge "$CC" ]; then
			        j_connection_count="O K     "
					Y=1
			else
			        j_connection_count="Need CHK"
					Y=0
			fi
			CC=`echo ${CC}%`
		fi
		if [ "$Y" == "1" ]; then
			c_connection_count=" OP Discrtn "
		elif [ "$Y" == "0" ]; then
			c_connection_count=" Need INC   "
		fi
		
		
		j_synchronous_commit=`BIGYO $synchronous_commit on`
		c_synchronous_commit=" on         "
		j_logging_collector=`BIGYO $logging_collector on`
		c_logging_collector=" on         "
		j_log_lock_waits=`BIGYO $log_lock_waits on`
		c_log_lock_waits=" on         "
		j_archive_mode=`BIGYO $archive_mode on`
		c_archive_mode=" on         "
		j_client_min_messages=`BIGYO $client_min_messages notice`
		c_client_min_messages=" notice     "
		j_log_min_messages=`BIGYO $log_min_messages warning`
		c_log_min_messages=" warning    "
		j_log_min_error_statement=`BIGYO $log_min_error_statement error`
		c_log_min_error_statement=" error      "
		
		
		if [ "$max_wal_senders" -ge "2" ]; then
		        j_max_wal_senders="O K     "
		else
		        j_max_wal_senders="Need CHK"
		fi
		c_max_wal_senders=" least 2    "
		
		
		C=`echo "$random_page_cost 1"| awk '{printf "%.0f", $1 * $2}'| sed 's/\..*$//g'`
		j_random_page_cost=`BIGYO $C 2`
		c_random_page_cost=" 2.0        "
		
	
		if [ 1 -eq `echo "0.9 $checkpoint_completion_target"|awk '{ if($1>=$2) print 1; else print 0; }'` ] && [ 1 -eq `echo "0.5 $checkpoint_c        ompletion_target"|awk '{ if($1<=$2) print 1; else print 0; }'` ]
		then
		        j_checkpoint_completion_target="O K     " 
		else
		        j_checkpoint_completion_target="Need CHK"
		fi
		c_checkpoint_completion_target=" 0.5 ~ 0.9  "
		
		if [ "$log_temp_files" != "-1" ]; then
		        j_log_temp_files="O K     "
		elif [ "$log_temp_files" == "-1" ]; then
		        j_log_temp_files="Need CHK"
		fi
		c_log_temp_files=" Not -1     "
		
		if [ "$log_min_duration_statement" != "-1" ]; then
		        j_log_min_duration_statement="O K     "
		elif [ "$log_min_duration_statement" == "-1" ]; then
		        j_log_min_duration_statement="Need CHK"
		fi
		c_log_min_duration_statement=" Not -1     "
		
		
		if [ "$VER" == "9.3" ] || [ "$VER" == "9.4" ] 
		then
			U=1
			WVT=`echo "$WT 3 1024 16"|awk '{printf "%.0f", ( ( $1 / $2 ) / $3 ) / $4 }'`
			MWS=`echo "$checkpoint_segments"`
			if [ "$MWS" -gt "$WVT" ]; then
				j_checkpoint_segments="Need CHK"
			else
				j_checkpoint_segments="O K     "
			fi
			c_checkpoint_segments=$WVT
			c_checkpoint_segments=`echo | awk -v temp="$c_checkpoint_segments" '{printf("%-11s",temp);}'`
		else
			U=0
			WVT=`echo "$WT 0.8 1024"|awk '{printf "%.0f", $1 * $2 / $3}'`
			MWS=`GBN $max_wal_size M`
			MWS=`echo $MWS|sed 's/\..*$//g'`
			if [ "$MWS" -gt "$WVT" ]; then
				j_max_wal_size="Need CHK"
			else
				j_max_wal_size="O K     "
			fi
			FKM=0
			if [ 1 -eq `echo "$WVT 1024"|awk '{ if($1>$2) print 1; else print 0; }'` ]; then
				WWVT=`echo "$WVT 1024"|awk '{printf "%.1f", $1 / $2}'`
				c_max_wal_size=`echo $(printf %.0f $WWVT)`
				c_max_wal_size=`echo ${c_max_wal_size}GB`
				FKM=1
			else
				c_max_wal_size=`echo ${WVT}MB`
			fi
			MMWS=`GBN $min_wal_size M`
			MMWS=`echo $MMWS|sed 's/\..*$//g'`
			if [ "$MMWS" -gt "80" ] && [ "$MWS" -ge "$WVT" ]
		 	then
				j_min_wal_size="Need CHK"
			else
				j_min_wal_size="O K     "
			fi
			c_min_wal_size=`echo "80MB~$c_max_wal_size"`
			c_max_wal_size=`echo | awk -v temp="$c_max_wal_size" '{printf("%-11s",temp);}'`
			c_min_wal_size=`echo | awk -v temp="$c_min_wal_size" '{printf("%-11s",temp);}'`
		fi
		
		echo "---------------------------------------------------------------------------" >> ./pbg_ser${TODAY}.log
		echo "                             PARAMETER CHECK" >> ./pbg_ser${TODAY}.log
		echo "---------------------------------------------------------------------------" >> ./pbg_ser${TODAY}.log
		echo "NO|            PARAMETER            |   CHECK  |  RECOMMAND |  YOUR_VALUE" >> ./pbg_ser${TODAY}.log
		echo "---------------------------------------------------------------------------" >> ./pbg_ser${TODAY}.log
		echo "01| (s)shared_buffers               | ""$j_shared_buffers"  "|"" $c_shared_buffers""|" $shared_buffers >> ./pbg_ser${TODAY}.log
		echo "02| (l)work_mem                     | ""$j_work_mem"  "|"" $c_work_mem""|" $work_mem >> ./pbg_ser${TODAY}.log
		echo "03| (l)maintenance_work_mem         | ""$j_maintenance_work_mem"  "|"" $c_maintenance_work_mem""|" $maintenance_work_mem >> ./pbg_ser${TODAY}.log
		echo "04| (s)listen_addresses             | ""$j_listen_addresses"  "|""$c_listen_addresses""|" `echo \\\"${listen_addresses}"|sed 's/ //g'` | sed 's/\\//g' >> ./pbg_ser${TODAY}.log
		echo "05| (s)max_connections              | ""$j_connection_count"  "|""$c_connection_count""|" $max_connections >> ./pbg_ser${TODAY}.log
		if [ "$VER" == "9.3" ] || [ "$VER" == "9.4" ]
		then
			echo "06| (s)checkpoint_segments          | ""$j_checkpoint_segments"  "|""$c_checkpoint_segments""|" $checkpoint_segments >> ./pbg_ser${TODAY}.log
			echo "07| (l)checkpoint_completion_target | ""$j_checkpoint_completion_target"  "|""$c_checkpoint_completion_target""|" $checkpoint_completion_target >> ./pbg_ser${TODAY}.log
			echo "08| (s)synchronous_commit           | ""$j_synchronous_commit"  "|""$c_synchronous_commit""|" $synchronous_commit >> ./pbg_ser${TODAY}.log
			echo "09| (s)archive_mode                 | ""$j_archive_mode"  "|""$c_archive_mode""|" $archive_mode >> ./pbg_ser${TODAY}.log
			echo "10| (s)max_wal_senders              | ""$j_max_wal_senders"  "|""$c_max_wal_senders""|" $max_wal_senders >> ./pbg_ser${TODAY}.log
			echo "11| (l)random_page_cost             | ""$j_random_page_cost"  "|""$c_random_page_cost""|" $random_page_cost >> ./pbg_ser${TODAY}.log
			echo "12| (l)effective_cache_size         | ""$j_effective_cache_size"  "|"" $c_effective_cache_size""|" $effective_cache_size >> ./pbg_ser${TODAY}.log
			echo "13| (s)logging_collector            | ""$j_logging_collector"  "|""$c_logging_collector""|" $logging_collector >> ./pbg_ser${TODAY}.log
			echo "14| (l)client_min_messages          | ""$j_client_min_messages"  "|""$c_client_min_messages""|" $client_min_messages >> ./pbg_ser${TODAY}.log
			echo "15| (l)log_min_messages             | ""$j_log_min_messages"  "|""$c_log_min_messages""|" $log_min_messages >> ./pbg_ser${TODAY}.log
			echo "16| (l)log_min_error_statement      | ""$j_log_min_error_statement"  "|""$c_log_min_error_statement""|" $log_min_error_statement >> ./pbg_ser${TODAY}.log
			echo "17| (l)log_min_duration_statement   | ""$j_log_min_duration_statement"  "|""$c_log_min_duration_statement""|" $log_min_duration_statement >> ./pbg_ser${TODAY}.log
			echo "18| (l)log_lock_waits               | ""$j_log_lock_waits"  "|""$c_log_lock_waits""|" $log_lock_waits >> ./pbg_ser${TODAY}.log
			echo "19| (l)log_temp_files               | ""$j_log_temp_files"  "|""$c_log_temp_files""|" $log_temp_files >> ./pbg_ser${TODAY}.log
		else
			echo "06| (s)max_wal_size                 | ""$j_max_wal_size"  "|"" $c_max_wal_size""|" $max_wal_size >> ./pbg_ser${TODAY}.log
			echo "07| (s)min_wal_size                 | ""$j_min_wal_size"  "|"" $c_min_wal_size""|" $min_wal_size >> ./pbg_ser${TODAY}.log
			echo "08| (l)checkpoint_completion_target | ""$j_checkpoint_completion_target"  "|""$c_checkpoint_completion_target""|" $checkpoint_completion_target >> ./pbg_ser${TODAY}.log
			echo "09| (s)synchronous_commit           | ""$j_synchronous_commit"  "|""$c_synchronous_commit""|" $synchronous_commit >> ./pbg_ser${TODAY}.log
			echo "10| (s)archive_mode                 | ""$j_archive_mode"  "|""$c_archive_mode""|" $archive_mode >> ./pbg_ser${TODAY}.log
			echo "11| (s)max_wal_senders              | ""$j_max_wal_senders"  "|""$c_max_wal_senders""|" $max_wal_senders >> ./pbg_ser${TODAY}.log
			echo "12| (l)random_page_cost             | ""$j_random_page_cost"  "|""$c_random_page_cost""|" $random_page_cost >> ./pbg_ser${TODAY}.log
			echo "13| (l)effective_cache_size         | ""$j_effective_cache_size"  "|"" $c_effective_cache_size""|" $effective_cache_size >> ./pbg_ser${TODAY}.log
			echo "14| (s)logging_collector            | ""$j_logging_collector"  "|""$c_logging_collector""|" $logging_collector >> ./pbg_ser${TODAY}.log
			echo "15| (l)client_min_messages          | ""$j_client_min_messages"  "|""$c_client_min_messages""|" $client_min_messages >> ./pbg_ser${TODAY}.log
			echo "16| (l)log_min_messages             | ""$j_log_min_messages"  "|""$c_log_min_messages""|" $log_min_messages >> ./pbg_ser${TODAY}.log
			echo "17| (l)log_min_error_statement      | ""$j_log_min_error_statement"  "|""$c_log_min_error_statement""|" $log_min_error_statement >> ./pbg_ser${TODAY}.log
			echo "18| (l)log_min_duration_statement   | ""$j_log_min_duration_statement"  "|""$c_log_min_duration_statement""|" $log_min_duration_statement >> ./pbg_ser${TODAY}.log
			echo "19| (l)log_lock_waits               | ""$j_log_lock_waits"  "|""$c_log_lock_waits""|" $log_lock_waits >> ./pbg_ser${TODAY}.log
			echo "20| (l)log_temp_files               | ""$j_log_temp_files"  "|""$c_log_temp_files""|" $log_temp_files >> ./pbg_ser${TODAY}.log
		fi
		echo "---------------------------------------------------------------------------" >> ./pbg_ser${TODAY}.log
		echo "" >> ./pbg_ser${TODAY}.log
		echo "" >> ./pbg_ser${TODAY}.log
		rm -rf ./pbg_YN.file
	fi		
	if [ "$NF" == "Y" ] || [ "$NF" == "y" ] && [ "$PID" != "temppid" ]
	then 
		rm -rf ./pbg.sql
		cat >> ./pbg.sql << EOFF
\! echo ""
\! echo "---------------------------------------------------------------------------"
SELECT '-'||TO_CHAR(NOW(), 'MM')||'MONTH: '||d.datname||' ('||CASE WHEN pg_catalog.has_database_privilege(d.datname, 'CONNECT')
THEN pg_catalog.pg_size_pretty(pg_catalog.pg_database_size(d.datname))
ELSE 'No	 Access'
END||') ' AS "			     Database Size    		 	   	"
FROM pg_catalog.pg_database d
JOIN pg_catalog.pg_tablespace t on d.dattablespace = t.oid
WHERE d.datname <> 'template0'
AND d.datname <> 'template1'
ORDER BY 1;
\! echo ""
\! echo ""
\! echo "---------------------------------------------------------------------------"
\! echo "                               Database Age"
\! echo "---------------------------------------------------------------------------"
select datname AS "                DB NAEM             ", age(datfrozenxid) as "               AGE                "from pg_database;
\! echo ""
\! echo ""
\! echo "---------------------------------------------------------------------------"
\! echo "                             Tablespace Size"
\! echo "---------------------------------------------------------------------------"
SELECT spcname AS "Name",
pg_catalog.pg_size_pretty(pg_catalog.pg_tablespace_size(oid)) AS "     Size     ",
pg_catalog.pg_tablespace_location(oid) AS "                Location                   "
FROM pg_catalog.pg_tablespace
WHERE spcname <> 'pg_global'
ORDER BY 3;
EOFF
		if [ "$NOP" == "0" ]; then
			chmod 600 ~/.pgpass
			sed -i '$d' ~/.pgpass
			cat >> ~/.pgpass <<EOFF
localhost:$PORT:$DB:$USER:$PWD
EOFF
		fi
		"$SPATH"psql $OPT -c "\i ./pbg.sql" >> ./pbg_ser${TODAY}.log
		if [ "$NOP" == "0" ]; then
			chmod 400 ~/.pgpass
		fi
		cat >> ./yaho.sql << EOFF
\! echo "---------------------------------------------------------------------------"
\! echo "                             Dead Tuple in TABLE"
\! echo "---------------------------------------------------------------------------"
SELECT 
	schemaname AS schema_name,
    relname AS table_name,
	n_live_tup as live_tuple, 
	n_dead_tup as dead_tuple, 
	round ( ( n_dead_tup + 0.000000000000001 ) * 100 / (n_dead_tup + n_live_tup), 2) AS dead_ratio, 
	pg_size_pretty (pg_relation_size(relid)) as size 
FROM pg_stat_user_tables 
WHERE n_live_tup > 0 
ORDER BY dead_ratio DESC;
\! echo "---------------------------------------------------------------------------"
\! echo "                           INDEX UNUSAGE RANGKING"
\! echo "---------------------------------------------------------------------------"
SELECT idstat.schemaname AS schema_name, 
	idstat.relname AS table_name, 
	indexrelname AS index_name, 
	idstat.idx_scan AS times_used, 
	pg_size_pretty(pg_relation_size(idstat.relid)) AS table_size, 
	pg_size_pretty(pg_relation_size(indexrelid)) AS index_size, 
	n_tup_upd + n_tup_ins + n_tup_del as num_writes, 
	indexdef AS definition 
FROM pg_stat_user_indexes AS idstat 
JOIN pg_indexes 
ON indexrelname = indexname 
JOIN pg_stat_user_tables AS tabstat 
ON idstat.relname = tabstat.relname 
WHERE idstat.idx_scan < 200 
AND indexdef !~* 'unique' 
AND pg_relation_size(idstat.indexrelid) > 1048576 
ORDER BY idstat.relname, indexrelname;
EOFF
                cat >> ./yaho2.sql << EOFF
\! echo "---------------------------------------------------------------------------"
\! echo "                           Buffer cache Hit ratio"
\! echo "---------------------------------------------------------------------------"
SELECT datname, 
	blks_read, 
	blks_hit, 
	round((blks_hit+0.0000000000000001::float/(blks_read+blks_hit+1)*100)::numeric, 2) as cachehitratio 
FROM pg_stat_database
WHERE datname <> 'template1' 
AND datname <> 'template0' 
ORDER BY datname, cachehitratio;
EOFF
		NUMM=`"$SPATH"psql $OPT -t -c "SELECT d.datname FROM pg_catalog.pg_database d WHERE d.datname <> 'template1' AND d.datname <> 'template0';" | sed '/^$/d' | wc -l`
		echo "" >> ./pbg_ser${TODAY}.log
		echo "" >> ./pbg_ser${TODAY}.log
		"$SPATH"psql $OPT -c '\i ./yaho2.sql' >> ./pbg_ser${TODAY}.log
		rm -rf ./yaho2.sql
		for (( i=1 ; i <= $NUMM; i++ ))
		do
			DBNM=`"$SPATH"psql $OPT -t -c "SELECT d.datname FROM pg_catalog.pg_database d WHERE d.datname <> 'template1' AND d.datname <> 'template0';" | sed '/^$/d' | head -n $i | tail -n 1`
			DBNM=`echo $DBNM`
			echo "" >> ./pbg_ser${TODAY}.log
			echo "" >> ./pbg_ser${TODAY}.log
			echo "###########################################################################" >> ./pbg_ser${TODAY}.log
			echo "                                 $DBNM" >> ./pbg_ser${TODAY}.log
			echo "###########################################################################" >> ./pbg_ser${TODAY}.log
                        if [ "$WRE" == "trust" ]; then
				ROPT=""
                        else
				ROPT="-w -U $USER -p $PORT"
				if [ "$NOP" == "0" ]; then
					chmod 600 ~/.pgpass
					cat >> ~/.pgpass <<EOFF
localhost:$PORT:$DBNM:$USER:$PWD
EOFF
					chmod 400 ~/.pgpass
				fi
			fi
			"$SPATH"psql $ROPT -d $DBNM -c '\i ./yaho.sql' >> ./pbg_ser${TODAY}.log
                        if [ "$WRE" != "trust" ] || [ "$NOP" == "0" ]
			then
				chmod 600 ~/.pgpass
				sed -i '$d' ~/.pgpass
			fi
		done
		if [ "$NOP" == "0" ]; then
			chmod 600 ~/.pgpass
			sed -i '$d' ~/.pgpass
		fi
		rm -rf ./yaho.sql
		if [ "$NOP" == "0" ]; then
			chmod 400 ~/.pgpass
		fi
		rm -rf ./pbg.sql
	fi
	echo "" >> ./pbg_ser${TODAY}.log
	echo "" >> ./pbg_ser${TODAY}.log
fi

if [ "$VER" == "10" ] || [ "$VER" == "11" ]
then
	LOG_DIRT="$DATA_DIR/log"
else
	LOG_DIRT="$DATA_DIR/pg_log"
fi
echo "-------------------------------------------------------------------"
echo -e "PLEASE TYPE THE LOG directory FULL PATH( default : $LOG_DIRT ) : \c "
read LOG_DIR
if [ "$LOG_DIR" == "" ]; then
	echo ""
	echo "YOU DID'NT TYPE LOG directory. IT WILL BE INSPECT PostgreSQL LOG in CURRENT directory."
	echo "LOG direcoty : $LOG_DIRT"
	echo ""
	if [ "$VER" == "10" ] || [ "$VER" == "11" ]
	then
	        LOG_DIR="$DATA_DIR/log"
	else
	        LOG_DIR="$DATA_DIR/pg_log"
	fi
else 
	echo ""
	echo "YOU TYPE BELOW LOG directory. IT WILL BE INSPECT PostgreSQL LOG in THIS directory."
	echo "LOG direcoty : $LOG_DIR"
	echo ""
fi
ls -ld $LOG_DIR &> /dev/null
if [ "$?" != "0" ]; then
	echo "-------------------------------------------------------------------"
	echo ""
	echo "THERE IS NO LOG_DIR. Please check LOG directory [you set : $LOG_DIR]"
	echo -e "PLEASE TYPE THE LOG directory FULL PATH( default : $LOG_DIRT ) [q is quit]: \c "
	read LOG_DIR
	ls -ld $LOG_DIR &> /dev/null
	while [ "$?" != "0" ]
	do
		echo "-------------------------------------------------------------------"
		echo ""
		echo "THERE IS NO LOG_DIR. Please check LOG directory [you set : $LOG_DIR]"
		echo -e "PLEASE TYPE THE LOG directory FULL PATH( default : $LOG_DIRT ) [q is quit]: \c "
		read LOG_DIR
		if [ "$LOG_DIR" == "q" ] || [ "$LOG_DIR" == "Q" ]
		then
			exit 0
		fi
		ls -ld $LOG_DIR &> /dev/null
	done
fi
LOG_PRE=`ls -rt $LOG_DIR | cut -c 1-2 | uniq -d -c | head -n 1 | awk {'print $2'}`
MAL=`cat $LOG_DIR/$LOG_PRE* 2>/dev/null | grep LOG: | head -n 1`
if [ "$MAL" == "" ]; then
	echo "-------------------------------------------------------------------"
	echo ""
	echo "THERE IS NO LOG in LOG directory. Please check LOG directory [you set : $LOG_DIR]"
	echo -e "PLEASE TYPE THE LOG directory FULL PATH( default : $LOG_DIRT ) [q is quit]: \c "
	read LOG_DIR
	LOG_PRE=`ls -rt $LOG_DIR | cut -c 1-2 | uniq -d -c | head -n 1 | awk {'print $2'}`
	MAL=`cat $LOG_DIR/$LOG_PRE* 2>/dev/null | grep LOG: | head -n 1`
	while [ "$MAL" == "" ]
	do
		echo "-------------------------------------------------------------------"
		echo ""
		echo "THERE IS NO LOG in LOG directory. Please check LOG directory [you set : $LOG_DIR]"
		echo -e "PLEASE TYPE THE LOG directory FULL PATH( default : $LOG_DIRT ) [q is quit]: \c "
		read LOG_DIR
		if [ "$LOG_DIR" == "q" ] || [ "$LOG_DIR" == "Q" ]
		then
			exit 0
		fi
		LOG_PRE=`ls -rt $LOG_DIR | cut -c 1-2 | uniq -d -c | head -n 1 | awk {'print $2'}`
		MAL=`cat $LOG_DIR/$LOG_PRE* 2>/dev/null | grep LOG: | head -n 1`
	done
fi
echo "-------------------------------------------------------------------"
echo ""
echo -e "ENTER THE DATE YOU WANT TO START THE CHECK.(YYYYMMDD): \c "
read START_DATE
CH=`echo $START_DATE | wc -c`
if [ "$CH" == "9" ];then
	r=${START_DATE//[0-9]/}
	if [ -z "$r" ] ; then
	    MON=`echo $START_DATE | cut -c 5-6`
	    DAY=`echo $START_DATE | cut -c 7-8`
	    if [ "12" -ge "$MON" -a "31" -ge "$DAY" ]; then
	    	FAIL=0
	    else
		FAIL=1
	    fi	
	else
	    FAIL=1
	fi	
else
	FAIL=1
fi
touch $LOG_DIR/pbg_err${TODAY}.log
touch $LOG_DIR/pbg_slow${TODAY}.log
touch $LOG_DIR/pbg_temp${TODAY}.log
touch $LOG_DIR/pbg_lock${TODAY}.log
touch ./pbg_lock_temp.sh
echo true >> ./pbg_lock_temp.sh
while [ "$FAIL" == "1" ]
do
	echo ""
	echo -e "The date you entered is not date format. Please retype DATE (If you want quit Enter the q): \c "
	read START_DATE
	if [ "$START_DATE" == "q" ]; then
		exit 0
	fi
	CH=`echo $START_DATE | wc -c`
	if [ "$CH" == "9" ];then
		r=${START_DATE//[0-9]/}
		if [ -z "$r" ] ; then
	    		MON=`echo $START_DATE | cut -c 5-6`
		   	DAY=`echo $START_DATE | cut -c 7-8`
			if [ "12" -ge "$MON" -a "31" -ge "$DAY" ]; then
				FAIL=0
			else
				FAIL=1
			fi	
		else
		    FAIL=1
		fi	
	else
		FAIL=1
	fi
done
END_DATE=`date +%Y%m%d%H%M`
START_DATE=`echo "$START_DATE"0000`
FD=`echo $START_DATE | cut -c 1-8`
SD=`echo $END_DATE | cut -c 1-8`
FD=`date -d "$FD" "+%s"`
SD=`date -d "$SD" "+%s"`
DD=`echo "$SD $FD 86400"|awk '{printf "%.0f", ( $1 - $2 ) / $3}'`

while [ "$START_DATE" -gt "$END_DATE" ]
do
	echo ""
	echo -e "The date you entered is later than the current date. Please retype DATE (If you want quit Enter the q): \c "
	read START_DATE
	if [ "$START_DATE" == "q" ]; then
		exit 0
	fi
done
echo "-------------------------------------------------------------------"
echo ""
touch -t $START_DATE $LOG_DIR/pbgstart.txt
touch -t $END_DATE $LOG_DIR/pbgend.txt
NUM=1
FILE=`ls -rt $LOG_DIR/$LOG_PRE* | head -n $NUM | tail -n 1`
R=`cat $LOG_DIR/$LOG_PRE* | grep LOG: | head -n 1 | sed -e 's;LOG:.*$;;'|awk '{print NF}'`
E=`echo "$R 2"|awk '{printf "%.0f", $1 + $2 }'`
T=`echo "$E 1"|awk '{printf "%.0f", $1 + $2 }'`
W=`echo "$R 9"|awk '{printf "%.0f", $1 + $2 }'`
Q=`echo "$W 2"|awk '{printf "%.0f", $1 + $2 }'`
AN=0
RN=0
AFN=`find $LOG_DIR/* -name "${LOG_PRE}*" | wc -l`
echo "                                               # Shutdown record Report #" >> $LOG_DIR/pbg_sht${TODAY}.log
echo "--------------------┬--------------------------------------------------------------------------------------------------" >> $LOG_DIR/pbg_sht${TODAY}.log
echo " Time of occurrence |                                              reason" >> $LOG_DIR/pbg_sht${TODAY}.log
echo "--------------------┴--------------------------------------------------------------------------------------------------" >> $LOG_DIR/pbg_sht${TODAY}.log
echo "                                                # FATAL record Report #" >> $LOG_DIR/pbg_fatl${TODAY}.log
echo "------┬-------------------┬--------------------------------------------------------------------------------------------" >> $LOG_DIR/pbg_fatl${TODAY}.log
echo " count| Time of occurrence|                                       reason" >> $LOG_DIR/pbg_fatl${TODAY}.log
echo "------┴-------------------┴--------------------------------------------------------------------------------------------" >> $LOG_DIR/pbg_fatl${TODAY}.log
echo "                                                # PANIC record Report #" >> $LOG_DIR/pbg_panic${TODAY}.log
echo "------┬-------------------┬--------------------------------------------------------------------------------------------" >> $LOG_DIR/pbg_panic${TODAY}.log
echo " count| Time of occurrence|                                       reason" >> $LOG_DIR/pbg_panic${TODAY}.log
echo "------┴-------------------┴--------------------------------------------------------------------------------------------" >> $LOG_DIR/pbg_panic${TODAY}.log
echo "                                               # WARNING record Report #" >> $LOG_DIR/pbg_warn${TODAY}.log
echo "------┬-------------------┬--------------------------------------------------------------------------------------------" >> $LOG_DIR/pbg_warn${TODAY}.log
echo " count| Time of occurrence|                                       reason" >> $LOG_DIR/pbg_warn${TODAY}.log
echo "------┴-------------------┴--------------------------------------------------------------------------------------------" >> $LOG_DIR/pbg_warn${TODAY}.log

while [ ${test} $FILE -ot $LOG_DIR/pbgstart.txt ]
do
	NUM=`echo "$NUM 1"|awk '{printf "%.0f", $1 + $2 }'`
	FILE=`ls -rt $LOG_DIR/$LOG_PRE* | head -n $NUM | tail -n 1`
done
while [ ${test} $LOG_DIR/pbgstart.txt -ot $FILE -a ${test} $FILE -ot $LOG_DIR/pbgend.txt ]
do
	RN=`echo "$RN 1"|awk '{printf "%.0f", $1 + $2 }'`
	PN=`echo "$RN 100 $AFN"|awk '{printf "%.0f", $1 * $2 / $3 }'`
	NUM=`echo "$NUM 1"|awk '{printf "%.0f", $1 + $2 }'`
	FILEB=$FILE
	FILE=`ls -rt $LOG_DIR/$LOG_PRE* | head -n $NUM | tail -n 1`
	if [ "$FILE" == "$FILEB" ]; then
		FILE=$LOG_DIR/pbgend.txt
	fi
	while [ ! ${test} -e $LOG_DIR/pbg_temp.file ];
	do
		if [ "$FILE" != "$LOG_DIR/pbgend.txt" ]; then
			FILEE=$FILE
		else
			FILEE=$FILEB
		fi
	        printf 'Inspect '${FILEE}' LOG files......[─]('${PN}'%%)\r';
		sleep 0.05
	        printf 'Inspect '${FILEE}' LOG files......[\\]('${PN}'%%)\r';
		sleep 0.05
	        printf 'Inspect '${FILEE}' LOG files......[|]('${PN}'%%)\r';
		sleep 0.05
	        printf 'Inspect '${FILEE}' LOG files......[/]('${PN}'%%)\r';
		sleep 0.05
	done &
	cat $FILEB | grep ERROR: >> $LOG_DIR/pbg_err${TODAY}.log
        SUN=`cat $FILEB | grep LOG: | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/LOG:/ & /g'| awk '{ num=1; while (index($num,"LOG:")==0) num=num+1; print num }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
	if [ "$SUN" == "" ]; then
		SUN=0
	fi
        RUN=`echo "$SUN 1"|awk '{printf "%.0f", $1 + $2 }'`
	cat $FILEB | grep -A15 duration: |sed 's/FATAL:/ & /gi'|sed 's/PANIC:/ & /gi'|sed 's/WARNING:/ & /gi'|sed 's/LOG:/ & /gi'|sed 's/DETAIL:/ & /gi'|sed 's/STATEMENT:/ & /gi'|sed 's/QUERY:/ & /gi'|sed 's/CONTEXT:/ & /gi'|sed '/^--/d'|sed '/^ --/d'| sed '/^\t$/d'| sed '/^$/d' | sed "s/^\t/;/" | sed "s/^ /;/"  | sed ':a;N;$!ba;s/\n;/ /gi'|awk {'if($'${SUN}'=="LOG:"){if($'${RUN}'=="statement:"){printf "bkbspark "$0} else{printf $0}} else{printf "bkbspark "$0;} print ""'}| sed -e 's/bkbspark.*statement:/bkbspark STATEMENT:/gi'| sed -e 's/bkbspark.*DETAIL:/bkbspark DETAIL:/gi'| sed -e 's/bkbspark.*QUERY:/bkbspark QUERY:/gi'| sed -e 's/bkbspark.*CONTEXT:/bkbspark CONTEXT:/gi'| sed ':a;N;$!ba;s/\nbkbspark//gi'| grep duration: > $LOG_DIR/pbg_slow_temp${TODAY}.log
        SUN=`cat $LOG_DIR/pbg_slow_temp${TODAY}.log | grep duration | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/LOG:/ & /g'| awk '{ num=1; while (index($num,"duration")==0) num=num+1; print num }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
        DUN=`cat $LOG_DIR/pbg_slow_temp${TODAY}.log | grep duration | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/LOG:/ & /g'| awk '{ num=1; while ($num !~ /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) num=num+1; print num }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
        TUN=`cat $LOG_DIR/pbg_slow_temp${TODAY}.log | grep duration | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/LOG:/ & /g'| awk '{ num=1; while ($num !~ /[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$/) num=num+1; print num }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
        NSUN=`echo "$SUN 3"|awk '{printf "%.0f", $1 + $2 }'`
        RUN=`echo "$SUN 1"|awk '{printf "%.0f", $1 + $2 }'`
        cat $LOG_DIR/pbg_slow_temp${TODAY}.log | grep duration: | sort | uniq -i | sort -k$NSUN,100 | awk {'num='${NSUN}'; for(i=num;i<=NF;i++){ if(i==num){printf $'${DUN}'" "$'${TUN}'" "; printf "%.3f", $'${RUN}'/1000;} printf " "$i };printf "\n"'} 2> /dev/null >> $LOG_DIR/pbg_slow${TODAY}.log
        SUN=`cat $FILEB | grep LOG: | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/LOG:/ & /g'| awk '{ num=1; while (index($num,"LOG:")==0) num=num+1; print num }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
	if [ "$SUN" == "" ]; then
		SUN=0
	fi
        RUN=`echo "$SUN 1"|awk '{printf "%.0f", $1 + $2 }'`
	cat $FILEB | grep -A15 "temporary file:" |sed 's/FATAL:/ & /gi'|sed 's/PANIC:/ & /gi'|sed 's/WARNING:/ & /gi'|sed 's/LOG:/ & /gi'|sed 's/DETAIL:/ & /gi'|sed 's/STATEMENT:/ & /gi'|sed 's/QUERY:/ & /gi'|sed 's/CONTEXT:/ & /gi'|sed '/^--/d'|sed '/^ --/d'| sed '/^\t$/d' | sed '/^$/d' | sed "s/^\t/;/"| sed "s/^ /;/" | sed ':a;N;$!ba;s/\n;/ /gi'|awk {'if($'${SUN}'=="LOG:"){if($'${RUN}'=="statement:"){printf "bkbspark "$0} else{printf $0}} else{printf "bkbspark "$0;} print ""'}| sed -e 's/bkbspark.*statement:/bkbspark STATEMENT:/gi'| sed -e 's/bkbspark.*DETAIL:/bkbspark DETAIL:/gi'| sed -e 's/bkbspark.*QUERY:/bkbspark QUERY:/gi'| sed -e 's/bkbspark.*CONTEXT:/bkbspark CONTEXT:/gi'| sed ':a;N;$!ba;s/\nbkbspark//gi'| grep "temporary file:" > $LOG_DIR/pbg_temp_temp${TODAY}.log
        SUN=`cat $LOG_DIR/pbg_temp_temp${TODAY}.log | grep ", size" | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/", size"/ & /g'| awk '{ num=1 ;while ($num!="size") num=num+1; print num }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
        DUN=`cat $LOG_DIR/pbg_temp_temp${TODAY}.log | grep ", size" | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/", size"/ & /g'| awk '{ num=1; while ($num !~ /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) num=num+1; print num }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
        TUN=`cat $LOG_DIR/pbg_temp_temp${TODAY}.log | grep ", size" | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/", size"/ & /g'| awk '{ num=1; while ($num !~ /[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$/) num=num+1; print num }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
        NSUN=`echo "$SUN 2"|awk '{printf "%.0f", $1 + $2 }'`
        RUN=`echo "$SUN 1"|awk '{printf "%.0f", $1 + $2 }'`
        cat $LOG_DIR/pbg_temp_temp${TODAY}.log | grep "temporary file:" | sort -k$NSUN,100 | awk {'num='${RUN}'; for(i=num;i<=NF;i++){ if(i==num){printf $'${DUN}'" "$'${TUN}'" "; printf "%.0f", $'${RUN}'/1048576;} printf " "$i };printf "\n"'} 2> /dev/null >> $LOG_DIR/pbg_temp${TODAY}.log

        SUN=`cat $FILEB | grep "lock:" | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/"DETAIL:"/ & /g'| awk '{ num=1 ;while ($num!="queue:") num=num+1; print num }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
        NSUN=`echo "$SUN 1"|awk '{printf "%.0f", $1 + $2 }'`
        MSUN=`echo "$SUN 3"|awk '{printf "%.0f", $1 + $2 }'`
        ISUN=`echo "$SUN 4"|awk '{printf "%.0f", $1 + $2 }'`
        PSUN=`echo "$SUN 5"|awk '{printf "%.0f", $1 + $2 }'`
        QSUN=`echo "$SUN 6"|awk '{printf "%.0f", $1 + $2 }'`
	cat $FILEB* | grep lock: | awk {'if(""!=$'${MSUN}'&&(""==$'${ISUN}'||""==$'${PSUN}'||""==$'${QSUN}')){print "cat '${FILEB}'* | grep -B1 -A15 \""$0"\""}'} >> pbg_lock_temp.sh
	SUN=`cat $FILEB | grep utdow | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/LOG:/ & /g'| awk '{ num=1; while (index($num,"LOG")==0) num=num+1; print num }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
	DUN=`cat $FILEB | grep utdow | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/LOG:/ & /g'| awk '{ num=1; while ($num !~ /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) num=num+1; print num }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
	TUN=`cat $FILEB | grep utdow | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/LOG:/ & /g'| awk '{ num=1; while ($num !~ /[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$/) num=num+1; print num }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
	NSUN=`echo "$SUN 1"|awk '{printf "%.0f", $1 + $2 }'`
	MSUN=""
	if [ "$SUN" != "" ]; then
		MSUN=`echo "-f $SUN"`
	fi
	cat $FILEB | grep utdow |sed 's/LOG:/ & /g'| sort -k$NSUN,21 | sort -r | awk {'num='${SUN}'; for(i=num;i<=NF;i++){ if(i==num){printf" "$'${DUN}'" "$'${TUN}';} printf " "$i };printf "\n"'} 2> /dev/null >>  $LOG_DIR/pbg_sht${TODAY}.log

	SUN=`cat $FILEB | grep FATAL | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/FATAL:/ & /g'| awk '{ num=1; while (index($num,"FATAL")==0) num=num+1; print num }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
	DUN=`cat $FILEB | grep FATAL | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/FATAL:/ & /g'| awk '{ num=1; while ($num !~ /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) num=num+1; print num + 1 }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
	TUN=`cat $FILEB | grep FATAL | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/FATAL:/ & /g'| awk '{ num=1; while ($num !~ /[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$/) num=num+1; print num + 1 }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
	NSUN=`echo "$SUN 1"|awk '{printf "%.0f", $1 + $2 }'`
	MSUN=""
	if [ "$SUN" != "" ]; then
		MSUN=`echo "-f $SUN"`
	fi
	cat $FILEB | grep FATAL |sed 's/FATAL:/ & /g'| sort -k$NSUN,21| uniq $MSUN -d -c | sort -r | awk {'num='${NSUN}'; for(i=num;i<=NF;i++){ if(i==num){printf ("%-6s",$1);printf" "$'${DUN}'" "$'${TUN}';} printf " "$i };printf "\n"'} 2> /dev/null >>  $LOG_DIR/pbg_fatl${TODAY}.log

	SUN=`cat $FILEB | grep PANIC | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/PANIC:/ & /g'| awk '{ num=1; while (index($num,"PANIC")==0) num=num+1; print num }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
	DUN=`cat $FILEB | grep PANIC | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/PANIC:/ & /g'| awk '{ num=1; while ($num !~ /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) num=num+1; print num + 1 }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
	TUN=`cat $FILEB | grep PANIC | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/PANIC:/ & /g'| awk '{ num=1; while ($num !~ /[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$/) num=num+1; print num + 1 }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
	NSUN=`echo "$SUN 1"|awk '{printf "%.0f", $1 + $2 }'`
	MSUN=""
	if [ "$SUN" != "" ]; then
		MSUN=`echo "-f $SUN"`
	fi
	cat $FILEB | grep PANIC |sed 's/PANIC:/ & /g'| sort -k$NSUN,21| uniq $MSUN -d -c | sort -r | awk {'num='${NSUN}'; for(i=num;i<=NF;i++){ if(i==num){printf ("%-6s",$1);printf" "$'${DUN}'" "$'${TUN}';} printf " "$i };printf "\n"'} 2> /dev/null >>  $LOG_DIR/pbg_panic${TODAY}.log

	SUN=`cat $FILEB | grep WARNING | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/WARNING:/ & /g'| awk '{ num=1; while (index($num,"WARNING")==0) num=num+1; print num }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
	DUN=`cat $FILEB | grep WARNING | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/WARNING:/ & /g'| awk '{ num=1; while ($num !~ /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) num=num+1; print num + 1 }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
	TUN=`cat $FILEB | grep WARNING | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/WARNING:/ & /g'| awk '{ num=1; while ($num !~ /[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$/) num=num+1; print num + 1 }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
	NSUN=`echo "$SUN 1"|awk '{printf "%.0f", $1 + $2 }'`
	MSUN=""
	if [ "$SUN" != "" ]; then
		MSUN=`echo "-f $SUN"`
	fi
	cat $FILEB | grep WARNING |sed 's/WARNING:/ & /g'| sort -k$NSUN,21| uniq $MSUN -d -c | sort -r | awk {'num='${NSUN}'; for(i=num;i<=NF;i++){ if(i==num){printf ("%-6s",$1);printf" "$'${DUN}'" "$'${TUN}';} printf " "$i };printf "\n"'} 2> /dev/null >> $LOG_DIR/pbg_warn${TODAY}.log
	touch $LOG_DIR/pbg_temp.file
	sleep 0.3
	rm -rf $LOG_DIR/pbg_temp.file
done
rm -rf $LOG_DIR/pbgstart.txt
rm -rf $LOG_DIR/pbgend.txt
echo "                                      # Syntax ERROR REPORT #">> $LOG_DIR/pbg_err2${TODAY}.log
echo "-------┬--------------------------------------------------------------------------------------------" >> $LOG_DIR/pbg_err2${TODAY}.log
echo " count |                                     ERROR query" >> $LOG_DIR/pbg_err2${TODAY}.log
echo "-------┴--------------------------------------------------------------------------------------------" >> $LOG_DIR/pbg_err2${TODAY}.log
cat $LOG_DIR/pbg_err${TODAY}.log | cut -d\  -f$E- | sort | uniq -c | sort -nr | awk '{if ($1>='${DD}')print}'>> $LOG_DIR/pbg_err2${TODAY}.log
rm -rf $LOG_DIR/pbg_err${TODAY}.log
mv $LOG_DIR/pbg_err2${TODAY}.log $LOG_DIR/pbg_err${TODAY}.log
cat $LOG_DIR/pbg_slow${TODAY}.log | sort -k 4,100 | uniq -f 3 -i -c | sort -nr | awk {'num=5; for(i=num;i<=NF;i++){ if(i==num){printf ("%7s",$1);printf "  "$2" "$3"  "; printf ("%5s",$4"s");} printf " "$i };printf "\n"'}>> $LOG_DIR/pbg_slow2${TODAY}.log
echo "                                      # Slow QUERY REPORT #"> $LOG_DIR/pbg_slow${TODAY}.log
echo "-------┬-------------------┬------┬--------------------------------------------------------------" >> $LOG_DIR/pbg_slow${TODAY}.log
echo " count | Time of occurrence |  time |                             SLOW query" >> $LOG_DIR/pbg_slow${TODAY}.log
echo "-------┴-------------------┴------┴--------------------------------------------------------------" >> $LOG_DIR/pbg_slow${TODAY}.log
#cat $LOG_DIR/pbg_slow2${TODAY}.log  >> $LOG_DIR/pbg_slow${TODAY}.log
cat $LOG_DIR/pbg_slow2${TODAY}.log | awk '{if ($1>='${DD}')print}' >> $LOG_DIR/pbg_slow${TODAY}.log
rm -rf $LOG_DIR/pbg_slow_temp${TODAY}.log
rm -rf $LOG_DIR/pbg_slow2${TODAY}.log
cat $LOG_DIR/pbg_temp${TODAY}.log | awk {'if(""==$5){print }'} >> $LOG_DIR/pbg_temp_n${TODAY}.log
cat $LOG_DIR/pbg_temp${TODAY}.log | awk {'if(""!=$5){print }'} >> $LOG_DIR/pbg_temp_p${TODAY}.log
cat $LOG_DIR/pbg_temp_n${TODAY}.log | sort | uniq -i -c | sort -nr | awk {'printf ("%7s",$1);printf "  "$2" "$3"  "; printf ("%5s",$4"MB");print ""'}>> $LOG_DIR/pbg_temp2${TODAY}.log
cat $LOG_DIR/pbg_temp_p${TODAY}.log | sort | uniq -i | sort -k5,100 | uniq -f 4 -c | sort -nr | awk {'num=6; for(i=num;i<=NF;i++){ if(i==num){printf ("%7s",$1);printf "  "$2" "$3"   "; printf ("%5s",$4"MB"); } printf " "$i };print ""'}>> $LOG_DIR/pbg_temp2${TODAY}.log
echo "                                      # TEMP QUERY REPORT #"> $LOG_DIR/pbg_temp${TODAY}.log
echo "-------┬-------------------┬------┬--------------------------------------------------------------" >> $LOG_DIR/pbg_temp${TODAY}.log
echo " count | Time of occurrence |  SIZE |                             TEMP query" >> $LOG_DIR/pbg_temp${TODAY}.log
echo "-------┴-------------------┴------┴--------------------------------------------------------------" >> $LOG_DIR/pbg_temp${TODAY}.log
cat $LOG_DIR/pbg_temp2${TODAY}.log | sort -k2,3 >> $LOG_DIR/pbg_temp${TODAY}.log
#cat $LOG_DIR/pbg_temp2${TODAY}.log | sort -k2,3 | awk '{if ($1>='${DD}')print}'>> $LOG_DIR/pbg_temp${TODAY}.log
rm -rf $LOG_DIR/pbg_temp2${TODAY}.log
rm -rf $LOG_DIR/pbg_temp_temp${TODAY}.log
rm -rf $LOG_DIR/pbg_temp_n${TODAY}.log
rm -rf $LOG_DIR/pbg_temp_p${TODAY}.log
sed -i 's/\[/\\[/g' pbg_lock_temp.sh
sed -i 's/\]/\\]/g' pbg_lock_temp.sh
bash pbg_lock_temp.sh >> $LOG_DIR/pbg_lock_temp${TODAY}.log
rm -rf pbg_lock_temp.sh
SUN=`cat $LOG_DIR/pbg_lock_temp${TODAY}.log | grep lock: | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/DETAIL:/ & /g'| awk '{ num=1; while (index($num,"queue:")==0) num=num+1; print num }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
SUN=`echo "$SUN 2"|awk '{printf "%.0f", $1 + $2 }'`
IUN=`echo "$SUN 3"|awk '{printf "%.0f", $1 + $2 }'`
HUN=`echo "$SUN 4"|awk '{printf "%.0f", $1 + $2 }'`
JUN=`echo "$SUN 5"|awk '{printf "%.0f", $1 + $2 }'`
KUN=`echo "$SUN 6"|awk '{printf "%.0f", $1 + $2 }'`
echo "                                            # LOCK QUERY REPORT #"> $LOG_DIR/pbg_lock${TODAY}.log
echo "------------------------------------------------------------------------------------------------------------------------------------------">> $LOG_DIR/pbg_lock${TODAY}.log
echo "┌┬┬┬┬┬┬┬┬┐" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "| |1|2|3|4|5|6|7|8| " >> $LOG_DIR/pbg_lock${TODAY}.log
echo "├┼┼┼┼┼┼┼┼┤  1) Access Share : select" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "|1| | | | | | | |X|   2) Row Share : select for update, select for share" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "├┼┼┼┼┼┼┼┼┤  3) Row Exclusive : DML" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "|2| | | | | | |X|X|   4) Share Update Exclusive : Vacuum, Analyze, Create index concurrently" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "├┼┼┼┼┼┼┼┼┤  5) Share : Create index" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "|3| | | | |X|X|X|X|   6) Share Row Exclusive : session level lock" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "├┼┼┼┼┼┼┼┼┤  7) Exclusive : Parallel Process" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "|4| | | |X|X|X|X|X|   8) Access Exclusive : Alter, Drop, Truncate Table, Reindex, Cluster, Vacuum Full" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "├┼┼┼┼┼┼┼┼┤" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "|5| | |X|X| |X|X|X|" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "├┼┼┼┼┼┼┼┼┤" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "|6| | |X|X|X|X|X|X|" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "├┼┼┼┼┼┼┼┼┤" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "|7| |X|X|X|X|X|X|X|" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "├┼┼┼┼┼┼┼┼┤" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "|8|X|X|X|X|X|X|X|X|" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "└┴┴┴┴┴┴┴┴┘" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "--------------------┬--------------------┬------------------------------┬--------------------------------------------------------------" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "        KIND        |  Time of occurrence |               queue           |                              query" >> $LOG_DIR/pbg_lock${TODAY}.log
echo "--------------------┴--------------------┴------------------------------┴--------------------------------------------------------------" >> $LOG_DIR/pbg_lock${TODAY}.log
LUN=`cat $LOG_DIR/pbg_lock_temp${TODAY}.log | grep DETAIL: | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/DETAIL:/ & /g'| awk '{ num=1; while (index($num,"DETAIL:")==0) num=num+1; print num }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
if [ "$LUN" == "" ]; then
	LUN=0
fi
GUN=`echo "$LUN 13"|awk '{printf "%.0f", $1 + $2 }'`
OUN=`echo "$LUN 1"|awk '{printf "%.0f", $1 + $2 }'`
cat $LOG_DIR/pbg_lock_temp${TODAY}.log |sed 's/LOG:/ & /g'|sed 's/FATAL:/ & /g'|sed 's/WARING:/ & /g'|sed 's/PANIC:/ & /g'|sed 's/DETAIL:/ & /g'|sed 's/STATEMENT:/ & /g'|sed 's/QUERY:/ & /g'|sed 's/CONTEXT:/ & /g'|sed '/^--/d'|sed '/^ --/d' | sed '/^\t$/d' | sed '/^$/d' | sed "s/^\t/;/" | sed "s/^ /;/" | sed ':a;N;$!ba;s/\n;/ /gi' |sed 's/"LOG:.*acquired.*Lock"//g'| sed '{s/^.*waiting for //gi}'| sed '{s/Lock on.*$/Lock bkbspark/g}'|sed -e '/bkbspark$/N;s/bkbspark\n/bkbspark /g' | awk {'if($'${SUN}'=="queue:" && $'${IUN}'!="" && $'${KUN}'==""){num=3;if($'${HUN}'!= ""){if($'${JUN}'!= ""){for(i=num;i<=NF;i++){printf $i" ";} printf $1; print "";}else{for(i=num;i<=NF;i++){printf $i" ";} printf "bkbspark "$1; print "";}} else{for(i=num;i<=NF;i++){printf $i" ";} printf "bkbspark bkbspark "$1;print "";}} else{print $0;}'}|awk {'if($'${LUN}'=="DETAIL:"||$'${LUN}'=="LOG:"||$'${LUN}'=="FATAL:"||$'${LUN}'=="PANIC:"||$'${LUN}'=="WARNING:"||index($1,"Lock")!=0){printf $0} else{printf "bkbspark "$0} print ""'}| sed -e 's/bkbspark.*statement:/bkbspark STATEMENT:/gi'| sed -e 's/bkbspark.*QUERY:/bkbspark QUERY:/gi'| sed -e 's/bkbspark.*CONTEXT:/bkbspark CONTEXT:/gi'| sed ':a;N;$!ba;s/\nbkbspark//gi' | awk {'if(index($1,"Lock")==0 && $'${LUN}'=="DETAIL:" && index($'${GUN}',"Lock")!=0){for(i=1;i<=NF;i++){printf $i" ";} print ""}'}> $LOG_DIR/pbg_lock_temp2${TODAY}.log
SUN=`cat $LOG_DIR/pbg_lock_temp2${TODAY}.log | grep lock: | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/lock:/ & /g'| awk '{ num=1; while (index($num,"queue:")==0) num=num+1; print num }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
DUN=`cat $LOG_DIR/pbg_lock_temp2${TODAY}.log | grep lock: | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/lock:/ & /g'| awk '{ num=1; while ($num !~ /[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]$/) num=num+1; print num }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
TUN=`cat $LOG_DIR/pbg_lock_temp2${TODAY}.log | grep lock: | sed 's/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]/ & /g'| sed 's/[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/ & /g'|sed 's/lock:/ & /g'| awk '{ num=1; while ($num !~ /[0-9][0-9]:[0-9][0-9]:[0-9][0-9]$/) num=num+1; print num }'| sort | uniq -c | sort -r | head -n 1 | awk {'print $2'}`
if [ "$SUN" == "" ]; then
	SUN=0
fi
EUN=`echo "$SUN 1"|awk '{printf "%.0f", $1 + $2 }'`
QUN=`echo "$SUN 2"|awk '{printf "%.0f", $1 + $2 }'`
WUN=`echo "$SUN 3"|awk '{printf "%.0f", $1 + $2 }'`
HUN=`echo "$SUN 4"|awk '{printf "%.0f", $1 + $2 }'`
JUN=`echo "$SUN 5"|awk '{printf "%.0f", $1 + $2 }'`
RUN=`echo "$SUN 6"|awk '{printf "%.0f", $1 + $2 }'`
IUN=`echo "$SUN 7"|awk '{printf "%.0f", $1 + $2 }'`
sed -i "s/bkbspark/bkbsp/g" $LOG_DIR/pbg_lock_temp2${TODAY}.log
cat $LOG_DIR/pbg_lock_temp2${TODAY}.log |awk {'if (index($'${SUN}',"queue:")!=0){printf $0; print""} else{print ""}'}|sed '/^$/d' | sort | uniq -i | sort -k$EUN,$JUN | awk {'printf ("%-21s",$'${RUN}');printf " "$'${DUN}'" "$'${TUN}'"   "; printf ("%-6s",$'${EUN}');printf ("%-6s",$'${QUN}');printf ("%-6s",$'${WUN}');printf ("%-6s",$'${HUN}');printf ("%-6s",$'${JUN}');printf " "; num='${IUN}' ;printf " ";for(i=num;i<=NF;i++){printf $i" ";}print "";'} | sed 's/bkbsp/     /g'|awk {'if($5!=""){printf $0;} print ""'}|sed '/^$/d' >> $LOG_DIR/pbg_lock${TODAY}.log
rm -rf $LOG_DIR/pbg_lock_temp2${TODAY}.log
rm -rf $LOG_DIR/pbg_lock_temp${TODAY}.log
BKN=25
NQ=START
while [ "$NQ" != "" ];
do
	BQ=$NQ
	BKN=`echo "$BKN 1"|awk '{printf "%.0f", $1 + $2 }'`
	NQ=`cat $LOG_DIR/pbg_lock${TODAY}.log | sed -n ''${BKN}'p' |awk {'print $4'}| sed -e 's/\.$//'| sed -e 's/,$//'`
	if [ "$BQ" != "START" ]; then
		if [ "$BQ" != "$NQ" ]; then
			sed -i -e ''${BKN}' i\------------------------------------------------------------------------------------------------------------------------------------------' $LOG_DIR/pbg_lock${TODAY}.log
			BKN=`echo "$BKN 1"|awk '{printf "%.0f", $1 + $2 }'`
		fi
	fi
done

echo ""
echo ""
echo "-------------------------------------------------------------------"
echo ""
echo "Inspect is FINISH. Please check RESULT, blow files."
echo "pbg_err${TODAY}.log   : Reports the occurrence of Syntax ERR"
echo "pbg_slow${TODAY}.log  : Reports the frequency of the SLOW QUERY and the longest time."
echo "pbg_temp${TODAY}.log  : Reports the usage history of TEMP FILE."
echo "pbg_lock${TODAY}.log  : Reports the occurrence of LOCK."
echo "pbg_sht${TODAY}.log   : Reports the occurrence of SHUTDOWN"
echo "pbg_warn${TODAY}.log  : Reports the occurrence of WARNING."
echo "pbg_panic${TODAY}.log : Reports the occurrence of PANIC."
echo "pbg_fatl${TODAY}.log  : Reports the occurrence of FATAL."
echo "pbg_ser${TODAY}.log   : Reports TOTAL ( include Server resource )"
echo ""
echo "-------------------------------------------------------------------"
mv $LOG_DIR/pbg_err${TODAY}.log ./ 
mv $LOG_DIR/pbg_slow${TODAY}.log ./ 
mv $LOG_DIR/pbg_temp${TODAY}.log ./ 
mv $LOG_DIR/pbg_lock${TODAY}.log ./ 
mv $LOG_DIR/pbg_sht${TODAY}.log ./ 
mv $LOG_DIR/pbg_fatl${TODAY}.log ./ 
mv $LOG_DIR/pbg_panic${TODAY}.log ./ 
mv $LOG_DIR/pbg_warn${TODAY}.log ./ 
cat ./pbg_err${TODAY}.log >> ./pbg_ser${TODAY}.log 
echo "" >> ./pbg_ser${TODAY}.log
echo "" >> ./pbg_ser${TODAY}.log
echo "" >> ./pbg_ser${TODAY}.log
cat ./pbg_slow${TODAY}.log >> ./pbg_ser${TODAY}.log 
echo "" >> ./pbg_ser${TODAY}.log
echo "" >> ./pbg_ser${TODAY}.log
echo "" >> ./pbg_ser${TODAY}.log
cat ./pbg_temp${TODAY}.log >> ./pbg_ser${TODAY}.log 
echo "" >> ./pbg_ser${TODAY}.log
echo "" >> ./pbg_ser${TODAY}.log
echo "" >> ./pbg_ser${TODAY}.log
cat ./pbg_lock${TODAY}.log >> ./pbg_ser${TODAY}.log 
echo "" >> ./pbg_ser${TODAY}.log
echo "" >> ./pbg_ser${TODAY}.log
echo "" >> ./pbg_ser${TODAY}.log
cat ./pbg_sht${TODAY}.log >> ./pbg_ser${TODAY}.log 
echo "" >> ./pbg_ser${TODAY}.log
echo "" >> ./pbg_ser${TODAY}.log
echo "" >> ./pbg_ser${TODAY}.log
cat ./pbg_fatl${TODAY}.log >> ./pbg_ser${TODAY}.log 
echo "" >> ./pbg_ser${TODAY}.log
echo "" >> ./pbg_ser${TODAY}.log
echo "" >> ./pbg_ser${TODAY}.log
cat ./pbg_panic${TODAY}.log >> ./pbg_ser${TODAY}.log 
echo "" >> ./pbg_ser${TODAY}.log
echo "" >> ./pbg_ser${TODAY}.log
echo "" >> ./pbg_ser${TODAY}.log
cat ./pbg_warn${TODAY}.log >> ./pbg_ser${TODAY}.log
echo "" >> ./pbg_ser${TODAY}.log
echo "" >> ./pbg_ser${TODAY}.log
echo "" >> ./pbg_ser${TODAY}.log
rm -rf ./pbg_YN.file
exit 0
