# PREREQ -----------------------------------------------------------------------

options(warn = -1) # too many "missing value" with ylim & high-d polynomials

# Install vistool
if (FALSE) {
  install.packages("pak")
  pak::pak("slds-lmu/vistool")
}

# To save plotly-based figures to static images, plotly uses the kaleido python
# library, which is accessed via reticulate. You might need to run:
if (FALSE) {
    install.packages("reticulate")
    reticulate::install_miniconda()
    reticulate::conda_install("r-reticulate", "python-kaleido")
    reticulate::conda_install("r-reticulate", "plotly", channel = "plotly")
    reticulate::use_miniconda("r-reticulate")
}
# R might throw an error about not finding the `sys` library -- circumvent with
if (FALSE) reticulate::py_run_string("import sys")

library(gridExtra)
library(vistool)
source("libfuns_lm.R")

# BASIC POLYNOMIAL RELATION ----------------------------------------------------

n_points = 50L
set.seed(pi)
x = runif(n_points, min = 0, max = 3)
y = x^3 + rnorm(n_points, sd = 0.5)

plot_yx = ggplot(data.frame(x = x, y = y), aes(x, y)) +
    theme_bw() +
    geom_point()
plot_yx3 = ggplot(data.frame(x = x^3, y = y), aes(x, y)) +
    theme_bw() +
    geom_point() +
    labs(x = expression(x**3))
ggsave(
    "../figure/reg_poly_yx3.pdf", 
    grid.arrange(plot_yx, plot_yx3, ncol = 2), 
    height = 2, 
    width = 6
)

# LINEARITY IN PARAMS ----------------------------------------------------------

set.seed(pi)
plot_linearity = ggplot(
    data.frame(x = x, y = 1 + x + rnorm(n_points, sd = 0.5)), aes(x, y)
) +
    theme_bw() +
    geom_point() +
    geom_abline(intercept = 0.5, slope = 0.4, color = "blue") +
    geom_abline(intercept = 1, slope = 0.8, color = "#feb078") +
    geom_abline(intercept = 1.5, slope = 1.2, color = "#b73779") +
    ylim(c(0, 5))
ggsave(
    "../figure/reg_poly_linearity.pdf", plot_linearity, height = 2, width = 2
)

# BASIS FUNS -------------------------------------------------------------------

degrees = 1:9 
plot_basis = ggplot() +
    theme_bw()

for (j in degrees) {
    plot_basis = plot_basis  +
        stat_function(
            data.frame(x = -2:2, col = as.character(j)),
            mapping = aes(x = x, col = col),
            fun = function(x, d) x**d, 
            args = list(d = j),
            linetype = j
        )
}
plot_basis = plot_basis +
    ylim(c(-3, 3)) +
    scale_color_viridis_d(
        "degree", 
        end = 0.9, 
        direction = -1,
        option = "magma",
        guide = guide_legend(
            override.aes = list(linetype = degrees)
        )
    ) +
    theme(
        legend.text = element_text(size = 9),
        legend.key.height = unit(0.1, "lines")
    )

n_points = 100L
set.seed(pi)
x = runif(n_points, min = -2, max = 2)
y = sin(x) + rnorm(n_points, sd = 0.5)
x_seq = seq(-2, 2, by = 0.05)
y_hat = predict(lm(y ~ poly(x, 10, raw = TRUE)), data.frame(x = x_seq))

plot_weighted = plot_basis +
    geom_line( # awful hack via alpha aes to get two legends
        data.frame(x = x_seq, y = y_hat, alpha = "weighted sum"), 
        mapping = aes(x, y, alpha = alpha), col = "blue"
    ) +
    geom_point(
        data.frame(x = x, y = y), 
        mapping = aes(x, y),
        size = 0.5
    ) +
    ylim(c(-3, 3)) +
    scale_color_viridis_d(
        "degree",
        end = 0.9,
        direction = -1,
        option = "magma",
        guide = guide_legend(
            override.aes = list(linetype = degrees)
        )
    ) +
    scale_alpha_manual(values = 1) +
    guides(
        alpha = guide_legend(title = "", override.aes = list(color = "blue")),
        color = "none"
    )

ggsave(
    "../figure/reg_poly_basis.pdf", 
    grid.arrange(
        plot_basis, 
        plot_weighted, 
        layout_matrix = matrix(c(1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2), nrow = 1)
    ),
    height = 1.7, 
    width = 8
)

# UNIVARIATE POLYNOMIALS -------------------------------------------------------

n_points = 50L
set.seed(pi)
x = runif(n_points, min = 0, max = 10)
y = 0.5 * sin(x) + rnorm(n_points, sd = 0.3)
dt = data.table(x, y)
degrees = c(1, 5, 25, 50)
models = lapply(degrees, function(i) lm(y ~ poly(x, i, raw = TRUE)))
plot_poly <- function(until = 1, xlim_low = 0, xlim_hi = 10) {
    p = ggplot(dt, aes(x = x, y = y)) +
        theme_bw() +
        geom_point()
    for (i in 1:until) {
        df =  data.frame(x = seq(xlim_low, xlim_hi, by = 0.01))
        p = p + geom_line(
            data.frame(
                x = df, 
                y = predict(models[[i]], newdata = df),
                col = as.character(i)
            ),
            mapping = aes(x = x, y = y, col = col)
        )
    }
    p + 
        ylim(c(-1, 1)) +
        scale_color_viridis_d(
            "degree", 
            option = "magma",
            end = 0.9, 
            direction = -1,
            labels = degrees[1:until]
        )
}

ggsave(
    "../figure/reg_poly_univ_2.pdf", plot_poly(2), height = 2, width = 4
)
ggsave(
    "../figure/reg_poly_univ_4.pdf", 
    plot_poly(4, -5, 15), 
    height = 2, 
    width = 6
)
ggsave("../figure/reg_poly_title.pdf", plot_poly(4), height = 2, width = 4)

# BIVARIATE EXAMPLE ------------------------------------------------------------

n_points = 50L
set.seed(pi)
dt_biv = data.table(x_1 = rnorm(n_points), x_2 = rnorm(n_points))
dt_biv[, y := 1 + 2 * x_1 + x_2^3 + rnorm(n_points, sd = 0.5)]

# from vistool
learner = LearnerRegrLMFormula$new()
learner$param_set$set_values(
  formula = as.formula("y ~ x_1 + poly(x_2, degree = 7)")
)
task = mlr3::as_task_regr(dt_biv, target = "y")
plot_biv = as_visualizer(task, learner)
plot_biv$add_training_data()
plot_biv$set_layout(
  title = "",
  scene = list(
    xaxis = list(title = "x1", showticklabels = FALSE), 
    yaxis = list(title = "x2", showticklabels = FALSE),
    zaxis = list(title = "f(x)", showticklabels = FALSE)
  )
)
plot_biv$set_scene(1.5 * 1.2, -1.25 * 1.2, 0.75 * 1.2)
plot_biv$plot()
plot_biv$save( "../figure/reg_poly_biv.pdf")