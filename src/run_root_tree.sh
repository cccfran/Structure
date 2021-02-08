#!/bin/bash
#$ -N tree
#$ -o ../job_output/$JOB_NAME-$JOB_ID.log
#$ -j y
#$ -l m_mem_free=10G

group_size=10000

for year in {1999..2020}
do
	taskname="tree-$year"
    file="../output_hpcc/roots_$year.csv"
    num_line=$(wc -l $file | awk '{print $1}')
    nrun=$(((num_line / group_size)+1))
    echo $nrun
	qsub -q short.q -N $taskname -t 1-$nrun -o '../job_output/$JOB_NAME-$JOB_ID-$TASK_ID.log' -j y -b y "Rscript --vanilla root_tree.R -g $group_size -i \${SGE_TASK_ID} --year=$year"
done