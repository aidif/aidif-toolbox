function [dti, U]=interpolateBasal(datetime, basal_rate)
%[dti, U]=interpolateBasal(dt,br)
% dt  - datetime datenum (days since January 0, 0000, i.e. 739707.3045)
% br  - basal rate (U/hr)
% dti - datetime datenum interpolated (5 minute intervals, aligned to % midnight)
% U   - amount delivered in 5 minute interval (U)

delivery=[0; cumsum(diff(dt).*br(1:end-1),"omitmissing")];
dti=(ceil(min(dt)*24*60/5):floor(max(dt)*24*60/5))'/(24*60/5);
deliveryi=interp1(dt,delivery,dti,"linear");
U=diff(deliveryi)*24;
U=[U;0];
