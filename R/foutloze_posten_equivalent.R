#' @title
#' Geef equivalent in getrokken foutloze posten voor verlaagde risicoschattingen.
#'
#' @param ihr inherente risico, te weten H, M of L
#' @param ibr internebeheersingsrisico, te weten H, M of L
#' @param car cijferanalyserisico, te weten H, M of L
#' @param materialiteit de maximale foutfractie in de te onderzoeken geldmassa
#'
#' @returns
#' Het equivalent in getrokken foutloze posten. Een integer >= 0.
#'
#' @importFrom drawsneeded drawsneeded
#'
#' @examples
#' fpe <- foutloze_posten_equivalent()
#' @export
foutloze_posten_equivalent <- function(ihr = 'H', ibr = 'H', car = 'H', materialiteit = 0.01) {
   # Controleer invoerparameters.
  stopifnot(ihr %in% c('H', 'M', 'L'))
  stopifnot(ibr %in% c('H', 'M', 'L'))
  stopifnot(car %in% c('H', 'M', 'L'))

  if (ihr == 'H' && ibr == 'H' && car == 'H') {
    return(0)
  }

  benodigde_zekerheid <- haro_nog_nodige_zekerheid(ihr, ibr, car)
  posten_alles_hoog <- drawsneeded(0, materialiteit, cert = 0.95)
  posten_niet_alles_hoog <- drawsneeded(0, materialiteit, cert = benodigde_zekerheid)
  return(posten_alles_hoog - posten_niet_alles_hoog)
}
