# Plot the results from the fixed effects produced by different optimizers. This function 
# takes the output from lme4::allFit(), tidies it, selects fixed effects and plots them.

plot.fixef.allFit = function(allFit_output, 
                             # Set the same Y axis limits in every plot
                             shared_y_axis_limits = TRUE,
                             # Multiply Y axis limits by a factor (only 
                             # available if shared_y_axis_limits = TRUE)
                             multiply_y_axis_limits = 1, 
                             # Number of decimal places
                             decimal_places = NULL,
                             # Select predictors
                             select_predictors = NULL, 
                             # Number of rows
                             nrow = NULL, 
                             # Y axis title
                             y_title = 'Fixed effect',
                             # Alignment of the Y axis title
                             y_title_hjust = NULL,
                             # Add number to the names of optimizers
                             number_optimizers = TRUE,
                             # Replace colon in interactions with x
                             interaction_symbol_x = TRUE) {
  
  require(lme4)
  require(dfoptim)
  require(optimx)
  require(dplyr)
  require(reshape2)
  require(stringr)
  require(scales)
  require(ggplot2)
  require(ggtext)
  require(patchwork)
  library(Cairo)
  
  # Tidy allFit output
  
  # Extract fixed effects from the allFit() output
  allFit_fixef = summary(allFit_output)$fixef %>%  # Select fixed effects in the allFit results
    reshape2::melt() %>%  # Structure the output as a data frame
    rename('Optimizer' = 'Var1', 'fixed_effect' = 'Var2')  # set informative names
  
  # If number_optimizers = TRUE, assign number to each optimizer and place it before its name
  if(number_optimizers == TRUE) {
    allFit_fixef$Optimizer = paste0(as.numeric(allFit_fixef$Optimizer), '. ', allFit_fixef$Optimizer)
  }
  
  # If select_predictors was supplied, select them along with the intercept (the latter required)
  if(!is.null(select_predictors)) {
    allFit_fixef = allFit_fixef %>% dplyr::filter(fixed_effect %in% c('(Intercept)', select_predictors))
  }
  
  # Order variables
  allFit_fixef = allFit_fixef[, c('Optimizer', 'fixed_effect', 'value')]
  
  # PLOT. The overall plot is formed of a first row containing the intercept and the legend 
  # (intercept_plot), and a second row containing the predictors (predictors_plot), 
  # which may in turn occupy several rows.
  
  # If multiply_y_axis_limits was supplied but shared_y_axis_limits = FALSE,
  # warn that shared_y_axis_limits is required.
  if(!multiply_y_axis_limits == 1 & shared_y_axis_limits == FALSE) {
    message('The argument `multiply_y_axis_limits` has not been used because \n it requires `shared_y_axis_limits` set to TRUE.')
  }
  
  # If extreme values were entered in y_title_hjust, show warning
  if(!is.null(y_title_hjust)) {
    if(y_title_hjust < 0.5 | y_title_hjust > 6) {
      message('NOTE: For y_title_hjust, a working range of values is between 0.6 and 6.')
    }
  }
  
  # If decimal_places was supplied, convert number to the format used in 'scales' package
  if(!is.null(decimal_places)) {
    decimal_places = 
      ifelse(decimal_places == 1, 0.1, 
             ifelse(decimal_places == 2, 0.01, 
                    ifelse(decimal_places == 3, 0.001, 
                           ifelse(decimal_places == 4, 0.0001, 
                                  ifelse(decimal_places == 5, 0.00001, 
                                         ifelse(decimal_places == 6, 0.000001, 
                                                ifelse(decimal_places == 7, 0.0000001, 
                                                       ifelse(decimal_places == 8, 0.00000001, 
                                                              ifelse(decimal_places == 9, 0.000000001, 
                                                                     ifelse(decimal_places == 10, 0.0000000001,
                                                                            ifelse(decimal_places == 11, 0.00000000001,
                                                                                   ifelse(decimal_places == 12, 0.000000000001,
                                                                                          ifelse(decimal_places == 13, 0.0000000000001,
                                                                                                 ifelse(decimal_places == 14, 0.00000000000001,
                                                                                                        ifelse(decimal_places >= 15, 0.000000000000001, 
                                                                                                               0.001
                                                                                                        )))))))))))))))
  }
  
  # First row: intercept_plot
  
  # Select intercept data only
  intercept = allFit_fixef %>% dplyr::filter(fixed_effect == '(Intercept)')
  
  intercept_plot = intercept %>%
    ggplot(., aes(fixed_effect, value, colour = Optimizer)) +
    geom_point(position = position_dodge(1)) +
    facet_wrap(~fixed_effect, scale = 'free') +
    guides(colour = guide_legend(title.position = 'left')) +
    theme_bw() + 
    theme(axis.title = element_blank(), axis.ticks.x = element_blank(),
          axis.text.x = element_blank(), 
          strip.text = element_text(size = 10, margin = margin(t = 4, b = 6)),
          strip.background = element_rect(fill = 'grey96'),
          legend.margin = margin(0.3, 0, 0.8, 1, 'cm'), 
          legend.title = element_text(size = unit(15, 'pt'), angle = 90, hjust = 0.5))
  
  # Second row: predictors_plot
  
  # Select all predictors except intercept
  predictors = allFit_fixef %>% dplyr::filter(!fixed_effect == '(Intercept)')
  
  # If interaction_symbol_x = TRUE (default), replace colon with times symbol x between spaces
  if(interaction_symbol_x == TRUE) {
    # Replace colon in interactions with \u00D7, i.e., x; then set factor class
    predictors$fixed_effect = predictors$fixed_effect %>% 
      str_replace_all(':', ' \u00D7 ') %>% factor()
  }
  
  # Order predictors as in the original output from lme4::allFit()
  predictors$fixed_effect = factor(predictors$fixed_effect, 
                                   levels = unique(predictors$fixed_effect))
  
  # Set number of rows for the predictors excluding the intercept.
  # First, if nrow argument supplied, use it
  if(!is.null(nrow)) {
    predictors_plot_nrow = nrow - 1  # Subtract 1 as intercept row not considered
    
    # Else, if nrow argument not supplied, calculate sensible number of rows: i.e., divide number of
    # predictors (exc. intercept) by 2 and round up the result. For instance, 7 predictors --> 3 rows
  } else predictors_plot_nrow = (length(unique(predictors$fixed_effect)) / 2) %>% ceiling()
  
  predictors_plot = ggplot(predictors, aes(fixed_effect, value, colour = Optimizer)) +
    geom_point(position = position_dodge(1)) +
    facet_wrap(~fixed_effect, scale = 'free',
               # Note that predictors_plot_nrow was defined a few lines above
               nrow = predictors_plot_nrow, 
               # Wrap names of predictors with more than 54 characters into new lines
               labeller = labeller(fixed_effect = label_wrap_gen(width = 55))) +
    labs(y = y_title) +
    theme_bw() + 
    theme(axis.title.x = element_blank(), axis.text.x = element_blank(),
          axis.ticks.x = element_blank(),
          axis.title.y = ggtext::element_markdown(size = 14, margin = margin(0, 15, 0, 0)),
          strip.text = element_text(size = 10, margin = margin(t = 4, b = 6)),
          strip.background = element_rect(fill = 'grey96'), legend.position = 'none')
  
  # Below, the function scale_y_continuous is applied conditionally to avoid overriding settings. First, 
  # if shared_y_axis_limits = TRUE and decimal_places was supplied, set the same Y axis limits in 
  # every plot and set decimal_places. By default, also expand limits by a seventh of its original 
  # limit, and allow further multiplication of limits through multiply_y_axis_limits.
  if(shared_y_axis_limits == TRUE & !is.null(decimal_places)) {
    
    intercept_plot = intercept_plot +
      scale_y_continuous(limits = c(min(allFit_fixef$value) - allFit_fixef$value %>% abs %>% 
                                      max / 7 * multiply_y_axis_limits,
                                    max(allFit_fixef$value) + allFit_fixef$value %>% abs %>% 
                                      max / 7 * multiply_y_axis_limits), 
                         # Set number of decimal places
                         labels = scales::label_number(accuracy = decimal_places))
    
    predictors_plot = predictors_plot + 
      scale_y_continuous(limits = c(min(allFit_fixef$value) - allFit_fixef$value %>% abs %>% 
                                      max / 7 * multiply_y_axis_limits,
                                    max(allFit_fixef$value) + allFit_fixef$value %>% abs %>% 
                                      max / 7 * multiply_y_axis_limits), 
                         # Set number of decimal places
                         labels = scales::label_number(accuracy = decimal_places))
    
    # Else, if shared_y_axis_limits = TRUE but decimal_places were not supplied, do as above but without
    # setting decimal_places.
  } else if(shared_y_axis_limits == TRUE & is.null(decimal_places)) {
    
    intercept_plot = intercept_plot +
      scale_y_continuous(limits = c(min(allFit_fixef$value) - allFit_fixef$value %>% abs %>% 
                                      max / 7 * multiply_y_axis_limits,
                                    max(allFit_fixef$value) + allFit_fixef$value %>% abs %>% 
                                      max / 7 * multiply_y_axis_limits),
                         # Set number of decimal places
                         labels = scales::label_number(accuracy = decimal_places))
    
    predictors_plot = predictors_plot + 
      scale_y_continuous(limits = c(min(allFit_fixef$value) - allFit_fixef$value %>% abs %>% 
                                      max / 7 * multiply_y_axis_limits,
                                    max(allFit_fixef$value) + allFit_fixef$value %>% abs %>% 
                                      max / 7 * multiply_y_axis_limits),
                         # Set number of decimal places
                         labels = scales::label_number(accuracy = decimal_places))
    
    # Else, if shared_y_axis_limits = FALSE and decimal_places was supplied, set decimal_places. 
  } else if(shared_y_axis_limits == FALSE & !is.null(decimal_places)) {
    
    # Set number of decimal places in both plots
    intercept_plot = intercept_plot +
      scale_y_continuous(labels = scales::label_number(accuracy = decimal_places))
    
    predictors_plot = predictors_plot +
      scale_y_continuous(labels = scales::label_number(accuracy = decimal_places))
  }
  
  # Plot matrix: based on number of predictors_plot_nrow, adjust height of Y axis title
  # (unless supplied), and assign space to intercept_plot and predictors_plot
  if(predictors_plot_nrow == 1) {
    
    # If y_title_hjust supplied, use it
    if(!is.null(y_title_hjust)) {
      predictors_plot = predictors_plot + 
        theme(axis.title.y = ggtext::element_markdown(hjust = y_title_hjust))
      # Otherwise, set a sensible height
    } else predictors_plot = predictors_plot + 
        theme(axis.title.y = ggtext::element_markdown(hjust = 3.6))
    
    layout = c(
      patchwork::area(t = 1.5, r = 8.9, b = 6.8, l = 0),  # intercept row
      patchwork::area(t = 7.3, r = 9, b = 11, l = 0)      # predictors row(s)
    )
    
  } else if(predictors_plot_nrow == 2) {
    
    # If y_title_hjust supplied, use it
    if(!is.null(y_title_hjust)) {
      predictors_plot = predictors_plot + 
        theme(axis.title.y = ggtext::element_markdown(hjust = y_title_hjust))
      # Otherwise, set a sensible height
    } else predictors_plot = predictors_plot + 
        theme(axis.title.y = ggtext::element_markdown(hjust = 1.4))
    
    layout = c(
      patchwork::area(t = 1.5, r = 8.9, b = 6.8, l = 0),  # intercept row
      patchwork::area(t = 7.3, r = 9, b = 16, l = 0)      # predictors row(s)
    )
    
  } else if(predictors_plot_nrow == 3) {
    
    # If y_title_hjust supplied, use it
    if(!is.null(y_title_hjust)) {
      predictors_plot = predictors_plot + 
        theme(axis.title.y = ggtext::element_markdown(hjust = y_title_hjust))
      # Otherwise, set a sensible height
    } else predictors_plot = predictors_plot + 
        theme(axis.title.y = ggtext::element_markdown(hjust = 0.92))
    
    layout = c(
      patchwork::area(t = 1.5, r = 8.9, b = 6.8, l = 0),  # intercept row
      patchwork::area(t = 7.3, r = 9, b = 21, l = 0)      # predictors row(s)
    )
    
  } else if(predictors_plot_nrow == 4) {
    
    # If y_title_hjust supplied, use it
    if(!is.null(y_title_hjust)) {
      predictors_plot = predictors_plot + 
        theme(axis.title.y = ggtext::element_markdown(hjust = y_title_hjust))
      # Otherwise, set a sensible height
    } else predictors_plot = predictors_plot + 
        theme(axis.title.y = ggtext::element_markdown(hjust = 0.8))
    
    layout = c(
      patchwork::area(t = 1.5, r = 8.9, b = 6.8, l = 0),  # intercept row
      patchwork::area(t = 7.3, r = 9, b = 26, l = 0)      # predictors row(s)
    )
    
  } else if(predictors_plot_nrow == 5) {
    
    # If y_title_hjust supplied, use it
    if(!is.null(y_title_hjust)) {
      predictors_plot = predictors_plot + 
        theme(axis.title.y = ggtext::element_markdown(hjust = y_title_hjust))
      # Otherwise, set a sensible height
    } else predictors_plot = predictors_plot + 
        theme(axis.title.y = ggtext::element_markdown(hjust = 0.73))
    
    layout = c(
      patchwork::area(t = 1.5, r = 8.9, b = 6.8, l = 0),  # intercept row
      patchwork::area(t = 7.3, r = 9, b = 31, l = 0)      # predictors row(s)
    )
    
  } else if(predictors_plot_nrow > 5) {
    
    # If y_title_hjust supplied, use it
    if(!is.null(y_title_hjust)) {
      predictors_plot = predictors_plot + 
        theme(axis.title.y = ggtext::element_markdown(hjust = y_title_hjust))
      # Otherwise, set a sensible height
    } else predictors_plot = predictors_plot + 
        theme(axis.title.y = ggtext::element_markdown(hjust = 0.65))
    
    layout = c(
      patchwork::area(t = 1.5, r = 8.9, b = 6.8, l = 0),  # intercept row
      patchwork::area(t = 7.3, r = 9, b = 36, l = 0)      # predictors row(s)
    )
    
    # Also, advise user to consider distributing predictors into several plots
    message('  Many rows! Consider distributing predictors into several plots \n  using argument `select_predictors`')
  } 
  
  # Add margin
  predictors_plot = predictors_plot + theme(plot.margin = margin(15, 15, 15, 15))
  
  # Return matrix of plots
  wrap_plots(intercept_plot, predictors_plot, design = layout,
             # The 2 below corresponds to intercept_plot and predictors_plot
             nrow = 2)
}
