# Gadi-Trinity 

## Description 

This repository contains a staged Trinity workflow that can be run on the National Computational Infrastructure’s (NCI) Gadi supercomputer. Trinity performs de novo transcriptome assembly of RNA-seq data by combining three independent software modules Inchworm, Chrysalis and Butterfly to process RNA-seq reads. The algorithm can detect isoforms, handle paired-end reads, multiple insert sizes and strandedness. For more information see the [Trinity user guide](https://github.com/trinityrnaseq/trinityrnaseq/wiki).

The Gadi-Trinity workflow leverages multiple nodes on NCI Gadi to run a number of Butterfly processes in parallel. This workflow is suitable for single sample and global assemblies of genomes < 2 Gb. 
<br />
<br />

<img src="https://github.com/Sydney-Informatics-Hub/Gadi-Trinity/blob/eda0a74bc0bee446bc84a13411fecfc2be734521/trinity_gadi_process.png" width="100%" height="100%">
<br />
<br />

## Set up 

This repository contains all scripts and software required to run Gadi-Trinity. Before running this workflow, you will need to do the following: 

1. Clone the Gadi-Trinity repository from github (see ‘Installation’ below)
2. Prepare the module archive by running `create-apps.sh` from the `resources` directory (See 'Software requirements' below)
3. Copy the template submission script `Scripts/template.sh` into the project directory and edit for the project. Give it a meaningful name. 
4. Make a list of fastq files to be submitted (See ‘Input’ below)
5. Edit key input variables in `template.sh` (See ‘Input’ below)
    - project= (er00) 
    - list= (path/to/fastq/list)
    - seqtype= (fq or fa)
    - tissue= make sure this pulls the correct field from your fq file name

### Installation 

Clone the trinity-NCI-Gadi repository to your project’s scratch directory 

    module load git 
    git clone https://github.com/Sydney-Informatics-Hub/Gadi-Trinity.git 

### Software requirements 

Trinity requires the following software to be installed and loaded as modules from apps already installed on Gadi. A module archive of these software is created by running `create-apps.sh` in the resources directory. 

trinity/2.9.1 \
bowtie2/2.3.5.1 \
samtools/1.10 \
salmon/1.1.0 \
python2/2.7.17 \
jellyfish/2.3.0 

### Input 

A plain text file containing a list of input fastq files is required input. In this file, each row corresponds to 1 sample. Each row consists of column 1: incremental number (for job array), column 2: read 1 name and column 3: read 2 name. This file can be created by running the following from the directory containing your fastq files: 

    readlink -f *.fastq.gz | sort -V | xargs -n 2 | cat -n > fastq.list

You will also need to edit key input variables in ‘set variables’ in `template.sh` that are required to run Trinity:
- project= (er00)
- list= (fastqlist.txt) 
- seqtype= (fq)
<br />

## Usage 

### Overview 

To manage the data-intensive computation of Trinity, each job utilises `/jobfs`, requiring jobs to be copied between file systems on Gadi. 

Once you have made the `fastq.list` and set the variables in `template.sh` simply run the workflow by: 

    sh template.sh 

`template.sh` runs Trinity in 3 phases (Trinity_1-3_fb.pbs), each being launched as an independent PBS script. 

- `trinity_1_fb.pbs`: clusters inchworm contigs with Chrysalis and maps reads. Stops before the parallel assembly of clustered reads 
- `trinity_2_fb.pbs`: assembles clusters of reads using Inchworm, Chrysalis and Butterfly. Chrysalis and Butterfly can be executed in parallel, each having independent input and output. This is the distributed part of the workflow. 
- `trinity_3_fb.pbs`: final assembly. Harvests all assembled transcripts into a single multi-fasta file. 

[HPC usage report scripts](https://github.com/Sydney-Informatics-Hub/HPC_usage_reports) are provided at the SIH repository for users to evaluate the KSU, walltime and resource consumption and efficiency of their job submissions. These scripts gather job request metrics from Gadi log files. To use, run all scripts from within the directories containing log files to be read.
<br />

### Resource usage 

The Trinity pipeline consists of a series of executables launched with a single command. Each of these stages have different compute resource requirements depending on the stage of the pipeline. The initial stages of the workflow (Inchworm and Chrysalis) are data-intensive and require high memory per core and the latter stages are scalable, embarrassingly parallel, single core jobs. General computing requirement recommendation from Trinity is ~1 Gb of RAM per ~1 M pairs of Illumina sequence reads.

The distributed part of the workflow is unlikely to require significant jobfs or memory resources. However, the initial phase of the workflow may need to run on the hugemem nodes. If this is the case, edit the qsub definition at the bottom of the `template.sh` script. As there are some serial bottlenecks in the first part of the workflow, reducing the requested resources may improve the 'efficiency' of the calculation. For instance half of a hugemem node (24 cores, 750 GB memory, 700 GB jobfs) may be sufficient for a larger assembly. Memory and jobfs requirements to process samples are sufficiently serviced with NCI Gadi’s normal nodes (48 CPUs, 400 Gb of /jobfs disk space).
<br />

### Benchmarking metrics 

The following benchmarking metrics were obtained using stem rust (_Puccinia graminis_) datasets with a genome size of ~170 Mb. Each of these were run on Gadi’s normal nodes (48 CPUs, 400 Gb of /jobfs disk space). 
<br />
<br />
**Wheat stem rust**

| Job                | CPUs | Mem      | CPUtime   | Walltime_used | JobFS_used | Efficiency | Service_units |
|--------------------|------|----------|-----------|---------------|------------|------------|---------------|
| trinity_1.pbs      | 48   | 182.49GB | 68:27:15  | 2:59:16       | 193.35GB   | 0.48       | 286.83        |
| trinity_2_fb_0.pbs | 48   | 80.33GB  | 115:52:10 | 2:33:03       | 19.89GB    | 0.95       | 244.88        |
| trinity_2_fb_1.pbs | 48   | 17.42GB  | 18:51:03  | 0:26:00       | 243.04MB   | 0.91       | 41.6          |
| trinity_3.pbs      | 48   | 5.14GB   | 0:00:12   | 0:01:26       | 267.1MB    | 0          | 2.29          |
| __Total__              |      |          |           | 5:33:45       |            |            | 576           |


**Rye rust**

| Job                | CPUs | Mem      | CPUtime  | Walltime_used | JobFS_used | Efficiency | Service_units |
|--------------------|------|----------|----------|---------------|------------|------------|---------------|
| trinity_1.pbs      | 48   | 182.26GB | 23:37:52 | 2:51:09       | 182.89GB   | 0.52       | 273.84        |
| trinity_2_fb_0.pbs | 48   | 66.32GB  | 21:48:17 | 2:05:58       | 19.73GB    | 0.93       | 201.55        |
| trinity_2_fb_1.pbs | 48   | 25.09GB  | 1:51:32  | 0:02:51       | 61.87MB    | 0.82       | 4.56          |
| trinity_3.pbs      | 48   | 4.39GB   | 0:00:08  | 0:00:16       | 192.7MB    | 0.01       | 0.43          |
| __Total__              |      |          |          | 4:57:23       |            |            | 480           |

**Scabrum rust**

| Job                | CPUs | Mem      | CPUtime  | Walltime_used | JobFS_used | Efficiency | Service_units |
|--------------------|------|----------|----------|---------------|------------|------------|---------------|
| trinity_1.pbs      | 48   | 141.51GB | 37:21:15 | 1:46:16       | 111.15GB   | 0.44       | 170.03        |
| trinity_2_fb_0.pbs | 48   | 53.1GB   | 99:12:17 | 2:12:50       | 11.39GB    | 0.93       | 212.53        |
| trinity_2_fb_1.pbs | 48   | 20.24GB  | 11:01:19 | 0:15:38       | 185.78MB   | 0.88       | 25.01         |
| trinity_3.pbs      | 48   | 4.54GB   | 0:00:08  | 0:00:13       | 233.19MB   | 0.01       | 0.35          |
| __Total__              |      |          |          | 3:59:19       |            |            | 408           |
<br />

### Additional notes 

* Trinity’s running time is exponentially related to the number of de Bruijn graph branches created. Given walltime limitations on Gadi, the Gadi-Trinity workflow is not recommended for use on genomes >2 Gb. For larger single sample and global assemblies, we recommend the [Flashlite-Trinity workflow](https://github.com/Sydney-Informatics-Hub/Flashlite-Trinity) that runs Trinity on the University of Queensland’s HPC, Flashlite. 

* All work is performed local to the node in `/jobfs` or in `/dev/shm`. 

* At the end of `trinity_1_fb.pbs`, a single tar file containing the full Trinity output directory is copied back to network storage. This will be >100 Gb.

* Each task running `trinity_2_fb.pbs` works on a single file bin representing ~100,000 tasks. Only the recursive_trinity.cmds and the relevant data from read_partitions are copied to the node. The full read_partitions directory is archived and pushed back to network storage at the end of processing. This will be up to 10 Gb.

* In `trinity_3_fb.pbs`, only the fasta files from the distributed step are copied to the node. Only the full assembly is copied back.  

* The `sort-recursive.py` script is run by `trinity_2_fb.pbs`. It will sort the recursive commands to run on input files based on their size (largest to smallest). This is included to avoid long running, single CPU jobs from holding up a whole node. It improves overall job efficiency. 

# Acknowledgements
Acknowledgements (and co-authorship, where appropriate) are an important way for us to demonstrate the value we bring to your research. Your research outcomes are vital for ongoing funding of the Sydney Informatics Hub and national compute facilities.

### Authors 

- Tracy Chew (Sydney Informatics Hub, University of Sydney)
- Georgina Samaha (Sydney Informatics Hub, University of Sydney)
- Rosemarie Sadsad (Sydney Informatics Hub, University of Sydney)
- Andrey Bliznyuk (National Computational Infrastructure)
- Rika Kobayashi (National Computational Infrastructure)
- Matthew Downton (National Computational Infrastructure)
- Ben Menadue (National Computational Infrastructure)
- Ben Evans (National Computational Infrastructure) 

### Suggested acknowledgements:

NCI Gadi

The authors acknowledge the technical assistance provided by the Sydney Informatics Hub, a Core Research Facility of the University of Sydney. This research/project was undertaken with the assistance of resources and services from the National Computational Infrastructure (NCI), which is supported by the Australian Government and Australian BioCommons which is enabled by NCRIS via Bioplatforms Australia funding.

# Cite us to support us!
If you use our pipelines, please cite us:

Sydney Informatics Hub, Core Research Facilities, University of Sydney, 2021, The Sydney Informatics Hub Bioinformatics Repository, \<date accessed\>, https://github.com/Sydney-Informatics-Hub/Bioinformatics

# References 

Grabherr MG, Haas BJ, Yassour M, et al. Full-length transcriptome assembly from RNA-Seq data without a reference genome. Nat Biotechnol. 2011;29(7):644-652. Published 2011 May 15. [doi:10.1038/nbt.1883](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3571712/)

Haas BJ, Papanicolaou A, Yassour M, et al. De novo transcript sequence reconstruction from RNA-seq using the Trinity platform for reference generation and analysis. Nat Protoc. 2013;8(8):1494-1512. [doi:10.1038/nprot.2013.084](https://www.ncbi.nlm.nih.gov/pmc/articles/pmid/23845962/)


