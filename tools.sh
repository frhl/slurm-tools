
# get user-id (could also be retreived from USER variable)
getuser () {
    echo "$( id | tr " " "\n" | grep uid | grep -oP '\(\K[^\)]+' )"
  }

# get a nice overview of the queue
gimmeq () {
  local uid=$(getuser)
  squeue -o "%.18i %.9P %.8j %.8u %.2t %.10M  %C  %.6D %R %.8p" | \
    awk -v user="${uid}" 'NR == 1 || $4==user'
}

# get a nice overview of the queue
gimmelq () {
  local uid=$(getuser)
  squeue -o "%.18i %.9P %.40j %.8u %.2t %.10M  %C  %.6D %R %.8p" | \
    awk -v user="${uid}" 'NR == 1 || $4==user' 
}

# get truncated overview
gimmeqt () {
  local _tmp=$(mktemp)
  local _n=${1:-5}
  gimmelq > ${_tmp}
  cat ${_tmp} | head -n 1 | column -t
  cat ${_tmp} | grep -w R | column -t
  cat ${_tmp} | tail -n +2 | grep -vw R | head -n ${_n} | column -t
  local n_waiting=$(cat ${_tmp} | grep -vw R | wc -l )
  local n_hidden=$((${n_waiting}-${_n}))
  if [ "${n_hidden}" -gt "0" ]; then
    echo "... ${n_hidden} file(s) waiting in queue."
  fi
  rm ${_tmp}
}

# What fraction of CPUs are we using
slurm_usage_lindgren() {
  sreport -t percent -T ALL cluster AccountUtilizationByUser | grep lindgren | grep cpu
}

slurm_usage_global() {
   sreport -p -t percent -T ALL cluster AccountUtilizationByUser | grep cpu | awk -F"|" '$3 != ""' | sed 's/ /-/g'
}

slurm_usage() {
  slurm_usage_global | tr "|" "\t" | sed 's/\%//g' | sort -n -k6 | awk '$6=$6"%"' | column -t | grep --color "${USER}\|$"
}


# what fraction of nodes are you using? 
hownaughtyami () {
  local ntotal=$( squeue | wc -l)
  local utotal=$( gimmeq | wc -l)
  echo "scale=2 ; $utotal / $ntotal" | bc
}


# delete a job by its jobname using regex
sdel_by_name_grep () {
  local string=${1?Error: arg1 (string)}
  local uid=$(getuser)
  local jids=$( squeue -o "%i %u %a %t %D %R %n %j" | \
    awk -v user="${uid}" ' $2==user && $3=="lindgren.prj"' | \
    cut -d" " -f1,8 | \
    grep "${string}" | \
    cut -d" " -f1 | \
    cut -d"_" -f1 |  \
    paste -s -d ',' | \
    sed '$s/ $/\n/')
  local n=$( echo ${jids} | tr "," "\n" | wc -l)
  if [ "${n}" -gt "0" ] && [ ! -z "${jids}" ] ; then
    echo "Deleting ${n} jobs with regex-string match "${string}" (${uid})."
    scancel ${jids}
  else
    echo "No jobs matching regex/string: "${string}" (${uid})."
  fi

}



sdel_by_partition () {
  local string=${1?Error: arg1 (string)}
  local uid=$(getuser)
  local jids=$( squeue -o "%i %u %a %t %D %R %n %j %P" | \
    awk -v user="${uid}" ' $2==user && $3=="lindgren.prj"' | \
    cut -d" " -f1,9 | \
    grep -w "${string}" | \
    cut -d" " -f1 | \
    cut -d"_" -f1 |  \
    paste -s -d ',' | \
    sed '$s/ $/\n/')
  local n=$( echo ${jids} | tr "," "\n" | wc -l)
  if [ "${n}" -gt "0" ] && [ ! -z "${jids}" ] ; then
    echo "Deleting ${n} jobs on queue: "${string}" (${uid})."
    scancel ${jids}
  else
    echo "No queue matching regex/string: "${string}" (${uid})."
  fi

}


# delete a job in the queue waiting to be submitted
sdel_pd_group () {
  local reason=${1?Error: arg1 (grep_reason)}
  local uid=$(getuser)
  local jids=$(squeue -o "%i %u %a %t %D %R" | \
     awk -v user="${uid}" ' $2==user && $3=="lindgren.prj" && $4=="PD"' | \
     grep -E "${reason}" | \
     cut -d" " -f1 | \
     cut -d"_" -f1 |  \
     paste -s -d ',' | \
     sed '$s/ $/\n/')
  local n=$( echo ${jids} | tr "," "\n" | wc -l)
  if [ "${n}" -gt "0" ] && [ ! -z "${jids}" ] ; then
    echo "Deleting ${n} jobs with reason: ${reason} (${uid})."
    scancel ${jids}
  else
    echo "No jobs with reason: ${reason} (${uid})."
  fi
}

sdel_failed_jobs() {
  sdel_pd_group "(DependencyNeverSatisfied)|(launch failed requeued held)"
}


sdel_priority_jobs() {
  sdel_pd_group "(DependencyNeverSatisfied)"
}

sdel_dependency_jobs() {
  sdel_pd_group "(Dependency)"
}

# good overview on finished jobs
seff () {
  sacct --format="JobID,JobName%20,Partition,NodeList,Elapsed,AllocCPUS,REQMEM,TotalCPU,State,AllocTRES%64,maxRSS,MaxVMSize"
}

# start interactive session on BMRC
sinit () {
  srun -p short --pty bash
}



