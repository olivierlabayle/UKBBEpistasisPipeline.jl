process filterASB {
    container "olivierlabayle/tmle-epistasis:0.3.1"

    input:
        path asb_snp_files

    output: 
        path "filtered_asb_snps.csv", emit: filtered_asb_snps

    script:
        "julia --project=/TMLEEpistasis.jl --startup-file=no /TMLEEpistasis.jl/bin/filter_asb.jl --out filtered_asb_snps.csv ${asb_snp_files.join(" ")}"
}


process queriesFromASBxTransActors {
    container "olivierlabayle/tmle-epistasis:0.3.1"
    publishDir "$params.OUTDIR/queries", mode: 'symlink'

    input:
        path filtered_asb_snps
        path trans_actors
        path chr_files
        path excluded_snps

    output:
        path "queries/*.toml", emit: queries

    script:
        bgen_sample = chr_files.find { it.toString().endsWith("bgen") }
        def exclude = excluded_snps.name != 'NO_FILE' ? "--exclude $excluded_snps" : ''
        """
        mkdir -p queries
        julia --project=/TMLEEpistasis.jl --startup-file=no /TMLEEpistasis.jl/bin/generate_queries.jl $filtered_asb_snps $trans_actors -o queries -s $bgen_sample -t $params.THRESHOLD $exclude
        """
}

process queriesFromQueryFiles{
    publishDir "$params.OUTDIR/queries", mode: 'symlink'
    
    input:
        path query_file
    
    output:
        path query_file

    script:
        "exit 0"

}