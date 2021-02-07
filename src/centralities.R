## 20201202
# centralities calculation
## Note: 
### missing cash filled with median
# outdeg, indeg
# outdeg_s: outdegree weighted by share
# outdeg_c: outdegree weighted by cash
# indeg_c: indegree weighted by cash (indeg weighted by share is always 1)
# eigen_undir, eigen_undir_c: undirected eigen
# eigen, eigen_c, directed eigen
# eigen_rev, eigen_rev_c: eigen reverse. we should use this.
# eigen_cc, eigen_cc_c: undirected eigen of each connencted component (of size >= 100)
# btw: betweeness using distance as 1/weight then normalized by mean
# hub, hub_c, authority, authority_c
# page_rank_rev, page_rank_rev_c: page rank reverse
# cc: id of connected component; csize: size of its connected component


pacman::p_load(data.table, ggplot2, igraph, xtable, optparse)
source('../src/utilities.R', encoding = 'UTF-8')

if(.Platform$OS.type=="windows") {
  ##setwd("C:/Users/junhui/Dropbox (Penn)/Linda_Wu Zhu/Data & Codes")
  Sys.setlocale(category = "LC_CTYPE", locale = "chs")
}

option_list = list(
  make_option(c("-y", "--year"), type="integer", default="1999", 
              help="year [default= %default]", metavar="number")
); 

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)
yr = opt$year

g <-readRDS(paste0("../../iFindData/data/g_", yr, ".RDS"))
E(g)$cash[is.na(E(g)$cash)] <- median(E(g)$cash, na.rm = T)
E(g)$cash[E(g)$cash < 0] <- median(E(g)$cash, na.rm = T)

E(g)$distance <- 1/(E(g)$weight + 1e-5)
E(g)$distance <- E(g)$distance/mean(E(g)$distance, na.rm = T)

E(g)$distance_c <- 1/(E(g)$cash + 1e-5)
E(g)$distance_c <- E(g)$distance_c/mean(E(g)$distance_c, na.rm = T)


# degree
V(g)$outdeg <- igraph::degree(g, mode="out")
V(g)$indeg <-igraph:: degree(g, mode="in") 
V(g)$eigen <- eigen_centrality(g,directed = T, weights = E(g)$weight)$vector
V(g)$eigen_c <- eigen_centrality(g,directed = T, weights = E(g)$cash)$vector
V(g)$eigen_unweighted <- eigen_centrality(g, directed = T, weights = NA)$vector
V(g)$btw <- estimate_betweenness(g,directed = TRUE, cutoff = 10, weights = E(g)$distance)
V(g)$btw_c <- estimate_betweenness(g,directed = TRUE, cutoff = 10, weights = E(g)$distance_c)
V(g)$hub <- hub_score(g, weights = E(g)$share)$vector
V(g)$hub_c <- hub_score(g, weights = E(g)$cash)$vector
V(g)$authority <- authority_score(g, weights = E(g)$share)$vector
V(g)$authority_c <- authority_score(g, weights = E(g)$cash)$vector


# undir graph
g_undir <- as.undirected(g)

# V(g_undir)$btw_undir <- estimate_betweenness(g_undir,directed = F, cutoff = 10, weights = E(g_undir)$distance+1e-5)
# V(g_undir)$btw_undir_c <- estimate_betweenness(g_undir,directed = F, cutoff = 10, weights = E(g_undir)$distance_c+1e-5)
V(g_undir)$eigen_undir <- eigen_centrality(g_undir, directed = F, weights = E(g_undir)$weight)$vector
V(g_undir)$eigen_undir_c <- eigen_centrality(g_undir, directed = F, weights = E(g_undir)$cash)$vector
V(g_undir)$eigen_undir_unweighted <- eigen_centrality(g_undir, directed = F, weights = NA)$vector

nodes <- igraph::as_data_frame(g_undir, "vertices")
setDT(nodes)

# cor(nodes[,.(outdeg, indeg, eigen, eigen_unweighted, eigen_undir, eigen_undir_unweighted, eigen_undir_c,
#              hub, authority, hub_c, authority_c)])

# lar
g_lar <- extract_cc(g, 1)
V(g_lar)$eigen_lar <- eigen_centrality(g_lar, directed = T, weights = E(g_lar)$weight)$vector
V(g_lar)$eigen_c_lar <- eigen_centrality(g_lar, directed = T, weights = E(g_lar)$cash)$vector
V(g_lar)$hub_lar <- hub_score(g_lar, weights = E(g_lar)$share)$vector
V(g_lar)$hub_c_lar <- hub_score(g_lar, weights = E(g_lar)$cash)$vector
V(g_lar)$authority_lar <- authority_score(g_lar, weights = E(g_lar)$share)$vector
V(g_lar)$authority_c_lar <- authority_score(g_lar, weights = E(g_lar)$cash)$vector

# undir lar
g_lar_undir <- as.undirected(g_lar)
V(g_lar_undir)$eigen_lar_undir <- eigen_centrality(g_lar_undir, directed = F, weights = E(g_lar_undir)$weight)$vector
V(g_lar_undir)$eigen_lar_undir_c <- eigen_centrality(g_lar_undir, directed = F, weights = E(g_lar_undir)$cash)$vector
V(g_lar_undir)$eigen_lar_undir_unweighted <- eigen_centrality(g_lar_undir, directed = F, weights = NA)$vector

nodes_lar <- igraph::as_data_frame(g_lar_undir, "vertices")
setDT(nodes_lar)

nodes <- merge(nodes, 
               nodes_lar[,.(name,
                            eigen_lar, eigen_c_lar,
                            hub_lar, hub_c_lar, authority_lar, authority_c_lar,
                            eigen_lar_undir, eigen_lar_undir_c, eigen_lar_undir_unweighted)],
               by ="name", all.x=T)

cor(nodes[,.(eigen, eigen_lar, eigen_c, eigen_c_lar, hub, hub_lar, hub_c, hub_c_lar)], use = "complete.obs")

# weighted degree
edges <- igraph::as_data_frame(g, "edges")
setDT(edges)
nodes <- merge(nodes, 
  edges[, .(outdeg_s = sum(weight, na.rm = T)), by = "from"],
  by.x = "name", by.y = "from", all.x = T)
nodes <- merge(nodes, 
  edges[, .(outdeg_c = sum(cash, na.rm = T)), by = "from"],
  by.x = "name", by.y = "from", all.x = T)
nodes <- merge(nodes, 
  edges[, .(indeg_s = sum(weight, na.rm = T)), by = "to"],
  by.x = "name", by.y = "to", all.x = T)
nodes <- merge(nodes, 
  edges[, .(indeg_c = sum(cash, na.rm = T)), by = "to"],
  by.x = "name", by.y = "to", all.x = T)
for(tar in c("outdeg_s", "outdeg_c", "indeg_s", "indeg_c")) {
  nodes[is.na(get(tar)), (tar) := 0]
}


centralities <- names(nodes)[grep("deg|eigen|hub|aut|btw", names(nodes))]

tbl <- do.call(rbind,
               lapply(centralities, function(i) c(summary(nodes[, get(i)]))))
tbl <- t(tbl)
colnames(tbl) <- centralities
tbl <- as.data.table(tbl)
# tbl[, (centralities) := round(.SD, 2), .SDcols = centralities]
# rownames(tbl) <-  c("min", "25", "50", "mean", "75", "max")
# if(nrow(tbl) == 7) rownames(tbl) <- c(rownames(tbl), "NA")

options(scipen = 0)
fwrite(tbl, 
       paste0("output_hpcc/centrality/centralities_", yr, ".csv"), 
       row.names = T)

print(xtable(tbl, 
             caption = paste0("Centralities summary of ", yr),
             label = paste0("tbl:cent-sum-", yr),
), file = paste0("output_hpcc/centrality/centralities_", yr, ".tex"))

ret_cols <- c("corp_name", "org_encode", centralities)
fwrite(nodes[,..ret_cols], paste0("output_hpcc/centrality/nodes_", yr, ".csv"))

