#' @title
#' Geef equivalent in getrokken foutloze posten voor
#' verlaagde risicoschattingen.
#'
#' @description
#' Volgens het HARo is de benodigde zekerheid bij een gegevensgerichte
#' controle 95%, namelijk 100% minus het accountantsrisico (5%).
#'
#' Ook volgens het HARo, definieren ihr, ibr en car samen de nog benodigde
#' zekerheid voor een gegevensgerichte controle.
#' Bereken het aantal foutloze posten dat daar mee overeenkomt,
#' rekeninghoudend met de materialiteit.
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
foutloze_posten_equivalent <-
  function(ihr = "H",
           ibr = "H",
           car = "H",
           materialiteit = 0.01) {
    # Controleer invoerparameters.
    stopifnot(ihr %in% c("H", "M", "L"))
    stopifnot(ibr %in% c("H", "M", "L"))
    stopifnot(car %in% c("H", "M", "L"))

    hoogste_zekerheid <- 0.95
    benodigde_zekerheid <- haro_nog_nodige_zekerheid(ihr, ibr, car)
    stopifnot(benodigde_zekerheid <= hoogste_zekerheid)
    posten_alles_hoog <- drawsneeded(0, materialiteit, cert = hoogste_zekerheid)
    posten_niet_alles_hoog <-
      drawsneeded(0, materialiteit, cert = benodigde_zekerheid)
    posten_alles_hoog - posten_niet_alles_hoog
  }
