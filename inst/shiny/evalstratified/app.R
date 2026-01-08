library(shiny)
library(evalstratified)
library(tibble)
library(dplyr)
library(readr)
library(rhandsontable)
library(htmlwidgets)

# <--- Make sure this is installed!

# Define risk options used in multiple tabs
risk_choices <- c("Hoog (H)" = "H",
                  "Midden (M)" = "M",
                  "Laag (L)" = "L")
risk_vec <- c("H", "M", "L") # For the table dropdowns

ui <- navbarPage(
  "EvalStratified",

  # --- 1. CSS STYLING FOR GREY ROWS ---
  header = tags$head(tags$style(
    HTML(
      "
      /* Define the style for empty/ignored rows */
      .dimmed {
        color: #d0d0d0 !important;
        background-color: #f9f9f9 !important;
      }
      /* Optional: Keep the first cell (Name) white so they know where to click */
      .dimmed:first-child {
        background-color: #ffffff !important;
      }
    "
    )
  )),

  # -------------------------------------------------------------------------
  # TAB 1: Haro Nog Nodige Zekerheid
  # -------------------------------------------------------------------------
  tabPanel(
    "Nog Nodige Zekerheid",
    sidebarLayout(
      sidebarPanel(
        h4("Risico Inschatting"),
        helpText(
          "Bereken de nog benodigde zekerheid volgens HARo paragraaf B7.3.4."
        ),
        selectInput("haro_ihr", "Inherent Risico (ihr):", choices = risk_choices),
        selectInput("haro_ibr", "Interne Beheersing (ibr):", choices = risk_choices),
        selectInput("haro_car", "Cijferanalyse (car):", choices = risk_choices)
      ),
      mainPanel(
        h3("Resultaat"),
        verbatimTextOutput("res_haro"),
        p(
          "Dit is de zekerheid (fractie 0-1) die u nog uit detailcontroles moet halen."
        )
      )
    )
  ),

  # -------------------------------------------------------------------------
  # TAB 2: Foutloze Posten Equivalent
  # -------------------------------------------------------------------------
  tabPanel(
    "Foutloze Posten Equivalent",
    sidebarLayout(
      sidebarPanel(
        h4("Risico & Materialiteit"),
        helpText("Bereken hoeveel foutloze posten uw risico-inschatting waard is."),
        selectInput("fpe_ihr", "Inherent Risico (ihr):", choices = risk_choices),
        selectInput("fpe_ibr", "Interne Beheersing (ibr):", choices = risk_choices),
        selectInput("fpe_car", "Cijferanalyse (car):", choices = risk_choices),
        numericInput(
          "fpe_mat",
          "Materialiteit (fractie):",
          value = 0.01,
          min = 0.0001,
          max = 1,
          step = 0.001
        )
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
  tabPanel(
    "Evaluatie Gestratificeerd",
    sidebarLayout(
      sidebarPanel(
        h4("1. Data Invoer"),

        # --- NEW: Toggle between Upload and Manual ---
        radioButtons(
          "input_method",
          "Methode:",
          choices = c("Handmatige Invoer" = "manual", "CSV Upload" = "upload")
        ),

        # Panel for CSV Upload
        conditionalPanel(
          condition = "input.input_method == 'upload'",
          fileInput("file_strat", "Upload CSV Bestand:", accept = ".csv"),
          downloadButton("download_template", "Download CSV Template")
        ),

        # Panel for Manual Entry
        conditionalPanel(
          condition = "input.input_method == 'manual'",
          helpText(
            "Vul de tabel rechts in. Regels zonder 'naam' worden genegeerd en grijs weergegeven."
          )
        ),

        hr(),
        h4("2. Instellingen"),
        numericInput(
          "strat_conf",
          "Zekerheid (0.95 = 95%):",
          value = 0.95,
          min = 0.5,
          max = 0.999
        ),
        numericInput(
          "strat_mc",
          "Monte Carlo Iteraties:",
          value = 100000,
          min = 1000,
          step = 10000
        ),
        numericInput("strat_seed", "Seed (Startwaarde):", value = 1),
        checkboxInput("strat_comp", "Vergelijk met 'Als 1' methode", value = TRUE),
        hr(),
        actionButton(
          "run_strat",
          "Bereken Evaluatie",
          class = "btn-success",
          width = "100%"
        )
      ),

      mainPanel(
        # Only show the editable table if "Manual" is selected
        conditionalPanel(
          condition = "input.input_method == 'manual'",
          h4("Invoertabel (Vul hier uw steekproeven in)"),
          rHandsontableOutput("hot_input"),
          hr()
        ),

        tabsetPanel(
          tabPanel(
            "Resultaten",
            h3("Convolutie Resultaten"),
            tableOutput("table_strat_main"),
            h3("Vergelijking"),
            tableOutput("table_strat_comp")
          ),
          tabPanel(
            "Gebruikte Data",
            h4("Data zoals verwerkt door het model"),
            tableOutput("table_strat_input")
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  # --- LOGIC TAB 1 & 2 (Standard) ---
  output$res_haro <- renderText({
    val <- haro_nog_nodige_zekerheid(input$haro_ihr, input$haro_ibr, input$haro_car)
    paste("Nog nodige zekerheid:", round(val, 4))
  })

  output$res_fpe <- renderText({
    val <- foutloze_posten_equivalent(input$fpe_ihr,
                                      input$fpe_ibr,
                                      input$fpe_car,
                                      input$fpe_mat)
    paste("Equivalent aantal foutloze posten:", val)
  })

  # --- LOGIC TAB 3: STRATIFIED ---

  # 1. Download Template Handler
  output$download_template <- downloadHandler(
    filename = function() {
      "steekproeven_template.csv"
    },
    content = function(file) {
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

  # 2. Render the Editable Table (Handsontable)
  output$hot_input <- renderRHandsontable({
    # Initialize an empty dataframe with 8 rows
    df <- data.frame(
      naam = rep(NA_character_, 8),
      w = rep(NA_real_, 8),
      n = rep(NA_integer_, 8),
      k = rep(NA_integer_, 8),
      ihr = rep("H", 8),
      ibr = rep("H", 8),
      car = rep("H", 8),
      materialiteit = rep(0.01, 8),
      stringsAsFactors = FALSE
    )

    rhandsontable(df, stretchH = "all") %>%
      hot_col("naam", type = "text") %>%
      hot_col("w", format = "0,0") %>% # Money format
      hot_col("n", type = "numeric") %>%
      hot_col("k", type = "numeric") %>%
      hot_col("ihr", type = "dropdown", source = risk_vec) %>%
      hot_col("ibr", type = "dropdown", source = risk_vec) %>%
      hot_col("car", type = "dropdown", source = risk_vec) %>%
      hot_col("materialiteit", format = "0.00%") %>%

      # --- VISUAL FEEDBACK: Grey out rows without a name ---
      hot_table(
        cells = JS(
          "
        function(row, col, prop) {
          var cellProperties = {};

          // 'this.instance' is the Handsontable table instance
          // getSourceDataAtRow(row) gets the raw data object {naam: '...', w: ...}
          var rowData = this.instance.getSourceDataAtRow(row);

          // Check if rowData exists, then check if 'naam' is empty/null/undefined
          // Using !rowData.naam covers null, undefined, and empty string
          if (rowData && !rowData.naam) {
            cellProperties.className = 'dimmed';
          }

          return cellProperties;
        }
      "
        )
      )
  })

  # 3. Reactive Calculation (Handles BOTH Upload and Manual)
  strat_results <- eventReactive(input$run_strat, {
    final_df <- NULL

    if (input$input_method == "upload") {
      # --- CSV PATH ---
      req(input$file_strat)
      tryCatch({
        final_df <- read_csv(input$file_strat$datapath, show_col_types = FALSE)
      }, error = function(e) {
        showNotification("Kan CSV bestand niet lezen.", type = "error")
        return(NULL)
      })

    } else {
      # --- MANUAL PATH ---
      req(input$hot_input)
      # Convert the Handsontable data back to an R dataframe
      raw_df <- hot_to_r(input$hot_input)

      # FILTER: Remove rows where 'naam' is empty or NA
      final_df <- raw_df %>%
        as_tibble() %>%
        filter(!is.na(naam) & naam != "") %>%
        mutate(
          w = as.numeric(w),
          n = as.numeric(n),
          k = as.numeric(k),
          materialiteit = as.numeric(materialiteit)
        )

      if (nrow(final_df) == 0) {
        showNotification("Vul tenminste één regel in met een 'naam'.", type = "warning")
        return(NULL)
      }
    }

    # RUN CALCULATION
    tryCatch({
      res <- eval_stratified(
        steekproeven = final_df,
        zekerheid = input$strat_conf,
        MC = as.integer(input$strat_mc),
        start = input$strat_seed,
        vergelijk = input$strat_comp
      )
      return(res)
    }, error = function(e) {
      showNotification(paste("Fout in berekening:", e$message), type = "error")
      return(NULL)
    })
  })

  # 4. Output Tables
  output$table_strat_main <- renderTable({
    res <- strat_results()
    req(res)
    tibble(
      Metriek = c(
        "Meest Waarschijnlijke Fout (fractie)",
        "Meest Waarschijnlijke Fout (geld)",
        "Maximale Fout (fractie)",
        "Maximale Fout (geld)"
      ),
      Waarde = c(
        sprintf("%.5f", res$mw_fout_convolutie),
        format(
          round(res$mw_fout_convolutie_geld, 2),
          big.mark = ".",
          decimal.mark = ","
        ),
        sprintf("%.5f", res$max_fout_convolutie),
        format(
          round(res$max_fout_convolutie_geld, 2),
          big.mark = ".",
          decimal.mark = ","
        )
      )
    )
  })

  output$table_strat_comp <- renderTable({
    res <- strat_results()
    req(res)
    if (is.null(res$vergelijk_met))
      return(tibble(Info = "Geen vergelijking gevraagd."))
    comp <- res$vergelijk_met
    tibble(
      Scenario = c("Los (Gewogen gemiddelde)", "Als 1 (Gepoolde data)"),
      `Max Fout (Geld)` = c(
        format(
          round(comp$max_fout_los_geld, 2),
          big.mark = ".",
          decimal.mark = ","
        ),
        format(
          round(comp$max_fout_als1_geld, 2),
          big.mark = ".",
          decimal.mark = ","
        )
      )
    )
  })

  output$table_strat_input <- renderTable({
    res <- strat_results()
    req(res)
    res$steekproeven
  })
}

shinyApp(ui, server)
