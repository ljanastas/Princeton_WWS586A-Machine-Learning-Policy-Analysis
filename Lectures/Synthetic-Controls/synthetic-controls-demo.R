library(Synth)
library(ggplot2)
library(foreign)


data(basque)

# How many regions are there?
table(basque$regionname)

#Basque region is region 17

# dataprep: prepare data for synth
dataprep.out <-
  dataprep(
    foo = basque
    ,predictors= c("school.illit", # These are the predictors that you want to include
                   "school.prim",
                   "school.med",
                   "school.high",
                   "school.post.high"
                   ,"invest"
    ) 
    ,predictors.op = c("mean") # Mean is the defailt
    ,dependent     = c("gdpcap")
    ,unit.variable = c("regionno")
    ,time.variable = c("year")
    ,special.predictors = list(
      list("gdpcap",1960:1969,c("mean")),                            
      list("sec.agriculture",seq(1961,1969,2),c("mean")),
      list("sec.energy",seq(1961,1969,2),c("mean")),
      list("sec.industry",seq(1961,1969,2),c("mean")),
      list("sec.construction",seq(1961,1969,2),c("mean")),
      list("sec.services.venta",seq(1961,1969,2),c("mean")),
      list("sec.services.nonventa",seq(1961,1969,2),c("mean")),
      list("popdens",1969,c("mean")))
    ,treatment.identifier  = 17
    ,controls.identifier   = c(2:16,18)
    ,time.predictors.prior = c(1964:1969)
    ,time.optimize.ssr     = c(1960:1969)
    ,unit.names.variable   = c("regionname")
    ,time.plot            = c(1955:1997) 
  )

# Dataprep stores all the relevant information in different matrices for the 
# pre- and post treatment period and the control and "donor pool" units

dataprep.out$X1  #X1	 matrix of treated predictor data, nrows = number of predictors ncols = ones.
dataprep.out$X0  #X0	 matrix ofmatrix of controls' predictor data. 
                 # nrows = number of predictors. ncols = number of control units (>=2).
dataprep.out$Z1  # Z1 matrix of treated outcome data for the pre-treatment periods over which 
                 # MSPE is to be minimized. nrows = number of pre-treatment periods. ncols = 1.
dataprep.out$Z0  # matrix of controls' outcome data for the pre-treatment periods over which 
                # MSPE is to be minimized. nrows = number of pre-treatment periods. ncols = number of control units.


# 1. combine highest and second highest 
# schooling category and eliminate highest category
dataprep.out$X1["school.high",] <- 
  dataprep.out$X1["school.high",] + 
  dataprep.out$X1["school.post.high",]
dataprep.out$X1                 <- 
  as.matrix(dataprep.out$X1[
    -which(rownames(dataprep.out$X1)=="school.post.high"),])
dataprep.out$X0["school.high",] <- 
  dataprep.out$X0["school.high",] + 
  dataprep.out$X0["school.post.high",]
#dataprep.out$X0                 <- 
#  dataprep.out$X0[
#    -which(rownames(dataprep.out$X0)=="school.post.high"),]

# 2. make total and compute shares for the schooling catgeories
lowest  <- which(rownames(dataprep.out$X0)=="school.illit")
highest <- which(rownames(dataprep.out$X0)=="school.high")

dataprep.out$X1[lowest:highest,] <- 
  (100 * dataprep.out$X1[lowest:highest,]) /
  sum(dataprep.out$X1[lowest:highest,])
dataprep.out$X0[lowest:highest,] <-  
  100 * scale(dataprep.out$X0[lowest:highest,],
              center=FALSE,
              scale=colSums(dataprep.out$X0[lowest:highest,])
  )

# run synth
synth.out <- synth(data.prep.obj = dataprep.out)

# Get result tables
synth.tables <- synth.tab(
  dataprep.res = dataprep.out,
  synth.res = synth.out
) 

# results tables:
print(synth.tables)

# plot results:
# path
path.plot(synth.res = synth.out,
          dataprep.res = dataprep.out,
          Ylab = c("real per-capita GDP (1986 USD, thousand)"),
          Xlab = c("year"), 
          Ylim = c(0,13), 
          Legend = c("Basque country","synthetic Basque country"),
) 

## gaps
gaps.plot(synth.res = synth.out,
          dataprep.res = dataprep.out, 
          Ylab = c("gap in real per-capita GDP (1986 USD, thousand)"),
          Xlab = c("year"), 
          Ylim = c(-1.5,1.5), 
)


