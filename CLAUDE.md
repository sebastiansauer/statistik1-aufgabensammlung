# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projekt-Überblick

Quarto-Buchprojekt: eine deutschsprachige Aufgabensammlung zur Einführung in die Statistik (Schwerpunkt Prognose-Modellierung). Begleitbuch: <https://sebastiansauer.github.io/statistik1/>.


## Themen
- Rahmen und Grundlagen der quantitativen Forschung
- Daten einlesen mit R sowie Grundlagen von R
- Daten umformen mit dplyr
- Daten visualisieren
- Daten zusammenfassen zu Lagemaßen
- Variabilität von Daten bestimmen
- Zusammen inkl. Korrelation
- Regression

## Build-Befehle

```bash
# Ganzes Buch rendern
quarto render

# Live-Vorschau (mit Hot-Reload)
quarto preview

# Einzelne Aufgabe rendern
quarto render exrs/posts/<aufgabe>/<aufgabe>.rmd

# Freeze-Cache löschen (erzwingt Neuberechnung aller R-Chunks)
rm -rf _freeze/
```

Das Projekt nutzt `freeze: auto` und `cache: true` – R-Code wird nur neu ausgeführt, wenn sich die Quelldatei ändert.

## Architektur

### Buchstruktur

`_quarto.yml` definiert alle Kapitel explizit. Neue Aufgaben müssen dort unter dem passenden `part:` eingetragen werden, bevor sie im Buch erscheinen.

### `exrs/` – Git-Submodul

Alle Aufgaben liegen im Submodul `exrs/` (→ <https://github.com/sebastiansauer/aufgabensammlung>), mit 624+ Aufgaben unter `exrs/posts/<slug>/`. Änderungen an Aufgaben müssen im Submodul selbst committet und dann im Hauptrepo als neue Submodul-Referenz eingetragen werden.

```bash
# Submodul aktualisieren
git submodule update --remote exrs
```

### Aufgaben-Format (r-exams)

Jede Aufgabe ist eine `.rmd`- oder `.qmd`-Datei mit r-exams-YAML-Header:

```yaml
extype: schoice   # oder: num, string, mchoice
exsolution: ...   # korrekte Antwort (dynamisch via R möglich)
exshuffle: no
categories:
  - regression
```

Dynamische Aufgaben generieren Parameterwerte per R-Code im `data generation`-Chunk und verwenden `answerlist()` für Antwortoptionen und Lösungen.

### Datensätze

Gemeinsam genutzte Datensätze liegen unter `data/` (CSV, XLSX). Aufgabenspezifische Daten können direkt im R-Code erzeugt oder aus Paketen (z. B. `ggplot2::diamonds`, `openintro::mariokart`) geladen werden.

### `specifics/`

- `bib-local.bib` – Literaturnachweise
- `apa7.csl` – Zitierstil
- `webex.css` / `webex.js` – CSS/JS des Pakets `exams2forms` (Quiz-Elemente im HTML-Output); bei Paket-Updates durch die Dateien aus `system.file("webex", package = "exams2forms")` ersetzen
- `quiz.R` – Funktion `quiz()`, bindet eine Aufgabe per `exams2forms` ein (siehe unten)


### Quiz-Rendering mit `exams2forms`

`_quarto.yml` listet nicht mehr die Aufgaben selbst, sondern generierte **Wrapper-Kapitel** `quiz/<ordner>.qmd`. Jeder Wrapper ruft `quiz()` (`specifics/quiz.R`) auf, das die Aufgabe aus `exrs/posts/` per `exams2forms` als HTML-Quiz rendert. Das Submodul `exrs/` bleibt unverändert.

- **Neue Aufgabe:** wie bisher als `exrs/posts/<ordner>/<datei>` in `_quarto.yml` eintragen und dann `Rscript scripts/make-quiz-chapters.R` ausführen. Das Skript erzeugt den Wrapper und biegt den Eintrag auf `quiz/<ordner>.qmd` um.
- **Aufgabe geändert:** Skript erneut ausführen. Der Quell-Hash im Wrapper ändert sich, dadurch rechnet `freeze: auto` neu.
- **Ausnahmen** (Aufgaben bleiben unverändert als Kapitel): `quiz/ausnahmen.yml`. Die Zuordnung Wrapper → Quelle steht in `quiz/quellen.csv`.
- **Wrapper nicht von Hand ändern**, sie werden überschrieben.
- **Aufgabenformate:** `quiz()` normalisiert drei Formate (Setext-Überschriften, ATX `## Question`, Quarto `## Aufgabe`/`## Exercise` mit Metadaten nur im YAML).
- **`string`-Aufgaben** sind nur dann interaktiv, wenn die Lösung kurz ist (höchstens 40 Zeichen, einzeilig); Leerzeichen und Groß-/Kleinschreibung sind egal. Sonst erscheint die Aufgabe klassisch mit einklappbarer Lösung.
- **Rückfall bei Fehlern:** scheitert `exams2forms`, wird die Aufgabe normal geknittet (Frage plus einklappbare Lösung); als letzter Ausweg erscheint ein Hinweiskasten. Aufgaben mit `textfeatures` werden ausgelassen.
- **Protokoll:** Ist die Umgebungsvariable `QUIZ_LOG` gesetzt, schreibt `quiz()` pro Aufgabe den gewählten Modus (`interaktiv`, `klassisch`, `klassisch-knit`, `fehler`, `ausgelassen`) in diese Datei.
- `quiz.R` nutzt die interne Funktion `exams2forms:::json_answer()`; bei Paket-Updates prüfen.

### Quizze

Manche Aufgaben sind Quizze. Quizze zeichnen sich durch vorgegebene Antworten aus (meist 4 oder 5), von denen eine (oder mehr) richtig sind. 
Quizze erkennt man an den Antwortoptionen nach der Zeile "Answerlist". Außerdem haben Sie unten einen Abschnitt "Meta-information". Dort ist unter "exsolution" codiert, welche Antwort richtig ist. "0" steht für eine falsche Antwortoption, und "1" für eine richtige. So würde der Code "01000" bedeuten, dass die erste Antwortoption falsch ist, die zweite Antwortoption richtig, und die dritte, vierte und fünfte Antwortoption falsch ist.

