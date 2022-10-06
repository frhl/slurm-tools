
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

# delete a job in the queue waiting to be submitted
sdel_pd_group () {
  local reason=${1?Error: arg1 (grep_reason)}
  local uid=$(getuser)
  local jids=$(squeue -o "%i %u %a %t %D %R" | \
     awk -v user="${uid}" ' $2==user && $3=="lindgren.prj" && $4=="PD"' | \
     grep "${reason}" | \
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
  sdel_pd_group "(DependencyNeverSatisfied)"
}

sdel_priority_jobs() {
  sdel_pd_group "(DependencyNeverSatisfied)"
}

sdel_dependency_jobs() {
  sdel_pd_group "(Dependency)"
}

# good overview on finished jobs
seff () {
  sacct --format="JobID,JobName%10,Partition,NodeList,Elapsed,AllocCPUS,REQMEM,TotalCPU,State,AllocTRES%64,maxRSS,MaxVMSize"
}

# start interactive session on BMRC
sinit () {
  srun -p short --pty bash
}



