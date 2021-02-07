#!/bin/bash
#$ -N root-tree
#$ -t 1-298
#$ -o ../job_output/$JOB_NAME-$JOB_ID-$TASK_ID.log
#$ -j y
#$ -l m_mem_free=4G


Rscript --vanilla root_tree.R -y 2012 -i $SGE_TASK_ID