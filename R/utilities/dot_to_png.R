# setwd("D:/workspace/DIASPARA_WP3_habitat/R")
setwd("C:/workspace/DIASPARA_WP3_migdb/R")
#    dot_path <- "C:/Program Files/Graphviz/bin/dot.exe"
dot_path <- "dot"
extract_and_convert_dot <- function(qmd_file = "diaspara_diagrams.qmd", output_dir = "images") {
    if (!dir.exists(output_dir)) dir.create(output_dir)

    lines <- readLines(qmd_file)
    in_chunk <- FALSE
    chunk_lines <- c()
    chunk_label <- NULL



    for (i in seq_along(lines)) {
        line <- lines[i]

        if (grepl("^```\\{dot.*\\}", line)) {
            in_chunk <- TRUE
            chunk_lines <- c()
            chunk_label <- NULL
            next
        }

        if (in_chunk && grepl("^```$", line)) {
            in_chunk <- FALSE
            if (is.null(chunk_label)) {
                chunk_label <- paste0("chunk-", i)
            }

            dot_file <- file.path(output_dir, paste0(chunk_label, ".dot"))
            svg_file <- file.path(output_dir, paste0(chunk_label, ".svg"))

            writeLines(chunk_lines, dot_file)

            cmd <- sprintf('"%s" -Tsvg "%s" -o "%s"', dot_path, dot_file, svg_file)
            exit_code <- system(cmd, intern = FALSE, ignore.stderr = FALSE, ignore.stdout = FALSE)

            if (exit_code != 0 || !file.exists(svg_file)) {
                message("Failed to convert: ", dot_file)
                message("Command used: ", cmd)
            } else {
                message("SVG generated: ", svg_file)
                unlink(dot_file)
            }
            next
        }

        if (in_chunk) {
            if (grepl("^//\\|\\s*label:", line)) {
                chunk_label <- trimws(sub("^//\\|\\s*label:\\s*", "", line))
            } else {
                chunk_lines <- c(chunk_lines, line)
            }
        }
    }
}

extract_and_convert_dot()
