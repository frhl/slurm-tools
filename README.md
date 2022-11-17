# slurm-tools

if you are not on the BMRC clone the repo and add the following to your ~/.bash_profile. Otherwise you can add the code below, and run it directly.
```
# add to ~/.bash_profile
source "/well/lindgren/flassen/ressources/slurm-tools/tools.sh"
source "/well/lindgren/flassen/ressources/slurm-tools/qtools.sh"
```


### Nice overview of what is running on slurm queue
```
gimmeqt
```

### Delete failed jobs on slurm queue
```
sdel_failed_jobs
```

### Delete jobs by name using regex on slurm queue
```
sdel_by_name_grep
```

### Monitor lindgren lab usage on slurm queue
```
slurm_usage
```

