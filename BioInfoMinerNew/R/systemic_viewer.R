#' BioInfoMiner Systemic Interpretation Viewer
#'
#' Launches an interactive Shiny/visNetwork viewer for a BioInfoMiner DAG
#' (GO / REACTOME / any ontology available in your results) enriched with:
#' - term genes (ea_results[[ontology]])
#' - systemic processes (gp_results[[ontology]]$clusters_configuration)
#' - top genes pills (gp_results[[ontology]]$top_genes_configuration)
#'
#' If neither `results` nor `json_path` is provided, the example JSON shipped
#' with the package (inst/examples/Onlygenes_CSV.json) is used.
#'
#' @param results BioInfoMiner results object (nested list). If provided, `json_path` is ignored.
#' @param json_path Path to a BioInfoMiner JSON results file (e.g. "results.json").
#' @param ontology Which ontology to view (case-insensitive), e.g. "GO", "REACTOME".
#' @param top_genes_n Number of top genes to show as clickable pills.
#' @return A Shiny app object (invisibly). This function launches the app.
#'
#' @examples
#' \dontrun{
#' # Load the built-in example JSON:
#' bim_systemic_viewer(ontology = "GO")
#'
#' # Load a JSON from disk:
#' bim_systemic_viewer(json_path = "BioInfoMiner_results.json", ontology = "REACTOME")
#'
#' # Use results already in R:
#' bim_systemic_viewer(results, ontology = "GO")
#' }
#'
#' @export
bim_systemic_viewer <- function(results = NULL,
                                json_path = NULL,
                                ontology = "GO",
                                top_genes_n = 15) {
  
  if (!requireNamespace("shiny", quietly = TRUE) ||
      !requireNamespace("visNetwork", quietly = TRUE) ||
      !requireNamespace("jsonlite", quietly = TRUE) ||
      !requireNamespace("htmltools", quietly = TRUE)) {
    stop("Missing packages. Please install: shiny, visNetwork, jsonlite, htmltools", call. = FALSE)
  }
  
  `%||%` <- function(a, b) if (!is.null(a)) a else b
  ontology <- toupper(as.character(ontology[1]))
  
  # ---- Helpers ----
  parse_path_points <- function(path) {
    if (is.null(path)) return(NULL)
    if (length(path) > 1) path <- path[1]
    path <- as.character(path)
    if (!nzchar(path)) return(NULL)
    
    start <- regmatches(path, regexec("^M\\s*([0-9\\.]+),\\s*([0-9\\.]+)", path))[[1]]
    if (length(start) < 3) return(NULL)
    x0 <- as.numeric(start[2]); y0 <- as.numeric(start[3])
    
    matches <- regmatches(path, gregexpr("([0-9\\.]+),\\s*([0-9\\.]+)", path, perl = TRUE))[[1]]
    if (length(matches) == 0) return(NULL)
    
    last_xy <- matches[length(matches)]
    end <- regmatches(last_xy, regexec("([0-9\\.]+),\\s*([0-9\\.]+)", last_xy))[[1]]
    if (length(end) < 3) return(NULL)
    x1 <- as.numeric(end[2]); y1 <- as.numeric(end[3])
    
    list(x0 = x0, y0 = y0, x1 = x1, y1 = y1)
  }
  
  nearest_node_id <- function(x, y, nodes_df) {
    d <- (nodes_df$x - x)^2 + (nodes_df$y - y)^2
    nodes_df$id[which.min(d)]
  }
  
  rescale_positions <- function(df, target_w = 2400, target_h = 1400, margin = 80) {
    xmin <- min(df$x); xmax <- max(df$x)
    ymin <- min(df$y); ymax <- max(df$y)
    w <- xmax - xmin; h <- ymax - ymin
    if (w == 0) w <- 1
    if (h == 0) h <- 1
    
    sx <- (target_w - 2 * margin) / w
    sy <- (target_h - 2 * margin) / h
    s <- min(sx, sy)
    
    df$x <- (df$x - xmin) * s + margin
    df$y <- (df$y - ymin) * s + margin
    df
  }
  
  make_ea_term_gene_map <- function(x, ont) {
    out <- list()
    ea <- x$ea_results[[ont]]
    if (is.null(ea)) return(out)
    
    for (sub in names(ea)) {
      rows <- ea[[sub]]
      if (is.null(rows)) next
      for (row in rows) {
        tid <- row$term_id
        genes <- row$genes
        if (!is.null(tid) && !is.null(genes) && length(genes) > 0) {
          out[[as.character(tid)]] <- genes
        }
      }
    }
    out
  }
  
  extract_clusters <- function(x, ont) {
    cfg <- x$gp_results[[ont]]$clusters_configuration
    if (is.null(cfg)) {
      return(list(items = list(), cluster_to_terms = list(), term_to_cluster_genes = list()))
    }
    
    items <- lapply(cfg, function(cl) {
      list(
        cluster_id = cl$cluster_id,
        term_id    = as.character(cl$term_id),
        definition = as.character(cl$definition),
        members    = cl$members,
        genes      = cl$genes
      )
    })
    
    cluster_to_terms <- vector("list", length(items))
    term_to_cluster_genes <- list()
    
    for (i in seq_along(items)) {
      m <- items[[i]]$members
      term_ids <- character(0)
      
      if (!is.null(m) && length(m) > 0) {
        for (mm in m) {
          if (is.list(mm) && !is.null(mm$term_id)) {
            term_ids <- c(term_ids, as.character(mm$term_id))
          } else if (is.character(mm)) {
            term_ids <- c(term_ids, mm)
          } else if (is.list(mm) && !is.null(mm$members)) {
            term_ids <- c(term_ids, as.character(mm$members))
          }
        }
      }
      
      term_ids <- unique(term_ids)
      cluster_to_terms[[i]] <- term_ids
      
      g <- items[[i]]$genes
      genes_vec <- character(0)
      if (!is.null(g) && length(g) > 0) {
        genes_vec <- unlist(g, use.names = FALSE)
        genes_vec <- genes_vec[!is.na(genes_vec) & nzchar(genes_vec)]
        genes_vec <- unique(as.character(genes_vec))
      }
      
      if (length(term_ids) > 0 && length(genes_vec) > 0) {
        for (tid in term_ids) {
          prev <- term_to_cluster_genes[[tid]]
          term_to_cluster_genes[[tid]] <- unique(c(prev, genes_vec))
        }
      }
    }
    
    list(items = items, cluster_to_terms = cluster_to_terms, term_to_cluster_genes = term_to_cluster_genes)
  }
  
  get_top_genes <- function(x, ont, n = 15) {
    tg <- x$gp_results[[ont]]$top_genes_configuration
    if (is.null(tg)) return(character(0))
    genes <- vapply(tg, function(z) as.character(z$gene_symbol %||% ""), character(1))
    genes <- genes[nzchar(genes)]
    unique(genes)[seq_len(min(n, length(unique(genes))))]
  }
  
  build_graph <- function(x, ont, ea_gene_map, term_to_cluster_genes) {
    dag <- x$vis_results[[ont]]$dag
    nodes_raw <- dag$dag_nodes
    edges_raw <- dag$dag_edges
    
    nodes_unscaled <- data.frame(
      id = vapply(nodes_raw, function(n) n$node_id, numeric(1)),
      x  = vapply(nodes_raw, function(n) as.numeric(n$cx), numeric(1)),
      y  = vapply(nodes_raw, function(n) as.numeric(n$cy), numeric(1))
    )
    
    nodes <- data.frame(
      id        = vapply(nodes_raw, function(n) n$node_id, numeric(1)),
      term_id   = vapply(nodes_raw, function(n) as.character(n$term_id), character(1)),
      term_name = vapply(nodes_raw, function(n) as.character(n$definition), character(1)),
      x         = vapply(nodes_raw, function(n) as.numeric(n$cx), numeric(1)),
      y         = vapply(nodes_raw, function(n) as.numeric(n$cy), numeric(1)),
      r         = vapply(nodes_raw, function(n) as.numeric(n$r), numeric(1)),
      stringsAsFactors = FALSE
    )
    
    nodes <- rescale_positions(nodes)
    nodes$size <- pmax(10, nodes$r * 1.6)
    nodes$label <- ""
    nodes$shape <- "dot"
    
    has_genes <- vapply(nodes$term_id, function(tid) {
      ea_ok <- !is.null(ea_gene_map[[tid]]) && length(ea_gene_map[[tid]]) > 0
      cl_ok <- !is.null(term_to_cluster_genes[[tid]]) && length(term_to_cluster_genes[[tid]]) > 0
      ea_ok || cl_ok
    }, logical(1))
    
    nodes$color.background <- ifelse(has_genes, "#B0BEC5", "#FFFFFF")
    nodes$color.border <- ifelse(has_genes, "#6E6E6E", "#CCCCCC")
    
    nodes$title <- vapply(seq_len(nrow(nodes)), function(i) {
      tid <- nodes$term_id[i]
      name <- nodes$term_name[i]
      ea_genes <- ea_gene_map[[tid]]
      cl_genes <- term_to_cluster_genes[[tid]]
      
      genes_line <- ""
      if (!is.null(ea_genes) && length(ea_genes) > 0) {
        genes_line <- paste0("<br><b>Term genes:</b> ", paste(ea_genes, collapse = ", "))
      } else if (!is.null(cl_genes) && length(cl_genes) > 0) {
        genes_line <- paste0("<br><b>Hub genes:</b> ", paste(cl_genes, collapse = ", "))
      }
      paste0("<b>", tid, "</b><br><b>", name, "</b>", genes_line)
    }, character(1))
    
    edges <- data.frame(from = numeric(0), to = numeric(0))
    for (e in edges_raw) {
      pts <- parse_path_points(e$path)
      if (is.null(pts)) next
      from_id <- nearest_node_id(pts$x0, pts$y0, nodes_unscaled)
      to_id   <- nearest_node_id(pts$x1, pts$y1, nodes_unscaled)
      edges <- rbind(edges, data.frame(from = from_id, to = to_id))
    }
    
    list(nodes = nodes, edges = edges)
  }
  
  render_gene_pills <- function(genes) {
    htmltools::tags$div(
      style = "display:flex; flex-wrap:wrap; gap:10px; align-items:center; font-family:Arial;",
      htmltools::tags$b("TOP GENES:"),
      lapply(genes, function(g) {
        htmltools::tags$button(
          g,
          class = "pill",
          onclick = sprintf("Shiny.setInputValue('pick_gene', '%s', {priority:'event'})", g)
        )
      }),
      htmltools::tags$button(
        "CLEAR",
        class = "pill_clear",
        onclick = "Shiny.setInputValue('pick_gene', '__CLEAR__', {priority:'event'})"
      )
    )
  }
  
  # ---- Load results ----
  if (!is.null(results)) {
    x <- results
    
  } else {
    # If user did not provide json_path, load the example shipped with the package
    if (is.null(json_path) || !nzchar(json_path)) {
      json_path <- system.file("examples", "Onlygenes_CSV.json", package = "BioInfoMinerNew")
      if (json_path == "") {
        stop("Example JSON not found. Expected at inst/examples/Onlygenes_CSV.json", call. = FALSE)
      }
    }
    
    if (!file.exists(json_path)) {
      stop("JSON file not found: ", json_path, call. = FALSE)
    }
    
    x <- jsonlite::fromJSON(json_path, simplifyVector = FALSE)
  }
  
  # ---- Validate ontology availability ----
  if (is.null(x$vis_results) || is.null(x$vis_results[[ontology]]) || is.null(x$vis_results[[ontology]]$dag)) {
    available <- if (!is.null(x$vis_results)) paste(names(x$vis_results), collapse = ", ") else "(none)"
    stop("Ontology '", ontology, "' not available in vis_results. Available: ", available, call. = FALSE)
  }
  
  ea_gene_map <- make_ea_term_gene_map(x, ontology)
  cl <- extract_clusters(x, ontology)
  top_genes <- get_top_genes(x, ontology, n = top_genes_n)
  
  graph <- build_graph(x, ontology, ea_gene_map, cl$term_to_cluster_genes)
  base_nodes <- graph$nodes
  edges <- graph$edges
  
  term_table <- data.frame(
    term_id = base_nodes$term_id,
    term    = base_nodes$term_name,
    node_id = base_nodes$id,
    stringsAsFactors = FALSE
  )
  
  apply_highlight <- function(nodes0, hit, fill, border = "#000000") {
    nodes2 <- nodes0
    nodes2$color.border[hit] <- border
    nodes2$color.background[hit] <- fill
    nodes2
  }
  
  normal_nodes <- base_nodes
  
  ui <- shiny::fluidPage(
    htmltools::tags$style(htmltools::HTML("
      .sidebar {height: 78vh; overflow-y: auto; border-right: 1px solid #ddd; padding-right: 10px;}
      .tabs {display:flex; gap:10px; margin-bottom:10px;}
      .btnItem {display:block; width:100%; text-align:left; margin:4px 0; padding:10px;
                border:1px solid #eee; background:#fff; border-radius:8px; font-family:Arial;}
      .btnItem:hover {background:#f7f7f7;}
      .pill {border:none; padding:10px 14px; border-radius:999px; background:#FFD54F;
             font-weight:700; cursor:pointer; box-shadow:0 1px 2px rgba(0,0,0,.2);}
      .pill_clear {margin-left:10px; padding:10px 14px; border-radius:999px; border:1px solid #ccc;
                   background:#fff; font-weight:700; cursor:pointer;}
      .pills {margin-top:10px;}
      .ontobox {font-family:Arial; margin-bottom:8px;}
    ")),
    shiny::fluidRow(
      shiny::column(
        3,
        htmltools::div(class = "sidebar",
                       htmltools::div(class = "ontobox", htmltools::tags$b("Ontology: "), ontology),
                       htmltools::div(class = "tabs",
                                      shiny::actionButton("tab_terms", "Terms", width = "48%"),
                                      shiny::actionButton("tab_sys",   "Systemic Processes", width = "48%")
                       ),
                       shiny::textInput("search", "Search", ""),
                       shiny::uiOutput("sidebar_list")
        )
      ),
      shiny::column(
        9,
        visNetwork::visNetworkOutput("net", height = "78vh"),
        htmltools::div(class = "pills", shiny::uiOutput("pills")),
        shiny::uiOutput("info_box")
      )
    )
  )
  
  server <- function(input, output, session) {
    tab <- shiny::reactiveVal("terms")
    shiny::observeEvent(input$tab_terms, tab("terms"))
    shiny::observeEvent(input$tab_sys,   tab("sys"))
    
    locked_mode  <- shiny::reactiveVal(NULL)  # "gene" | "sys" | NULL
    locked_value <- shiny::reactiveVal(NULL)
    
    output$net <- visNetwork::renderVisNetwork({
      visNetwork::visNetwork(normal_nodes, edges) |>
        visNetwork::visEdges(arrows = "to", smooth = list(enabled = TRUE, type = "cubicBezier")) |>
        visNetwork::visNodes(fixed = TRUE) |>
        visNetwork::visInteraction(hover = TRUE, navigationButtons = TRUE) |>
        visNetwork::visPhysics(enabled = FALSE)
    })
    
    output$pills <- shiny::renderUI({
      if (length(top_genes) == 0) return(NULL)
      render_gene_pills(top_genes)
    })
    
    output$sidebar_list <- shiny::renderUI({
      q <- trimws(input$search)
      
      if (tab() == "terms") {
        df <- term_table
        if (nzchar(q)) {
          df <- df[grepl(q, df$term, ignore.case = TRUE) | grepl(q, df$term_id, ignore.case = TRUE), ]
        }
        if (nrow(df) == 0) return(htmltools::tags$div("No matches"))
        return(htmltools::tags$div(
          lapply(seq_len(nrow(df)), function(i) {
            htmltools::tags$button(
              paste0(df$term_id[i], " — ", df$term[i]),
              class = "btnItem",
              onclick = sprintf("Shiny.setInputValue('pick_node', %d, {priority:'event'})", df$node_id[i])
            )
          })
        ))
      }
      
      items <- cl$items
      if (nzchar(q)) {
        items <- items[vapply(items, function(z) grepl(q, z$definition, ignore.case = TRUE), logical(1))]
      }
      if (length(items) == 0) return(htmltools::tags$div("No systemic processes"))
      
      htmltools::tags$div(
        lapply(seq_along(items), function(i) {
          htmltools::tags$button(
            items[[i]]$definition,
            class = "btnItem",
            onclick = sprintf("Shiny.setInputValue('pick_sys', %d, {priority:'event'})", i),
            onmouseover = sprintf("Shiny.setInputValue('hover_sys', %d, {priority:'event'})", i),
            onmouseout  = "Shiny.setInputValue('hover_sys', '__OUT__', {priority:'event'})"
          )
        })
      )
    })
    
    shiny::observeEvent(input$pick_node, {
      visNetwork::visNetworkProxy("net") |>
        visNetwork::visSelectNodes(id = input$pick_node) |>
        visNetwork::visFit(animation = TRUE)
    })
    
    cluster_hit <- function(idx) {
      term_ids <- cl$cluster_to_terms[[idx]]
      if (is.null(term_ids)) term_ids <- character(0)
      normal_nodes$term_id %in% term_ids
    }
    
    shiny::observeEvent(input$pick_gene, {
      g <- input$pick_gene
      if (is.null(g) || g == "__CLEAR__") {
        locked_mode(NULL); locked_value(NULL)
        output$info_box <- shiny::renderUI(NULL)
        visNetwork::visNetworkProxy("net") |> visNetwork::visUpdateNodes(normal_nodes)
        return()
      }
      
      locked_mode("gene")
      locked_value(g)
      
      hit <- vapply(normal_nodes$term_id, function(tid) {
        ea  <- ea_gene_map[[tid]]
        clg <- cl$term_to_cluster_genes[[tid]]
        (!is.null(ea)  && g %in% ea) || (!is.null(clg) && g %in% clg)
      }, logical(1))
      
      nodes2 <- apply_highlight(normal_nodes, hit, fill = "#FFB300", border = "#000000")
      
      output$info_box <- shiny::renderUI({
        htmltools::tags$div(style = "margin-top:10px; font-family:Arial;",
                            htmltools::tags$b("Locked gene: "), g,
                            htmltools::tags$br(),
                            htmltools::tags$small("Highlighted terms contain this gene (EA genes or cluster hub genes).")
        )
      })
      
      visNetwork::visNetworkProxy("net") |> visNetwork::visUpdateNodes(nodes2)
    })
    
    shiny::observeEvent(input$pick_sys, {
      idx <- input$pick_sys
      if (is.null(idx) || idx < 1 || idx > length(cl$items)) return()
      
      locked_mode("sys")
      locked_value(idx)
      
      hit <- cluster_hit(idx)
      nodes2 <- apply_highlight(normal_nodes, hit, fill = "#BBDEFB", border = "#000000")
      
      g <- unlist(cl$items[[idx]]$genes, use.names = FALSE)
      g <- g[!is.na(g) & nzchar(g)]
      g <- unique(as.character(g))
      
      output$info_box <- shiny::renderUI({
        htmltools::tags$div(style = "margin-top:10px; font-family:Arial;",
                            htmltools::tags$b("Locked systemic process: "), cl$items[[idx]]$definition,
                            if (length(g) > 0) htmltools::tags$div(htmltools::tags$br(), htmltools::tags$b("Hub genes: "), paste(g, collapse = ", ")) else NULL
        )
      })
      
      visNetwork::visNetworkProxy("net") |> visNetwork::visUpdateNodes(nodes2)
    })
    
    shiny::observeEvent(input$hover_sys, {
      if (is.null(input$hover_sys)) return()
      
      if (is.character(input$hover_sys) && input$hover_sys == "__OUT__") {
        if (is.null(locked_mode())) {
          output$info_box <- shiny::renderUI(NULL)
          visNetwork::visNetworkProxy("net") |> visNetwork::visUpdateNodes(normal_nodes)
          return()
        }
        
        if (locked_mode() == "sys") {
          idx <- locked_value()
          hit <- cluster_hit(idx)
          nodes2 <- apply_highlight(normal_nodes, hit, fill = "#BBDEFB", border = "#000000")
          visNetwork::visNetworkProxy("net") |> visNetwork::visUpdateNodes(nodes2)
          return()
        }
        
        if (locked_mode() == "gene") {
          g <- locked_value()
          hit <- vapply(normal_nodes$term_id, function(tid) {
            ea  <- ea_gene_map[[tid]]
            clg <- cl$term_to_cluster_genes[[tid]]
            (!is.null(ea)  && g %in% ea) || (!is.null(clg) && g %in% clg)
          }, logical(1))
          nodes2 <- apply_highlight(normal_nodes, hit, fill = "#FFB300", border = "#000000")
          visNetwork::visNetworkProxy("net") |> visNetwork::visUpdateNodes(nodes2)
          return()
        }
        
        visNetwork::visNetworkProxy("net") |> visNetwork::visUpdateNodes(normal_nodes)
        return()
      }
      
      idx <- suppressWarnings(as.integer(input$hover_sys))
      if (is.na(idx) || idx < 1 || idx > length(cl$items)) return()
      
      hit <- cluster_hit(idx)
      nodes2 <- apply_highlight(normal_nodes, hit, fill = "#E3F2FD", border = "#000000")
      
      g <- unlist(cl$items[[idx]]$genes, use.names = FALSE)
      g <- g[!is.na(g) & nzchar(g)]
      g <- unique(as.character(g))
      
      output$info_box <- shiny::renderUI({
        htmltools::tags$div(style = "margin-top:10px; font-family:Arial;",
                            htmltools::tags$b("Preview systemic process: "), cl$items[[idx]]$definition,
                            if (length(g) > 0) htmltools::tags$div(htmltools::tags$br(), htmltools::tags$b("Hub genes: "), paste(g, collapse = ", ")) else NULL
        )
      })
      
      visNetwork::visNetworkProxy("net") |> visNetwork::visUpdateNodes(nodes2)
    })
  }
  
  app <- shiny::shinyApp(ui, server)
  shiny::runApp(app)
  invisible(app)
}
