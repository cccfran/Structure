#!/bin/bash
#$ -N root-tree
#$ -t 1999-2020
#$ -o ../job_output/$JOB_NAME-$JOB_ID-$TASK_ID.log
#$ -j y
#$ -l m_mem_free=10G


Rscript --vanilla extract_tree_root.R -y $SGE_TASK_ID