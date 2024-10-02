rule extract_barcodes:
    input: 
        fb = "data/lane_merged/{{sample}}_FB_S1_L001_{}_001.fastq.gz".format(LARRY["read_feature_bc"]),
        #cb = "data/lane_merged/{{sample}}_FB_S1_L001_{}_001.fastq.gz".format(LARRY["read_cellular_bc"]),
    output:
        filt_fb = temp(
            expand(
                "data/bc_filt/{{sample}}_FB_S1_L001_{read_fb}_001_{larry_color}.fastq.gz", 
                larry_color = LARRY_COLORS, 
                read_fb = LARRY["read_feature_bc"]
                )
            ),
        #filt_cb = temp("data/clean/{{sample}}_FB_S1_L001_{}_001.fastq.gz".format(LARRY["read_cellular_bc"]))
    params:
        barcode_dict = LARRY["bc_patterns"]
    log:
        "results/00_logs/extract_barcodes/{sample}.log"
    benchmark:
        "results/benchmarks/extract_barcodes/{sample}.txt"
    conda:
         "../envs/python.yaml"
    resources:
        mem_mb  = get_mem_mb(RESOURCES["extract_barcodes"]["mem_mb"], 20000),
        runtime = RESOURCES["extract_barcodes"]["runtime"],
        retries = RESOURCES["extract_barcodes"]["retries"]
    script:
        "../scripts/python/extract_barcodes.py"


rule collapse_fastq_hd:
    input:
        "data/bc_filt/{sample}_FB_S1_L001_{read_fb}_001_{larry_color}.fastq.gz"
    output:
        temp("data/collapsed/{sample}_FB_S1_L001_{read_fb}_001_{larry_color}_collapsed-hd{hd}.fastq.gz")
    log:
        "results/00_logs/collapse_fastq_hd/{sample}_{read_fb}_{larry_color}_{hd}.log"
    benchmark:
        "results/benchmarks/collapse_fastq_hd/{sample}_{read_fb}_{larry_color}_{hd}.txt"
    resources:
        mem_mb  = get_mem_mb(RESOURCES["collapse_fastq_hd"]["mem_mb"], 20000),
        runtime = RESOURCES["collapse_fastq_hd"]["runtime"],
        retries = RESOURCES["collapse_fastq_hd"]["retries"]
    container:
        config["singularity"]["umicollapse"]
    shell:
        """
        java -Xms{resources.mem_mb}m -Xmx{resources.mem_mb}m -Xss1G -jar /UMICollapse/umicollapse.jar fastq -k {wildcards.hd} --tag -i {input} -o {output} 2> {log}
        """

rule make_csv:
    input:
        expand(
            "data/collapsed/{sample}_FB_S1_L001_{read_fb}_001_{larry_color}_collapsed-hd{hd}.fastq.gz",
            sample = SAMPLES, read_fb = LARRY["read_feature_bc"], larry_color = LARRY_COLORS, hd = LARRY["hamming_distance"]
            )
    output:
        "results/01_collapsing/{sample}_FB_S1_L001_{read_fb}_001_{larry_color}_collapsed-hd{hd}.csv"
    params:
        sample = SAMPLES,
        larry_color = LARRY_COLORS,
    log:
        "results/00_logs/make_csv/{sample}_{read_fb}_{larry_color}_{hd}.log"
    benchmark:
        "results/benchmarks/make_csv/{sample}_{read_fb}_{larry_color}_{hd}.txt"
    resources:
        mem_mb  = get_mem_mb(RESOURCES["collapse_fastq_hd"]["mem_mb"], 20000),
        runtime = RESOURCES["collapse_fastq_hd"]["runtime"],
        retries = RESOURCES["collapse_fastq_hd"]["retries"]
    shell:
        """
        echo "cluster_id,cluster_size,original_seq_size,sequence" > {output}
        zcat "data/collapsed/{wildcards.sample}_FB_S1_L001_{wildcards.read_fb}_001_{wildcards.larry_color}_collapsed-hd{wildcards.hd}.fastq.gz" | grep 'cluster_size' -A 1 | tr '\n' ' ' | tr '@' '\n' | cut -d ' ' -f 3-6 | tr ' ' '=' | cut -d '=' -f 2,4,6,7 | tr '=' ',' | tail -n +2 >> {output}
        """

