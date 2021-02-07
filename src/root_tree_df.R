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
# batch_tree <- 10
# batch_size <- 1000*batch_tree
# group_size <- 1000
# roots <- readRDS(paste0("../output/roots_", opt$year, ".RDS"))
# g <- readRDS(paste0("../output/g_lar_", opt$year, ".RDS"))
# nodes_name <- readRDS(paste0("../output/nodes_name_", opt$year, ".RDS"))

# bfs tree matrix
# tar_roots <- roots[((opt$batch-1)*batch_size+1):min(opt$batch*batch_size, length(roots))]
# tar_roots <- roots[((opt$igr-1)*group_size+1):min((opt$igr-1)*group_size+group_size, length(roots))]
# g <- g[which(rownames(g[]) %in% tar_roots)]

m <- lapply(1:298, function(t) {
  print(t); readRDS(paste0("../output_hpcc/tree_weights_", opt$year, "_", t, ".RDS"))
})

m <- rbindlist(m)

# for(gr in ((opt$batch-1)*batch_tree+1) : min(298, opt$batch*batch_tree) ) {
#   print(gr)
#   opt$igr <- gr
#   tree <- readRDS(paste0("../output_hpcc/tree_", opt$year, "_", opt$igr, ".RDS"))
#   
#   i = (unlist(sapply(tree, function(x) rep(names(x)[x==0], length(x)-1))))
#   j = (unlist(sapply(tree, function(x) names(x)[x!=0] )))
#   
#   g[match(i, rownames(g)), match(j, colnames(g)) ] <- 1
# }

# saveRDS(m, paste0("../output_hpcc/tree_mat_", opt$year, "_", opt$batch, ".RDS"))

saveRDS(m, paste0("../output_hpcc/tree_df_", opt$year, ".RDS"))

