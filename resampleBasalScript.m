% this is just an example for basal rate resampling

%create some basal rates in time table format
timestamps = datetime("today")+minutes(2):minutes(30):start+hours(2);
basal_rates = ones(size(timestamps)); basal_rates(1:2:length(basal_rates))=0;
basal_rates = timetable(timestamps', basal_rates', 'VariableNames', {'basal_rate'});

%resample
tt_resampled = interpolateBasal(basal_rates);

%draw
clf; 
stairs(basal_rates.Properties.RowTimes, basal_rates.basal_rate); 
hold on; 
scatter(basal_rates.Properties.RowTimes, basal_rates.basal_rate, 'filled','o','MarkerFaceColor','blue');
yyaxis right; 
stem(tt_resampled, 'dti', 'InsulinDelivery'); 
hold off;
