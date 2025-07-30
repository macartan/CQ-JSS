# This function replaces verbatim for CodeOutput
# And wraps CodeInput + CodeOutput within CodeChunk

library(stringr)
process_code_blocks <- function(file_path, out_path = file_path, max_width = 76) {
  # Read file
  tex <- readLines(file_path, warn = FALSE)
  content <- paste(tex, collapse = "\n")

  # Replace ←→ with LaTeX symbol
  content <- gsub("←→", "$\\\\leftrightarrow$", content)

  # Step 1: Replace verbatim with CodeOutput, preserving whitespace
  verbatim_pattern <- "(?s)\\\\begin\\{verbatim\\}(\\s*?\n)(.*?)(\\\\end\\{verbatim\\})"
  content <- str_replace_all(content, verbatim_pattern, function(m) {
    parts <- str_match(m, verbatim_pattern)
    ws <- parts[2]
    body <- parts[3]
    paste0("\\begin{CodeOutput}", ws, body, "\\end{CodeOutput}")
  })

  # Write intermediate result to lines for further processing
  lines <- unlist(strsplit(content, "\n"))

  # Step 2: Wrap CodeInput + CodeOutput pairs with CodeChunk
  begin_positions <- c()
  end_positions <- c()
  for (i in seq_along(lines)) {
    if (grepl("^\\\\end\\{CodeOutput\\}", lines[i])) {
      for (j in seq(i - 1, 1)) {
        if (grepl("^\\\\begin\\{CodeInput\\}", lines[j])) {
          begin_positions <- c(begin_positions, j)
          end_positions <- c(end_positions, i)
          break
        }
      }
    }
  }
  offset <- 0
  for (k in seq_along(begin_positions)) {
    b <- begin_positions[k] + offset
    e <- end_positions[k] + offset + 1
    lines <- append(lines, "\\begin{CodeChunk}", after = b - 1)
    lines <- append(lines, "\\end{CodeChunk}", after = e)
    offset <- offset + 2
  }

  inside_env <- FALSE

  for (i in seq_along(lines)) {
    line <- lines[i]

    # Detect CodeOutput environment
    if (grepl("\\\\begin\\{CodeOutput\\}", line)) {
      inside_env <- TRUE
    } else if (grepl("\\\\end\\{CodeOutput\\}", line)) {
      inside_env <- FALSE
    }

    # If inside CodeOutput and line exceeds max_width, truncate
    if (inside_env && nchar(line) > max_width) {
      lines[i] <- paste0(substr(line, 1, max_width - 3), "...")
    }
  }

  writeLines(lines, out_path)
  message(
    "✔ Done: verbatim replaced and code blocks grouped/wrapped in ",
    out_path, ".")
}

fix_code_file <- function(file_path) {
  # Read file into vector
  lines <- readLines(file_path, warn = FALSE)

  # Replace 'echo: false' → 'echo: true'
  lines <- gsub("echo:\\s*false", "echo: true", lines)

  # Replace 'include: false' → 'include: true'
  lines <- gsub("include:\\s*false", "include: true", lines)

  # Replace 'eval: false' → 'include: false'
  lines <- gsub("eval:\\s*false", "include: false", lines)

  # Write back to file
  writeLines(lines, file_path)
  message("✔ Done: updated echo/eval/include flags in ", file_path, ".")

}

# Implement
process_code_blocks("paper.tex", "CQ_JSS.tex")
fix_code_file("code.R")
