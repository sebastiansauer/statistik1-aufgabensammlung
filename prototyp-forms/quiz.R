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

# Eine string-Aufgabe eignet sich nur dann als Quiz, wenn die Loesung kurz
# ist (ein Wort oder ein einzelner R-Befehl). Alle anderen string-Aufgaben
# (exsolution NA/leer, lange Texte) werden nicht interaktiv gerendert.
quiz_string_max_zeichen <- 40

quiz_antworten <- function(html) {
  m <- regmatches(html, regexpr("data-answer='[^']*'", html))
  if (length(m) == 0) return(character())
  json <- sub("^data-answer='(.*)'$", "\\1", m)
  tryCatch(as.character(jsonlite::fromJSON(json)), error = function(e) character())
}

quiz_string_geeignet <- function(antworten) {
  length(antworten) > 0 &&
    all(!is.na(antworten) & nzchar(trimws(antworten)) & !antworten %in% c("NA", "NULL", "~") &
        !grepl("\n", antworten) &
        nchar(antworten) <= quiz_string_max_zeichen)
}

# Workaround fuer exams2forms (usespace = FALSE): Das JS entfernt Leerzeichen aus
# der Eingabe, nicht aber aus der hinterlegten Loesung (ebenso Kleinschreibung). Deshalb Leerzeichen aus
# der Loesung entfernen und neu verschluesseln. Nutzt die interne Funktion
# exams2forms:::json_answer() (bei Paket-Updates pruefen).
quiz_loesung_ohne_leerzeichen <- function(html, antworten) {
  k <- grep("^<input class='webex-solveme", html)
  for (i in k) {
    alt <- sub(".* id='webex-([^']*)'.*", "\\1", html[i])
    # Verschluesselung greift nur bei reiner Hex-ID -> neue ID erzeugen
    neu_id <- paste(sample(c(0:9, letters[1:6]), 32, replace = TRUE), collapse = "")
    html <- gsub(alt, neu_id, html, fixed = TRUE)
    neu <- exams2forms:::json_answer(tolower(gsub(" ", "", antworten)), neu_id)
    html[i] <- sub("data-answer='[^']*'", paste0("data-answer='", neu, "'"), html[i])
  }
  html
}

# Nicht interaktive Darstellung: Frage normal, Loesung einklappbar, ohne Eingabefeld
quiz_klassisch <- function(html) {
  html <- html[!grepl("^<input class='webex-solveme", html)]
  k <- grep("^::: \\{\\.webex-check", html)[1]
  if (!is.na(k)) {
    zu <- which(html == ":::" & seq_along(html) > k)[1]
    html <- html[-c(k, zu)]
  }
  sub("^::: \\{\\.webex-solution\\}",
      "::: {.callout-tip collapse=\"true\" title=\"L\u00f6sung\"}", html)
}

quiz <- function(datei, seed = getOption("quiz.seed", 42), ...) {
  x <- quiz_normalisieren(readLines(datei, encoding = "UTF-8", warn = FALSE))
  tmp <- file.path(tempdir(), basename(datei))
  writeLines(x, tmp, useBytes = TRUE)
  edir <- dirname(normalizePath(datei))
  rendern <- function(...) {
    set.seed(seed)
    capture.output(exams2forms(tmp, edir = edir, ...))
  }

  ist_string <- any(grepl("^extype: *string *$", x))
  if (!ist_string) {
    cat(rendern(...), sep = "\n")
    return(invisible("interaktiv"))
  }

  # string: Leerzeichen und Gross-/Kleinschreibung egal
  probe <- rendern(obfuscate = FALSE, usespace = FALSE, usecase = FALSE, ...)
  antworten <- quiz_antworten(probe)
  if (quiz_string_geeignet(antworten)) {
    cat(quiz_loesung_ohne_leerzeichen(probe, antworten), sep = "\n")
    invisible("interaktiv")
  } else {
    cat(quiz_klassisch(probe), sep = "\n")
    invisible("klassisch")
  }
}
