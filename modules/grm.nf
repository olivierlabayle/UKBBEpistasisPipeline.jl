process GRM {
    container "olivierlabayle/ukbb-estimation-pipeline:0.2.0"
    label "verybigmem"

    input:
        path bedfiles
    
    output:
        path "grmmatrix"
    
    script:
        println(bedfiles)
        println("--")
        only_bedfiles = bedfiles.findAll { it.endsWith(".bed") }
        println(only_bedfiles)
        "julia --threads=${task.cpus} --project=/EstimationPipeline.jl --startup-file=no /EstimationPipeline.jl/bin/compute_grm.jl grmmatrix ${only_bedfiles.join(" ")}"
}