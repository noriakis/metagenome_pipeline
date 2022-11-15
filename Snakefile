
DATASETS=["CRR385951","CRR385952"]

fwd_suffix="_f1.fq.gz"
rev_suffix="_r2.fq.gz"

## Quality filtering
rule fastp:
    input:
        fwd="fqs/{sample}"+fwd_suffix,
        rev="fqs/{sample}"+rev_suffix
    output:
        outfwd="qf/{sample}_f1.fp.fq.gz",
        outrev="qf/{sample}_r2.fp.fq.gz"
    threads: 2
    shell:
        "fastp -w 2 -i {input.fwd} -o {output.outfwd} \
        -I {input.rev} -O {output.outrev}"

## Classification and abundance estimation
rule kraken2_and_bracken:
    input:
        fwd="qf/{sample}_f1.fp.fq.gz",
        rev="qf/{sample}_r2.fp.fq.gz"
    output:
        kraken2_out="kraken2_out/{sample}_kraken2.txt",
        braken_out="kraken2_out/{sample}_bracken.txt",
        kraken2_report_out="kraken2_out/{sample}_kraken2.report.txt"
    threads: 2
    shell:
        "~/.local/kraken2/kraken2 --db ~/.local/db_20220607 --threads 2 \
         --output {output.kraken2_out} --report {output.kraken2_report_out} \
         --gzip-compressed --paired {input.fwd} {input.rev}"
        "~/.local/Bracken-2.5/bracken -d ~/.local/db_20220607 \
         -i {output.kraken2_report_out} -o {output.bracken_out}"

## Error correction before making contigs
rule error_correction:
    input:
        fwd="qf/{sample}_f1.fp.fq.gz",
        rev="qf/{sample}_r2.fp.fq.gz"
    output:
        ec_out="error_correction/{sample}"
    threads: 4    
    shell:
        "python ~/SPAdes-3.15.5-Linux/bin/metaspades.py \
         --only-error-correction -t 4 \
         -1 {input.fwd} -2 {input.rev} -o {output.ec_out}"

## TODO:
## MEGAHIT --presets meta-sensitive
## Pool contigs using CD-HIT
## Gene prediction
## Clustering using MMSeq2
## Producing DAGs