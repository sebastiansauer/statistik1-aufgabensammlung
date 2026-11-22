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

  # Eigene Abbildungsordner (fig.path = "chunk-img/") wuerden von exams2forms
  # nicht eingebettet -> wie in den uebrigen Aufgaben auf "" setzen.
  x <- gsub("fig\\.path *= *[\"'][^\"']+[\"']", "fig.path = \"\"", x)

  # Meta-information aus dem YAML-Header ergaenzen, falls nicht vorhanden
  if (!any(x == "Meta-information")) {
    yaml_end <- which(x == "---")
    meta <- character()
    if (length(yaml_end) >= 2 && yaml_end[1] == 1) {
      kopf <- x[2:(yaml_end[2] - 1)]
      meta <- grep("^ex[a-z]+:", kopf, value = TRUE)
    }
    meta <- sub("^(ex[a-z]+: *)r +(.*[^ ]) *$", "\\1`r \\2`", meta)
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

# Aufgaben, auf die im Buch verzichtet wird (Paket nicht verfuegbar)
quiz_ausgelassen_muster <- "textfeatures"

# Rueckfall 1: Aufgabe ohne exams2forms knitten und Frage/Loesung klassisch
# darstellen (Bilder als base64 eingebettet).
quiz_knit_klassisch <- function(tmp, seed) {
  # In frischem R-Prozess knitten: nach einem Fehler in exams2forms bleibt in
  # der aktuellen Sitzung Zustand zurueck, der das Knitten stoert.
  out <- tempfile(fileext = ".md")
  xfun::Rscript_call(function(tmp, out, seed, libs, wd) {
    .libPaths(libs); setwd(wd); set.seed(seed)
    knitr::knit(tmp, out, quiet = TRUE, envir = new.env(), encoding = "UTF-8")
  }, list(tmp, out, seed, .libPaths(), getwd()))
  md <- readLines(out, encoding = "UTF-8", warn = FALSE)
  setext <- function(titel) which(md == titel & grepl("^=+$", c(md[-1], "")))[1]
  q <- setext("Question"); l <- setext("Solution"); m <- setext("Meta-information")
  if (is.na(q)) stop("keine Question-Ueberschrift")
  ende_q <- if (is.na(l)) length(md) else l - 1
  frage <- md[(q + 2):ende_q]
  loesung <- if (is.na(l)) character() else md[(l + 2):(if (is.na(m)) length(md) else m - 1)]
  # r-exams-Zwischenueberschrift "Answerlist" (cloze: Liste der Teilfragen) ausblenden
  ohne_answerlist <- function(z) {
    k <- which(z == "Answerlist" & c(z[-1], "") %in% c("----------", "--------"))
    if (length(k)) z[-c(k, k + 1)] else z
  }
  frage <- ohne_answerlist(frage); loesung <- ohne_answerlist(loesung)
  einbetten <- function(z) {
    for (i in grep("!\\[[^]]*\\]\\([^)]+\\)", z)) {
      pfad <- sub(".*!\\[[^]]*\\]\\(([^) ]+).*", "\\1", z[i])
      if (file.exists(pfad))
        z[i] <- sub("(!\\[[^]]*\\]\\()[^) ]+", paste0("\\1", xfun::base64_uri(pfad)), z[i])
    }
    z
  }
  c("::: {.aufgabe-klassisch}", einbetten(frage), ":::", "",
    "::: {.callout-tip collapse=\"true\" title=\"L\u00f6sung\"}", einbetten(loesung), ":::")
}

# Rueckfall 2: Hinweis statt Aufgabe, damit das Buch nie abbricht
quiz_hinweis <- function(datei, grund) {
  warning("quiz(): ", basename(datei), " nicht darstellbar: ", grund, call. = FALSE)
  c("::: {.callout-warning title=\"Aufgabe derzeit nicht darstellbar\"}",
    paste0("`", basename(datei), "`"), ":::")
}

# Quarto installiert beim Rendern knitr-Hooks, die jede Chunk-Ausgabe in
# "::: {.cell}"-Bloecke packen. Innerhalb von exams2forms haengt sich der
# schliessende ":::" dann an die letzte Antwortoption. Deshalb exams2forms mit
# Standard-Hooks und -Optionen von knitr ausfuehren und danach alles zuruecksetzen.
quiz_ohne_quarto_hooks <- function(expr) {
  hooks <- knitr::knit_hooks$get()
  chunk <- knitr::opts_chunk$get()
  knit  <- knitr::opts_knit$get()
  on.exit({
    knitr::knit_hooks$set(hooks)
    knitr::opts_chunk$set(chunk)
    knitr::opts_knit$set(knit)
  })
  knitr::knit_hooks$restore()
  knitr::opts_chunk$restore()
  knitr::opts_knit$restore()
  expr
}

quiz_interaktiv <- function(tmp, edir, seed, x, ...) {
  rendern <- function(...) {
    set.seed(seed)
    quiz_ohne_quarto_hooks(capture.output(exams2forms(tmp, edir = edir, ...)))
  }
  ist_string <- any(grepl("^extype: *string *$", x))
  if (!ist_string) return(list(modus = "interaktiv", html = rendern(...)))

  # string: Leerzeichen und Gross-/Kleinschreibung egal
  probe <- rendern(obfuscate = FALSE, usespace = FALSE, usecase = FALSE, ...)
  antworten <- quiz_antworten(probe)
  if (quiz_string_geeignet(antworten))
    list(modus = "interaktiv", html = quiz_loesung_ohne_leerzeichen(probe, antworten))
  else
    list(modus = "klassisch", html = quiz_klassisch(probe))
}

# Rueckgabe (unsichtbar): "interaktiv", "klassisch", "klassisch-knit",
# "fehler" oder "ausgelassen"
# Vor jedem Zaun ":::" muss eine Leerzeile stehen, sonst liest Pandoc ihn als
# Text der letzten Antwortoption (sichtbares ":::" im Quiz).
quiz_leerzeilen <- function(z) {
  k <- which(grepl("^:::", z) & c(FALSE, nzchar(trimws(z[-length(z)]))) &
             !c(FALSE, grepl("^:::", z[-length(z)])))
  for (i in rev(k)) z <- append(z, "", after = i - 1)
  z
}

# Die Auswahl-Gruppen (Radio-Buttons/Checkboxen) sind HTML-Zeilen. Quarto liest sie
# je nach Pandoc-Einstellung als nicht geschlossenes <div>; dann landen die
# folgenden ":::" als Text im Quiz. Als rohen HTML-Block kennzeichnen.
quiz_rohhtml <- function(z) {
  k <- grep("^<div class='webex-(radiogroup|checkboxgroup)'", z)
  for (i in rev(k)) z <- append(z, c("```{=html}", z[i], "```"), after = i)[-i]
  z
}

quiz_nachbearbeiten <- function(z) quiz_leerzeilen(quiz_rohhtml(z))

quiz_protokoll <- function(datei, modus) {
  log <- Sys.getenv("QUIZ_LOG")
  if (nzchar(log))
    cat(basename(dirname(datei)), modus, sep = "\t", file = log, append = TRUE, fill = TRUE)
  invisible(modus)
}

quiz <- function(datei, seed = getOption("quiz.seed", 42), ...) {
  quiz_protokoll(datei, quiz_ausfuehren(datei, seed, ...))
}

quiz_ausfuehren <- function(datei, seed, ...) {
  roh <- readLines(datei, encoding = "UTF-8", warn = FALSE)
  if (any(grepl(quiz_ausgelassen_muster, roh, ignore.case = TRUE))) return(invisible("ausgelassen"))

  x <- quiz_normalisieren(roh)
  tmp <- file.path(tempdir(), basename(datei))
  writeLines(x, tmp, useBytes = TRUE)
  edir <- dirname(normalizePath(datei))

  erg <- tryCatch(quiz_interaktiv(tmp, edir, seed, x, ...), error = function(e) e)
  # Bleiben Quarto-Zellen ("::: {.cell...}") im Text stehen (z.B. bei kableExtra),
  # waere das Ergebnis kaputt -> wie ein Fehler behandeln (Rueckfall).
  if (!inherits(erg, "error") && any(grepl("::: *\\{\\.cell", erg$html)))
    erg <- simpleError("Quarto-Zellen im Ausgabetext")
  if (!inherits(erg, "error")) {
    cat(quiz_nachbearbeiten(erg$html), sep = "\n")
    return(invisible(erg$modus))
  }
  kl <- tryCatch(quiz_knit_klassisch(tmp, seed), error = function(e) e)
  if (!inherits(kl, "error")) {
    cat(quiz_nachbearbeiten(kl), sep = "\n")
    return(invisible("klassisch-knit"))
  }
  cat(quiz_nachbearbeiten(quiz_hinweis(datei, conditionMessage(erg))), sep = "\n")
  invisible("fehler")
}
