#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = FALSE)
script_arg <- args[grepl("^--file=", args)]
if (length(script_arg) != 1L) stop("Run with Rscript source/render_oriented_six_port.R")
script_path <- normalizePath(sub("^--file=", "", script_arg))
root <- dirname(dirname(script_path))
output_dir <- file.path(root, "artifacts")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

navy <- "#0B4F6C"
teal <- "#168A84"
orange <- "#E56B1F"
ink <- "#18252E"
gray <- "#98A7B3"
light <- "#DCE5EA"

ports <- c(1, 5, 7, 11, 13, 17)
lifted <- c(1, 5, 7, 11, 13, 17, 19)
gaps <- diff(lifted)

polar <- function(value, radius = 1) {
  angle <- pi / 2 - 2 * pi * value / 18
  cbind(radius * cos(angle), radius * sin(angle))
}

draw_arc <- function(start, finish, color) {
  values <- seq(start, finish, length.out = 90)
  xy <- polar(values, 1)
  lines(xy[, 1], xy[, 2], col = color, lwd = 2.2)
  n <- nrow(xy)
  arrows(xy[n - 5, 1], xy[n - 5, 2], xy[n, 1], xy[n, 2],
         length = 0.075, angle = 24, code = 2, col = color, lwd = 2.2)
}

draw_figure <- function() {
  par(mfrow = c(1, 2), mar = c(2.4, 2.5, 3.2, 1.4),
      oma = c(1.8, 0.5, 1.2, 0.5), family = "serif",
      xaxs = "i", yaxs = "i")

  # Panel a: the complete residue circle and reversing chords.
  plot.new()
  plot.window(xlim = c(-1.32, 1.32), ylim = c(-1.25, 1.25), asp = 1)
  circle <- polar(seq(0, 18, length.out = 721), 1)
  lines(circle[, 1], circle[, 2], col = light, lwd = 1.4)

  all_xy <- polar(0:17, 1)
  points(all_xy[, 1], all_xy[, 2], pch = 16, cex = 0.38, col = light)
  label_xy <- polar(0:17, 1.12)
  text(label_xy[, 1], label_xy[, 2], labels = 0:17,
       cex = 0.55, col = gray)

  opposite_pairs <- list(c(1, 17), c(5, 13), c(7, 11))
  for (pair in opposite_pairs) {
    xy <- polar(pair, 0.96)
    segments(xy[1, 1], xy[1, 2], xy[2, 1], xy[2, 2],
             col = gray, lty = 3, lwd = 1.1)
  }

  for (i in seq_along(gaps)) {
    draw_arc(lifted[i], lifted[i + 1], if (gaps[i] == 4) navy else orange)
    midpoint <- (lifted[i] + lifted[i + 1]) / 2
    xy <- polar(midpoint, 0.82)
    text(xy[1, 1], xy[1, 2], labels = paste0("+", gaps[i]),
         cex = 0.72, font = 2,
         col = if (gaps[i] == 4) navy else orange)
  }

  port_xy <- polar(ports, 1)
  points(port_xy[, 1], port_xy[, 2], pch = 21, cex = 1.55,
         bg = teal, col = "white", lwd = 1.2)
  text(port_xy[, 1], port_xy[, 2], labels = ports,
       cex = 0.64, col = "white", font = 2)
  text(0, 0.08, expression(0 %<->% 1), cex = 1.15, col = ink)
  text(0, -0.10, "oriented root", cex = 0.68, col = gray)
  title("(a) Reversible six-port cycle", cex.main = 0.95, font.main = 1)

  # Panel b: one lifted bar, with the return made explicit.
  plot(0:6, lifted, type = "n", axes = FALSE,
       xlab = "advance k", ylab = "lifted residue", xlim = c(-0.3, 6.65),
       ylim = c(0, 21))
  axis(1, at = 0:6, col = gray, col.axis = ink, cex.axis = 0.72)
  axis(2, at = lifted, las = 1, col = gray, col.axis = ink, cex.axis = 0.68)
  abline(h = c(1, 19), col = light, lty = 3)

  for (i in seq_along(gaps)) {
    color <- if (gaps[i] == 4) navy else orange
    segments(i - 1, lifted[i], i, lifted[i + 1], col = color, lwd = 2.5)
    text(i - 0.5, (lifted[i] + lifted[i + 1]) / 2,
         paste0("+", gaps[i]), pos = 4, offset = 0.25,
         cex = 0.72, font = 2, col = color)
  }
  points(0:6, lifted, pch = 21, cex = 1.25, bg = teal, col = "white", lwd = 1.1)
  text(0:5, lifted[1:6], labels = ports, pos = 3, offset = 0.45,
       cex = 0.68, col = ink)
  text(6, 19, expression(19 == 1 ~~ "(mod 18)"), pos = 3,
       offset = 0.45, cex = 0.72, col = ink)

  text(1.7, 18.2, expression(T^6 == I), cex = 0.82, col = ink)
  text(3.15, 18.2, expression(M^2 == I), cex = 0.82, col = ink)
  text(4.75, 18.2, expression(M*T*M == T^{-1}), cex = 0.82, col = ink)
  text(3.2, 16.25, expression(frac(57, 14) %<->% frac(14, 57)),
       cex = 0.94, col = ink)
  title("(b) One complete return bar", cex.main = 0.95, font.main = 1)

  mtext("Oriented Reciprocal Six-Port Law · exact finite structure",
        side = 3, outer = TRUE, cex = 1.05, font = 2, col = ink)
  mtext("Reduced residues modulo 18; navy = +4, orange = +2.",
        side = 1, outer = TRUE, cex = 0.72, col = gray)
}

png(file.path(output_dir, "Oriented_Reciprocal_Six_Port_Law.png"),
    width = 3000, height = 1550, res = 300, type = "quartz")
draw_figure()
dev.off()

pdf(file.path(output_dir, "Oriented_Reciprocal_Six_Port_Law.pdf"),
    width = 10, height = 5.2, family = "serif", pointsize = 10,
    useDingbats = FALSE)
draw_figure()
dev.off()

cat("Rendered Oriented Reciprocal Six-Port Law figure.\n")
