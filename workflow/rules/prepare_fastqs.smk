# This currently expects names as I receive them from the core
rule clean_names:
    input:
        get_fastqs,
    output:
        fw = temp("data/symlink/{sample}_{lib_type}_{lane}_R1.fastq.gz"),
        rv = temp("data/symlink/{sample}_{lib_type}_{lane}_R2.fastq.gz"),
    script:
        "../scripts/python/create_symlink.py"

rule merge_lanes:
    input:
        fw = lambda w: expand(
            "data/symlink/{sample.sample_id}_{sample.lib_type}_{sample.lane}_R1.fastq.gz", 
            sample=units.loc[(w.sample, w.lib_type)].itertuples()
            ),
        rv = lambda w: expand(
            "data/symlink/{sample.sample_id}_{sample.lib_type}_{sample.lane}_R2.fastq.gz", 
            sample=units.loc[(w.sample, w.lib_type)].itertuples()
            )
    output:
        fw = temp("data/lane_merged/{sample}_{lib_type}_S1_L001_R1_001.fastq.gz"),
        rv = temp("data/lane_merged/{sample}_{lib_type}_S1_L001_R2_001.fastq.gz")
    log:
        "results/00_logs/merge_lanes/{sample}_{lib_type}.log"
    resources:
        runtime = RESOURCES["merge_lanes"]["runtime"]
    container:
        None
    shell:
        """
        cat {input.fw} > {output.fw} 2> {log}
        cat {input.rv} > {output.rv} 2>> {log}
        """
