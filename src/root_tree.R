pacman::p_load(data.table, igraph, optparse, Matrix)

# parse option
option_list = list(
  make_option(c("-i", "--igr"), type="integer", default="1", 
              help="i-th group of roots [default= %default]", metavar="number"),
  make_option(c("-g", "--group_size"), type="integer", default="1000", 
              help="i-th group of roots [default= %default]", metavar="number"),
  make_option(c("-y", "--year"), type="integer", default="1999", 
              help="year [default= %default]", metavar="number")
); 

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)
source("../../src/utilities.R")

# setup
group_size <- opt$group_size
roots <- fread(paste0("../output_hpcc/roots_", opt$year, ".csv"))
roots <- roots$root
g <- readRDS(paste0("../../../iFindData/data/g_", opt$year, ".RDS"))
g_lar <- extract_cc(g, 1)

edges <- as_data_frame(g_lar, "edges")
setDT(edges)
edges[, weight:=weight/100]

tar_roots <- roots[((opt$igr-1)*group_size+1):min((opt$igr-1)*group_size+group_size, length(roots))]

# bfs trees
# bfs_lar <- lapply(tar_roots, function(r) {
#   dist <- bfs(g, V(g)[V(g)$name == r], neimode = "out", unreachable = F, dist = T)$dist;
#   dist <- dist[!is.na(dist)]
# })

ret <- vector("list", length(tar_roots))
for(i in seq_along(tar_roots)) {
  if(i %% 100 == 0 ) print(i)
  r <- tar_roots[i]
  step <- 1
  es <- edges[from == r]
  if(nrow(es) == 0) next
  es[is.na(weight), weight := 1]
  es <- es[,.(root = from, desc = to, weight, step = step, ctrl = (weight >= .5))]
  rret <- es
  
  es_nxt <- merge(es, edges, by.x="desc", by.y="from")
  es_nxt <- es_nxt[!(to %in% rret$desc)]
  while(nrow(es_nxt)!=0) {
    step <- step + 1
    es_nxt[is.na(weight.y), weight.y := 1]
    es_nxt[, step := NULL]
    es_nxt <- es_nxt[,.(root = root, desc = to, 
                        weight = weight.x * weight.y,
                        step = step, ctrl = (ctrl & weight.y >= .5))]
    rret <- rbind(rret, es_nxt)
    es_nxt <- merge(es_nxt, edges, by.x="desc", by.y="from")
    es_nxt <- es_nxt[!(to %in% rret$desc)]
  }
  ret[[i]] <- rret
}

ret <- rbindlist(ret)

fwrite(ret, paste0("../output_hpcc/tree/", opt$year, "_", opt$igr, ".csv"))

# distances(make_star(10, "out"))

