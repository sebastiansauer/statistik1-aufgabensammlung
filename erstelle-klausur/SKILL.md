---
name: klausur-erstellen
description: >
  Erstellt eine Klausur im R-exams-Format aus QMD-Aufgabendateien.
  Nutze diesen Skill immer, wenn der Nutzer eine Klausur, einen Test, eine Prüfung
  oder Aufgabensammlung erstellen möchte, oder wenn QMD-Dateien in das R-exams-Format
  (schoice, Rmd) umgewandelt werden sollen. Auch bei Begriffen wie "exams", "rexams",
  "Aufgabenpool", "Prüfungsaufgaben" oder "exrs/" diesen Skill verwenden.
---

# Skill: Klausur erstellen (QMD → R exams)

## Überblick

Dieser Skill liest QMD-Aufgabendateien aus dem Ordner `exrs/`, wählt zufällig eine
vom Nutzer bestimmte Anzahl aus, und wandelt sie in `.Rmd`-Dateien im R-`exams`-Format
(Typ `schoice`) um. Die Ausgabe landet im Ordner `rexams/`.

---

## Schritt 1: Anzahl der Aufgaben erfragen

Frage den Nutzer: **„Wie viele Aufgaben soll die Klausur enthalten?"**

---

## Schritt 2: QMD-Dateien einlesen und zufällig ziehen

```bash
ls exrs/*.qmd
```

Ziehe zufällig N Dateien (N = Anzahl vom Nutzer). Nutze dafür bash:

```bash
ls exrs/*.qmd | shuf -n N
```

---

## Schritt 3: Jede QMD-Datei parsen

Lese jede gezogene Datei und extrahiere:

### 3a. YAML-Frontmatter
Extrahiere `exname`, `categories`, `date`, `title` aus dem YAML-Block (zwischen `---` und `---`).

### 3b. Aufgabentext
Suche nach der Sektion `## Aufgabe` oder `## Exercise` (case-insensitiv).
Alles bis zur nächsten `##`-Überschrift ist der Aufgabentext (inkl. R-Code-Chunks).

### 3c. Antwortoptionen aus der Lösung
Suche nach der Sektion `## Lösung` oder `## Solution` (case-insensitiv).

- Die Bullet-Liste (`- ...`) enthält alle Antwortoptionen.
- Es sollten **genau 5 Optionen** vorhanden sein.
  - Sind es **mehr als 5**: Wähle die 5 inhaltlich relevantesten aus (die richtige muss dabei sein).
  - Sind es **weniger als 5**: Ergänze eigene, plausible Distraktoren.
- **Fehlt die `## Lösung`-Sektion komplett**: Formuliere Lösung und Distraktoren selbst.
  Füge in der fertigen `.Rmd`-Datei einen Kommentar ein:
  `% ACHTUNG - NOCH ZU KONTROLLIEREN!`

### 3d. Richtige Antwort bestimmen
Analysiere die 5 Antwortoptionen inhaltlich und bestimme, welche **eine** Option korrekt ist.
Merke dir ihren Index (1–5) für `exsolution`.

---

## Schritt 4: R-exams `.Rmd`-Datei erstellen

Erstelle für jede Aufgabe eine Datei `rexams/<exname>.Rmd` nach folgendem Template:

```markdown
---
exname: <exname>
extype: schoice
exsolution: <5-stelliger Binärstring, z.B. "01000" wenn Option 2 richtig>
exshuffle: 5
expoints: 1
categories:
<categories aus Original, z.B.: - R\n- probability>
date: '<date>'
title: <title>
---

```{r global-knitr-options, include=FALSE, message=FALSE}
knitr::opts_chunk$set(fig.pos = 'H',
                      fig.asp = 0.618,
                      fig.width = 4,
                      fig.cap = "",
                      fig.path = "",
                      echo = FALSE,
                      message = FALSE,
                      warning = FALSE,
                      fig.show = "hold")
```

## Question

<Aufgabentext hier, inkl. R-Code-Chunks>

## Solution

<Lösungstext / Erklärung (optional, kann leer bleiben)>

## Meta-information

extype: schoice
exsolution: <5-stelliger Binärstring>
exname: <exname>
exshuffle: 5
```

### Wichtige Formatregeln für `exsolution`
- 5-stelliger Binärstring: eine `1` an der Position der richtigen Antwort, sonst `0`
- Beispiel: Option 3 ist richtig → `"00100"`
- Die Reihenfolge der Antwortoptionen im `## Solution`-Block entspricht den Positionen

### Antwortoptionen im `## Question`-Block
Die 5 Antwortoptionen werden als Answerlist eingebettet:

```markdown
Answerlist
----------
* <Option 1>
* <Option 2>
* <Option 3>
* <Option 4>
* <Option 5>
```

---

## Schritt 5: Ausgabe bestätigen

Nach dem Erstellen aller Dateien:
- Liste alle erzeugten Dateien auf: `ls rexams/`
- Weise den Nutzer auf alle Stellen hin, die mit `ACHTUNG - NOCH ZU KONTROLLIEREN!` markiert sind.
- Weise darauf hin, ob Antwortoptionen ergänzt wurden.

---

## Referenz: Vollständiges Beispiel

Siehe `references/beispiel.md` für ein vollständiges Beispiel einer Eingabe-QMD
und der zugehörigen Ausgabe-Rmd.
