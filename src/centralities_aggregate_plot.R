
ret_list <- NULL
ctr <- 1

for(year in 1999:2018) {
  ret <- fread(paste0("output/centrality/centralities_", year, ".csv"))
  
  ret[, msr := c("min", "1st", "med", "mean", "3rd", "max", "NA")]
  ret[, year := year]
  ret_list[[ctr]] <- ret
  ctr <- ctr + 1
}


ret <- rbindlist(ret_list)

cents <- c(
  "outdeg" = "Out-degree",
  "indeg" = "In-degree",
  "deg" = "Degree",
  "btw" = "Betweenness",
  "eigen_undir" = "Eigenvector",
  "hub" = "Hub",
  "authority"  = "Authority"
)

# ret[, .(outdeg, indeg, deg, btw, eigen_undir, hub, authority, year)] %>% 
ret[msr == "min"] %>%
  melt(id.vars=c("year", "msr", "V1")) %>%
  ggplot(aes(x=year, y=value, color=variable)) +
  geom_point(size=2) +
  geom_line(size=1) +
  facet_wrap(~variable, scales = "free_y") +
  # facet_wrap(~variable, scales = "free_y", strip.position = "right", 
  #            ncol = 1, labeller = as_labeller(cents)) + 
  ggtitle("Mean Centralities") +
  xlab("Year") + ylab("") +
  scale_x_continuous(labels=seq(1999, 2017), breaks=seq(1999,2017)) + 
  ylab("Centrality") +
  guides(col=guide_legend(ncol=1)) +
  theme_bw() +
  theme(legend.position = "none")
