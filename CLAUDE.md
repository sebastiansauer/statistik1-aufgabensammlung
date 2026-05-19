# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Projekt-Überblick

Quarto-Buchprojekt: eine deutschsprachige Aufgabensammlung zur Einführung in die Statistik (Schwerpunkt Prognose-Modellierung). Begleitbuch: <https://sebastiansauer.github.io/statistik1/>.

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
- `webex.css` / `webex.js` – JavaScript-Interaktivität für r-exams-Fragen im HTML-Output
