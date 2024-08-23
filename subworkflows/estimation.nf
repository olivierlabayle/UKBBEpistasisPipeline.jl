include { TMLE; MergeOutputs } from '../modules/estimation.nf'
include { GenerateSummaryPlots } from '../modules/plot.nf'

workflow EstimationWorkflow {
    take:
        dataset_and_estimands
        estimators_config

    main:
        // Run the estimation process for each estimands configuration
        TMLE(
            dataset_and_estimands,
            estimators_config,
        )
        // Merge results files together
        MergeOutputs(TMLE.out.collect())

        // Generate Plots
        GenerateSummaryPlots(MergeOutputs.out.hdf5_file)

    emit:
        hdf5_result = MergeOutputs.out.hdf5_file
}