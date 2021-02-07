#!/bin/bash
#$ -N ais-2
#$ -t 1-100
#$ -o ../job_output/$JOB_NAME-$JOB_ID-$TASK_ID.log
#$ -j y
#$ -l m_mem_free=16G


Rscript --vanilla ais_in_net_pairs.R -y 2012 -i $SGE_TASK_ID -n 25