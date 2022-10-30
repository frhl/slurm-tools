

# From https://stackoverflow.com/questions/26104116/qstat-and-long-job-names
qstatl () {

 qstat -xml | tr '\n' ' ' | sed 's#<job_list[^>]*>#\n#g' \
  | sed 's#<[^>]*>##g' | grep " " | column -t

}

# Show a trunated and pretty version of qsub
qstatt () {
  local _tmp=$(mktemp)
  local _n=${1:-5}
  qstatl > ${_tmp}
  cat ${_tmp} | grep -w r | column -t
  cat ${_tmp} | grep -vw r | head -n ${_n} | column -t
  local n_waiting=$(cat ${_tmp} | grep -vw r | wc -l )
  local n_hidden=$((${n_waiting}-${_n}))
  if [ "${n_hidden}" -gt "0" ]; then
    echo "... ${n_hidden} file(s) waiting in queue."
  fi
  rm ${_tmp}
}






