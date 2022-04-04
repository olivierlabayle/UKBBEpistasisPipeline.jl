process Summary {
    container "olivierlabayle/tmle-epistasis:0.3.1"
    publishDir "$params.OUTDIR/summaries", mode: 'symlink'
    label "bigmem"

    input:
        tuple val(rsids), file(tmle), file(sieve)
    
    output:
        path "${rsids}_summary.csv"
    
    script:
        """
        julia --project=/TMLEEpistasis.jl --startup-file=no \
        /TMLEEpistasis.jl/bin/summarize.jl $rsids ${rsids}_summary.csv
        """
}