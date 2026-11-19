# make-quiz-chapters.R
#
# Erzeugt pro Aufgabe ein Wrapper-Kapitel quiz/<ordner>.qmd, das die Aufgabe
# ueber quiz() (specifics/quiz.R, exams2forms) einbindet, und biegt die Eintraege
# in _quarto.yml von exrs/posts/<ordner>/<datei> auf quiz/<ordner>.qmd um.
#
# Aufruf (vom Projektroot):   Rscript scripts/make-quiz-chapters.R
#
# - Neue Aufgabe: wie bisher in _quarto.yml als exrs/posts/... eintragen und das
#   Skript erneut ausfuehren.
# - Aenderte sich der Quelltext einer Aufgabe oder specifics/quiz.R, Skript erneut
#   ausfuehren: Der Stand im Wrapper (Kommentar + cache.extra) aendert sich, damit
#   rechnen `freeze: auto` und der knitr-Cache neu.
# - Ausnahmen (bleiben unveraendert): quiz/ausnahmen.yml
# - Zuordnung Wrapper -> Quelldatei: quiz/quellen.csv

stopifnot(file.exists("_quarto.yml"), dir.exists("exrs/posts"))
dir.create("quiz", showWarnings = FALSE)

ausnahmen <- names(yaml::read_yaml("quiz/ausnahmen.yml"))
zuordnung_datei <- "quiz/quellen.csv"
zuordnung <- if (file.exists(zuordnung_datei)) {
  read.csv(zuordnung_datei, stringsAsFactors = FALSE)
} else data.frame(ordner = character(), quelle = character())

# 1. _quarto.yml umbiegen -----------------------------------------------------
yml <- readLines("_quarto.yml", encoding = "UTF-8")
muster <- "^(\\s*-\\s+)(exrs/posts/([^/]+)/([^\\s#]+))(\\s*)$"
fehlend <- character()
for (i in grep(muster, yml, perl = TRUE)) {
  m <- regmatches(yml[i], regexec(muster, yml[i], perl = TRUE))[[1]]
  quelle <- m[3]; ordner <- m[4]
  if (ordner %in% ausnahmen) next
  if (!file.exists(quelle)) { fehlend <- c(fehlend, quelle); next }
  zuordnung <- rbind(zuordnung[zuordnung$ordner != ordner, ],
                     data.frame(ordner = ordner, quelle = quelle))
  yml[i] <- paste0(m[2], "quiz/", ordner, ".qmd")
}
writeLines(yml, "_quarto.yml", useBytes = TRUE)
zuordnung <- zuordnung[order(zuordnung$ordner), ]
write.csv(zuordnung, zuordnung_datei, row.names = FALSE)

# 2. Wrapper erzeugen -----------------------------------------------------------
titel_von <- function(datei) {
  x <- readLines(datei, encoding = "UTF-8", warn = FALSE)
  x <- sub("\r$", "", x)
  ende <- which(x == "---")
  kopf <- if (length(ende) >= 2 && ende[1] == 1) x[2:(ende[2] - 1)] else character()
  t <- tryCatch(yaml::yaml.load(paste(kopf, collapse = "\n"))$title, error = function(e) NULL)
  if (is.null(t) || !nzchar(t)) basename(dirname(datei)) else as.character(t)
}
seed_von <- function(ordner) sum(utf8ToInt(ordner) * seq_along(utf8ToInt(ordner))) %% 100000

for (k in seq_len(nrow(zuordnung))) {
  ordner <- zuordnung$ordner[k]; quelle <- zuordnung$quelle[k]
  if (!file.exists(quelle)) { fehlend <- c(fehlend, quelle); next }
  titel <- gsub("\"", "\\\\\"", titel_von(quelle))
  md5 <- unname(tools::md5sum(quelle))
  # Aufgabe UND quiz.R gehen in den Cache-Schluessel ein, damit freeze/knitr-Cache
  # bei Aenderungen an einer von beiden neu rechnen.
  stand <- paste0(md5, "-", substr(unname(tools::md5sum("specifics/quiz.R")), 1, 12))
  wrapper <- c(
    "---",
    paste0("title: \"", titel, "\""),
    "---",
    "",
    "<!-- ERZEUGT von scripts/make-quiz-chapters.R, nicht von Hand aendern. -->",
    paste0("<!-- quelle: ", quelle, " | stand: ", stand, " -->"),
    "",
    "```{r}",
    "#| include: false",
    "#| cache: false",
    "root <- Sys.getenv(\"QUARTO_PROJECT_DIR\", unset = normalizePath(\"..\"))",
    "source(file.path(root, \"specifics\", \"quiz.R\"))",
    "```",
    "",
    "```{r}",
    "#| echo: false",
    "#| results: asis",
    paste0("#| cache.extra: \"", stand, "\""),
    paste0("quiz(file.path(root, \"", quelle, "\"), seed = ", seed_von(ordner), ")"),
    "```"
  )
  writeLines(wrapper, file.path("quiz", paste0(ordner, ".qmd")), useBytes = TRUE)
}

# alte Wrapper ohne Eintrag entfernen
alt <- setdiff(sub("\\.qmd$", "", list.files("quiz", pattern = "\\.qmd$")), zuordnung$ordner)
if (length(alt)) { file.remove(file.path("quiz", paste0(alt, ".qmd"))); message("entfernt: ", paste(alt, collapse = ", ")) }

message(nrow(zuordnung), " Wrapper erzeugt.")
if (length(fehlend)) message("Quelldatei fehlt (Eintrag unveraendert): ", paste(unique(fehlend), collapse = ", "))
