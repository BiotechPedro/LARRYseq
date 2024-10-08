# Configuration files

To setup the pipeline for execution it is very simple, however there are some files in the folder `config` that need to be modified/adapted. These are the main configuration files and their contents:

* `config/samples/units.tsv`: Sample name information and paths to fastq files (see [units section](#samples-to-process-and-raw-data-configsamplesunitstsv)).
* `config/config.yaml`: Main configuration file such paths to singularity images and the path for other configuration files.
* `config/larry_config.yaml`: Parameters regarding LARRY barcode processing. **Important to check before running the pipeline**. The default behavior is to run the pipeline with LARRY processing activated. If you don't have larry barcodes but want to run the pipeline, switch it to off (see [larry section](#larry-configuration-configlarry_configyaml)).

## Samples to process and raw data: `config/samples/units.tsv`

Paths to raw data (fastq files) are located in the file `config/samples/units.tsv`. The file has the following structure:

| sample_id | lane | lib_type | R1 | R2 | R3 |
|-----------|------|----------|----|----|----|
| name_of_sample | name_of_lane_or_resequencing | library type | path/to/forward.fastq.gz | path/to/reverse.fastq.gz | path/to/ATAC-R3.fastq.gz

**The library type is of one kind (FB) for this workflow, but a general structure is allowed for the seek of compatibility with other workflows if integrated in the future**

* `sample_id`: The first field correspond to the sample name. This field has to be identical for all the fastqs corresponding to the same sample, independently of the library type of the fastq. If a sample is split in 2 different library types (such as ATAC + RNA or RNA and LARRY), both of them must have the same sample_id.

* `lane`: The idea of this field is to group fastq files corresponding to the same sample (or to samples that have to be merged). For example, if 1 sample arrived in 2 different lanes from a PE experiment, in total there will be 4 fastqs (2 forward and 2 reverse). In this case, one should enter the same sample 2 times, putting in the `lane` field the corresponding lanes (lane1 and lane2, for example). Actually one can write any word in this field, the idea is to group fastqs from the same sample. All the entries with the same name in the `sample` field with different `lane` will be merged in the same fastq. Here an example of how it would be with 1 sample that arrived in 2 lanes:

    | sample_id | lane | lib_type | R1 | R2 | R3 |
    |-----------|------|----------|----|----|----|
    | foo | lane1 | FB | path/to/forward_lane1.fastq.gz | path/to/reverse_lane1.fastq.gz | |
    | foo | lane2 | FB | path/to/forward_lane2.fastq.gz | path/to/reverse_lane2.fastq.gz | |

    Usually I use lane1 and lane2 for consistency and making things more clear, but the following would also work:

    | sample_id | lane | lib_type | R1 | R2 | R3 |
    |-----------|------|----------|----|----|----|
    | foo | whatever | FB | path/to/forward_lane1.fastq.gz | path/to/reverse_lane1.fastq.gz | |
    | foo | helloworld | FB | path/to/forward_lane2.fastq.gz | path/to/reverse_lane2.fastq.gz | |

    The important thing is that if a sample is split in different pairs of fastq files (different pairs of R1 & R2 files) in the units file they must be inserted in 2 different rows, with the **same sample_id** and **different lane**.

* `lib_type`: Corresponds to the type of library. Basically it can be one of 3: **GEX** (Gene expression), **ATAC** (Chromatin accessibility), **FB** (Feature barcoding, which has to be set for the LARRY fastqs) and **CH** (Fast files containing cellhashing data).

* `R1`, `R2` and `R3`: Correspond to the paths to the fastq files. For RNA (GEX) `R1` is the FORWARD read and `R2` the REVERSE. Usually the cellular barcode is present in the R1 and the transcript in the R2, same for LARRY. In the case of the ATAC, `R2` corresponds to the dual illumina indexing and `R3` corresopnds to the reverse read (where the tn5 fragment is present). `R3` is never used in this workflow therefore.

Example of a units.tsv file with GEX, LARRY and Cellhashing:

| sample_id | lane | lib_type | R1 | R2 | R3 |
|-----------|------|----------|----|----|----|
| sample1 | lane1 | GEX | path/to/forward_GEX_lane1.fastq.gz | path/to/reverse_GEX_lane1.fastq.gz | |
| sample1 | lane2 | GEX | path/to/forward_GEX_lane2.fastq.gz | path/to/reverse_GEX_lane2.fastq.gz | |
| sample1 | lane1 | FB | path/to/forward_LARRY_lane1.fastq.gz | path/to/reverse_LARRY_lane1.fastq.gz | |
| sample1 | lane1 | CH | path/to/forward_cellhashing_lane2.fastq.gz | path/to/reverse_cellhashing_lane2.fastq.gz | |

## LARRY configuration: `config/larry_config.yaml`

`config/larry_config.yaml` contains the parameters of LARRY processing:

* `feature_bc`: Does data contain barcodes? set `True` or `False`
* `read_feature_bc`: In which fastq (fw or rv) are located LARRY barcodes. Usually is the `R2`.
* `read_cellular_bc`: In which fastq (fw or rv) are located cellular barcodes. Usually is the `R1`. This is the opposite fastq than `read_feature_bc`.
* `hamming_distance`: The hamming distance that will be used to collapse LARRY barcodes. We have seen that for a barcode of 20 nucleotides in length, `3` or `4` are good values. 
* `reads_cutoff`: (not used in this pipeline) Number of minimum reads that a molecule needs to have in order to consider a UMI. Cellranger considers any molecule sequenced at least 1 time as a valid UMI. Since usually we sequence LARRY libraries at >90% saturation, most molecules should be sequenced way more than 1 time (we are sequencing many PCR duplicates). Setting this threshold `between 5 and 10` has helped us to reduce the number of false positive larry assignments in our datasets.
* `umi_cutoff`: (not used in this pipeline) Number of UMIs required to consider a LARRY barcode detected in a cell when performing the barcode calling. This depends a lot on the expression of the barcode mRNA. For LARRY-v1 libraries this value could be increase easily at 5-10, however with LARRY-v2 the expression is lower. This can be easily re-executed by the user in R after running the pipeline. Default: `3`.
* `bc_patterns`: The patterns of the larry barcodes integrated in the sequenced cells. It has the following structure:

    ```yaml
    bc_patterns:
        "TGATTG....TG....CA....GT....AG...." : "Sapphire"
        "TCCAGT....TG....CA....GT....AG...." : "GFP"
    ```

## Resources configuration

`config/resources.yaml` contains the per rule resource parameters (ncpus, ram, walltime...). It can be modified as desired. Just be sure to respect the amount of CPUs and RAM that each rule required (the parameters set by default have been set based on trial and error and should be over what is actually required). The RAM and CPUs are also used by snakemake to calculate which and how many jobs can be run in parallel. If the rule actually uses more resources than those set, it can drive to running parallel jobs that exceed the computers RAM, which can force the abortion of jobs. 