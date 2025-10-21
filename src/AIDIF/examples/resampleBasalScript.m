% this is just an example for basal rate resampling

%% single sample
start = datetime('today')
timestamps = datetime("today")
basal_rates = 1
basal_rates = timetable(timestamps', basal_rates', 'VariableNames', {'basal_rate'});

%% perfectly aligned (0 to 1)
start = datetime('today')
timestamps = datetime("today"):minutes(30):start+hours(2);
basal_rates = ones(size(timestamps)); basal_rates(1:2:length(basal_rates))=0;
basal_rates = timetable(timestamps', basal_rates', 'VariableNames', {'basal_rate'});

%% perfectly aligned (only one)
start = datetime('today')
timestamps = datetime("today"):minutes(5):start+minutes(15);
basal_rates = ones(size(timestamps)); %basal_rates(1:2:length(basal_rates))=0;
basal_rates = timetable(timestamps', basal_rates', 'VariableNames', {'basal_rate'});

%% not perfectly aligned  (only 1)
timestamps = datetime("today") + [minutes(2),minutes(60)]
basal_rates = [1,0]
basal_rates = timetable(timestamps', basal_rates', 'VariableNames', {'basal_rate'});

%% not perfectly aligned  (two within 5 minutes)
timestamps = datetime("today") + [minutes(2),minutes(4)]
basal_rates = [1,0]
basal_rates = timetable(timestamps', basal_rates', 'VariableNames', {'basal_rate'});


%% not perfectly aligned  (start 0)
timestamps = datetime("today")+minutes(1):minutes(30):start+hours(2);
basal_rates = ones(size(timestamps));basal_rates(1:2:length(basal_rates))=0;
basal_rates = timetable(timestamps', basal_rates', 'VariableNames', {'basal_rate'});


%% not perfectly aligned  (start 1)
timestamps = datetime("today")+minutes(4):minutes(30):start+hours(2);
basal_rates = ones(size(timestamps));basal_rates(2:2:length(basal_rates))=0;
basal_rates = timetable(timestamps', basal_rates', 'VariableNames', {'basal_rate'});
%TODO: The first resampled value of unaligned values is always NaN. This
%only shows effect when first basal rate is not zero


%% RESAMPLE
%resample
tt_resampled = AIDIF.interpolateBasal(basal_rates)

%draw
clf; 
hold on; 
%area(basal_rates.Properties.RowTimes, basal_rates.basal_rate,"FaceColor","blue","FaceAlpha",0.5) 
[xs, ys] = stairs(basal_rates.Properties.RowTimes, basal_rates.basal_rate);
area(xs ,ys ,'FaceAlpha', 0.3, 'EdgeColor', 'none');

scatter(basal_rates.Properties.RowTimes, basal_rates.basal_rate,"o","MarkerFaceColor","blue"); 

scatter(basal_rates.Properties.RowTimes, basal_rates.basal_rate, 'filled','o','MarkerFaceColor','blue');
ylim([0,1.2])
% Expand xlim by 5 minutes left and right
xlim([min(tt_resampled.Properties.RowTimes) - minutes(10), max(tt_resampled.Properties.RowTimes) + minutes(10)]);
% make 5 minute grid
xticks(tt_resampled.Properties.RowTimes);
grid('on')

% Identify NaN values in the basal rate

% Scatter plot NaN values in red
yyaxis right; 
nan_indices = isnan(tt_resampled.InsulinDelivery);
stem(tt_resampled, 'Time', 'InsulinDelivery','Color','red'); 
scatter(tt_resampled.Time(nan_indices), zeros(sum(nan_indices),1), 'filled', 'x', 'MarkerEdgeColor', 'red');
ylim([0,5/60 *1.2])
hold off;

%%
clf
%area(basal_rates.Properties.RowTimes, basal_rates.basal_rate,"FaceColor","blue","FaceAlpha",0.5) 
[xs, ys] = stairs(basal_rates.Properties.RowTimes, basal_rates.basal_rate);
area(xs ,ys ,'FaceAlpha', 0.3, 'EdgeColor', 'none');