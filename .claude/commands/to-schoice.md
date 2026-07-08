# Quiz-Aufgabe in schoice-Format überführen

Konvertiere eine bestehende Quiz-Aufgabe in das `schoice`-Format des R-Pakets `exams`.

## Vorgehen

1. Lies die angegebene Aufgabendatei (`.rmd` oder `.qmd`) vollständig ein.
2. Erstelle eine neue Version im `schoice`-Format mit folgender Struktur:

### Ziel-Struktur

````markdown
```{r, include=FALSE}
# optionaler Setup-Chunk (nur wenn nötig)
```



Question
========
Was ist die Hauptstadt der Schweiz?


Answerlist
----------
* Basel
* Bern
* Geneva
* Lausanne
* Zurich
* St. Gallen
* Vaduz


Solution
========
Es gibt keine offizielle Hauptstadt, aber faktisch ist Bern die Hauptstadt, da dort der Regierungssitz ist.


Answerlist
----------
* False
* True
* False
* False
* False
* False
* False


Meta-information
================
exname: <hier_dateinamen_einfügen> 
extype: schoice
exsolution: 0100000
exshuffle: 5

## Regeln

- `extype` ist immer `schoice` (single choice: genau eine richtige Antwort).
- `exsolution` ist ein Binärstring (z.B. `01000`): `1` = richtige Antwortoption, `0` = falsch. Länge = Anzahl der Antwortoptionen.
- Es gibt genau **eine** `1` im `exsolution`-String.
- Die Aufgabe bzw. Frage steht unter der Überschrift "Question". 
- Die Lösung (Antwort) steht unter der Überschrift "Solution".
- Es muss jeweils eine `Answerlist` geben unter `Question` und unter `Solution`.
- Antwortoptionen beginnen mit `*` unter `Answerlist` im Abschnitt `Question`.
- Im Abschnitt `Solution` steht für jede Antwortoption, ob sie richtig (true)  oder falsch (false) ist.
- Richtig soll immer nur die erste Antwortoption sein.- 
- `exname` = Dateiname ohne Endung (slug), stets in Kleinbuchstaben.
- `exshuffle: 5` immer setzen, unabhängig vom Wert in der Quelldatei.
- Fragetext und Antwortoptionen inhaltlich nicht verändern – nur Format anpassen.
- Es soll KEINE `excategory` Einträge unter `Meta-information` geben. Nur die 4 oben aufgeführten (exname, extype, exsolution, exshuffle).
- Falls bereits ein `Solution`-Abschnitt existiert, übernehmen. Andernfalls kurze Begründung aus dem Kontext ableiten.
- Schreibe NICHT, welche Nummer der Antwortoption richtig ist, da die Aufgaben permutiert werden (und sich die Reihenfolge ändert).

## Bilder

Falls die Quelldatei Bild-Referenzen enthält (z.B. `![](bild.jpg)`), kopiere alle referenzierten Bilddateien aus dem Quellordner in den Zielordner.

## Ausgabe

Zeige die fertige Datei vollständig im Chat, damit der Nutzer sie prüfen kann, bevor sie gespeichert wird. Frage danach, ob die Datei mit gleichem Namen plus "_schoice" angehängt (vor der Dateiendung) als neue Datei geschrieben werden soll.

