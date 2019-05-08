include("get_sepsis_score.jl")

using DelimitedFiles

function load_challenge_data(file)
    (data, header) = readdlm(file, '|', header=true)

    # Ignore SepsisLabel column if present.
    if header[end] == "SepsisLabel"
        header = header[1:end-1]
        data = data[:, 1:end-1]
    end

    return data
end

function save_challenge_predictions(file, scores, labels)
    f = open(file, "w")
    write(f, "PredictedProbability|PredictedLabel\n")
    writedlm(f, hcat(scores, labels), '|')
    close(f)
end

function driver(input_directory, output_directory)
    # Find files.
    files = []
    for f in readdir(input_directory)
        if isfile(joinpath(input_directory, f)) && !startswith(lowercase(f), ".") && endswith(lowercase(f), "psv")
            push!(files, f)
        end
    end

    if !isdir(output_directory)
        mkdir(output_directory)
    end

    # Load model.
    model = load_sepsis_model()

    # Iterate over files.
    for f in files
        # Load data.
        input_file = joinpath(input_directory, f)
        data = load_challenge_data(input_file)

        # Make predictions.
        num_rows = size(data, 1)
        scores = zeros(Float64, num_rows)
        labels = zeros(Int, num_rows)
        for t = 1:num_rows
            scores[t], labels[t] = get_sepsis_score(data[1:t, :], model)
        end

        # Save results.
        output_file = joinpath(output_directory, f)
        save_challenge_predictions(output_file, scores, labels)
    end
end

# Parse arguments.
if length(ARGS) != 2
    error("Include the input and output directories as arguments, e.g., julia driver.jl input output.")
end

driver(ARGS[1], ARGS[2])
