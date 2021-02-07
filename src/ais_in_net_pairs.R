pacman::p_load(data.table, optparse, igraph)

# parse option
option_list = list(
  make_option(c("-i", "--i"), type="integer", default="1", 
              help="i-th sim [default= %default]", metavar="number"),
  make_option(c("-n", "--n"), type="integer", default="100", 
              help="i-th sim [default= %default]", metavar="number"),
  make_option(c("-y", "--year"), type="integer", default="1", 
              help="year [default= %default]", metavar="number")
); 

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

roots <- readRDS("../output/ais_in_net_tree_roots_2012.RDS")
# roots <- readRDS("../output/roots_left.RDS")
tree <- fread("../output/ais_in_net_tree_2012.csv")
g <- readRDS("../output/g_lar_2012.RDS")

root <- roots[(1+(opt$i-1)*opt$n):min(length(roots), (opt$i-1)*opt$n + opt$n)]
tree <- tree[roots %in% root]
tree[, new_entid:=as.character(new_entid)]
sub <- tree[, as.data.table(t(combn(new_entid, 2))), .(roots)]
# sub <- merge(sub, tree[,!c("roots")], by.x = "V1", by.y = "new_entid", all.x = T)
# sub <- merge(sub, tree[,!c("roots")], by.x = "V2", by.y = "new_entid", all.x = T)

dist_1 <- shortest.paths(g, V(g)[V(g)$name %in% sub$V1], V(g)[V(g)$name %in% sub$V2],
                  mode = "out", 
                  weights = NA)

dist_1_df <- data.table(from = rownames(dist_1), dist_1)
dist_1_df <- melt(dist_1_df, id.vars = "from", variable.name = "to", value.name = "distance")
dist_1_df <- dist_1_df[!is.infinite(distance) & distance != 0]

dist_2 <- shortest.paths(g,V(g)[V(g)$name %in% sub$V2], V(g)[V(g)$name %in% sub$V1], 
                      mode = "out", 
                      weights = NA)

dist_2_df <- data.table(from = rownames(dist_2), dist_2)
dist_2_df <- melt(dist_2_df, id.vars = "from", variable.name = "to", value.name = "distance")
dist_2_df <- dist_2_df[!is.infinite(distance) & distance != 0]

dist_df <- rbind(dist_1_df, dist_2_df)

# weighted
dist_1 <- shortest.paths(g, V(g)[V(g)$name %in% sub$V1], V(g)[V(g)$name %in% sub$V2],
                    weights = -log(E(g)$weight),
                    mode = "out")
dist_1_df <- data.table(from = rownames(dist_1), dist_1)
dist_1_df <- melt(dist_1_df, id.vars = "from", variable.name = "to", value.name = "distance_w")
dist_1_df <- dist_1_df[!is.infinite(distance_w) & distance_w != 0]
dist_1_df[, distance_w := exp(-distance_w)]

dist_2 <- shortest.paths(g,V(g)[V(g)$name %in% sub$V2], V(g)[V(g)$name %in% sub$V1], 
                    weights = -log(E(g)$weight),
                    mode = "out")
dist_2_df <- data.table(from = rownames(dist_2), dist_2)
dist_2_df <- melt(dist_2_df, id.vars = "from", variable.name = "to", value.name = "distance_w")
dist_2_df <- dist_2_df[!is.infinite(distance_w) & distance_w != 0]
dist_2_df[, distance_w := exp(-distance_w)]

dist_df_w <- rbind(dist_1_df, dist_2_df)

dist_df <- merge(dist_df, dist_df_w, by = c("from", "to"))
dist_df <- unique(dist_df, by=c("from", "to"))
dist_df <- merge(dist_df, tree[,.(new_entid, growth_asset, TFP)], by.x = "from", by.y = "new_entid", all.x = T)
dist_df <- merge(dist_df, tree[,.(new_entid, growth_asset, TFP)], by.x = "to", by.y = "new_entid", all.x = T)

fwrite(dist_df, paste0("../output_hpcc/ais_in_net_pairs_", opt$year, "i", opt$i, ".csv"))