# Reworked trinity workflow

Key changes:
- Reduces scripts from 5 to 3 to reduce the overhead of moving large
  tar files between network storage and /jobfs
- Moves the key modules onto the node to reduce the overhead of
  loading executables across the network
- For the distributed part of the workflow a separate batch task is
  submitted for each of the 'file bin' directories. These represent
  ~100,000 mostly small tasks. In this way, the workflow can scale
  with the amount of work to be performed.

- - -

## Orientation

The repository consists of the following directories:

- `Scripts` The main pbs scripts that are used to execute the
  different trinity phases plus a template script that can be
  customised for each assembly.
- `resources` Script to create a tar file containing the software
  dependencies to be copied across to the compute node.
  
- - -

## Steps

- Clone repository/copy directory
- Create module archive by running `create-apps.sh` in the
   `resources` directory.
- Copy the template submission script (`Scripts/template.sh`) into the
  project directory and edit for the project. Give it a meaningful name.
  - The key variables to edit are `project` (e.g ab73), `list` which
    contains the list of input fastq pairs, `seqtype`.

- - -

## Very large assemblies

The distributed part of the workflow is unlikely to require
significant jobfs or memory resources. However, the initial phase of
the workflow may need to run on the hugemem nodes. If this is the
case, edit the qsub definition at the bottom of the submission
script. As there are some serial bottlenecks in the first part of the
workflow, reducing the requested resources may improve the
'efficiency' of the calculation. For instance half of a hugemem node
(24 cores, 750GB memory, 700GB jobfs) may be sufficient for a larger
assembly.

- - -

## Data movement

- All work is performed local to the node in /jobfs or in /dev/shm
- At the end of trinity_1_fb.pbs, a single tar file containing the
  full Trinity output directory is copied back to network
  storage. 100GB+
- Each task running trinity_2_fb.pbs works on a single file bin
  representing ~100,000 tasks. Only the `recursive_trinity.cmds` and
  the relevant data from `read_partitions` are copied to the node. The
  full `read_partitions` directory is archived and pushed back to
  network storage at the end of processing. Up to 10GB.
- In trinity_3_fb.pbs, only the fasta files from the distributed step
  are copied to the node. Only the full assembly is copied back.
