haro_nog_nodige_zekerheid <- function(ihr = 'H',
                                      ibr = 'H',
                                      car = 'H') {
  # Controleer invoerparameters.
  stopifnot(ihr %in% c('H', 'M', 'L'))
  stopifnot(ibr %in% c('H', 'M', 'L'))
  stopifnot(car %in% c('H', 'M', 'L'))

  # Zie HAR0 7.3.4.
  ihr_risico <- switch(ihr,
                       'H' = 1,
                       'M' = 0.63,
                       'L' = 0.40)

  ibr_risico <- switch(ibr,
                       'H' = 1,
                       'M' = 0.52,
                       'L' = 0.34)

  car_risico <- switch(car,
                       'H' = 1,
                       'M' = 0.50,
                       'L' = 0.25)

  auditrisico <- 0.05
  detectierisico <- auditrisico / (ihr_risico * ibr_risico * car_risico)
  nog_nodige_zekerheid <- max(0, 1 - detectierisico)
  return(nog_nodige_zekerheid)
}
