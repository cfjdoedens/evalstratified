#' @title
#' Evalueer samennemend de resultaten van 1 of meer steekproeven op uitgaand geld
#'
#' @description
#' Evalueer samennemend als onafhankelijke steekproeven 1 of meer steekproeven op
#' uitgaand geld. Doe dit ook door ze te beschouwen als getrokken op dezelfde massa,
#' dus als afhankelijk.
#' Evalueer ook de steekproeven afzonderlijk.
#'
#' @details
#' We gaan hierbij uit van de som van de foutfracties, dus we kijken niet naar
#' de foutfracties per post.
#' Belangrijkste dat we berekenen is de maximale foutfractie.
#'
#' @param steken
#' Een tibble.
#' Elke regel van de tibble beschrijft 1 steekproef.
#' De tibble heeft als kolommen naam w n k car cir dir.
#' Dit zijn repectievelijk
#' \code{naam}, een aanduiding, van de steekproef,
#' \code{w}, de omvang in geld van de massa waaruit getrokken is,
#' \code{n}, het aantal getrokken posten,
#' \code{k}, de som van de foutfracties van de posten,
#' \code{ihr}, ihr risico, te weten H, M of L,
#' \code{ibr}, ibr risico, te weten H, M of L en
#' \code{car}, car risico, te weten H, M of L.
#' @param zekerheid
#' Het zekerheidsniveau waarop we de maximale foutfractie berekenen.
#' @param MC
#' Het aantal Monte Carlo berekeningen per steekproef, berekeningen gebaseerd op toevalsgetallen, dat gebruikt wordt.
#' @param start
#' Startwaarde voor de toevalsgenerator.
#' @return
#' Een lijst, bestaande uit
#' - \code{mw_fout_samen_onafh}, de meest waarschijnlijke fout als fractie van de totale massa in geld
#' - \code{mw_fout_samen_onafh_geld}, de meest waarschijnlijke fout in geld
#' - \code{max_fout_samen_onafh}, de maximale fout als fractie van de totale massa in geld
#' - \code{max_fout_samen_onafh_geld}, de maximale fout in geld
#' - een tibble, \code{steken} waarin per steekproef:
#'   + \code{naam}, een aanduiding, van de steekproef,
#'   + \code{w}, de omvang in geld van de massa waaruit getrokken is,
#'   + \code{n}, het aantal getrokken posten,
#'   + \code{k}, de som van de foutfracties van de posten,
#'   + \code{ihr}, het ihr risico,
#'   + \code{ibr}, het ibr risico,
#'   + \code{car}, het car risico,
#'   + \code{extra_foutloze_posten}, het aantal foutloze posten dat equivalent is aan ihr+ibr+car volgens
#'                                   het ARM model en de interpretatie daarvan door de ADR,
#'   + \code{mw_fout}, de meest waarschijnlijke fout als fractie van de massa in geld van de steekproef,
#'   + \code{mw_fout_geld}, de meest waarschijnlijke fout in geld,
#'   + \code{max_fout}, de maximale fout als fractie van de massa in geld van de steekproef,
#'   + \code{max_fout_geld}, de maximale fout in geld.
#' - \code{zekerheid}
#' - \code{MC}
#' - \code{start}
#' - \code{mw_fout_samen_afh}, de meest waarschijnlijke fout als percentage, er
#'   vanuit gaande dat de steekproeven allemaal samen uit dezelfde massa zouden zijn getrokken
#' - \code{mw_fout_samen_afh_geld}, de meest waarschijnlijke fout in geld daarbij
#' - \code{max_fout_samen_afh}, de maximale fout als percentage, er
#'   vanuit gaande dat de steekproeven allemaal samen uit dezelfde massa zouden zijn getrokken
#' - \code{max_fout_samen_afh_geld}, de maximale fout in geld daarbij
#'
#' @export
#' @importFrom tibble tribble
#' @importFrom tibble add_row
#' @importFrom tibble is_tibble
#' @importFrom dplyr %>%
#' @importFrom dplyr pull
#' @examples
#' steken <- tribble(~naam, ~w, ~n, ~k) # Creeer lege invoertibble.
#'
#' naam <- "Steekproef1" # De naam van de 1e steekproef.
#' w <- 35060542 # Het gewicht van de steekproef, als geldomvang van de massa waarover wordt gestoken.
#' n <- 31 # Het aantal getrokken en geevalueerde posten.
#' k <- 0 # De som van de foutfracties.
#' steken <- add_row(steken, naam = naam, w = w, n = n, k = k)
#'
#' naam <- "Steekproef2" # De naam van de 2e steekproef.
#' w <- 3044699  # Het gewicht van de steekproef, als geldomvang van de massa waarover wordt gestoken.
#' n <- 8 # Het aantal getrokken en geevalueerde posten.
#' k <- 0 # De som van de foutfracties.
#' steken <- add_row(steken, naam = naam, w = w, n = n, k = k)
#'
#' # Kortheidshalve hadden we steken ook kunnen invoeren als:
#' steken <- tribble(
#' ~naam, ~w, ~n, ~k, ~ihr, ~ibr, ~car,
#' "Steekproef1", 35060542, 31, 0, 'H', 'H', 'H',
#' "Steekproef2", 3044699, 8, 0, 'H', 'H', 'H')
#'
#' # Evalueer steekproef1 en steekproef2 samen.
#' evalstratified(steken = steken)
evalstratified <-
  function(steken,
           zekerheid = 0.95,
           MC = 1e7,
           start = 1) {
    # Controleer de invoer.
    stopifnot(is_tibble(steken))
    stopifnot("naam" %in% colnames(steken))
    stopifnot("w" %in% colnames(steken))
    stopifnot("n" %in% colnames(steken))
    stopifnot("k" %in% colnames(steken))
    stopifnot("ihr" %in% colnames(steken))
    stopifnot("ibr" %in% colnames(steken))
    stopifnot("car" %in% colnames(steken))

    naam <- steken %>% pull(naam)
    w <- steken %>% pull(w)
    n <- steken %>% pull(n)
    k <- steken %>% pull(k)
    ihr <- steken %>% pull(ihr)
    ibr <- steken %>% pull(ibr)
    car <- steken %>% pull(car)
    len_naam <- length(naam)
    stopifnot(len_naam > 0)
    len_w <- length(w)
    len_n <- length(n)
    len_k <- length(k)
    len_ihr <- length(ihr)
    len_ibr <- length(ibr)
    len_car <- length(car)
    stopifnot(len_naam == len_w)
    stopifnot(len_naam == len_n)
    stopifnot(len_naam == len_k)
    stopifnot(len_naam == len_ihr)
    stopifnot(len_naam == len_ibr)
    stopifnot(len_naam == len_car)

    stopifnot(w > 0)
    stopifnot(n > 0)
    stopifnot(k >= 0)

    stopifnot(is.finite(w))
    stopifnot(is.finite(n))
    stopifnot(is.finite(k))

    stopifnot(n >= k)

    stopifnot(zekerheid >= 0)
    stopifnot(zekerheid <= 1)
    stopifnot(MC >= 1)
    stopifnot(is.finite(MC))

    # Creeer uitvoertibble, su, met regels per steekproef.
    su <-
      tribble( ~ naam,
               ~ w,
               ~ n,
               ~ k,
               ~ mw_fout,
               ~ mw_fout_geld,
               ~ max_fout,
               ~ max_fout_geld)

    # Vul met invoertibble.
    n_steken <- nrow(steken)
    for (i in 1:n_steken) {
      su <-
        add_row(
          su,
          naam = steken$naam[[i]],
          w = steken$w[[i]],
          n = steken$n[[i]],
          k = steken$k[[i]]
        )
    }

    # Voeg toe evaluaties van de afzonderlijke steekproeven.
    for (i in 1:n_steken) {
      w <- su$w[[i]]
      n <- su$n[[i]]
      k <- su$k[[i]]
      su$mw_fout[[i]] = k / n
      su$max_fout[[i]] = qbeta(zekerheid, k + 1, n - k + 1)
      su$mw_fout_geld[[i]] = su$mw_fout[[i]] * w
      su$max_fout_geld[[i]] = su$max_fout[[i]] * w
    }
    # Tel maximale fouten op.
    max_fout_opgeteld_geld <- sum(su$max_fout_geld)

    # Evalueer alle steekproeven samen, alsof het
    # 1 steekproef is, dus als afhankelijke steekproeven.
    n <- 0
    k <- 0
    for (i in 1:n_steken) {
      n <- n + su$n[[i]]
      k <- k + su$k[[i]]
    }
    mw_fout_samen_afh = k / n
    max_fout_samen_afh = qbeta(zekerheid, k + 1, n - k + 1)
    w <- 0
    for (i in 1:n_steken) {
      w <- w + su$w[[i]]
    }
    mw_fout_samen_afh_geld = mw_fout_samen_afh * w
    max_fout_samen_afh_geld = max_fout_samen_afh * w

    # Evalueer alle steekproeven samen als onafhankelijke steekproeven.
    w <- su$w
    n <- su$n
    k <- su$k
    mw_fout_samen_onafh <- sum(w * k / n) / sum(w)
    mw_fout_samen_onafh_geld = mw_fout_samen_onafh * sum(w)

    krommen <- matrix(NA, nrow = MC, ncol = n_steken)
    set.seed(start)
    for (i in 1:n_steken) {
      n <- su$n[[i]]
      k <- su$k[[i]]
      krommen[, i] <-
        rbeta(MC, shape1 = 1 + k, shape2 = 1 + n - k) # Kanskromme i.
    }
    samen <-
      krommen %*% w / sum(w) # Gewogen samengevoegde kanskrommen.
    max_fout_samen_onafh <-
      unname(quantile(samen, probs = zekerheid)) # Max gebaseerd op 1-zijdige significantie.
    max_fout_samen_onafh_geld <- max_fout_samen_onafh * sum(w)

    # Voeg alle resultaten als 1 lijst samen, en geef terug als resultaat van de functie.
    list(
      mw_fout_samen_onafh = mw_fout_samen_onafh,
      mw_fout_samen_onafh_geld = mw_fout_samen_onafh_geld,
      max_fout_samen_onafh = max_fout_samen_onafh,
      max_fout_samen_onafh_geld = max_fout_samen_onafh_geld,

      steken = su,
      max_fout_opgeteld_geld = max_fout_opgeteld_geld,
      verkleiningsfactor_max_fout = max_fout_samen_onafh_geld / max_fout_opgeteld_geld,
      zekerheid = zekerheid,
      MC = MC,
      start = start,

      mw_fout_samen_afh = mw_fout_samen_afh,
      mw_fout_samen_afh_geld = mw_fout_samen_afh_geld,
      max_fout_samen_afh = max_fout_samen_afh,
      max_fout_samen_afh_geld = max_fout_samen_afh_geld
    )
  }

steken <- tribble(~ naam, ~ w, ~ n, ~ k)

# De naam van de 1e steekproef.
naam <- "Steekproef1"

# Het gewicht van de steekproef, als geldomvang van de massa waarover wordt gestoken.
w <- 35060542

# Het aantal getrokken en geevalueerde posten.
n <- 31

# De som van de foutfracties.
k <- 0

steken <- add_row(
  steken,
  naam = naam,
  w = w,
  n = n,
  k = k
)

# De naam van de 2e steekproef.
naam <- "Steekproef2"

# Het gewicht van de steekproef, als geldomvang van de massa waarover wordt gestoken.
w <- 3044699

# Het aantal getrokken en geevalueerde posten.
n <- 8

# De som van de foutfracties.
k <- 0

steken <- add_row(
  steken,
  naam = naam,
  w = w,
  n = n,
  k = k
)

# evalstratified(steken = steken)

# Voorbeeld voor Niels.
sniels <- tribble( ~ naam, ~ w, ~ n, ~ k, "x", 100, 300, 0, "y", 200, 160, 0)
#
# # Evalueer x en y samen.
# evalstratified(steken = sniels, zekerheid = 0.95)
# evalstratified(steken = sniels, zekerheid = 0.90)
# evalstratified(steken = sniels, zekerheid = 0.85)
# evalstratified(steken = sniels, zekerheid = 0.80)

# LNV 2023.
# Originele opgave van Wim voor LNV 2023 artikel 21.
# Deze leidt tot een maximale fout van 34,2 miljoen, wat boven de tolerantie
# van 25 miljoen is.
lnv_2023_art21 <- tribble(
  ~ naam,
  ~ w,
  ~ n,
  ~ k,
  "kd_beleid",
  69600741,
  8,
  0,
  "lbv",
  223532422,
  22,
  0.0331905,
  "inkopen",
  12146914,
  1,
  0
)
# evalstratified(steken = lnv_2023_art21, zekerheid = 0.88)
# $max_fout_opgeteld_geld:    42.736.846
# $max_fout_samen_onafh_geld: 34.194.014
# verkleiningsfactor_max_fout: 0,8001062

# Deze opgave zou er voor zorgen dat de maximale fout onder de 25 miljoen
# blijft, namelijk 24,2 miljoen.
# Ik ga er hier vanuit dat de foutfractie bij lbv evenredig oploopt met
# het aantal steken.
lnv_2023_art21b <- tribble(
  ~ naam,
  ~ w,
  ~ n,
  ~ k,
  "kd_beleid",
  69600741,
  11,
  0,
  "lbv",
  223532422,
  36,
  0.055,
  "inkopen",
  12146914,
  2,
  0
)
# evalstratified(steken = lnv_2023_art21b, zekerheid = 0.88)

# lnv_2023_art22 <- tribble(
#   ~naam, ~w, ~n, ~k,
#   "kd_beleid",  95929220, 0,
#   "inkopen",    43785149, 0)

# Vraag Wim Slot of som maximale fouten afzonderljke steekproeven kleiner kan
# zijn dan de maximale fout van de samengevoegde steekproeven.
# Onderstaande combinatie bevestigt dat.
combinatie <- tribble( ~ naam,
                       ~ w,
                       ~ n,
                       ~ k,
                       "kd_beleid",
                       48,
                       12,
                       0,
                       "lbv",
                       80,
                       20,
                       0,
                       "inkopen",
                       170,
                       34,
                       0)
# evalstratified(steken = combinatie2, zekerheid = 0.65)
# $max_fout_opgeteld_geld:    11.52542
# $max_fout_samen_onafh_geld: 12.05485
# verkleiningsfactor_max_fout: 1.045936 # Foute boel.

# Er is mogelijk een raar effect doordat niet alle massa's
# naar evenredigheid steken hebben.
# Daarom deze aangepaste combinatie.
combinatie2 <- tribble( ~ naam,
                        ~ w,
                        ~ n,
                        ~ k,
                        "kd_beleid",
                        48,
                        12,
                        0,
                        "lbv",
                        80,
                        20,
                        0,
                        "inkopen",
                        132,
                        34,
                        0)
# evalstratified(steken = combinatie2, zekerheid = 0.65)
# Maar blijkt nog steeds hetzelfde effect te geven!
# $max_fout_opgeteld_geld:    11.52542
# $max_fout_samen_onafh_geld: 12.05485
# verkleiningsfactor_max_fout: 1.045936 # Foute boel.

# Laten we eens kijken wat er gebeurt als ongeveer 50% fout optreedt.
combinatie3 <- tribble( ~ naam,
                        ~ w,
                        ~ n,
                        ~ k,
                        "kd_beleid",
                        48,
                        12,
                        6,
                        "lbv",
                        80,
                        20,
                        10,
                        "inkopen",
                        132,
                        34,
                        17)
# evalstratified(steken = combinatie3, zekerheid = 0.65)
# $max_fout_opgeteld_geld:    140.0905
# $max_fout_samen_onafh_geld: 135.8522
# Dus dan blijft max_fout_opgeteld_geld > max_fout_samen_onafh_geld

# evalstratified(steken = combinatie3, zekerheid = 0.51)
# $max_fout_opgeteld_geld:    130.6576
# $max_fout_samen_onafh_geld: 130.3869
# Dus zelfs bij zekerheid van 51% blijft
# max_fout_opgeteld_geld > max_fout_samen_onafh_geld !!

# Laten we nu eens kijken of het uitmaakt hoeveel steekproeven we
# samenvoegen.
# Conclusie zal blijken te zijn: als we meer steekproeven samenvoegen,
# dan wordt de verkleiningsfactor groter, en zelfs boven de 1.
combinatie4 <- tribble( ~ naam, ~ w, ~ n, ~ k, "s1", 10, 10, 0)
# evalstratified(steken = combinatie4, zekerheid = 0.51)
# $max_fout_opgeteld_geld:    0.6279196
# $max_fout_samen_onafh_geld: 0.6275299
# verkleiningsfactor_max_fout: 0.9993794

combinatie5 <- tribble( ~ naam, ~ w, ~ n, ~ k, "s1", 10, 10, 0, "s2", 10, 10, 0)
# evalstratified(steken = combinatie5, zekerheid = 0.51)
# $max_fout_opgeteld_geld:    1.255839
# $max_fout_samen_onafh_geld: 1.477473
# verkleiningsfactor_max_fout 1.176482 # Foute boel!!

combinatie6 <- tribble( ~ naam, ~ w, ~ n, ~ k, "s1", 10, 10, 0, "s2", 10, 10, 0, "s3", 10, 10, 0)
# evalstratified(steken = combinatie6, zekerheid = 0.51)
# $max_fout_opgeteld_geld:    1.883759
# $max_fout_samen_onafh_geld: 2.321252
# verkleiningsfactor_max_fout: 1.232245 # Foute boel!!

combinatie7 <- tribble( ~ naam,
                        ~ w,
                        ~ n,
                        ~ k,
                        "s1",
                        10,
                        10,
                        0,
                        "s2",
                        10,
                        10,
                        0,
                        "s3",
                        10,
                        10,
                        0,
                        "s4",
                        10,
                        10,
                        0)
# evalstratified(steken = combinatie7, zekerheid = 0.51)
# $max_fout_opgeteld_geld:    2.511678
# $max_fout_samen_onafh_geld: 3.16308
# verkleiningsfactor_max_fout 1.259349 # Foute boel!!

combinatie8 <- tribble(
  ~ naam,
  ~ w,
  ~ n,
  ~ k,
  "s1",
  10,
  10,
  0,
  "s2",
  10,
  10,
  0,
  "s3",
  10,
  10,
  0,
  "s4",
  10,
  10,
  0,
  "s5",
  10,
  10,
  0,
  "s6",
  10,
  10,
  0,
  "s7",
  10,
  10,
  0,
  "s8",
  10,
  10,
  0,
  "s9",
  10,
  10,
  0,
  "s10",
  10,
  10,
  0,
  "s11",
  10,
  10,
  0,
  "s12",
  10,
  10,
  0,
  "s13",
  10,
  10,
  0,
  "s14",
  10,
  10,
  0,
  "s15",
  10,
  10,
  0,
  "s16",
  10,
  10,
  0,
  "s17",
  10,
  10,
  0,
  "s18",
  10,
  10,
  0,
  "s19",
  10,
  10,
  0,
  "s20",
  10,
  10,
  0,
  "s21",
  10,
  10,
  0,
  "s22",
  10,
  10,
  0,
  "s23",
  10,
  10,
  0,
  "s24",
  10,
  10,
  0,
  "s25",
  10,
  10,
  0,
  "s26",
  10,
  10,
  0,
  "s27",
  10,
  10,
  0,
  "s28",
  10,
  10,
  0,
  "s29",
  10,
  10,
  0,
  "s30",
  10,
  10,
  0,
  "s31",
  10,
  10,
  0,
  "s32",
  10,
  10,
  0
)
# evalstratified(steken = combinatie8, zekerheid = 0.51)
# $max_fout_opgeteld_geld:    20.09343
# $max_fout_samen_onafh_geld: 26.57505
# verkleiningsfactor_max_fout 1.322574 # Foute boel!!

# evalstratified(steken = combinatie8, zekerheid = 0.95)
# $max_fout_opgeteld_geld:    76.28934
# $max_fout_samen_onafh_geld: 34.12538
# verkleiningsfactor_max_fout 0.4473152

# evalstratified(steken = combinatie8, zekerheid = 0.70)
# $max_fout_opgeteld_geld:    33.17596
# $max_fout_samen_onafh_geld: 28.79159
# verkleiningsfactor_max_fout 0.8678448

# evalstratified(steken = combinatie8, zekerheid = 0.05)
# $max_fout_opgeteld_geld:    1.488695
# $max_fout_samen_onafh_geld: 19.89126
# verkleiningsfactor_max_fout 13.36154
