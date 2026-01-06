
<!-- README.md is generated from README.Rmd. Please edit that file -->

# evalstratified

<!-- badges: start -->

[![R-CMD-check](https://github.com/cfjdoedens/evalstratified/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/cfjdoedens/evalstratified/actions/workflows/R-CMD-check.yaml)
[![Deploy Shiny
App](https://github.com/cfjdoedens/evalstratified/actions/workflows/deploy-shiny.yaml/badge.svg)](https://github.com/cfjdoedens/evalstratified/actions/workflows/deploy-shiny.yaml)
<!-- badges: end -->

The goal of evalstratified is to make an estimate of the error fraction
of a set of monetary files. This based on a global level of certainty, a
level of certainty per file, and on error fractions found in sampled
items of each of these files.

## Installation

You can install the development version of evalstratified from
[GitHub](https://github.com/) with:

``` r
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}
devtools::install_github("cfjdoedens/evalstratified")
```

## Example

Steekproef1 is gebaseerd op een zekerheid van 95% omdat ihr, ibr en car
alledrie op hoog (H) staan. We kunnen dit ook narekenen met
`haro_nog_nodige_zekerheid(ihr = "H", ibr = "H", car = "H")`. Dit levert
inderdaad 0.95 op. De materialiteit is 2%. Het betreft 100 miljoen euro.
Om te bepalen hoeveel posten we moeten trekken voor steekproef1
gebruiken we `drawsneeded::drawsneeded(0, 0.02, cert = 0.95)`.
Resultaat: 148. Na trekken en evalueren blijkt er 1 post fout te zijn.

Bij steekproef2 staan ihr en ibr allebei op laag en alleen car staat op
hoog. We berekenen de benodigde zekerheid met
`haro_nog_nodige_zekerheid(ihr = "L", ibr = "L", car = "H")`. Dit levert
0.6323529 op. Het betreft ook 100 miljoen euro en een materialiteit van
ook 2%. Voor steekproef2 bepalen we vervolgens het aantal te trekken
posten met `drawsneeded::drawsneeded(0, 0.02, cert = 0.64)`. Resultaat:
50. Na trekken en evalueren blijkt geen enkele post hiervan fout te
zijn.

``` r
library(evalstratified)

example <- tribble(
  ~naam,
  ~w,
  ~n,
  ~k,
  ~ihr,
  ~ibr,
  ~car,
  ~materialiteit,
  "populatie1",
  100000000,
  148,
  1,
  "H",
  "H",
  "H",
  0.02,
  "populatie2",
  100000000,
  50,
  0,
  "L",
  "L",
  "H",
  0.02
)
r <- eval_stratified(steekproeven = example, zekerheid = 0.95)
r
#> $modus_fout_convolutie
#> [1] 0.00663809
#> 
#> $modus_fout_convolutie_geld
#> [1] 1327618
#> 
#> $mediaan_fout_convolutie
#> [1] 0.008923597
#> 
#> $mediaan_fout_convolutie_geld
#> [1] 1784719
#> 
#> $gemiddelde_fout_convolutie
#> [1] 0.009981522
#> 
#> $gemiddelde_fout_convolutie_geld
#> [1] 1996304
#> 
#> $mw_fout_convolutie
#> [1] 0.00663809
#> 
#> $mw_fout_convolutie_geld
#> [1] 1327618
#> 
#> $max_fout_convolutie
#> [1] 0.0208458
#> 
#> $max_fout_convolutie_geld
#> [1] 4169160
#> 
#> $vergelijk_met
#> $vergelijk_met$mw_fout_los
#> [1] 0.003378378
#> 
#> $vergelijk_met$mw_fout_los_geld
#> [1] 675675.7
#> 
#> $vergelijk_met$max_fout_los
#> [1] 0.02560712
#> 
#> $vergelijk_met$max_fout_los_geld
#> [1] 5121425
#> 
#> $vergelijk_met$mw_fout_als1
#> [1] 0.003367003
#> 
#> $vergelijk_met$mw_fout_als1_geld
#> [1] 673400.7
#> 
#> $vergelijk_met$max_fout_als1
#> [1] 0.01581936
#> 
#> $vergelijk_met$max_fout_als1_geld
#> [1] 3163872
#> 
#> 
#> $steekproeven
#> # A tibble: 2 × 12
#>   naam       w     n     k ihr   ibr   car   materialiteit extra_foutloze_posten
#>   <chr>  <dbl> <dbl> <dbl> <chr> <chr> <chr>         <dbl>                 <dbl>
#> 1 popul…   1e8   148     1 H     H     H              0.02                     0
#> 2 popul…   1e8    50     0 L     L     H              0.02                    99
#> # ℹ 3 more variables: toch_fouten <lgl>, mw_fout <dbl>, max_fout <dbl>
#> 
#> $invoer
#> $invoer$steekproeven
#> # A tibble: 2 × 8
#>   naam               w     n     k ihr   ibr   car   materialiteit
#>   <chr>          <dbl> <dbl> <dbl> <chr> <chr> <chr>         <dbl>
#> 1 populatie1 100000000   148     1 H     H     H              0.02
#> 2 populatie2 100000000    50     0 L     L     H              0.02
#> 
#> $invoer$zekerheid
#> [1] 0.95
#> 
#> $invoer$MC
#> [1] 1e+07
#> 
#> $invoer$start
#> [1] 1
#> 
#> $invoer$vergelijk
#> [1] TRUE
```
