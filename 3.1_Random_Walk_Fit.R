
#' Function for the random walk model. Observations are modelled under a Poisson, while the the species is 
#' modelled with normal process error 
#' 
#' @param county.name Name of county of interest
#' @param spp species, one of "albo" or "aegypti"
#' @param data.set data
#' @param n.iter number of iterations, default = 5000
#' @param inits initial conditions, default = NULL

Random_Walk_Fit <- function(county.name, spp, data.set, inits = NULL, ...){

  # get county of interest and create a "year-month" column
  county.sub <- data.fit %>% 
    filter(state_county == counties[i]) 
  for(i in 1:nrow(county.sub)){
    if(county.sub$month[i]==10){
      county.sub$new.month[i] <- 91 
    } else if(county.sub$month[i]==11){
      county.sub$new.month[i] <- 92 
    } else if(county.sub$month[i]==12){
      county.sub$new.month[i] <- 93 
    } else {
      county.sub$new.month[i] <- county.sub$month[i] 
    }
  }
  
  county.sub <- county.sub %>% 
    unite("year_month", year, month, sep = "-", remove = FALSE) %>% 
    unite("year_month_seq", year, new.month, sep = "-")
  
  # aggregate counts for each month, as they are separated by trap type
  y.albo <- aggregate(county.sub$num_albopictus_collected, by = list(county.sub$year_month_seq), FUN = sum)[,2]
  y.aegypti <- aggregate(county.sub$num_aegypti_collected, by = list(county.sub$year_month_seq), FUN = sum)[,2]
  
  # use appropriate data (which species?)
  if(spp == "albo"){
    y <- y.albo
  } else {
    y <- y.aegypti
  }
  
  # create data list for JAGS
  data <- list(y = y,
               n.month = length(y))
  
  model <- "
  model{
    
    #### Data Model
    for(i in 1:n.month){
      y[i] ~ dpois(x[i])
    }
    
    #### Process Model
    for(i in 2:n.month){
      x[i] ~ dnorm(x[i-1], tau_proc)
    }
    
    #### Priors
    x[1] ~ dpois(5)
    tau_proc ~ dgamma(0.01,0.01)
  
  }"
  
  j.model <- jags.model(file = textConnection(model),
                        data = data,
                        n.chains = 3,
                        inits = inits,
                        ...)

  return(j.model)

}
