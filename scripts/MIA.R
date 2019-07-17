library(shiny)
library(shinyWidgets)
library(shinyjs)
library(RSQLite)
library(DBI)
library(ggplot2)
library(scales)
library(reshape2)
library(stringr)
library(ggtree)
library(DT)
library(ape)
library(phangorn)
#library(rhandsontable)
library(ggthemes)
#library(scales)
library(shinycssloaders)
library(data.table)
library(subprocess)
library("rhandsontable")
library(dplyr)
#library(msaR)

options(browser='xdg-open')

root = '/scripts/MIA'
#initial.options <- commandArgs(trailingOnly = FALSE)
#file.arg.name <- "--file="
#script.name <- sub(file.arg.name, "", initial.options[grep(file.arg.name, initial.options)])
#root <- dirname(script.name)
#print(paste('ROOT=',root, 'INITIAL.OPTIONS=', initial.options, sep=''))
MIAdb = paste(root, '/db/MIA.db', sep='')
logRoot = paste(root, '/scripts/logs/', sep='')

# Connect to MIA.db
db = dbConnect(SQLite(), MIAdb)
runsAtLoad = as.list(dbGetQuery(db, "select distinct RunID from progress"))$RunID

# Functions
meanCov = function(d){
  # d = dbGetQuery(db, sprintf("select RunID, Sample, Segment, Position, Coverage from coverage where RunID = '%s' and NumReads = '%s'", run, numreads))
  l = tapply(d$Position, c(d$Segment), max)
  d = d %>% group_by(Sample, Segment) %>% summarise_at(vars('Coverage'), sum) %>% select(Sample, Segment, Coverage)
  d = data.table(d)
  d$CovMean = d$Coverage / l[d$Segment]
  d[,c(1,2,4)]
}

########################################################################################################################################################################
########################################################################################################################################################################
# UI
########################################################################################################################################################################
########################################################################################################################################################################

ui = fluidPage(
  headerPanel('',windowTitle="Mia"),
  useShinyjs(),
  fluidRow(
    column(3, selectizeInput("runs", "Select Run", runsAtLoad, selected=tail(runsAtLoad,1))),
    column(1, actionButton("refreshRuns", 'Refresh Runs')),
    column(7,offset=1, tableOutput("progress")),
    #column(1, actionButton("close","End Session")),
    mainPanel(width=12,
      tabsetPanel(type = "tabs",
                  tabPanel("Albacore Summary",
                            fluidRow(column(12, plotOutput("passFilter"),style="height:70px;")),
                            fluidRow(column(12,withSpinner( plotOutput("barcodeAssPlot") ), style="height:200px;") ,
                                     fluidRow(column(2, offset=8, checkboxInput("unassignedBar","Unclassified", value=T)),
                                              column(2,  checkboxInput("passedQC","Passed QC only", value=F))
                                     )
                            ),
                            fluidRow(verbatimTextOutput("barcodeAssTable")), 
                            fluidRow(column(6,fluidRow(withSpinner(plotOutput("readLen"))),
                                              fluidRow(column(11,offset=1,sliderInput("readLenXmax", "X axis max", min=0, max=0, value=1, step=10, width="100%"))),
                                              fluidRow(column(6,offset=3, numericInput("readLenBins", "Bin Size",20)))),
                                     column(6,withSpinner(plotOutput("qScorePlot")))
                            )
                  ), 
                  tabPanel("IRMA Summary",
                  		   fluidRow(switchInput('mappingCount', value=TRUE, label='Display', onLabel="Counts", offLabel="Percent", size="mini", onStatus="blue", offStatus="blue")),
                           fluidRow(column(6, withSpinner(plotOutput("fluMapping", height='900px'))),
                                    column(6, withSpinner(plotOutput("segMapping", height='900px')))),
                           fluidRow(column(8, offset=4, withSpinner(tableOutput("mappingTable"))))
                  ), 
                  tabPanel("IRMA Coverage Plots",
                           fluidRow(column(5, radioButtons("segs", "Select Segment", c('All','segments'), inline=TRUE)), #radioButtons("seqORid", "View: ", c("All Samples, Across Segment", "All Segments, Across Sample"))),
                                    column(3, selectizeInput("sampleIDs", "Select Sample", c('All','samples')) #conditionalPanel("input.seqORid == 'All Samples, Across Segment'", selectizeInput("segs", "Select Segment", c('All','segments') )),
                                              #conditionalPanel("input.seqORid == 'All Segments, Across Sample'", selectizeInput("sampleIDs", "Select Sample", c('All','samples') ))
                                    ),
                                    column(2, checkboxInput("independantYaxes","Independant Y Axes"))#,
                                    #column(2, downloadBttn('coverageReport', 'Save Coverage PDFs', size='sm'))
                           ),
                           fluidRow(column(12, withSpinner( plotOutput("coverage") ) ))
                  ),
                  tabPanel("Blast",
                           fluidRow(column(3, selectizeInput("blastSample", "Sample", c('samples'))),
                                    column(3, selectizeInput("blastSeg", "Segment", c('segment')))
                           ),
                           fluidRow(column(10,offset=1,withSpinner(tableOutput("blast"))))
                  ),
                  tabPanel("CVV Variants",
                           fluidRow(column(2, offset=2,selectizeInput("cvvSample", "Sample", c('All'))),
                                    column(2, selectizeInput("cvvReference", "CVV Reference", c('All'))),
                                    column(2, checkboxInput("cvv_vars", "Variants only", value=T)),
                                    column(2, checkboxInput("cvv_anti", "Antigenic sites only", value=T))         
                           ),
                           fluidRow(column(10,offset=1, withSpinner(DT::dataTableOutput("cvv_table"))))
                  ),
                  
                  navbarMenu("Genome Constellation", 
                  
                      tabPanel("Tree + Heatmap",
                               fluidRow(
                                   column(2, selectizeInput("treeSeg", "Segment", c('segments'))),
                                   column(2, selectizeInput("treeSegBranch", "Annotate branches by:", c('HA', 'NA'))),
                                   column(2, numericInput("percIden", "Heatmap Minimum Identity", max=100, min=0, value=80)),
                                   column(4, selectizeInput("treeSegIDs", "Select IDs for IRMA-utr >> Alignment View", c('ids'), multiple=TRUE, width="150%")), #Nanopolish >> 
                                   column(1, checkboxInput("overwrite","Overwrite")),
                                   column(1, actionButton("IRMAutr2nanopolish", '', icon=icon("motorcycle", "fa-3x")))),
                               #fluidRow(offset=6, actionButton("zoomOutTree", "", icon=icon("minus", "fa-1x")),
                              #          actionButton("zoomResetTree", "Reset"),
                               #         actionButton("zoomInTree", "", icon=icon("plus", "fa-1x"))),
                               fluidRow(column(9,offset=1, withSpinner(plotOutput("GCTree"))))
                               
                           
                      )
                  
                      ,
                      tabPanel("Constellation Table",
                               fluidRow(column(9,offset=1, withSpinner(DT::dataTableOutput("GCTable"))))
                               )
                  ),
                  #tabPanel("IDs",
                        #   h4("Plate Layout"),
                        #   withSpinner(fluidRow(rHandsontableOutput('plate'),
                        #                         br(),
                        #                         actionButton("save", "Save Plate")
                        #   )),
                        #   br(),
                        #   h4("Barcode IDs")#,
                           #withSpinner(fluidRow(rHandsontableOutput('barcodeKey'),
                             #                   br(),
                            #                    actionButton("saveBar", "Save Barcode IDs")
                           #))
                    
                  #)
                  tabPanel("Log Feed",
                           h5("mia.log"),
                           fluidRow(verbatimTextOutput('log_mia'),
                                    tags$head(tags$style("#log_mia{font-size:10px; overflow-y:scroll; max-height: 200px;}"))
                                   ),
                           h5("inotify.log"),
                           fluidRow(verbatimTextOutput('log_inotify'),
                                    tags$head(tags$style("#log_inotify{font-size:10px; overflow-y:scroll; max-height: 200px;}"))
                           ),
                          switchInput('runtop','Run \'top\' command'),
                          fluidRow(verbatimTextOutput('log_top'),
                                    tags$head(tags$style("#log_top{font-size:10px; overflow-y:scroll; max-height: 400px;}"))
                          )
                    )
                  
        )
      )
    )
)

# 
########################################################################################################################################################################
########################################################################################################################################################################
# SERVER
########################################################################################################################################################################
########################################################################################################################################################################

server = function(input, output, session){

  #observe({
  #  if(! is.null(input$click)){print(input$click)}
  #})
  
  observeEvent(input$refreshRuns,{
    runs = as.list(dbGetQuery(db, "select distinct RunID from progress"))$RunID
    updateSelectizeInput(session, "runs", "Select Run", choices=runs, selected=tail(runs,1))
  })
  # Samples in run  
  observe({
    run = input$runs
    samples = sort(as.list(dbGetQuery(db, sprintf("select distinct Sample from coverage where RunID = '%s'", run)))$Sample)
    updateSelectizeInput(session,"sampleIDs", label="Select Sample", choices=c('All',samples))
    updateSelectizeInput(session, "cvvSample", "Sample", choices=c('All',samples))
  })
  # Segments in run  
  observe({
    run = input$runs
    segments = sort(as.list(dbGetQuery(db, sprintf("select distinct Segment from coverage where RunID = '%s'", run)))$Segment)
    updateRadioButtons(session,"segs", label="Select Segment", choices=c('All',segments), selected = 'HA', inline=TRUE)
  })
  observeEvent(input$IRMAutr2nanopolish,{
    run = input$runs
    seg = input$treeSeg
    if (input$overwrite){
     overwrite = "-o"   
    }else{overwrite = ""}
    #runDir = as.character(system2("/usr/bin/find", c("/home/*/minionRuns/", "-type", "d", "-name", run)))
    system2('/bin/bash', c(paste(root, "/scripts/runIRMAutr.sh", sep=''), run, overwrite))
    #system2(paste(root,"/scripts/MIApolish.sh", sep=''), c(run, "ALL", "utr", overwrite))
    system2(paste(root,"/scripts/alignSamples2aliview.sh", sep=''), c(run, seg, noquote(input$treeSegIDs)))
  })
  # Segment color scale
  plotCols = hcl(seq(15,375,length=9),l=65, c=100)[1:8]
  names(plotCols) = c('HA', 'NA', 'PB2', 'PB1', 'PA', 'NS', 'MP', 'NP')
  segColScale = scale_color_manual(name='Segment', values=plotCols)
  segFilScale = scale_fill_manual(name='Segment', values=plotCols )
  
  #################################################
  ## DIRECTORY PROGRESS TEXT HEADER
  output$progress = renderTable(colnames = F, rownames = T, spacing='xs', align='c', {
    invalidateLater(2000, session)
    run = input$runs
    f5 = dbGetQuery(db, sprintf("select DirType as 'Process', sum(Reads) as 'Reads' from progress where RunID = '%s' and DirType = 'FAST5'", run))
    a= dbGetQuery(db, sprintf("select DirType as 'Process', max(Reads) as 'Reads' from progress where RunID = '%s' and DirType != 'FAST5' group by DirType", run)) #, max(DirMtime) as Timestamp
    a = rbind(f5,a)
    a$Process = toupper(a$Process)
    a$Reads = format(a$Reads, big.mark=',', scientific = F)
    t(a)
  })
  
  ######################################################################################################################################################################
  ##### ALBACORE SUMMARY TAB    
  # Albacore summary reactive dataframe
  albaSum = reactivePoll(1000,session,
                         checkFunc = function(){
                             run = input$runs
                             dbGetQuery(db, sprintf("select DirType, max(Reads) from progress where RunID = '%s' and DirType = 'FASTQ' group by DirType", run))
                         },
                         valueFunc = function(){
                             run = input$runs
                             dbGetQuery(db, sprintf("select * from albacore_summary where RunID = '%s'", run))
                         })
                         
  ##################################################
  ## PASS FILTERING BARPLOT
  output$passFilter = renderPlot(height=70,{
    a = albaSum()
    if (length(a[,1])<1)
     return(NULL)
    if (! input$unassignedBar){a = a[a$Barcode != 'unclassified',] }
    b = melt(table(a$RunID,a$PassesFiltering))
    ggplot(b, aes(x=Var1, y=value, fill=Var2, label=paste(c('Failed QC reads:', 'Passed QC reads:'),format(value, big.mark=','),sep=' ')))+
      geom_bar(position = 'fill', stat='identity', color="black")+
      scale_y_continuous(labels=percent_format())+
      theme(axis.title=element_blank(), axis.text.y =element_blank(), text=element_text(size=20),legend.position="none")+
      geom_text(position=position_fill(0.5), cex=6)+
      coord_flip()
  })
  ##################################################
  ## BARCODE ASSIGNMENT BARPLOT
  output$barcodeAssPlot = renderPlot(height=200,{
    a = albaSum()
    if (length(a[,1])<1)
      return(plot.new())
    if (! input$unassignedBar){a = a[a$Barcode != 'unclassified',] }
    if ( input$passedQC){a = a[tolower(a$PassesFiltering) == 'true',]}
    b = melt(table(a$RunID,a$Barcode))
    ggplot(b, aes(x=Var1, y=value, fill=Var2, label=sub('barcode', 'B_',Var2)))+
      geom_bar(position="fill", stat='identity', color="black")+
      scale_y_continuous(labels=percent_format())+
      theme(axis.title=element_blank(), axis.text.y=element_blank(), text=element_text(size=20), legend.position="none", legend.direction="horizontal")+
      geom_text(position=position_fill(0.5), cex=5, angle=90, check_overlap=T)+
      coord_flip()
  })
  ##################################################
  ## BARCODE ASSIGNMENT TABLE
  output$barcodeAssTable = renderPrint({
        a = albaSum()
        if (length(a[,1])<1)
          return(NULL)
        if ( input$passedQC){a = a[tolower(a$PassesFiltering) == 'true',]}
        a = table(a$Barcode)
        return(a)
      })
  ##################################################
  ## READ LENGTH HISTOGRAM
  observe({
    a = albaSum()
    if (! input$unassignedBar){a = a[a$Barcode != 'unclassified',]}
    if ( input$passedQC){a = a[tolower(a$PassesFiltering) == 'true',]}
    readLenXmaxDefault = max(a$SeqLength) 
    updateSliderInput(session,"readLenXmax", "X axis max", min=0, max=readLenXmaxDefault, value=readLenXmaxDefault, step=10)
  })
  aL=60 # adapter Length
  #seglens = data.frame('segs'=c('PB1/2', 'PA', 'HA', 'NP' , 'NA', 'M', 'NS'), 'lens'=c(2277+aL, 2151+aL, 1701+aL, 1497+aL, 1413+aL, 981+aL, 837+aL))

  output$readLen =renderPlot({
    xMax = input$readLenXmax
    bins = input$readLenBins
    a = albaSum()
    if (! input$unassignedBar){a = a[a$Barcode != 'unclassified',] }
    if ( input$passedQC){a = a[tolower(a$PassesFiltering) == 'true',]}
    if (length(a$SeqLength > 1)){
      ggplot(a, aes(a$SeqLength))+
        geom_histogram(breaks=seq(min(a$SeqLength), xMax, by=bins))+
        labs( x="Read Length", y="Count")+
        theme(text=element_text(size=20))#+
        #geom_vline(aes(xintercept=2277+aL))+geom_text(aes(2277+80,-50, label='PB1/2'))+
        #geom_vline(aes(xintercept=2151+aL))+geom_text(aes(2151-60,-50, label='PA'))+
        #geom_vline(aes(xintercept=1701+aL))+geom_text(aes(1701+60,-50, label='HA'))+
        #geom_vline(aes(xintercept=1497+aL))+geom_text(aes(1497+60,-50, label='NP'))+
        #geom_vline(aes(xintercept=1413+aL))+geom_text(aes(1413-60,-50, label='NA'))+
        #geom_vline(aes(xintercept=981+aL))+geom_text(aes(981+50,-50, label='M'))+
        #geom_vline(aes(xintercept=837+aL))+geom_text(aes(837-60,-50, label='NS'))
      }
  })
  
  ##################################################
  ## Q SCORE PLOT
  output$qScorePlot = renderPlot({
    a = albaSum()
    if (length(a[,1])<1)
      return(NULL)
    if ( input$passedQC){a = a[tolower(a$PassesFiltering) == 'true',]}
    ggplot(a, aes(a$MeanQscore))+geom_histogram()+labs(x='Mean Q Score', y=element_blank())+theme(text = element_text(size=20))
  })
  
  ######################################################################################################################################################################
  ##### IRMA SUMMARY TAB  
  ##################################################
  ## FLU MAPPING PLOT
  fluMappingData = reactivePoll(1000,session,
                                checkFunc = function(){
                                        run = input$runs
                                        dbGetQuery(db, sprintf("select DirType, max(Reads) from progress where RunID = '%s' and DirType = 'IRMA' group by DirType", run))
                                    },
                                valueFunc = function(){
                                    run =input$runs
                                    numreads = dbGetQuery(db, sprintf("select max(Reads) from progress where RunID = '%s' and DirType = 'IRMA' group by DirType", run))[[1]] #input$covRound
                                    if (is.numeric(numreads)){
                                        d = dbGetQuery(db, sprintf("select Sample, Match, Nomatch, Chimeric from irma_summary where RunID = '%s' and NumReads = '%s'", run, numreads))
                                        dfm = melt(d, id.vars="Sample")
                                        return(dfm)
                                    }
                                    else{return(NULL)}
                                    }
                                )
  output$fluMapping = renderPlot({
    dfm = fluMappingData()
    if (is.null(dfm)){return(NULL)}
    if (input$mappingCount == TRUE){p="stack"; l=waiver()}else{p="fill"; l=percent_format()}
    barColors=c(hue_pal()(3)[c(2,1,3)])
    ggplot(dfm, aes(x=Sample, y=value, fill=variable))+
      geom_bar(position=p, stat="identity", col="black")+ #position="stack"
      scale_y_continuous(labels=l)+
      theme(text=element_text(size=20), axis.text.x = element_text(angle = 60, hjust = 1), axis.title.y=element_blank(), axis.title.x=element_blank(), legend.position='left')+ 
      guides(fill=guide_legend(title="Flu Mapping"))+
      scale_fill_manual(values=barColors)+coord_flip()
  })
  ##################################################
  ## SEGMENT MAPPING PLOT
  segmentMappingData = reactivePoll(1000,session,
                                    checkFunc = function(){
                                        run = input$runs
                                        dbGetQuery(db, sprintf("select DirType, max(Reads) from progress where RunID = '%s' and DirType = 'IRMA' group by DirType", run))
                                    },
                                    valueFunc = function(){
                                        run = input$runs
                                        numreads = dbGetQuery(db, sprintf("select max(Reads) from progress where RunID = '%s' and DirType = 'IRMA' group by DirType", run))[[1]]
                                        if (is.numeric(numreads)){
                                            d = dbGetQuery(db, sprintf("select Sample, HA, MP, NA, NP, NS, PA, PB1, PB2 from irma_summary where RunID = '%s' and NumReads = '%s'", run, numreads))
                                            dfm = melt(d, id.vars="Sample")
                                        }
                                        else{return(NULL)}
                                    })
  output$segMapping = renderPlot({
    dfm =segmentMappingData()
    if (is.null(dfm)){return(NULL)}
    if (input$mappingCount == TRUE){p="stack"; l=waiver()}else{p="fill"; l=percent_format()}
    ggplot(dfm, aes(x=Sample, y=value, fill=variable))+
      geom_bar(position=p, stat="identity", col="black")+
      scale_y_continuous(labels=l)+
      scale_x_discrete(position='top')+
      theme(text=element_text(size=20),axis.text.x = element_text(angle = 60, hjust = 1), axis.title.y=element_blank(), axis.title.x=element_blank())+
      guides(fill=guide_legend(title="Segment"))+
      segFilScale+coord_flip()
  })
  ##################################################
  ## MAPPING TABLE
  mappingTableData = reactivePoll(1000,session,
                                  checkFunc = function(){
                                      run = input$runs
                                      dbGetQuery(db, sprintf("select DirType, max(Reads) from progress where RunID = '%s' and DirType = 'IRMA' group by DirType", run))
                                  },
                                  valueFunc = function(){
                                      run = input$runs
                                      numreads = dbGetQuery(db, sprintf("select max(Reads) from progress where RunID = '%s' and DirType = 'IRMA' group by DirType", run))[[1]]
                                      if (is.numeric(numreads)){
                                        d = dbGetQuery(db, sprintf("select Sample, Match, Nomatch, Chimeric, HA, MP, NA, NP, NS, PA, PB1, PB2 from irma_summary where RunID = '%s' and NumReads = '%s'", run, numreads))
                                      }
                                      else{return(NULL)}
                                  })
  output$mappingTable = renderTable({
    a = mappingTableData()
    if (is.null(a)){return(NULL)}
    return(a[order(a$Sample),])
  })
  
  ######################################################################################################################################################################
  ##### COVERAGE TAB
  ##################################################
  ## COVERAGE PLOTS
  plotHeight = reactive({ifelse(input$segs == 'All' && input$sampleIDs != 'All', 500, 800)})

  covPerSampData = reactivePoll(10000,session,
                        checkFunc = function(){
                             run = input$runs 
                             dbGetQuery(db, sprintf("select DirType, max(Reads) from progress where RunID = '%s' and DirType = 'IRMA' group by DirType", run))
                         },
                         valueFunc = function(){
                            run = input$runs 
                            numreads = dbGetQuery(db, sprintf("select max(Reads) from progress where RunID = '%s' and DirType = 'IRMA' group by DirType", run))[[1]]
                            sample = input$sampleIDs
                            if (is.numeric(numreads)){
                                dbGetQuery(db, sprintf("select RunID, Sample, Segment, Position, Coverage from coverage where RunID = '%s' and Sample = '%s' and NumReads = '%s'", run, sample, numreads)) 
                            }
                            else{return(NULL)}
                         }
                   )
  covPerSegData = reactivePoll(10000,session,
                         checkFunc = function(){
                           run = input$runs 
                           dbGetQuery(db, sprintf("select DirType, max(Reads) from progress where RunID = '%s' and DirType = 'IRMA' group by DirType", run))
                         },
                         valueFunc = function(){
                           run = input$runs 
                           numreads = dbGetQuery(db, sprintf("select max(Reads) from progress where RunID = '%s' and DirType = 'IRMA' group by DirType", run))[[1]]
                           seg = input$segs
                           if (is.numeric(numreads)){
                             dbGetQuery(db, sprintf("select RunID, Sample, Segment, Position, Coverage from coverage where RunID = '%s' and Segment = '%s' and NumReads = '%s'", run, seg, numreads))
                           }
                           else{return(NULL)}
                         }
                    )
  cov1sam1seg = reactivePoll(10000,session,
                             checkFunc = function(){
                               run = input$runs
                               dbGetQuery(db, sprintf("select DirType, max(Reads) from progress where RunID = '%s' and DirType = 'IRMA' group by DirType", run))
                             },
                             valueFunc = function(){
                               run = input$runs
                               numreads = dbGetQuery(db, sprintf("select max(Reads) from progress where RunID = '%s' and DirType = 'IRMA' group by DirType", run))[[1]]
                               seg = input$segs
                               sample = input$sampleIDs
                               if (is.numeric(numreads)){
                                 dbGetQuery(db, sprintf("select RunID, Sample, Segment, Position, Coverage from coverage where RunID = '%s' and Segment = '%s' and NumReads = '%s' and Sample = '%s'", run, seg, numreads, sample))
                               }
                               else{return(NULL)}
                             }
                    )
  covAll = reactivePoll(10000,session,
                             checkFunc = function(){
                               run = input$runs
                               dbGetQuery(db, sprintf("select DirType, max(Reads) from progress where RunID = '%s' and DirType = 'IRMA' group by DirType", run))
                             },
                             valueFunc = function(){
                               run = input$runs
                               numreads = dbGetQuery(db, sprintf("select max(Reads) from progress where RunID = '%s' and DirType = 'IRMA' group by DirType", run))[[1]]
                               if (is.numeric(numreads)){
                                 dbGetQuery(db, sprintf("select RunID, Sample, Segment, Position, Coverage from coverage where RunID = '%s' and NumReads = '%s'", run, numreads))                               }
                               else{return(NULL)}
                             }
  )                              

#  output$coverageReport = downloadHandler(
#    filename = function(){
#      'test.png'
#    }
#    content = function(file){
#      coverage = covAll()
#      if (is.null(coverage) || length(unique(coverage$Sample)) < 2){return(NULL)}
#      samples = sort(unique(coverage$Sample))
#      g = ggplot(coverage, aes(x=Position, y=Coverage, col=Segment))+
#        geom_line()+facet_wrap(~ Sample , scales="free", ncol=8)+ 
#        theme(text=element_text(size=16), axis.text.x = element_text(angle = 60, hjust = 1), legend.title=element_blank(), legend.position="top", legend.key.size=unit(2,'cm'), legend.direction="horizontal")+
#        guides(linetype = guide_legend(override.aes = list(size = 10)), colour = guide_legend(nrow = 1))+
#        segColScale
#      ggsave(file, g)
#    }
#  )
  
  output$coverage = renderPlot(height=plotHeight,{
    run = input$runs
    covRound = input$covRound
    scale = ifelse(! input$independantYaxes, "free_x","free")
    # COVERAGE PLOTS PER SAMPLE
    if (input$sampleIDs == 'All' && input$segs == 'All'){
      coverage = covAll()
      if (is.null(coverage) || length(unique(coverage$Sample)) < 2){return(NULL)}
      samples = sort(unique(coverage$Sample))
      ggplot(coverage, aes(x=Position, y=Coverage, col=Segment))+
        geom_line()+facet_wrap(~ Sample , scales=scale)+ 
        theme(text=element_text(size=16), axis.text.x = element_text(angle = 60, hjust = 1), legend.title=element_blank(), legend.position="top", legend.key.size=unit(2,'cm'), legend.direction="horizontal")+
        guides(linetype = guide_legend(override.aes = list(size = 10)), colour = guide_legend(nrow = 1))+
        segColScale
    }
    else if (input$segs == 'All'){
        coverage = covPerSampData()
      if (is.null(coverage) || length(unique(coverage$Segment)) < 2){return(NULL)}

      ggplot(coverage, aes(x=Position, y=Coverage, col=Segment))+
        geom_line()+facet_wrap( ~ Segment , nrow=2, scales=scale)+
        theme(text=element_text(size=16), axis.text.x = element_text(angle = 60, hjust = 1), legend.position="none")+segColScale
    }
    # COVERAGE PLOTS PER SEGMENT
    else if (input$sampleIDs == 'All'){
      coverage = covPerSegData()
      if (is.null(coverage) || length(unique(coverage$Sample)) < 2){return(NULL)}
      samples = sort(unique(coverage$Sample))
      ggplot(coverage, aes(x=Position, y=Coverage, col=Segment))+
        geom_line()+facet_wrap( ~ Sample , scales=scale)+ 
        theme(text=element_text(size=16), axis.text.x = element_text(angle = 60, hjust = 1), legend.position="none")+segColScale
    }
    else{
      coverage = cov1sam1seg()
      if (is.null(coverage)){return(NULL)}
      segLen = max(coverage$Position)
      ggplot(coverage, aes(x=Position, y=Coverage, col=Segment))+
        geom_line()+
        theme(text=element_text(size=26), axis.text.x = element_text(angle = 60, hjust = 1), legend.position="none")+
        segColScale+
        scale_x_continuous(breaks=seq(0,segLen, 100))
      
    }
  })

  
  ######################################################################################################################################################################
  ##### TREE TAB  
  ##################################################  
  observe({
      run = input$runs
      segments = dbGetQuery(db,sprintf("select distinct Segment from newick where RunID = '%s'",run))$Segment
      updateSelectizeInput(session,"treeSeg", label="Segment", choices=segments, selected="HA")
  })
  
  treeBlastData = reactivePoll(1000,session,
                             checkFunc = function(){
                                 run = input$runs
                                 dbGetQuery(db, sprintf("select max(Reads) from progress where RunID = '%s' and DirType = 'blast'", run))
                             },
                             valueFunc = function(){
                                 run = input$runs
                                 percIden = as.character(input$percIden)
                                 numreads = dbGetQuery(db, sprintf("select max(Reads) from progress where RunID = '%s' and DirType = 'blast' group by DirType", run))[[1]]
                                 if (is.numeric(numreads)){
                                    seg = input$treeSeg
                                    d = dbGetQuery(db, sprintf("select RunID, NumReads, Sample, Segment, subject, max(percent_identity) from blast where percent_identity >= '%s' and  RunID = '%s' and NumReads = '%s' group by RunID, NumReads, Sample, Segment", percIden, run, numreads))
                                 }
                                 else{return(NULL)}
                             })
  treeNewickData = reactivePoll(1000,session,
                               checkFunc = function(){
                                   run = input$runs
                                   dbGetQuery(db, sprintf("select max(Reads) from progress where RunID = '%s' and DirType = 'newick'", run))
                               },
                               valueFunc = function(){
                                   run = input$runs
                                   numreads = dbGetQuery(db, sprintf("select max(Reads) from progress where RunID = '%s' and DirType = 'newick' group by DirType", run))[[1]]
                                   if (is.numeric(numreads)){
                                       seg = input$treeSeg
                                       d = dbGetQuery(db, sprintf("select newick from newick where RunID = '%s' and NumReads = '%s' and Segment = '%s'", run, numreads, seg))[[1]]
                                   }
                                   else{return(NULL)}
                               })
  treeHaNaData = reactivePoll(1000,session,
                              checkFunc = function(){
                                run = input$runs
                                dbGetQuery(db, sprintf("select max(Reads) from progress where RunID = '%s' and DirType = 'newick'", run))
                              },
                              valueFunc = function(){
                                run = input$runs
                                numreads = dbGetQuery(db, sprintf("select max(NumReads) from hana where RunID = '%s'", run))[[1]]
                                if (is.numeric(numreads)){
                                    seg = input$treeSegBranch
                                    refs = dbGetQuery(db, sprintf("select Sample, Subtype from hana where RunID = 'references002' and NumReads = 0 and Segment = '%s'", seg))
                                    barcodes = dbGetQuery(db, sprintf("select Sample, Subtype, max(NumReads) from hana where RunID = '%s' and Segment = '%s' group by Sample, Subtype", run, seg))
                                    h = rbind(refs, barcodes[,1:2])
                                    h$Sample = ifelse(grepl('barcode',h$Sample), paste('***** ',h$Sample,sep=''), h$Sample)
                                    split(h$Sample, h$Subtype)

                                }
                                else{return(NULL)}
                              })
  A = function(){treeHeight=1250 #850
  observeEvent(
    input$zoomOutTree,{
    treeHeight = treeHeight*1.1})
  observeEvent(
    input$zoomInTree,{
    treeHeight = treeHeight*0.9
  })
  observeEvent(
    input$zoomResetTree,{
    treeHeight=850
  })
  treeHeight
  }
  output$GCTree = renderPlot(height=A(),{ # 850
      seg = input$treeSeg
      refs = dbGetQuery(db, sprintf("select RunID, NumReads, Sample, Segment, subject, max(percent_identity) from blast where RunID = '%s' and NumReads = '%s' group by RunID, NumReads, Sample, Segment", "references002", 1))
      topBlastResults = treeBlastData()
      if (is.null(topBlastResults)){return(NULL)}
      
      allBlast = rbind(refs, topBlastResults)
      genotypes =dcast(allBlast, Sample~Segment, value.var="subject")
      rownames_g = genotypes[,"Sample"]
      genotypes = genotypes[,2:length(genotypes)]
      genotypes = sapply(genotypes, str_extract,"(?<=\\{).*(?=\\})") #regex pulls out name within curly braces {name}.
      rownames(genotypes) = rownames_g
      g_vals  = c()
      for (i in genotypes){g_vals=c(g_vals, i)}
      g_vals = sort(unique(g_vals))
      treeString = treeNewickData()
      if (is.null(treeString)){return(NULL)}
      
      tree = read.tree(text=treeString)
      tree = midpoint(tree)
      
      updateSelectizeInput(session, "treeSegIDs", "Select IDs for IRMA-utr >> Alignment View", c(tree$tip.label)) #Nanopolish >>
      
      g2 = data.frame(genotypes[tree$tip.label,], check.names=FALSE)
      rownames(g2) = ifelse(grepl('barcode',rownames(g2)), paste('***** ',rownames(g2),sep=''), rownames(g2))
      tree$tip.label  = ifelse(grepl('barcode',tree$tip.label), paste('***** ',tree$tip.label,sep=''), tree$tip.label)
      g2 = g2[,c('HA','NA', 'NS', 'MP', 'NP', 'PA', 'PB1', 'PB2')] # reorder columns
      g3 = as.data.frame( cbind(rownames(g2), as.character(g2$HA)))#, as.character(g2[,seg])))
      g3 = as.data.frame(sapply(g3, function(x) {ifelse(is.na(x), 'NA', as.character(x))}))
      g4 = g2
      g4$HA = sapply(g4$HA, function(x) {ifelse(grepl("H1N1Pdm09", x),as.character(x),ifelse(grepl('_', x),str_extract(x, ".*(?=\\_)"), as.character(x))) })
      
      hana = treeHaNaData()
      tree <-  groupOTU(tree, hana)
      treeview = ggtree(tree, branch.length="none", aes(linetype=group)) + scale_linetype_manual(values = c(3,1,5)) #+ geom_text2(aes(subset=!isTip, label=node), hjust=-.3) # + geom_tiplab(color=ifelse(grepl("barcode*",tree$tip.label), 'red3', 'gray30'), size=6)
      treeview = treeview %<+% g3 + geom_tiplab(aes(color=V2), size=6) + scale_color_ptol(15)
          
      gheatmap(treeview,g4, offset=5.2, width=0.5, colnames_position = "top", font.size=6, colnames_angle=45, colnames_offset_y=0.1 ) + 
          theme(legend.position="right", legend.text = element_text(size=18)) + scale_fill_ptol(11)
  })

  
  output$GCTable = renderDataTable(rownames=TRUE,{
      seg = input$treeSeg
      refs = dbGetQuery(db, sprintf("select RunID, NumReads, Sample, Segment, subject, max(percent_identity) from blast where RunID = '%s' and NumReads = '%s' group by RunID, NumReads, Sample, Segment", "references002", 1))
      topBlastResults = treeBlastData()
      if (is.null(topBlastResults)){return(NULL)}
      
      allBlast = rbind(refs, topBlastResults)
      genotypes =dcast(allBlast, Sample~Segment, value.var="subject")
      rownames_g = genotypes[,"Sample"]
      genotypes = genotypes[,2:length(genotypes)]
      genotypes = sapply(genotypes, str_extract,"(?<=\\{).*(?=\\})") #regex pulls out name within curly braces {name}.
      rownames(genotypes) = rownames_g
      g_vals  = c()
      for (i in genotypes){g_vals=c(g_vals, i)}
      g_vals = sort(unique(g_vals))
      treeString = treeNewickData()
      if (is.null(treeString)){return(NULL)}
      
      tree = read.tree(text=treeString)
      tree = midpoint(tree)
      g2 = data.frame(genotypes[tree$tip.label,], check.names=FALSE)
      rownames(g2) = ifelse(grepl('barcode',rownames(g2)), paste('***** ',rownames(g2),sep=''), rownames(g2))
      tree$tip.label  = ifelse(grepl('barcode',tree$tip.label), paste('***** ',tree$tip.label,sep=''), tree$tip.label)
      g2 = g2[,c('HA','NA', 'NS', 'MP', 'NP', 'PA', 'PB1', 'PB2')] # reorder columns
      #g3 = as.data.frame( cbind(rownames(g2), as.character(g2$HA)))#, as.character(g2[,seg])))
      #g3 = as.data.frame(sapply(g3, function(x) {ifelse(is.na(x), 'NA', as.character(x))}))
      #return(g2)
      g2[order(row.names(g2), decreasing=TRUE),]
  })
  
  
  ######################################################################################################################################################################
  ##### BLAST TAB  
  ##################################################  
  observe({
      run = input$runs
      samples = sort(dbGetQuery(db, sprintf("select distinct Sample from blast where RunID ='%s'", run))$Sample)
      updateSelectizeInput(session,"blastSample", label="Sample", choices=samples)
      })
  observe({
      run = input$runs
      segments = dbGetQuery(db, sprintf("select distinct Segment from blast where RunID ='%s' and Sample = '%s'", run, input$blastSample))$Segment
      updateSelectizeInput(session,"blastSeg", label="Segment", choices=segments)
      })
  blastData = reactivePoll(1000,session,
               checkFunc = function(){
                   run = input$runs
                   dbGetQuery(db, sprintf("select DirType, max(Reads) from progress where RunID = '%s' and DirType = 'blast' group by DirType", run))
               },
               valueFunc = function(){
                   run = input$runs
                   numreads = dbGetQuery(db, sprintf("select max(Reads) from progress where RunID = '%s' and DirType = 'blast' group by DirType", run))[[1]]
                   if (is.numeric(numreads)){
                       seg = input$blastSeg
                       samp = input$blastSample
                       d = dbGetQuery(db, sprintf("select  subject, percent_identity, align_len, mismatches, gaps, q_start, q_end, s_start, s_end, evalue, bit_score from blast where RunID = '%s' and Sample = '%s' and Segment = '%s' and NumReads = '%s'", run, samp, seg, numreads))
                   }
                   else{return(NULL)}
               })
  output$blast = renderTable({
    d = blastData()
    if (is.null(d)){return(NULL)}
    d
  })
  ######################################################################################################################################################################
  ##### CVV TAB  
  ##################################################
  
  observe({
      run = input$runs
      refs = dbGetQuery(db, sprintf("select distinct CVV_reference from cvv_vars where RunID = '%s'",run))
      updateSelectizeInput(session, "cvvReference", label="CVV Reference", choices=c('All', refs))
  })
  
  cvvData = reactivePoll(1000,session,
                         checkFunc = function(){
                             run = input$runs
                             dbGetQuery(db, sprintf("select DirType, max(Reads) from progress where RunID = '%s' and DirType = 'cvv_aa' group by DirType", run))
                         },
                         valueFunc = function(){
                             run = input$runs
                             numreads = dbGetQuery(db, sprintf("select max(Reads) from progress where RunID = '%s' and DirType = 'cvv_aa' group by DirType", run))[[1]]
                             if (is.numeric(numreads)){
                                 seg = input$blastSeg
                                 samp = input$blastSamp
                                 vars = input$cvv_vars
                                 anti = input$cvv_anti
                                 if(anti && vars){
                                     dbGetQuery(db, sprintf("select Sample, CVV_reference, AA_position as Mature_HA_position, CVV_reference_AA, Sample_AA, Antigenic_site from cvv_vars where RunID = '%s' and NumReads = '%s' and Antigenic_site != '' and Match == 0", run, numreads))
                                 }
                                 else if(vars){
                                     dbGetQuery(db, sprintf("select Sample, CVV_reference, AA_position as Mature_HA_position, CVV_reference_AA, Sample_AA, Antigenic_site from cvv_vars where RunID = '%s' and NumReads = '%s' and Match == 0", run, numreads))
                                 }
                                 else if(anti){
                                     dbGetQuery(db, sprintf("select Sample, CVV_reference, AA_position as Mature_HA_position, CVV_reference_AA, Sample_AA, Antigenic_site from cvv_vars where RunID = '%s' and NumReads = '%s' and Antigenic_site != ''", run, numreads))
                                 }
                                 else{
                                     dbGetQuery(db, sprintf("select Sample, CVV_reference, AA_position as Mature_HA_position, CVV_reference_AA, Sample_AA, Antigenic_site from cvv_vars where RunID = '%s' and NumReads = '%s'", run, numreads))
                                 }
                             }
                             else{return(NULL)}
                         })
  
  output$cvv_table = renderDataTable({
    d = cvvData()
    if (is.null(d)){return(NULL)}
    if (input$cvvReference != 'All'){
        d = d[d$CVV_reference == input$cvvReference,]
    }
    if (input$cvvSample != 'All'){
        d = d[d$Sample == input$cvvSample,]
    }
    return(d)
  })
  
  
  #### LOG FEED
  logmia <- reactivePoll(1000,session,
                      checkFunc = function(){
                        try(read.table(paste(logRoot,'mia.log', sep=''), sep='\n', blank.lines.skip = F),silent=T)
                      },
                      valueFunc = function(){
                        d = try(read.table(paste(logRoot,'mia.log', sep=''), sep='\n'), silent=T)
                        colnames(d) = NULL
                        try(return(d[length(d[,1]):1,1]), T)
                      })
  
  output$log_mia <- renderPrint({
    print(logmia(), right=F, row.names=F)
  })
  
  loginotify <- reactivePoll(1000,session,
                         checkFunc = function(){
                           try(read.table(paste(logRoot,'inotify.log', sep=''), sep='\n'),silent=T)
                         },
                         valueFunc = function(){
                           d = try(read.table(paste(logRoot,'inotify.log', sep=''), sep='\n'),silent=T)
                           colnames(d) = NULL
                           try(return(d[length(d[,1]):1,1]),T)
                         })
  
  output$log_inotify <- renderPrint({
    print(loginotify(), right=F, row.names=F)
  })
  
  logtop <- reactivePoll(1000,session,
                             checkFunc = function(){
                               system2("/usr/bin/top", "-bn1", stdout = T)
                             },
                             valueFunc = function(){
                               d = system2("/usr/bin/top", "-bn1", stdout = T)
                               colnames(d) = NULL
                               return(d)
                             })
  
  output$log_top <- renderPrint({
    if (input$runtop){
      print(logtop(), right=F, row.names=F)
    }
    else{
      NULL
    }
  })
##############################################################################################################################################################################
#### ID TAB
##############################################################################################################################################################################
#  observeEvent(input$save,{
#      runID = input$runs
#      DF = hot_to_r(input$plate)
#      DFout = melt(as.matrix(DF))
#      DFout = data.frame(cbind(rep(input$runs, length(DFout[,1])), DFout))
#      colnames(DFout) = c('RunID', 'Row', 'Col', 'CDC_ID')
#      print(DFout)

#      DFnorm = dbGetQuery(db,sprintf("select * from plateLayout where runID = '%s'",runID))
#      if (length(DFnorm[,1]) > 0) {
#        dbSendQuery(db, sprintf("delete from plateLayout where RunID = '%s'", runID))
#      }
#      dbAppendTable(db, 'plateLayout', DFout)
    
#  })
  
#  DFnorm = dbGetQuery(db,sprintf("select * from plateLayout where runID = '%s'",input$runs))
#  DFnorm$CDC_ID = as.character(DFnorm$CDC_ID)
#  if (length(DFnorm[,1]) > 0) {
#    DF = dcast(DFnorm, Row~Col, value.var='CDC_ID', fun.aggregate=max)[,c('One','Two','Three','Four','Five','Six','Seven','Eight','Nine','Ten','Eleven','Twelve')]
#  }
#  else{
#    DF = data.frame(One=rep('',8),
#                    Two=rep('',8),
#                    Three=rep('',8),
#                    Four=rep('',8),
#                    Five=rep('',8),
#                    Six=rep('',8),
#                    Seven=rep('',8),
#                    Eight=rep('',8),
#                    Nine=rep('',8),
#                    Ten=rep('',8),
#                    Eleven=rep('',8),
#                    Twelve=rep('',8),
#                    stringsAsFactors=F)
#    rownames(DF) = LETTERS[1:8]
    
#  }
#  output$plate = renderRHandsontable({rhandsontable(DF, stretchH='all')})
  
  #observeEvent(input$saveBar,{
  #  DF = hot_to_r(input$barcodeKey)
  #})
  
}

shinyApp(ui, server)
