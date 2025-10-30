## Resampling Standard and Extended Boluses
This notebooks illustrates how we can resample boluses to a regular 5 minute grid aligned to the full hour. It also shows that we can reuse the interpolate Basal logic by treating extended boluses as rates.
### Create some bolus data
datetimes = datetime("today")+minutes([4,59, 92.5])';
bolus = [1,1,10]';
duration = [seconds(0), seconds(0),hours(1)]';
ttBolus = timetable(datetimes,bolus,duration);
ttBolus.Properties.DimensionNames{'datetimes'} = 'Time'
%%
### Standard boluses
ttStandard = ttBolus(ttBolus.duration==seconds(0),'bolus');
ttStandard.Properties.VariableNames{'bolus'} = 'InsulinDelivery';
ttStandard.Time = AIDIF.roundTo5Minutes(ttStandard.Time, 'closest')
%other ways
%interp1 doesn't work requires at least two samples, use retime instead
%ttStandard = interp1(ttStandard.Time,ttStandard.bolus,datetimeResampled,"nearest")
%ttStandardResampled = retime(ttStandard,newTimes,'fillwithconstant','Constant',0);
%%
### Convert Extended to fake basal rates
ttExtended = ttBolus(ttBolus.duration>0,:);
ttExtended.rate = ttExtended.bolus./hours(ttExtended.duration);

%stop rate after duration
ttBasalFake = ttExtended(:,'rate');
zeroRates = timetable(ttExtended.Properties.RowTimes + ttExtended.duration, ...
                      zeros(height(ttExtended),1), 'VariableNames', {'rate'});
ttBasalFake = sortrows([ttBasalFake; zeroRates]);

%convert to basal rate format
ttBasalFake.Properties.VariableNames{'rate'} = 'basal_rate';
%resample using interpolate Basal
ttExtendedResampled = AIDIF.interpolateBasal(ttBasalFake)
%%
### Combine
newTimes = (AIDIF.roundTo5Minutes(ttBolus.Time(1),'start'):minutes(5):AIDIF.roundTo5Minutes(ttBolus.Time(end)+ttBolus.duration(end),'end'))';
ttCombined = [ttStandard;ttExtendedResampled];

retime(ttCombined,newTimes,"sum")
### Draw results
clf; hold on;

%draw bolus rates
yyaxis('right'); ylabel('U/hr');
[xs, ys] = stairs(ttBasalFake.Time, ttBasalFake.basal_rate);
area(xs ,ys ,'FaceAlpha', 0.3, 'EdgeColor', 'none','FaceColor','blue',DisplayName='Bolus Rate');
ylim([0,max(ttBolus.bolus)+1]);

%draw deliveries
yyaxis('left'); ylabel('U')
%boluses
stem(ttBolus.Properties.RowTimes,ttBolus.bolus,"filled","-","Marker","^",DisplayName='Bolus',Color='blue');
%resampled deliveries
stem(ttCombined,"Time","InsulinDelivery",Color='red',Marker='.',MarkerSize=10,DisplayName='5 minute deliveries')
xlim([ttBolus.Properties.RowTimes(1)-minutes(10), ttBolus.Properties.RowTimes(end)+ttBolus.duration(end)+minutes(10)])
legend(); hold('off')
