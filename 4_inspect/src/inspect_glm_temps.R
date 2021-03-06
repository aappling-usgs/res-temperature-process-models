
# tar_load(c('p1_ltmp_temps.rds','p2_reservoir_ids','p2_meteo','p2_nml_objects','p3_glm','p1_io_res_io_obs.feather'))
# sim_dir <- '3_run/out/no_io'
# res_id <- p2_reservoir_ids[2]
# out_dir <- '4_inspect/out'

# Plot temperature predictions - heat map for all depths, with reservoir observations for comparison
plot_temps_all_depths <- function(sim_dir, nml_obj, plot_id, out_dir) {
  out_file <- file.path(out_dir, sprintf('temps_all_depths_%s.png', plot_id))
  glmtools::plot_temp(
    locate_out_files(sim_dir, nml_obj, file_type='depthwise'),
    reference = 'surface',
    fig_path = out_file,
    width=1100, height=400, res=150, units='px')
  return(out_file)
}

# Compute RMSE of reservoir pred vs obs temperatures


# Plot temperature predictions - time series for the three depth monitoring categories
plot_temps_sensor_depths <- function(sim_dir, nml_obj, obs_temps_rds, res_id, plot_id, out_dir) {

  # Compare predictions to observations on specific dates and times
  all_res_obs <- read_rds(obs_temps_rds)
  res_obs <- all_res_obs %>%
    filter(site_id == res_id) %>%
    select(datetime = date, depth, temp)
  obs_tsv <- tempfile(fileext = '.tsv')
  write_tsv(res_obs, obs_tsv)
  nc_file <- locate_out_files(sim_dir, nml_obj, file_type='depthwise')
  temp_matchups <- resample_to_field(
    nc_file,
    obs_tsv,
    var_name = 'temp') %>%
    group_by(DateTime) %>%
    mutate(DepthRank = ordered(3 - length(Depth) + order(Depth), levels=1:3)) %>% # 1,2,3 when n=3; 2,3 otherwise (because the first depth category is the one that gets cut off when water levels drop)
    ungroup()

  # Plot preds and obs
  temp_matchups %>%
    ggplot(aes(x=DateTime, color=DepthRank)) +
    geom_point(aes(y=Observed_temp)) +
    geom_line(aes(y=Modeled_temp), size=1) +
    scale_color_manual(values=RColorBrewer::brewer.pal(3, "Set2")) +
    theme_classic() +
    xlab('Date') +
    ylab('Temperature (deg C)') +
    xlim(as.POSIXct('2019-08-01'), as.POSIXct('2021-01-01')) +
    ylim(0, 28) +
    ggtitle(sprintf('Preds (lines) and obs (points) for %s (%s)', names(res_id), res_id))

  # Save the plot
  out_file <- file.path(out_dir, sprintf('temps_sensor_depths_%s.png', plot_id))
  ggsave(out_file)
  return(out_file)
}

# Compute RMSE by depth category

# Plot temperature predictions - time series for ~three constant depths

# Plot temperature predictions - time series for the outlet depths
plot_temps_outlet_depths <- function(sim_dir, nml_obj, plot_id, out_dir) {
}

# Compute expected total flow and temperature for the combined outflows
# Plot outflow temperature predictions and observations
# Compute RMSEs of outflow pred vs obs for temperature




# analyze_res <- function(
#   model_log = p3_glm,
#   sim_dir = 'tmp/io',
#   all_io_obs = arrow::read_feather(p1_io_res_io_obs.feather),
#   all_res_obs = read_rds(p1_ltmp_temps.rds),
#   res_id = p2_reservoir_ids[2]) {
#
#   # read the extracted output file (fixed depths)
#   temp_preds <- model_log %>%
#     filter(site_id == !!res_id) %>%
#     pull(export_fl) %>%
#     arrow::read_feather()
#
#   # plot temperatures at a few fixed depths over time
#   preds_long <- temp_preds %>%
#     select(-ice) %>%
#     pivot_longer(names_to='temp_depth', values_to='wtemp', -time) %>%
#     mutate(depth = as.numeric(gsub('temp_', '', temp_depth))) %>%
#     select(-temp_depth)
#   preds_long %>%
#     filter(depth %in% c(0, 10, 40)) %>%
#     mutate(Depth = as.factor(depth)) %>%
#     ggplot(aes(x=time, y=wtemp, color=Depth)) +
#     geom_line() +
#     theme_classic()
#
#   # outflow_obs <-
#   #   preds_long %>% filter(depth %in% c(0, 39)) %>% # 39 is approx cannonsville outflow depth
#
#   # Compare predictions to observations on specific dates and times
#   res_obs <- all_res_obs %>%
#     filter(site_id == res_id) %>%
#     select(datetime = date, depth, temp)
#   obs_tsv <- sprintf('tmp/res_obs_%s.tsv', res_id)
#   write_tsv(obs_data, obs_tsv)
#
#   nc_file <- sprintf(
#     '%s/%s/%s/%s.nc',
#     sim_dir,
#     res_id,
#     get_nml_value(p2_nml_objects[[res_id]], 'out_dir'),
#     get_nml_value(p2_nml_objects[[res_id]], 'out_fn'))
#
#   temp_matchups <- resample_to_field(
#     nc_file,
#     obs_tsv,
#     var_name = 'temp') %>%
#     group_by(DateTime) %>%
#     mutate(DepthRank = ordered(3 - length(Depth) + order(Depth), levels=1:3)) %>% # 1,2,3 when n=3; 2,3 otherwise (because the first depth category is the one that gets cut off when water levels drop)
#     ungroup()
#   temp_matchups %>%
#     #filter(DepthRank == 1) %>%
#     select(-Depth) %>%
#     ggplot(aes(x=DateTime, color=DepthRank)) +
#     geom_point(aes(y=Observed_temp)) +
#     geom_line(aes(y=Modeled_temp), size=1) +
#     scale_color_manual(values=RColorBrewer::brewer.pal(3, "Set2")) +
#     theme_classic() +
#     ylab('Temperature (deg C)') +
#     ggtitle(sprintf('Preds (lines) and obs (points) for %s', res_id))
#   ggsave(sprintf('4_inspect/out/predobsts_%s.png', res_id), width=5, height=5)
#
#   # make plot of temperature predictions for a couple of years
#   png(sprintf('4_inspect/out/preds2D_%s.png', res_id), width=1100, height=400, res=150, units='px')
#   glmtools::plot_temp(sprintf(nc_file, res_id))
#   dev.off()
#
#   # return table of RMSEs
#   rmses <- temp_matchups %>%
#     filter(!is.na(Modeled_temp), !is.na(Observed_temp)) %>%
#     group_by(DepthRank) %>%
#     summarize(
#       n = length(Modeled_temp),
#       MinDepth = min(Depth),
#       MaxDepth = max(Depth),
#       RMSE = sqrt(mean((Modeled_temp - Observed_temp)^2)))
#
#   # plot predicted vs observed lake levels
#   lake_preds <- read_csv(sprintf('tmp/io/%s/out/lake.csv', res_id))
#   ggplot(lake_preds, aes(x=time, y=`Lake Level`)) + geom_line()
#
#   return(rmses)
#
# }
# analyze_res(res_id=p2_reservoir_ids[1])
# # DepthRank     n MinDepth MaxDepth  RMSE
# # <ord>     <int>    <dbl>    <dbl> <dbl>
# # 1            23    0.128     2.02 0.593
# # 2           110    8.39     13.9  3.55
# # 3           110   19.7      25.2  1.32
# analyze_res(res_id=p2_reservoir_ids[2])
# # DepthRank     n MinDepth MaxDepth  RMSE
# # <ord>     <int>    <dbl>    <dbl> <dbl>
# # 2            26     7.47     10.9  1.78
# # 3            31     6.33     27.3  1.74
