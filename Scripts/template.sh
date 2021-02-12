#!/bin/bash

## ---------------------------------------------------------------------------
## This will launch trinity for all samples listed in a fastq.list file.
## Trinity is run 3 parts
## Authors: Tracy Chew, Andrey Bliznyuk, Rika Kobayashi
## Suggested acknowledgement: "The authors acknowledge the scientific and/or technical 
## assistance of Tracy Chew of the Sydney Informatics Hub at the University of Sydney 
## and use of the National Computational Infrastructure facility."
## ---------------------------------------------------------------------------
## list of fastq files, which can be created by: readlink -f *fq.gz | sort -V | xargs -n 2 | cat -n > test_fastq.list
## ---------------------------------------------------------------------------

# Copy this script into the base directory of project and edit as appropriate

# Set variables
project= <project>
list= <fastq.list>
seqtype= <seqtype>

io=$PWD
script=${io}/Scripts
resources=${io}/resources
logs=${io}/Logs/test_fastq

# Resource requests for steps 2 and 3. If the initial step (which will
# run through to the end of chrysalis) is likely to be very large (for
# instance using the hugemem queue), edit the qsub submission below.
cpu_per_node=48
mem_per_node=190
jobfs_per_node=400

echo "CPUs per node: ${cpu_per_node}, mem per node: ${mem_per_node}"
echo "JobFS per node: ${jobfs_per_node}"

num_pairs=$(grep -c -v '^$' ${list})

mkdir -p ${logs}

# Loop through each line of fastq.list, and submit all trinity jobs. Trinity 2-3 will only start
# when the previous part has run successfully
for i in $(seq 1 ${num_pairs}); do
	# Extracts "tissue" name from filename - change to suit your samples
	tissue=$(basename -- "$(awk -v taskID=$i '$1==taskID {print $2}' ${list})" | cut -d _ -f 1 | cut -d . -f 1)
	out=${io}/Trinity/${tissue}
	
	echo `date` ": STARTING TRINITY FOR ${tissue}"
	# trinity_1.pbs
	echo `date` ": Launching Trinity Part 1"
	qsub \
	    -v input="${i}",seqtype="${seqtype}",out="${out}",list="${list}",tissue="${tissue}",resources="${resources}",cpu_per_node="${cpu_per_node}",jobfs_per_node="${jobfs_per_node}",mem_per_node="${mem_per_node}",project="${project}",script="${script}",logs="${logs}",io="${io}" \
	    -N ${tissue}_1 \
	    -P ${project} \
	    -l wd,ncpus=48,mem=190GB,walltime=24:00:00,jobfs=400GB \
	    -W umask=022 \
	    -l storage=scratch/${project} \
	    -q normal \
	    -o ${logs}/${tissue}_job1.o \
	    -e ${logs}/${tissue}_job1.e \
	    ${script}/trinity_1_fb.pbs
	
done
