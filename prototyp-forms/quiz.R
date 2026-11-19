# quiz(): bindet eine Aufgabe aus der Aufgabensammlung per exams2forms ein.
# Die Aufgaben liegen in drei Formaten vor; quiz() normalisiert sie zum
# r-exams-Standard (Setext-Ueberschriften + "Meta-information"-Abschnitt),
# ohne die Quelldatei zu aendern:
#   1. Standard:  "Question\n====" / "Solution\n====" / Meta-information
#   2. ATX:       "## Question" / "## Solution" / Meta-information
#   3. Quarto:    "## Aufgabe|Exercise" / "## Loesung|Solution", Metadaten nur im YAML-Header
library(exams2forms)

quiz_normalisieren <- function(x) {
  x <- sub("\r$", "", x)

  # Ueberschriften (nur Ebene 1-2, nur jeweils die erste)
  setext <- function(x, muster, titel) {
    k <- grep(paste0("^#{1,2} +(", muster, ") *$"), x)
    if (length(k) == 0) return(x)
    k <- k[1]
    x[k] <- titel
    append(x, "========", after = k)
  }
  x <- setext(x, "Question|Aufgabe|Exercise", "Question")
  x <- setext(x, "Solution|Lösung|Loesung", "Solution")
  x <- sub("^Meta-information *$", "Meta-information", x)

  # Meta-information aus dem YAML-Header ergaenzen, falls nicht vorhanden
  if (!any(x == "Meta-information")) {
    yaml_end <- which(x == "---")
    meta <- character()
    if (length(yaml_end) >= 2 && yaml_end[1] == 1) {
      kopf <- x[2:(yaml_end[2] - 1)]
      meta <- grep("^ex[a-z]+:", kopf, value = TRUE)
    }
    meta <- sub("^(exsolution: *)(r +)(.*[^ ]) *$", "\\1`r \\3`", meta)
    x <- c(x, "", "Meta-information", "================", meta)
  }
  x
}

quiz <- function(datei, seed = getOption("quiz.seed", 42), ...) {
  x <- quiz_normalisieren(readLines(datei, encoding = "UTF-8", warn = FALSE))
  tmp <- file.path(tempdir(), basename(datei))
  writeLines(x, tmp, useBytes = TRUE)
  set.seed(seed)
  exams2forms(tmp, edir = dirname(normalizePath(datei)), ...)
}
