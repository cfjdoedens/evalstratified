library(shiny)
library(evalstratified)
library(tibble)
library(dplyr)
library(readr)

# Define risk options used in multiple tabs
risk_choices <- c("Hoog (H)" = "H", "Midden (M)" = "M", "Laag (L)" = "L")

ui <- navbarPage("EvalStratified",

                 # -------------------------------------------------------------------------
                 # TAB 1: Haro Nog Nodige Zekerheid
                 # -------------------------------------------------------------------------
                 tabPanel("Nog Nodige Zekerheid",
                          sidebarLayout(
                            sidebarPanel(
                              h4("Risico Inschatting"),
                              helpText("Bereken de nog benodigde zekerheid volgens HARo paragraaf B7.3.4."),
                              selectInput("haro_ihr", "Inherent Risico (ihr):", choices = risk_choices),
                              selectInput("haro_ibr", "Interne Beheersing (ibr):", choices = risk_choices),
                              selectInput("haro_car", "Cijferanalyse (car):", choices = risk_choices)
                            ),
                            mainPanel(
                              h3("Resultaat"),
                              verbatimTextOutput("res_haro"),
                              p("Dit is de zekerheid (fractie 0-1) die u nog uit detailcontroles moet halen.")
                            )
                          )
                 ),

                 # -------------------------------------------------------------------------
                 # TAB 2: Foutloze Posten Equivalent
                 # -------------------------------------------------------------------------
                 tabPanel("Foutloze Posten Equivalent",
                          sidebarLayout(
                            sidebarPanel(
                              h4("Risico & Materialiteit"),
                              helpText("Bereken hoeveel foutloze posten uw risico-inschatting waard is."),
                              selectInput("fpe_ihr", "Inherent Risico (ihr):", choices = risk_choices),
                              selectInput("fpe_ibr", "Interne Beheersing (ibr):", choices = risk_choices),
                              selectInput("fpe_car", "Cijferanalyse (car):", choices = risk_choices),
                              numericInput("fpe_mat", "Materialiteit (fractie):", value = 0.01, min = 0.0001, max = 1, step = 0.001)
                            ),
                            mainPanel(
                              h3("Resultaat"),
                              verbatimTextOutput("res_fpe"),
                              p("Aantal posten dat overeenkomt met de verlaagde risico's.")
                            )
                          )
                 ),

                 # -------------------------------------------------------------------------
                 # TAB 3: Eval Stratified (Main Analysis)
                 # -------------------------------------------------------------------------
                 tabPanel("Evaluatie Gestratificeerd",
                          sidebarLayout(
                            sidebarPanel(
                              h4("1. Upload Steekproeven"),
                              fileInput("file_strat", "Upload CSV Bestand:", accept = ".csv"),
                              downloadButton("download_template", "Download CSV Template"),
                              hr(),
                              h4("2. Instellingen"),
                              numericInput("strat_conf", "Zekerheid (0.95 = 95%):", value = 0.95, min = 0.5, max = 0.999),
                              numericInput("strat_mc", "Monte Carlo Iteraties:", value = 100000, min = 1000, step = 10000),
                              numericInput("strat_seed", "Seed (Startwaarde):", value = 1),
                              checkboxInput("strat_comp", "Vergelijk met 'Als 1' methode", value = TRUE),
                              hr(),
                              actionButton("run_strat", "Bereken Evaluatie", class = "btn-success", width = "100%")
                            ),
                            mainPanel(
                              tabsetPanel(
                                tabPanel("Resultaten",
                                         h3("Convolutie Resultaten"),
                                         tableOutput("table_strat_main"),
                                         h3("Vergelijking"),
                                         tableOutput("table_strat_comp")
                                ),
                                tabPanel("Invoer Data",
                                         h4("Geupload bestand (met berekende kolommen)"),
                                         tableOutput("table_strat_input")
                                )
                              )
                            )
                          )
                 )
)

server <- function(input, output, session) {

  # --- LOGIC TAB 1: HARO ---
  output$res_haro <- renderText({
    val <- haro_nog_nodige_zekerheid(
      ihr = input$haro_ihr,
      ibr = input$haro_ibr,
      car = input$haro_car
    )
    paste("Nog nodige zekerheid:", round(val, 4))
  })

  # --- LOGIC TAB 2: FPE ---
  output$res_fpe <- renderText({
    val <- foutloze_posten_equivalent(
      ihr = input$fpe_ihr,
      ibr = input$fpe_ibr,
      car = input$fpe_car,
      materialiteit = input$fpe_mat
    )
    paste("Equivalent aantal foutloze posten:", val)
  })

  # --- LOGIC TAB 3: STRATIFIED ---

  # 1. Template Download Handler
  output$download_template <- downloadHandler(
    filename = function() { "steekproeven_template.csv" },
    content = function(file) {
      # Create an empty tibble structure that matches user requirements
      df <- tibble(
        naam = c("Steekproef 1", "Steekproef 2"),
        w = c(1000000, 500000),
        n = c(30, 20),
        k = c(0, 1),
        ihr = c("H", "L"),
        ibr = c("H", "L"),
        car = c("H", "H"),
        materialiteit = c(0.01, 0.01)
      )
      write_csv(df, file)
    }
  )

  # 2. Reactive Calculation
  strat_results <- eventReactive(input$run_strat, {
    req(input$file_strat)

    # Read CSV
    tryCatch({
      df <- read_csv(input$file_strat$datapath, show_col_types = FALSE)

      # Convert inputs to simple tibble expected by function
      # Ensure data types are correct
      df <- df %>%
        mutate(
          w = as.numeric(w),
          n = as.numeric(n),
          k = as.numeric(k),
          materialiteit = as.numeric(materialiteit)
        )

      # Run the package function
      res <- eval_stratified(
        steekproeven = df,
        zekerheid = input$strat_conf,
        MC = as.integer(input$strat_mc),
        start = input$strat_seed,
        vergelijk = input$strat_comp
      )
      return(res)

    }, error = function(e) {
      showNotification(paste("Error:", e$message), type = "error")
      return(NULL)
    })
  })

  # 3. Output Tables
  output$table_strat_main <- renderTable({
    res <- strat_results()
    req(res)

    # Create a nice summary table
    tibble(
      Metriek = c("Meest Waarschijnlijke Fout (fractie)",
                  "Meest Waarschijnlijke Fout (geld)",
                  "Maximale Fout (fractie)",
                  "Maximale Fout (geld)"),
      Waarde = c(
        sprintf("%.5f", res$mw_fout_convolutie),
        format(round(res$mw_fout_convolutie_geld, 2), big.mark=".", decimal.mark=","),
        sprintf("%.5f", res$max_fout_convolutie),
        format(round(res$max_fout_convolutie_geld, 2), big.mark=".", decimal.mark=",")
      )
    )
  })

  output$table_strat_comp <- renderTable({
    res <- strat_results()
    req(res)
    if(is.null(res$vergelijk_met)) return(tibble(Info = "Geen vergelijking gevraagd."))

    comp <- res$vergelijk_met
    tibble(
      Scenario = c("Los (Gewogen gemiddelde)", "Als 1 (Gepoolde data)"),
      `Max Fout (Geld)` = c(
        format(round(comp$max_fout_los_geld, 2), big.mark=".", decimal.mark=","),
        format(round(comp$max_fout_als1_geld, 2), big.mark=".", decimal.mark=",")
      )
    )
  })

  output$table_strat_input <- renderTable({
    res <- strat_results()
    req(res)
    # Show the enriched tibble (which includes extra_foutloze_posten)
    res$steekproeven
  })
}

shinyApp(ui, server)
