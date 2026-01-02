# Evalueer samen de resultaten van 1 of meer steekproeven op uitgaand geld

Het samennemen van de resultaten gebeurt door convolutie van de
foutkanskrommes van de afzonderlijke steekproeven tot 1 foutkanskromme.

We berekenen de meest waarschijnlijke en de maximale fout als fractie en
in geld.

De meest waarschijnlijke fout is de modus van de kanskromme. De maximale
fout is afhankelijk van de gevraagde zekerheid, en is de fout bij een
cumulatieve kans gelijk aan deze zekerheid.

## Usage

``` r
eval_stratified(
  steekproeven,
  zekerheid = 0.95,
  MC = 1e+07,
  start = 1,
  vergelijk = TRUE
)
```

## Arguments

- steekproeven:

  Een tibble. Elke regel van de tibble beschrijft 1 steekproef, dus 1
  van de genomen steekproeven. De tibble heeft als kolommen: naam w n k
  car cir dir. Dit zijn repectievelijk `naam`, een aanduiding van de
  steekproef, `w`, de omvang in geld van de massa waaruit getrokken is,
  `n`, het aantal getrokken posten, `k`, de som van de foutfracties van
  de posten, `ihr`, inherent risico, te weten H, M of L, `ibr`, intern
  beheersingsrisico, te weten H, M of L, `car`, cijferanalyserisico, te
  weten H, M of L, en `materialiteit`, als fractie van de totale massa

- zekerheid:

  Het zekerheidsniveau waarop we de maximale foutfractie berekenen.

- MC:

  Het aantal Monte Carlo iteraties dat gebruikt wordt. Monte Carlo
  berekeningen baseren zich op toevalsgetallen.

- start:

  Startwaarde voor de toevalsgenerator.

- vergelijk:

  TRUE of FALSE, als TRUE dan worden wat vergelijkende berekeningen
  uitgevoerd en de resultaten daarvan toegevoegd aan de uitkomst van de
  functie.

## Value

Een lijst, bestaande uit

- `mw_fout_convolutie`, de meest waarschijnlijke fout als fractie van de
  totale massa in geld

- `max_fout_convolutie`, de maximale fout als fractie van de totale
  massa in geld

- en zo ook voor modus, mediaan en gemiddelde

- als vergelijk == TRUE een lijst `vergelijk_met`, met daarin
  vergelijkende cijfers voor "los" en voor "als1". Hierbij staat "los"
  voor de samengenomen, gewogen, cijfers der afzonderlijke steekproeven,
  en "als1" voor als alle steken en de resultaten daarvan worden
  beschouwd als voor 1 steekproef getrokken uit 1 massa.

- `steekproeven`, de invoer tibble, verrijkt per steekproef: met

  - `extra_foutloze_posten`, het aantal foutloze posten dat equivalent
    is aan ihr+ibr+car volgens het ARM model en de interpretatie daarvan
    door de ADR,

  - `toch_fouten`, TRUE of FALSE, geeft aan of tenminste 1 van ihr, ibr
    of car niet op hoog staat en er wel fouten zijn gevonden

  - `mw_fout`, als vergelijk TRUE, de meest waarschijnlijke fout voor
    die steekproef als fractie van de massa in geld van de steekproef,

  - `max_fout`, als vergelijk TRUE, de maximale fout als fractie van de
    massa in geld van de steekproef,

- `invoer`, een lijst bestaande uit de invoerparameters

## Details

We gaan uit van de som van de foutfracties, de k-waarde, dus we kijken
niet naar de foutfracties per post.

De maximale fout wordt bepaald aan de hand van de resulterende
kanskromme, op basis van de gewenste zekerheid. Visueel is de maximale
fout, pm, te bepalen in een tweedimensionaal, haaks, assenstelsel. De
horizontale as, de p-as, loopt van 0 tot 1. De waarden langs die as
geven de mogeljke foutfracties weer, lopend van 0 (geen fouten) tot 1
(alles fout). De verticale as, de c-as, loopt van 0 to oneindig. Deze as
geeft de kanswaarden van de foutfracties aan. In dit assenstelsel kunnen
we de kanskromme afbeelden. Het oppervlak onder de kanskromme is 1.
Hierbij praten we over het oppervlak begrenst door de p-as, aan de
onderkant, en de verticale lijnen p = 0, en p = 1. pm is het punt op de
p-as waarbij de verticale lijn p = pm, het oppervlak onder de kanskromme
begrenst zodat links van deze lijn het oppervlak gelijk is aan de
zekerheid, bijvoorbeeld 0,95.

Aggregatie is puur op statistische gronden: namelijk risico's op fouten
boven de meest waarschijnlijke fout en op onder de meest waarschijnlijke
fout vlakken elkaar enigszins uit genomen over de meerdere steekproeven.
Dus, bij het aggregeren van de resultaten van de verschillende
steekproeven wordt geen enkele aanname gedaan over gelijkenis tussen de
eigenschappen van de afzonderlijke administraties waaruit is getrokken.

Deze module kan ook steekproeven combineren over massa's waarvoor een
verschillende risicoinschatting geldt.

Bijvoorbeeld: Steekproef1 is gebaseerd op een zekerheid van 95% omdat
ihr, ibr en car alledrie op hoog (H) staan. De materialiteit is 2%. Het
betreft 100 miljoen euro. Voor steekproef1 trekken we 148 posten,
waarbij 1 fout blijkt. Steekproef2 is gebaseerd op een zekerheid van 64%
omdat ihr en ibr allebei op laag staan en alleen car op hoog. Het
betreft ook 100 miljoen euro en een materialiteit van 2%. Voor
steekproef2 trekken we 50 posten waarvan er 0 fout blijken.

Bij een risicoinschatting onder 95% van een of meer van de massa's
waarover wordt gestoken worden deze lagere risicoinschattingen vertaald
naar extra getrokken foutloze posten. In ons voorbeeld bepalen we voor
steekproef2 het aantal foutloze posten nodig om een positieve uitspraak
te doen bij 64% en bij 95%. Dit zijn respectievelijk 50 en 148. Het
verschil is 148-50 = 98 posten. Daarna berekenen we totale maximale fout
op basis van een zekerheid van 95%, en steekproef1, 148 posten waarvan 1
fout, en steekproef2, met 50 + 98 posten, waarvan 0 fout. De maximale
fout is dan 1,83% ofwel ongeveer3.660.000. De meest waarschijnlijke fout
0,52% ofwel ongeveer 1.160.000 euro.

Het is de verantwoordelijkheid van de auditor hoe om te gaan met een
steekproef waarbij de risicoinschatting niet op H staat en er toch
fouten worden gevonden. Dit probleem staat los van hoe de uitkomsten van
meerdere steekproeven samen te nemen.

Als de parameter vergelijk TRUE is doen we, ter vergelijking, ook een
evaluatie:

- voor elke steekproef los

- voor alle steekproeven samen, waarbij ze beschouwd worden als te zijn
  getrokken op 1 massa, en als 1 steekproef.

## Examples

``` r
# Creeer lege invoertibbe.
steekproeven <-
  tibble::tribble(~naam, ~w, ~n, ~k, ~ihr, ~ibr, ~car, ~materialiteit)
naam <- "Steekproef1" # De naam van de 1e steekproef.
w <- 35060542 # Het gewicht van de steekproef, als geldomvang van de massa
# waarover wordt gestoken.
n <- 31 # Het aantal getrokken en geevalueerde posten.
k <- 0 # De som van de foutfracties.
ihr <- "H"
ibr <- "H"
car <- "H"
materialiteit <- 0.01
steekproeven <-
  tibble::add_row(steekproeven,
    naam = naam,
    w = w,
    n = n,
    k = k,
    ihr = ihr,
    ibr = ibr,
    car = car,
    materialiteit = materialiteit
  )

naam <- "Steekproef2" # De naam van de 2e steekproef.
w <- 3044699 # Het gewicht van de steekproef, als geldomvang van de
# massa waarover wordt gestoken.
n <- 8 # Het aantal getrokken en geevalueerde posten.
k <- 0 # De som van de foutfracties.
ihr <- "H"
ibr <- "H"
car <- "H"
materialiteit <- 0.1
tibble::add_row(steekproeven,
  naam = naam,
  w = w,
  n = n,
  k = k,
  ihr = ihr,
  ibr = ibr,
  car = car,
  materialiteit = materialiteit
)
#> # A tibble: 2 × 8
#>   naam               w     n     k ihr   ibr   car   materialiteit
#>   <chr>          <dbl> <dbl> <dbl> <chr> <chr> <chr>         <dbl>
#> 1 Steekproef1 35060542    31     0 H     H     H              0.01
#> 2 Steekproef2  3044699     8     0 H     H     H              0.1 

# Kortheidshalve hadden we steekproeven ook kunnen invoeren als:
steekproeven <- tibble::tribble(
  ~naam, ~w, ~n, ~k, ~ihr, ~ibr, ~car, ~materialiteit,
  "Steekproef1", 35060542, 31, 0, "H", "H", "H", 0.01,
  "Steekproef2", 3044699, 8, 0, "H", "H", "H", 0.01
)

# Evalueer steekproef1 en steekproef2 samen.
eval_stratified(steekproeven = steekproeven)
#> $modus_fout_convolutie
#> [1] 0.01497407
#> 
#> $modus_fout_convolutie_geld
#> [1] 570590.6
#> 
#> $mediaan_fout_convolutie
#> [1] 0.02848983
#> 
#> $mediaan_fout_convolutie_geld
#> [1] 1085612
#> 
#> $gemiddelde_fout_convolutie
#> [1] 0.03586305
#> 
#> $gemiddelde_fout_convolutie_geld
#> [1] 1366570
#> 
#> $mw_fout_convolutie
#> [1] 0.01497407
#> 
#> $mw_fout_convolutie_geld
#> [1] 570590.6
#> 
#> $max_fout_convolutie
#> [1] 0.09124468
#> 
#> $max_fout_convolutie_geld
#> [1] 3476901
#> 
#> $vergelijk_met
#> $vergelijk_met$mw_fout_los
#> [1] 0
#> 
#> $vergelijk_met$mw_fout_los_geld
#> [1] 0
#> 
#> $vergelijk_met$max_fout_los
#> [1] 0.0297634
#> 
#> $vergelijk_met$max_fout_los_geld
#> [1] 1134141
#> 
#> $vergelijk_met$mw_fout_als1
#> [1] 0
#> 
#> $vergelijk_met$mw_fout_als1_geld
#> [1] 0
#> 
#> $vergelijk_met$max_fout_als1
#> [1] 0.07215752
#> 
#> $vergelijk_met$max_fout_als1_geld
#> [1] 2749580
#> 
#> 
#> $steekproeven
#> # A tibble: 2 × 12
#>   naam       w     n     k ihr   ibr   car   materialiteit extra_foutloze_posten
#>   <chr>  <dbl> <dbl> <dbl> <chr> <chr> <chr>         <dbl>                 <dbl>
#> 1 Stee… 3.51e7    31     0 H     H     H              0.01                     0
#> 2 Stee… 3.04e6     8     0 H     H     H              0.01                     0
#> # ℹ 3 more variables: toch_fouten <lgl>, mw_fout <dbl>, max_fout <dbl>
#> 
#> $invoer
#> $invoer$steekproeven
#> # A tibble: 2 × 8
#>   naam               w     n     k ihr   ibr   car   materialiteit
#>   <chr>          <dbl> <dbl> <dbl> <chr> <chr> <chr>         <dbl>
#> 1 Steekproef1 35060542    31     0 H     H     H              0.01
#> 2 Steekproef2  3044699     8     0 H     H     H              0.01
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
#> 
#> 
```
