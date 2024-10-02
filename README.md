# Snakemake workflow: `LARRYseq`

[![Snakemake](https://img.shields.io/badge/snakemake-≥8.4.7-brightgreen.svg)](https://snakemake.github.io)

Snakemake workflow to process **amplicon sequencing** libraries of [LARRY barcodes](https://www.nature.com/articles/s41586-020-2503-6) after DNA isolation and amplification with LARRY-specific primers. In fact, it should work for any type of DNA-seq data whose reads need to be collapsed and counted, if the users know which sequence pattern they are looking for.

The input should be pairs of compressed fastq files, written in the `config/samples/units.tsv`. The output is a csv file per each sample and barcode type (different sequence patterns can be given, if multiple barcoding viral libraries were used to infect the samples).

The pipeline uses [UMICollapse](https://github.com/Daniel-Liu-c0deb0t/UMICollapse) to collapse the sequences up to a given Hamming distance i.e. substitution edits, without the need of explicitly specifying which concrete sequecences we are interested in, since we may not know it in the case of libraries with high diversity of random barcodes. Once the representative sequences (aka clusters) are obtained, their number of reads are counted

## Advice

Before running the pipeline, it is recommended to search for the sequence pattern in both R1 and R2 fastq files, in case the user is not sure which read contains the desired sequence(s). This can be done by counting the times the sequence pattern is found in each file with the following bash code:

 ```bash
zcat R1.fastq.gz | grep -c 'AC..GT..'
zcat R2.fastq.gz | grep -c 'AC..GT..' 
```

Also, one should modify the `config/snakemake_profile/*/config.yaml` to request the computational resources respectfully enough with other users, when running the pipeline in a shared harwdare. Take a look especially at the `cores` and the `resources`.

## Software requirements

**IMPORTANT**: To run this pipeline you must have [Snakemake](https://snakemake.github.io) installed. You can follow their [tutorial](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html) for installing the software. Also, to run the pipeline some [singularity](https://docs.sylabs.io/guides/latest/user-guide/) containers for UMICollapse are also required.


## Main output

* `results/00_logs`: Logs of the different rules executed by the pipeline.
* `results/benchmarks`: Times of execution for each rule and input file.
* `results/01_collapsing`: 4-columns csv file including the clusted ID (identificator for the representative sequence), cluster size (number of total reads once sequences are collapsed), original sequence size (number of reads comming from the representative sequence if no errors are allowed), and sequence (actual representative sequence).


## Configuration files

To setup the pipeline for execution it is very simple, however there are some files in the folder `config` that need to be modified/adapted. These are the main configuration files and their contents:

* `config/samples/units.tsv`: Sample name information and paths to fastq files (see [units](#samples-to-process-and-raw-data-configsamplesunitstsv) section).
* `config/config.yaml`: Configuration file and path to singularity images, etc (see [config](#configuration-of-pipeline-parameters-configconfigyaml) section).
* `config/larry_config.yaml`: Parameters regarding LARRY barcode processing. **Important to check before running the pipeline**. The default behavior is to run the pipeline with LARRY processing activated. If you don't have LARRY barcodes but want to run the pipeline, switch it to off (see [LARRY params](#larry-configuration-configlarry_configyaml) section).
* `config/resources.yaml`: Computational resources or requirements for some rules (see [resources](#resources-configuration) section).


### Samples to process and raw data: `config/samples/units.tsv`

Paths to raw data (fastq files) are located in the file `config/samples/units.tsv`. The file has the following structure:

| sample_id | lane | lib_type | R1 | R2 | R3 |
|-----------|------|----------|----|----|----|
| name_of_sample | name_of_lane_or_resequencing | library type | path/to/forward.fastq.gz | path/to/reverse.fastq.gz | path/to/ATAC-R3.fastq.gz

* `sample_id`: The first field correspond to the sample name. This field has to be identical for all the fastqs corresponding to the same sample, independently of the lane and the library type of the fastq.

* `lane`: The idea of this field is to group fastq files corresponding to the same sample (or to samples that have to be merged). For example, if 1 sample arrived in 2 different lanes from a PE experiment, in total there will be 4 fastq files (2 forward and 2 reverse). In this case, one should enter the same sample 2 times, putting in the `lane` field the corresponding lanes (lane1 and lane2, for example). Actually one can write any word in this field, the idea is to group fastqs from the same sample. All the entries with the same name in the `sample` field with different `lane` will be merged in the same fastq. Here an example of how it would be with 1 sample that arrived in 2 lanes:

    | sample_id | lane | lib_type | R1 | R2 | R3 |
    |-----------|------|----------|----|----|----|
    | foo | lane1 | FB | path/to/forward_lane1.fastq.gz | path/to/reverse_lane1.fastq.gz | |
    | foo | lane2 | FB | path/to/forward_lane2.fastq.gz | path/to/reverse_lane2.fastq.gz | |

    We usually write lane1 and lane2 for consistency and making things more clear, but the following would also work:

    | sample_id | lane | lib_type | R1 | R2 | R3 |
    |-----------|------|----------|----|----|----|
    | foo | whatever | FB | path/to/forward_lane1.fastq.gz | path/to/reverse_lane1.fastq.gz | |
    | foo | helloworld | FB | path/to/forward_lane2.fastq.gz | path/to/reverse_lane2.fastq.gz | |

    In conclusion, if one sample is split in different pairs of fastq files (different pairs of R1 & R2 files) in the units file, they must be inserted in 2 different rows, with the **same sample_id** and **different lane**.

* `lib_type`: Corresponds to the type of library. In this pipeline it can be anything, so we use **FB** (feature barcoding).

* `R1`, `R2` and `R3`: Correspond to the paths to the fastq files. In this pipeline `R3` is not used, but we leave it for the seek of compatibility with other workflows if integrated in the future.


### Configuration of pipeline parameters: `config/config.yaml`

Please, define the Singularity image to use for UMICollapse software (done by default).

Inside the file, and also in the file `workflow/schema/config.schema.yaml` you can find what is controlled by each tunable parameter.

### LARRY configuration: `config/larry_config.yaml`

`config/larry_config.yaml` contains the parameters of LARRY processing:

* `feature_bc`: Does data contain barcodes? set `True` or `False`
* `read_feature_bc`: In which fastq (fw or rv) are located LARRY barcodes. Usually is the `R2`.
* `read_cellular_bc`: In which fastq (fw or rv) are located cellular barcodes. Usually is the `R1`. This is the opposite fastq than `read_feature_bc`.
* `hamming_distance`: The hamming distance that will be used to collapse LARRY barcodes. We have seen that for a barcode of 20 nucleotides in length, `3` or `4` are good values.
* `bc_patterns`: The patterns of the LARRY barcodes integrated in the sequenced cells. It has the following structure:

    ```yaml
    bc_patterns:
        "TGATTG....TG....CA....GT....AG...." : "Sapphire"
        "TCCAGT....TG....CA....GT....AG...." : "GFP"
    ```

### Resources configuration

`config/resources.yaml` contains the per rule resource parameters (ncpus, ram, walltime...). It can be modified as desired. Just be sure to respect the amount of CPUs and RAM that each rule required (the parameters set by default have been set based on trial and error and should be over what is actually required). The RAM and CPUs are also used by snakemake to calculate which and how many jobs it can run in parallel. If the rule actually uses more resources than those set, it can drive to running parallel jobs that exceed the computers RAM, which can force the abortion of jobs. 

## Snakemake profiles

In Snakemake 4.1 [snakemake profiles](https://snakemake.readthedocs.io/en/stable/executing/cli.html#profiles) were introduced. They are supposed to substitute the classic cluster.json file and make the execution of snakemake more simple. The parameters that will be passed to snakemake (i.e: --cluster, --use-singularity...) now are inside a yaml file (`config.yaml`) inside the profile folder (in the case of this repository is `config/snakemake_profile`). There is one config.yaml for local execution (`config/snakemake_profile/local`) and another for execution in HPCs using the [Slurm Workload Manager](https://github.com/SchedMD/slurm) (`config/snakemake_profile/slurm`). The `config.yaml` contains the parameters passed to Snakemake. 

If you are running the pipeline locally (personal computer/workstation), some important parameters that you may have to adapt in `config/snakemake_profile/local` are:

```yaml
cores            : 120 # Define total amount of cores that the pipeline can use
resources        : mem_mb=128000 # Define total amount of ram that pipeline can use
default-resources: mem_mb=1000 # Set default ram for rules (cores is by default 1)
latency-wait     : 60
keep-going       : true
use-singularity  : true
singularity-args : "--bind /stemcell" # Volumes to mount for singularity (important to mount the volume where the pipeline will be executed)
--use-conda      : true
```

Adapt them according to your computer hardware. Then adapt the path to bind in singularity from `singularity-args` to the folder in which you are running the pipeline form.

In case of running the pipeline using slurm:

```yaml
executor         : slurm
jobs             : unlimited # Define total amount of parallel jobs that the pipeline can execute
latency-wait     : 60
keep-going       : true
use-singularity  : true
singularity-args : "--bind /scratch --bind /data --bind /home" # Volumes to mount for singularity (important to mount the volume where the pipeline will be executed)
--use-conda      : true
default-resources: 
  mem_mb : 1000 # Set default ram for rules (cores is by default 1)
  runtime: 5    # Set the default walltime for jobs (in minutes)
  retries: 1    # Set the default number of retires if a job fails
```

Particularly important to adapt the volumes to bind for singularity to your own HPC.

## Execution of the pipeline

Once you have all the configuration files as desired, it's time to execute the pipeline. For that you have to execute the `execute_pipeline.sh` script, followed by the name of the rule that you want to execute. There is one script to execute the pipeline locally and another for execution in HPC's with slurm:

```bash
./local_execute_pipeline.sh # local
./slurm_execute_pipeline.sh # HPC with slurm scheduler
```

If no rule is given it will automatically execute the rule `all` (which would execute the standard pipeline).

```bash
./local_execute_pipeline.sh  all
```

is equivalent to 

```bash
./local_execute_pipeline.sh
```

If you want to add extra snakemake parameters without modifying `config/snakemake_profile/config.yaml`:

```bash
./local_execute_pipeline.sh --rerun-triggers mtime
```


