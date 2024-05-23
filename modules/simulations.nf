include { longest_prefix } from './utils'

process NullSimulationEstimation {
    label 'simulation_image'
    publishDir "${params.OUTDIR}/null_simulation_results", mode: 'symlink'

    input:
        path origin_dataset 
        tuple path(estimators), path(estimands), val(sample_size), val(rng)
        
    output:
        path out

    script:
        out = "results__${rng}__${sample_size}__${estimands.getBaseName()}__${estimators.getBaseName()}.hdf5"
        sample_size_option = sample_size != -1 ? "--sample-size=${sample_size}" : ""
        """
        mkdir workdir
        TEMPD=\$(mktemp -d)
        JULIA_DEPOT_PATH=\$TEMPD:/opt julia --project=/opt/Simulations --startup-file=no --sysimage=/opt/Simulations/Simulations.so /opt/Simulations/targene-simulation.jl \
        estimation ${origin_dataset} ${estimands} ${estimators} \
            ${sample_size_option} \
            --n-repeats=${params.N_REPEATS} \
            --out=${out} \
            --verbosity=${params.VERBOSITY} \
            --chunksize=${params.TL_SAVE_EVERY} \
            --rng=${rng} \
            --workdir=workdir
        """
}

process RealisticSimulationEstimation {
    label 'simulation_image'
    publishDir "${params.OUTDIR}/null_simulation_results", mode: 'symlink'

    input:
        path origin_dataset
        path density_estimates
        tuple path(estimators), path(estimands), val(sample_size), val(rng)
        
    output:
        path out

    script:
        density_estimate_prefix = longest_prefix(density_estimates)
        out = "results__${rng}__${sample_size}__${estimands.getBaseName()}__${estimators.getBaseName()}.hdf5"
        sample_size_option = sample_size != -1 ? "--sample-size=${sample_size}" : ""
        """
        mkdir workdir
        TEMPD=\$(mktemp -d)
        JULIA_DEPOT_PATH=\$TEMPD:/opt julia --project=/opt/Simulations --startup-file=no --sysimage=/opt/Simulations/Simulations.so /opt/Simulations/targene-simulation.jl \
        estimation ${origin_dataset} ${estimands} ${estimators} \
        --density-estimates-prefix=${density_estimate_prefix} \
        ${sample_size_option} \
        --n-repeats=${params.N_REPEATS} \
        --out=${out} \
        --verbosity=${params.VERBOSITY} \
        --chunksize=${params.TL_SAVE_EVERY} \
        --rng=${rng} \
        --workdir=workdir
        """
}

process AggregateSimulationResults {
    label "bigmem"
    label "simulation_image"
    publishDir "${params.OUTDIR}", mode: 'symlink'

    input:
        path results
        val outfile
        
    output:
        path outfile

    script:
        """
        TEMPD=\$(mktemp -d)
        JULIA_DEPOT_PATH=\$TEMPD:/opt julia --project=/opt/Simulations --startup-file=no --sysimage=/opt/Simulations/Simulations.so /opt/Simulations/targene-simulation.jl \
        aggregate results ${outfile}
        """
}

process RealisticSimulationInputs {
    label "bigmem"
    label "simulation_image"
    publishDir "${params.OUTDIR}/realistic_simulation_inputs/", mode: 'symlink'
    
    input:
        path estimands
        path bgen_files
        path traits
        path pcs
        path ga_trait_table
        
    output:
        path "ga_sim_input.dataset.arrow", emit: dataset
        path "ga_sim_input.conditional_density*", emit: conditional_densities
        path "ga_sim_input.estimand*", emit: estimands

    script:
        estimands_prefix = longest_prefix(estimands)
        bgen_prefix = longest_prefix(bgen_files)
        """
        TEMPD=\$(mktemp -d)
        JULIA_DEPOT_PATH=\$TEMPD:/opt julia --project=/opt/Simulations --startup-file=no --sysimage=/opt/Simulations/Simulations.so /opt/Simulations/targene-simulation.jl \
        simulation-inputs-from-ga ${estimands_prefix} ${bgen_prefix} ${traits} ${pcs} \
        --ga-download-dirgene_atlas \
        --remove-ga-data=true \
        --ga-trait-table=${ga_trait_table} \
        --maf-threshold=${params.GA_MAF_THRESHOLD} \
        --pvalue-threshold=${params.GA_PVAL_THRESHOLD} \
        --distance-threshold=${params.GA_DISTANCE_THRESHOLD} \
        --max-variants=${params.GA_MAX_VARIANTS} \
        --positivity-constraint=${params.POSITIVITY_CONSTRAINT} \
        --call-threshold=${params.CALL_THRESHOLD} \
        --output-prefix=ga_sim_input \
        --batchsize=${params.BATCH_SIZE} \
        --verbosity=${params.VERBOSITY}
        """
}

process DensityEstimation {
    label 'multithreaded'
    label "bigmem"
    label "simulation_image"
    publishDir "${params.OUTDIR}/density_estimates/", mode: 'symlink'

    input:
        path dataset 
        path density
        
    output:
        path outfile

    script:
        file_splits = density.name.split("_")
        prefix = file_splits[0..-2].join("_")
        file_id = file_splits[-1][0..-6]
        outfile = "${prefix}_estimate_${file_id}.hdf5"
        """
        TEMPD=\$(mktemp -d)
        JULIA_DEPOT_PATH=\$TEMPD:/opt julia --project=/opt/Simulations --startup-file=no --sysimage=/opt/Simulations/Simulations.so /opt/Simulations/targene-simulation.jl \
        density-estimation ${dataset} ${density} \
            --mode=study \
            --output=${outfile} \
            --train-ratio=${params.TRAIN_RATIO} \
            --verbosity=${params.VERBOSITY}
        """
}