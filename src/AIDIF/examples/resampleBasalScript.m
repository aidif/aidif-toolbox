% this is just an example for basal rate resampling

%create some basal rates in time table format
%timestamps = datetime("today")+minutes(2):minutes(30):start+hours(2);
timestamps = datetime("today")+seconds([-150, 150])
basal_rates = ones(size(timestamps));% basal_rates(1:2:length(basal_rates))=0;
basal_rates = timetable(timestamps', basal_rates', 'VariableNames', {'basal_rate'});

%resample
tt_resampled = AIDIF.interpolateBasal(basal_rates)

%draw
clf; 
stairs(basal_rates.Properties.RowTimes, basal_rates.basal_rate); 
hold on; 
scatter(basal_rates.Properties.RowTimes, basal_rates.basal_rate, 'filled','o','MarkerFaceColor','blue');
% Identify NaN values in the basal rate

% Scatter plot NaN values in red
yyaxis right; 
nan_indices = isnan(tt_resampled.InsulinDelivery);
stem(tt_resampled, 'dti', 'InsulinDelivery'); 
scatter(tt_resampled.dti(nan_indices), zeros(sum(nan_indices),1), 'filled', 'x', 'MarkerEdgeColor', 'red');
hold off;
