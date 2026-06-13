library(ggplot2)
library(dplyr)
library(grid)

set.seed(42)

# --- Simulierte Daten für drei Visualisierungen ---

# Regressions-Scatter
n <- 280
x  <- rnorm(n, 5, 1.8)
y  <- 1.2 + 0.9 * x + rnorm(n, 0, 1.6)
df_reg <- data.frame(x = x, y = y)

# Residuen-Punkte (zweite "Wolke" im Hintergrund, kleiner)
n2 <- 120
x2 <- rnorm(n2, 5, 2.2)
y2 <- 1.2 + 0.9 * x2 + rnorm(n2, 0, 3.2)
df_res <- data.frame(x = x2, y = y2)

# --- Farbpalette ---
bg      <- "#1A2332"   # fast schwarz-blau
col1    <- "#4FC3F7"   # hellblau (Punkte)
col2    <- "#FF6B6B"   # koralle (Regressionslinie)
col3    <- "#A5D6A7"   # mintgrün (zweite Punktwolke)
col_txt <- "#FFFFFF"

# --- Haupt-Scatter-Plot ---
p_main <- ggplot() +
  geom_point(data = df_res, aes(x = x, y = y),
             color = col3, alpha = 0.18, size = 1.8) +
  geom_point(data = df_reg, aes(x = x, y = y),
             color = col1, alpha = 0.55, size = 2.6) +
  geom_smooth(data = df_reg, aes(x = x, y = y),
              method = "lm", se = TRUE,
              color = col2, fill = col2, alpha = 0.15,
              linewidth = 2.2) +
  # Achsenbeschriftungen als Platzhalter für den Stil
  labs(x = "Prädiktor  x", y = "Kriterium  y") +
  theme_minimal(base_size = 28) +
  theme(
    plot.background  = element_rect(fill = bg, color = NA),
    panel.background = element_rect(fill = bg, color = NA),
    panel.grid.major = element_line(color = "#2E4057", linewidth = 0.4),
    panel.grid.minor = element_blank(),
    axis.text        = element_text(color = "#90A4AE", size = 22),
    axis.title       = element_text(color = "#90A4AE", size = 26),
    axis.ticks       = element_blank()
  )

# --- Cover zusammensetzen (Gesamtbild via ggdraw-Technik mit cowplot ODER
#     einfache Annotation direkt) ---
# Wir verwenden ein leeres ggplot als Canvas und annotieren alles.

cover <- ggplot() +
  # Hintergrund
  theme_void() +
  theme(plot.background = element_rect(fill = bg, color = NA)) +

  # Dekorativer Streifen oben
  annotate("rect", xmin = 0, xmax = 1, ymin = 0.88, ymax = 1,
           fill = col2, alpha = 0.85) +

  # Dekorativer Streifen unten
  annotate("rect", xmin = 0, xmax = 1, ymin = 0, ymax = 0.09,
           fill = col1, alpha = 0.25) +

  # Titel im roten Streifen
  annotate("text", x = 0.5, y = 0.958,
           label = "Aufgabensammlung",
           color = col_txt, size = 12, fontface = "bold",
           hjust = 0.5, vjust = 0.5, family = "sans") +

  # Untertitel
  annotate("text", x = 0.5, y = 0.83,
           label = "Statistik 1",
           color = col1, size = 18, fontface = "bold",
           hjust = 0.5, vjust = 0.5, family = "sans") +

  annotate("text", x = 0.5, y = 0.765,
           label = "Einführung in die Prognose-Modellierung",
           color = "#B0BEC5", size = 6,
           hjust = 0.5, vjust = 0.5, family = "sans") +

  # Trennlinie
  annotate("segment", x = 0.08, xend = 0.92, y = 0.725, yend = 0.725,
           color = col2, linewidth = 0.8) +

  # Autor
  annotate("text", x = 0.5, y = 0.050,
           label = "Sebastian Sauer",
           color = col_txt, size = 8, fontface = "bold",
           hjust = 0.5, vjust = 0.5, family = "sans") +

  # Kleiner Hinweis
  annotate("text", x = 0.5, y = 0.022,
           label = "sebastiansauer.github.io/statistik1",
           color = "#546E7A", size = 4,
           hjust = 0.5, vjust = 0.5, family = "sans") +

  xlim(0, 1) + ylim(0, 1)

# --- Visualisierung als Inset einbetten ---
# Wir speichern den Plot zunächst als Grob
library(cowplot)

final <- ggdraw() +
  draw_plot(cover) +
  draw_plot(p_main,
            x = 0.05, y = 0.15,
            width = 0.90, height = 0.52)

# --- Speichern ---
outdir  <- "img/statistik1-cover"
outfile <- file.path(outdir, "statistik1-cover.001.png")

ggsave(outfile, plot = final,
       width  = 2100 / 300,
       height = 2970 / 300,
       dpi    = 300,
       bg     = bg)

message("Cover gespeichert: ", outfile)
