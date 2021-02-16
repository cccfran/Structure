# Extract the ultimate owners of each listed firm in listed_firms_with_orgencode.csv in 2017.
# 
# * org_encode: org_encode of listed firms
# * ultimate_owner: ultimate owner org_encode (same as org_encode if a firm does not have an investor)
# * accu_weight: cumulative product of weights from listed firm to the ultimate owner
# * step: how many layers between firm and its ultimate owner. Note if step=0 means it is the ultimate owner itself, i.\
# e. the firm does not have an investor.

pacman::p_load(data.table, igraph, optparse, Matrix)

g <- readRDS("../../iFindData/data/g_2017.RDS")
edges <- as_data_frame(g, "edges")
setDT(edges)
edges[, weight:=weight/100]

# listed firm's shareholders
lf <- fread("../../data-listed firms/listed_firm_investee_investor_pair.csv")
edges <- rbind(edges, lf[,.(from = org_encode_investor, to = org_encode, 
                            weight = percent/100, cash = NA)])

firms_raw <- fread("output/listed_firms_with_orgencode.csv")

firms <- firms_raw[org_encode != "",.(corp_name, org_encode)]
firms <- merge(firms, edges[,.(from, to, weight)], by.x = "org_encode", by.y = "to", all.x = T)
# no investor
ret_sub <- firms[is.na(from), .(org_encode, investor = org_encode, weight, step = 0)]
# with investor
firms <- unique(firms[!is.na(from), org_encode])

ret <- vector("list", length(firms))
ret_ult <- vector("list", length(firms))
for(i in seq_along(firms)) {
  if(i %% 100 == 0)print(i)
  
  step <- 1
  r <- firms[i]
  es <- edges[to == r]
  if(nrow(es) == 0) next
  es[is.na(weight), weight := 1]
  es <- es[,.(org_encode = to, investor = from, weight = weight, step = step)]
  rret <- es
  
  # get next layer
  es_nxt <- merge(es[,.(org_encode, investor, accu_weight = weight)], 
                  edges, by.x="investor", by.y="to", all.x = T)
  ## next layer is ultimate
  es_nxt_end <- unique(es_nxt[is.na(from), .(investor)])
  ## next layer that is not ultimate
  es_nxt <- es_nxt[!(from %in% rret$investor) & !is.na(from)]

  # if next layer is ultimate, store to ultimate
  ultimate <- merge(es[, .(org_encode, investor, accu_weight = weight, step)], 
                    es_nxt_end, by="investor")
  
  while(nrow(es_nxt)!=0) {
    step <- step + 1
    es <- es_nxt[,.(org_encode, investor = from, weight, 
                    accu_weight = weight*accu_weight, step = step)]
    rret <- rbind(rret, es[,.(org_encode, investor, weight, step)])
    
    # get next layer
    es_nxt <- merge(es[,.(org_encode, investor, accu_weight)], 
                    edges, by.x="investor", by.y="to", all.x = T)
    ## next layer is ultimate
    es_nxt_end <- unique(es_nxt[is.na(from), .(investor)])
    ## next layer that is not ultimate
    es_nxt <- es_nxt[!(from %in% rret$investor) & !is.na(from)]
    
    # if no investor up one layer, then they are the ultimate owners
    ultimate <- rbind(ultimate,
                      merge(es[, .(org_encode, investor, accu_weight, step)], 
                            es_nxt_end, by="investor"))
    ultimate
  }
  
  ret[[i]] <- rret
  ret_ult[[i]] <- ultimate
}

ret_ult_df <- rbindlist(ret_ult)
ret_ult_df <- rbind(ret_ult_df, ret_sub[,.(investor, org_encode, accu_weight = 1, step)])
ret_ult_df <- ret_ult_df[,.(org_encode, ultimate_owner = investor, accu_weight, step)]
ret_ult_df <- ret_ult_df[order(step)]
ret_ult_df <- ret_ult_df[ultimate_owner!=""]
tmp <- unique(ret_ult_df[,.(org_encode, ultimate_owner, accu_weight, step)], 
       by = c("org_encode", "ultimate_owner", "step"))

# cumulative weight by layer
tmp[, .(mean_weight = mean(accu_weight), 
        median_weight = median(accu_weight), .N), by=.(step)]

# layer of the max cumulative weight of each firm
summary(tmp[tmp[,.I[which.max(accu_weight)], by=.(org_encode)]$V1]$step)


fwrite(rbind(rbindlist(ret), ret_sub), "output/listed_firms_investor.csv")
fwrite(unique(ret_ult_df[,.(org_encode, ultimate_owner, accu_weight, step)], 
              by = c("org_encode", "ultimate_owner", "step")), 
       "../../data-listed firms/listed_firms_ultimate_owner_long.csv")
fwrite(unique(ret_ult_df[,.(ultimate_owner)]), 
       "../../data-listed firms/listed_firms_ultimate_owner.csv")


# firms <- firms_raw[org_encode != "",.(corp_name, org_encode)]
# firms <- merge(firms, edges[,.(from, to, weight)], by.x = "org_encode", by.y = "to", all.x = T)
# 
# ret_sub <- firms[is.na(from), .(org_encode)]
# ret_sub[, `:=` (investor = org_encode, weight = 100, step = 0)]
# firms <- firms[!is.na(from)]
# 
# stop_rule <- T
# ret <- NULL
# ret[[1]] <- ret_sub
# ret[[2]] <- firms[,.(org_encode, investor = from, weight, step = 1)]
# step <- 2
# 
# while(stop_rule) {
#   print(step)
#   setnames(firms, old = "from", new =  "to")
#   firms <- merge(firms[, .(org_encode, to)], edges[,.(from, to, weight)], 
#                  by = "to", all.x = T)
#   firms <- firms[!is.na(from)]
#   ret[[step+1]] <- firms[,.(org_encode, investor = from, weight, step = step)]
#   firms[, to:=NULL]
#   
#   print(nrow(firms))
#   stop_rule <- (!(nrow(firms) == 0))
#   step <- step + 1
# }
# 



