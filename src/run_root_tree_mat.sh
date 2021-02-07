#!/bin/bash
#$ -N root-tree-mat
#$ -t 1
#$ -o ../job_output/$JOB_NAME-$JOB_ID-$TASK_ID.log
#$ -j y
#$ -l m_mem_free=12G


Rscript --vanilla root_tree_mat.R -y 2012 -i $SGE_TASK_ID