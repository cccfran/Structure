pacman::p_load(data.table, igraph, optparse)

# parse option
option_list = list(
  make_option(c("-y", "--year"), type="integer", default="2017", 
              help="year [default= %default]", metavar="number")
); 

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

source("../../src/utilities.R")

g <- readRDS(paste0("../../../iFindData/data/g_", opt$year, ".RDS"))
g_lar <- extract_cc(g, 1)

in_deg <- degree(g_lar, mode = "in")
roots <- V(g_lar)$org_encode[in_deg == 0]

fwrite(as.data.table(roots), 
       paste0("../output_hpcc/roots_", opt$year, ".csv"))
