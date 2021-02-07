pacman::p_load(data.table, igraph, optparse, Matrix)

# parse option
option_list = list(
  make_option(c("-i", "--igr"), type="integer", default="1", 
              help="i-th group of roots [default= %default]", metavar="number"),
  make_option(c("-y", "--year"), type="integer", default="1", 
              help="year [default= %default]", metavar="number")
); 

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

# setup
group_size <- 1000
roots <- readRDS(paste0("../output/roots_", opt$year, ".RDS"))
g <- readRDS(paste0("../output/g_lar_", opt$year, ".RDS"))
edges <- as_data_frame(g, "edges")
setDT(edges)

tar_roots <- roots[((opt$igr-1)*group_size+1):min((opt$igr-1)*group_size+group_size, length(roots))]

# bfs trees
# bfs_lar <- lapply(tar_roots, function(r) {
#   dist <- bfs(g, V(g)[V(g)$name == r], neimode = "out", unreachable = F, dist = T)$dist;
#   dist <- dist[!is.na(dist)]
# })

ret <- NULL
for(i in seq_along(tar_roots)) {
  print(i)
  r <- tar_roots[i]
  step <- 1
  es <- edges[from == r]
  if(nrow(es) == 0) next
  es[is.na(weight), weight := 1]
  es <- es[,.(root = from, desc = to, weight = weight, x = step, ctrl = (weight >= .5))]
  rret <- es
  
  es_nxt <- merge(es, edges, by.x="desc", by.y="from")
  es_nxt <- es_nxt[!(to %in% rret$desc)]
  while(nrow(es_nxt)!=0) {
    step <- step + 1
    es_nxt[is.na(weight.y), weight.y := 1]
    es_nxt <- es_nxt[,.(root = root, desc = to, 
                        weight = weight.x * weight.y,
                        x = step, ctrl = (ctrl & weight.y >= .5))]
    rret <- rbind(rret, es_nxt)
    es_nxt <- merge(es_nxt, edges, by.x="desc", by.y="from")
    es_nxt <- es_nxt[!(to %in% rret$desc)]
  }
  ret[[i]] <- rret
}

ret <- rbindlist(ret)

saveRDS(ret, paste0("../output_hpcc/tree_weights_", opt$year, "_", opt$igr, ".RDS"))

# distances(make_star(10, "out"))

