
<!-- README.md is generated from README.Rmd. Please edit that file -->

# evalstratified

<!-- badges: start -->

<!-- badges: end -->

The goal of evalstratified is to make an estimate of the error fraction
of a set of monetary files. This based on a level of certainty, and on
error fractions found in sampled items of each of these files.

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
alledrie op hoog (H) staan.

De materialiteit is 2%. Het betreft 100 miljoen euro. Voor steekproef1
trekken we 148 posten, waarbij 1 fout blijkt. Steekproef2 is gebaseerd
op een zekerheid van 64% omdat ihr en ibr allebei op laag staan en
alleen car op hoog. Het betreft ook 100 miljoen euro en een
materialiteit van 2%. Voor steekproef2 trekken we 50 posten waarvan er 0
fout blijken.

``` r
library(evalstratified)

  example <- tribble(
      ~ naam,
      ~ w,
      ~ n,
      ~ k,
      ~ ihr,
      ~ ibr,
      ~ car,
      "populatie1",
      100000000,
      148,
      1,
      'H',
      'H',
      'H',
      "populatie2",
      100000000,
      50,
      0,
      'L',
      'L',
      'H'
    )
    r <- eval_stratified(steekproeven = example, zekerheid = 0.95)
    r
#> $modus_fout_convolutie
#> [1] 0.00581861
#> 
#> $modus_fout_convolutie_geld
#> [1] 1163722
#> 
#> $mediaan_fout_convolutie
#> [1] 0.007683834
#> 
#> $mediaan_fout_convolutie_geld
#> [1] 1536767
#> 
#> $gemiddelde_fout_convolutie
#> [1] 0.008661908
#> 
#> $gemiddelde_fout_convolutie_geld
#> [1] 1732382
#> 
#> $mw_fout_convolutie
#> [1] 0.00581861
#> 
#> $mw_fout_convolutie_geld
#> [1] 1163722
#> 
#> $max_fout_convolutie
#> [1] 0.01834587
#> 
#> $max_fout_convolutie_geld
#> [1] 3669175
#> 
#> $vergelijk_met
#> $vergelijk_met$mw_fout_los
#> [1] 0.003378378
#> 
#> $vergelijk_met$mw_fout_los_geld
#> [1] 675675.7
#> 
#> $vergelijk_met$max_fout_los
#> [1] 0.04424438
#> 
#> $vergelijk_met$max_fout_los_geld
#> [1] 8848876
#> 
#> $vergelijk_met$mw_fout_als1
#> [1] 0.005050505
#> 
#> $vergelijk_met$mw_fout_als1_geld
#> [1] 1010101
#> 
#> $vergelijk_met$max_fout_als1
#> [1] 0.02361544
#> 
#> $vergelijk_met$max_fout_als1_geld
#> [1] 4723089
#> 
#> 
#> $steekproeven
#> # A tibble: 2 × 11
#>   naam         w     n     k ihr   ibr   car   extra_foutloze_posten toch_fouten
#>   <chr>    <dbl> <dbl> <dbl> <chr> <chr> <chr>                 <dbl> <lgl>      
#> 1 populat…   1e8   148     1 H     H     H                         0 FALSE      
#> 2 populat…   1e8    50     0 L     L     H                       199 FALSE      
#> # ℹ 2 more variables: mw_fout <dbl>, max_fout <dbl>
#> 
#> $invoer
#> $invoer$steekproeven
#> # A tibble: 2 × 7
#>   naam               w     n     k ihr   ibr   car  
#>   <chr>          <dbl> <dbl> <dbl> <chr> <chr> <chr>
#> 1 populatie1 100000000   148     1 H     H     H    
#> 2 populatie2 100000000    50     0 L     L     H    
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
