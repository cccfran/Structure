pacman::p_load(data.table, igraph, optparse, Matrix)

# parse option
option_list = list(
  make_option(c("-i", "--igr"), type="integer", default="1", 
              help="i-th group of roots [default= %default]", metavar="number"),
  make_option(c("-y", "--year"), type="integer", default="2017", 
              help="year [default= %default]", metavar="number")
); 

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

g <- readRDS(paste0("../output/g_lar_", opt$year, ".RDS"))
cp <- fread(paste0("../output/soe_central_0_", opt$year, ".csv"))

