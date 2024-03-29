% for loop in each section is for readability of code in matlab editor
clear;  clc;
close all

load('/home/yunjaeh/github/Bangladesh_measurement/TemperatureWind/Data/MeasurementData.mat','hourly','raw','config');
load('/home/yunjaeh/github/Bangladesh_measurement/WeatherStation/Data/Hazrat2019.mat');

%% calibration

T = hourly.OUT.mean+273.15;
p0 = [1.468e-3, 2.383e-4, 1.007e-7];
alpha = (p0(1)-(1./T))/p0(3);
beta = sqrt( (p0(2)/(3*p0(3)))^3 + (alpha/2).^2);
R_backward = exp((beta-alpha/2).^(1/3) -(beta+alpha/2).^(1/3));

% p1 = [0.00176731574380468,0.000186518641244415,3.85293568627452e-07];
p1 = [0.00171130201084220,0.000198927688551477,3.06170162883606e-07];

T_new = 1./(p1(1) + p1(2) *log(R_backward) + p1(3)*log(R_backward).^3);
figure(); hold on
plot( T-273.15, T_new-273.15, 'b.');
plot(10:50, 10:50, 'k:');
xlabel('Measured T');
ylabel('Calibrated T');

figure(); hold on
plot(Hazrat.Time, Hazrat.TEMP, 'k');
plot(hourly.OUT.time, T-273.15, 'b:');
plot(hourly.OUT.time, T_new-273.15, 'b');

hourly.OUT.mean = T_new-273.15;

%%
% parameters
zMeasurement = 30;
zRef = 10;
zTH = 3;
z0 = 2.0; 

uConv = log((zRef+z0)/z0)/log((zMeasurement+z0)/z0) ;
uConvTH = log((zTH+z0)/z0)/log((zMeasurement+z0)/z0) ;


figure(); hold on
plot(Hazrat_hourly.mean.Time, Hazrat_hourly.mean.WS,'b');
plot(hourly.Wind_FS.time, hourly.Wind_FS.ws.mean,'k');

% plot(hourly.Wind_FS.time, uConv*hourly.Wind_FS.ws.mean,'b:');


plot(hourly.Wind_FS.time, hourly.Wind_FS.ws.mean*uConvTH,'k:');
plot(hourly.Wind_TH.time, hourly.Wind_TH.ws.mean,'r');

% plot(raw.Wind_FS.time, raw.Wind_FS.ws,'k:');
xlim([datetime(2019,2,1,0,00,00),datetime(2019,2,14,0,00,00)])
ylim([0 7]);

legend('Weather station @airport','Measurement: 35 m','Measurement: 35 m -> roof height','Measurement: Roof height');
ylabel('Wind speed [m/s]');


%% outdoor temperature + wind
% daytime data export
uniqueDates = unique(day(hourly.OUT.time));
for i=1:length(uniqueDates)
    uniqueMonth(i) = 2;
    if uniqueDates(i) > 15
        uniqueMonth(i) = 1;
    end
end

TT = timetable(hourly.OUT.time, hourly.OUT.mean, hourly.OUT.std);

outTime = 1:1440';
TEMPERATURE = zeros(1440,3);    TEMPERATURE(:,1) = outTime;
RADIATION = zeros(1440,3);     RADIATION(:,1) = outTime;
WIND = zeros(1440,3);      WIND(:,1) = outTime;


% for i = 1:length(uniqueDates)
for i = 8
    % day
    dd = uniqueDates(i);
    
    % target day 
    idT = (dd == day(hourly.OUT.time));
    idWS = (dd == day(hourly.Wind_FS.time));
    
    timeT = linspace(0,24,length(raw.Temp.out(dd == day(raw.Temp.time))));
    timeWS = linspace(0,24,length(raw.Wind_FS.time(dd == day(raw.Wind_FS.time))));
    
    idStationMn = (dd == day(Hazrat.Time)) & (2 == month(Hazrat.Time));
    idStationHr = (dd == day(Hazrat_hourly.mean.Time)) & (2 == month(Hazrat_hourly.mean.Time))  ;
    timeMnStation = linspace(0,24,length(Hazrat.Time(idStationMn)));
        
    
    TEMPERATURE(:,2) = interp1((0.5:23.5)*60,TT.Var1(idT), outTime,'pchip')+273.15;
    RADIATION(:,2) = interp1((0.5:23.5)*60,Hazrat_hourly.mean.RAD(idStationHr), outTime,'pchip');
    WIND(:,2) = interp1((0.5:23.5)*60,uConv*hourly.Wind_FS.ws.mean(idWS), outTime,'pchip');
    
    TEMPERATURE(:,3) = interp1((0.5:23.5)*60,TT.Var2(idT), outTime,'pchip');
    RADIATION(:,3) = interp1((0.5:23.5)*60,Hazrat_hourly.std.RAD(idStationHr), outTime,'pchip');
    WIND(:,3) = interp1((0.5:23.5)*60,uConv*hourly.Wind_FS.ws.std(idWS), outTime,'pchip');
    
    figure();
    subplot(1,3,1); hold on
    plot(outTime,TEMPERATURE(:,2)+TEMPERATURE(:,3),'b');
    plot(outTime,TEMPERATURE(:,2),'k','linewidth',2);
    plot(outTime,TEMPERATURE(:,2)-TEMPERATURE(:,3),'b');
    subplot(1,3,2); hold on
    plot(outTime,RADIATION(:,2)+RADIATION(:,3),'b');
    plot(outTime,RADIATION(:,2),'k','linewidth',2);
    plot(outTime,RADIATION(:,2)-RADIATION(:,3),'b');
    subplot(1,3,3); hold on
    plot(outTime,WIND(:,2)+WIND(:,3),'b');
    plot(outTime,WIND(:,2),'k','linewidth',2);
    plot(outTime,WIND(:,2)-WIND(:,3),'b');
    
    figure();
    % TEMPERATURE
    subplot(1,3,1); hold on
    % plot raw
    plot(timeT,raw.Temp.out(dd == day(raw.Temp.time)),'r','linewidth',0.1);

    % plot hourly
    patch( [0.5:23.5, fliplr(0.5:23.5)],...
        [TT.Var1(idT)'+TT.Var2(idT)',...
        fliplr(TT.Var1(idT)'-TT.Var2(idT)')],...
        [0.8 0.8 0.8],'EdgeColor','none','FaceAlpha',0.8);
    plot(0.5:23.5, TT.Var1(idT),'ko-','linewidth',2);
%     plot(TT.Time(idDay)+minutes(30), TT.Var1(idDay),'ko-','linewidth',2);
    xlim([0 24]);
    xlabel('Time [hr]');  ylabel('Temperature');

    % RADIATION
    subplot(1,3,2); hold on
    plot(timeMnStation, Hazrat.RAD(idStationMn),'r');
    patch( [0.5:23.5, fliplr(0.5:23.5)],...
        [Hazrat_hourly.mean.RAD(idStationHr)'+Hazrat_hourly.std.RAD(idStationHr)',...
        fliplr(Hazrat_hourly.mean.RAD(idStationHr)'-Hazrat_hourly.std.RAD(idStationHr)')],...
        [0.8 0.8 0.8],'EdgeColor','none','FaceAlpha',0.8);
    plot(0.5:23.5, Hazrat_hourly.mean.RAD(idStationHr),'ko-','linewidth',2);

    xlim([0 24]);
    xlabel('Time [hr]');  ylabel('Solar radiation [W/m^2]');
    
    
    % WIND
    subplot(1,3,3); hold on
    plot(timeWS,uConv*raw.Wind_FS.ws(dd == day(raw.Wind_FS.time)),'r','linewidth',0.1);
    patch( [0.5:23.5, fliplr(0.5:23.5)],...
        uConv*[hourly.Wind_FS.ws.mean(idWS)'+hourly.Wind_FS.ws.std(idWS)',...
        fliplr(hourly.Wind_FS.ws.mean(idWS)'-hourly.Wind_FS.ws.std(idWS)')],...
        [0.8 0.8 0.8],'EdgeColor','none','FaceAlpha',0.8);
    plot(0.5:23.5, uConv*hourly.Wind_FS.ws.mean(idWS),'ko-','linewidth',2);
%     plot(timeMnStation, Hazrat.WS(idStationMn),'k');
%     plot(0.5:23.5, Hazrat_hourly.mean.WS(idStationHr),'kx-','linewidth',2);
    xlim([0 24]);
    xlabel('Time [hr]');  ylabel('Wind speed [m/s]');
    
    
%     save(['./DataExport/Day_',num2str(uniqueMonth(i),'%02d'),num2str(uniqueDates(i),'%02d'),'.mat'],...
%         'TEMPERATURE','RADIATION','WIND');

end

%% test poly fit
% plot(outTime,TEMPERATURE(:,2),'k','linewidth',2);
% plot(0.5:23.5, TT.Var1(idT),'ko-','linewidth',2);
xFit = 0.5:23.5;    
% yFit = TT.Var1(idT)';
yFit = uConv*hourly.Wind_FS.ws.mean(idWS)';

Pcoef = polyfit(xFit, yFit, 8);
xx = linspace(0,24,100);
yy = polyval(Pcoef,xx);

figure(); hold on
plot(xFit, yFit,'ko-','linewidth',1);
plot(xx, yy,'b-','linewidth',1);

% ylim([10 30]);
% ylim([0 2]);

% 
% xFit = TEMPERATURE(:,1);    yFit = TEMPERATURE(:,2);
xFit = WIND(:,1);    yFit = WIND(:,2);
Pcoef = polyfit(xFit, yFit, 23);
xx = linspace(0,1440,100);
yy = polyval(Pcoef,xx);
figure(); hold on
plot(xFit, yFit,'k-','linewidth',1);
plot(xx, yy,'b-','linewidth',1);

%%
% # of Beizer points
nBezier = 8;
BezierTerms = {};
for i=0:nBezier
    c(i+1) = nchoosek(nBezier,i);
    c(i+1)
end

%%
Bezier3 = {'(1-x)^3','3*(1-x)^2*x','3*(1-x)*x^2','x^3'};
Bezier4 = {'(1-x)^4','4*(1-x)^3*x','6*(1-x)^2*x^2','4*(1-x)*x^3','x^4'};
Bezier5 = {'(1-x)^5','5*(1-x)^4*x','10*(1-x)^3*x^2',...
    '10*(1-x)^2*x^3','5*(1-x)^1*x^4','x^5'};
Bezier6 = {'(1-x)^6','6*(1-x)^5*x','15*(1-x)^4*x^2','20*(1-x)^3*x^3',...
    '15*(1-x)^2*x^4','6*(1-x)^1*x^5','x^6'};
Bezier7 = {'(1-x)^7','7*(1-x)^6*x','21*(1-x)^5*x^2','35*(1-x)^4*x^3',...
    '35*(1-x)^3*x^4','21*(1-x)^2*x^5','7*(1-x)^1*x^6','x^7'};
Bezier8 = {'(1-x)^8','8*(1-x)^7*x','28*(1-x)^6*x^2','56*(1-x)^5*x^3',...
    '70*(1-x)^4*x^4','56*(1-x)^3*x^5','28*(1-x)^2*x^6','8*(1-x)^1*x^7','x^8'};


ft = fittype(Bezier7);   % bezier curve equation

fitBezier = fit(xFit'/24, yFit', ft);
% find bezier points that make the best fit to the data

figure();
plot(xFit/24, yFit, 'bo');
hold on
plot(fitBezier, 'k')

fitBezier2 = fitBezier;
fitBezier2.a = fitBezier2.a*0.95;
fitBezier2.d = fitBezier2.d*1.05;
plot(fitBezier2,'k:')
% plot(linspace(0,24,4),coeffvalues(fitBezier),'kx');





%% Nighttime data export
uniqueDates = unique(day(hourly.OUT.time));
for i=1:length(uniqueDates)
    uniqueMonth(i) = 2;
    if uniqueDates(i) > 15
        uniqueMonth(i) = 1;
    end
end

TT = timetable(hourly.OUT.time, hourly.OUT.mean, hourly.OUT.std);

outTime = 1:1440';
TEMPERATURE = zeros(1440,3);    TEMPERATURE(:,1) = outTime;
RADIATION = zeros(1440,3);      RADIATION(:,1) = outTime;
WIND = zeros(1440,3);           WIND(:,1) = outTime;


for i = 1:length(uniqueDates)
% for i = 6
    % day
    dd = uniqueDates(i);
    dd
    
    % target day 
    idT = (dd == day(hourly.OUT.time));         idT = circshift(idT,12);
    idWS = (dd == day(hourly.Wind_FS.time));    idWS = circshift(idWS,12);
    
    idRawT = (dd == day(raw.Temp.time));        idRawT = circshift(idRawT, 12*60*60);
    idRawWS = (dd == day(raw.Wind_FS.time));    idRawWS = circshift(idRawWS,12*60*60 );
    
    timeT = linspace(0,24,length(raw.Temp.out(idRawT)));
    timeWS = linspace(0,24,length(raw.Wind_FS.time(idRawWS)));
    
    idStationMn = (dd == day(Hazrat.Time)) & (2 == month(Hazrat.Time));
    idStationHr = (dd == day(Hazrat_hourly.mean.Time)) & (2 == month(Hazrat_hourly.mean.Time))  ;
    timeMnStation = linspace(0,24,length(Hazrat.Time(idStationMn)));
    
    idStationMn = circshift(idStationMn,12*60);
    idStationHr = circshift(idStationHr,12);
        
    
    TEMPERATURE(:,2) = interp1((0.5:23.5)*60,TT.Var1(idT), outTime,'pchip')+273.15;
    RADIATION(:,2) = interp1((0.5:23.5)*60,Hazrat_hourly.mean.RAD(idStationHr), outTime,'pchip');
    WIND(:,2) = interp1((0.5:23.5)*60,uConv*hourly.Wind_FS.ws.mean(idWS), outTime,'pchip');
    
    TEMPERATURE(:,3) = interp1((0.5:23.5)*60,TT.Var2(idT), outTime,'pchip');
    RADIATION(:,3) = interp1((0.5:23.5)*60,Hazrat_hourly.std.RAD(idStationHr), outTime,'pchip');
    WIND(:,3) = interp1((0.5:23.5)*60,uConv*hourly.Wind_FS.ws.std(idWS), outTime,'pchip');
    
    
    figure();
    subplot(1,3,1); hold on
    plot(outTime,TEMPERATURE(:,2)+TEMPERATURE(:,3),'b');
    plot(outTime,TEMPERATURE(:,2),'k','linewidth',2);
    plot(outTime,TEMPERATURE(:,2)-TEMPERATURE(:,3),'b');
    subplot(1,3,2); hold on
    plot(outTime,RADIATION(:,2)+RADIATION(:,3),'b');
    plot(outTime,RADIATION(:,2),'k','linewidth',2);
    plot(outTime,RADIATION(:,2)-RADIATION(:,3),'b');
    subplot(1,3,3); hold on
    plot(outTime,WIND(:,2)+WIND(:,3),'b');
    plot(outTime,WIND(:,2),'k','linewidth',2);
    plot(outTime,WIND(:,2)-WIND(:,3),'b');
    
    figure();
    % TEMPERATURE
    subplot(1,3,1); hold on
    % plot raw
    plot(timeT,raw.Temp.out(circshift(dd==day(raw.Temp.time),12*60*60)),'r','linewidth',0.1);

    % plot hourly
    patch( [0.5:23.5, fliplr(0.5:23.5)],...
        [TT.Var1(idT)'+TT.Var2(idT)',...
        fliplr(TT.Var1(idT)'-TT.Var2(idT)')],...
        [0.8 0.8 0.8],'EdgeColor','none','FaceAlpha',0.8);
    plot(0.5:23.5, TT.Var1(idT),'ko-','linewidth',2);
%     plot(TT.Time(idDay)+minutes(30), TT.Var1(idDay),'ko-','linewidth',2);
    xlim([0 24]);
    xlabel('Time [hr]');  ylabel('Temperature');

    % RADIATION
    subplot(1,3,2); hold on
    plot(timeMnStation, Hazrat.RAD(idStationMn),'r');
    patch( [0.5:23.5, fliplr(0.5:23.5)],...
        [Hazrat_hourly.mean.RAD(idStationHr)'+Hazrat_hourly.std.RAD(idStationHr)',...
        fliplr(Hazrat_hourly.mean.RAD(idStationHr)'-Hazrat_hourly.std.RAD(idStationHr)')],...
        [0.8 0.8 0.8],'EdgeColor','none','FaceAlpha',0.8);
    plot(0.5:23.5, Hazrat_hourly.mean.RAD(idStationHr),'ko-','linewidth',2);

    xlim([0 24]);
    xlabel('Time [hr]');  ylabel('Solar radiation [W/m^2]');
    
    
    % WIND
    subplot(1,3,3); hold on
    plot(timeWS,uConv*raw.Wind_FS.ws(circshift(dd == day(raw.Wind_FS.time),12*60*60)),'r','linewidth',0.1);
    patch( [0.5:23.5, fliplr(0.5:23.5)],...
        uConv*[hourly.Wind_FS.ws.mean(idWS)'+hourly.Wind_FS.ws.std(idWS)',...
        fliplr(hourly.Wind_FS.ws.mean(idWS)'-hourly.Wind_FS.ws.std(idWS)')],...
        [0.8 0.8 0.8],'EdgeColor','none','FaceAlpha',0.8);
    plot(0.5:23.5, uConv*hourly.Wind_FS.ws.mean(idWS),'ko-','linewidth',2);
%     plot(timeMnStation, Hazrat.WS(idStationMn),'k');
%     plot(0.5:23.5, Hazrat_hourly.mean.WS(idStationHr),'kx-','linewidth',2);
    xlim([0 24]);
    xlabel('Time [hr]');  ylabel('Wind speed [m/s]');
    
    
%     save(['./DataExport/Night_',num2str(uniqueMonth(i),'%02d'),num2str(uniqueDates(i),'%02d'),'.mat'],...
%         'TEMPERATURE','RADIATION','WIND');

end



%%
% avgSpan = 120;
avgSpan = 60*60;    % moving average with span of 1 hour

% plot(TT.Time, TT.Var1);

% for i = 1:length(unique_dates)
for i= 3
    dd = unique_dates(i);
    id_day = (dd == day(raw.Temp.time));

    tRaw = raw.Temp.time(id_day);   
    TRaw = raw.Temp.out(id_day);     
    tT_hourly_mean = retime(timetable(tRaw,TRaw),'hourly','mean');
    tT_hourly_std = retime(timetable(tRaw,TRaw),'hourly',@std);
%     tReshape = reshape(tRaw, 60, []);
%     TReshape = reshape(TRaw, 60, []);
       
%     figure();
%     plot(tReshape(1,:), mean(TReshape));

    TSmooth = smooth(TRaw, avgSpan);
    Tstd = sqrt((TSmooth - TRaw).^2);
    Tstd = abs(TSmooth - TRaw);
    
    figure(); 
    subplot(2,2,1); hold on
    plot(tRaw,TRaw);
%     plot(tReshape(1,:), mean(TReshape), 'k','linewidth',1.5);
    plot(tRaw, TSmooth, 'k','linewidth',1.5);
    plot(tT_hourly_std.tRaw,tT_hourly_mean.TRaw,'ko','linewidth',1.5);
    xlabel('Time');
    ylabel('Outdoor temperature');
    legend('Raw','Smoothed');

    subplot(2,2,2); hold on
    plot(tRaw, Tstd, '.');
    plot(tT_hourly_std.tRaw,tT_hourly_std.TRaw,'linewidth',1.5);
    xlabel('Time');
    ylabel('| Raw - Smoothed |');
    
    subplot(2,2,3); hold on
    id_station = (day(Hazrat.Time)==dd & month(Hazrat.Time) == 2);
    sum(id_station)
    tT_hourly_mean = retime(timetable(tRaw,TRaw),'hourly','mean');
    tT_hourly_std = retime(timetable(tRaw,TRaw),'hourly',@std);
    
    subplot(2,2,4); 
    
    
%     t = 1:length(tRaw);
%     fitInitialGuess = [6,1/84000,10000,24];
%     myFitType = fittype('a*cos(b*x+c)^2+d',...
%         'dependent',{'y'}, 'independent',{'x'},...
%         'coefficients',{'a','b','c','d'});
%     [Tfit, Tgof] = fit(t', TSmooth, myFitType,'StartPoint' ,fitInitialGuess);
%     Tgof
%     figure(10*i+2);   hold on
%     plot(t, TRaw, 'b');
%     plot(t, Tfit.a * cos(Tfit.b * t + Tfit.c).^2 + Tfit.d, 'r');
%     TT_h_mean = retime(TT,'hourly','mean');
%     TT_h_std  = retime(TT,'hourly',@std);

end



%%
   
tt1 = datetime(2019,2,2,0,00,00);
tt2 = datetime(2019,2,15,0,00,00);
id = tt1 < TT_h_mean.Time & TT_h_mean.Time < tt2;

figure();
subplot(1,2,1);
scatter(TT_h_mean.Var1(id), TT_h_std.Var1(id));
% corr(TT_h_mean.Var1(id), TT_h_std.Var1(id))
corr(TT_h_mean.Var1(id), smooth(TT_h_std.Var1(id)))

subplot(1,2,2);
 hold on
plot(TT_h_mean.Time(id), TT_h_mean.Var1(id)/10);
plot(TT_h_mean.Time(id), TT_h_std.Var1(id));

figure();
PP = polyfit(TT_h_mean.Var1(id), TT_h_std.Var1(id),1)
hold on
plot(TT_h_mean.Time(id), TT_h_std.Var1(id));
plot(TT_h_mean.Time(id), PP(1)*TT_h_mean.Var1(id)+PP(2));

%% 
TT_m_mean = retime(TT,'minutely','mean');
TT_m_std  = retime(TT,'minutely',@std);
id_nan = isnan(TT_m_mean.Var1) & isnan(TT_m_std.Var1);
TT_m_mean = TT_m_mean(~id_nan,:);
TT_m_std = TT_m_std(~id_nan,:);


tt1 = datetime(2019,2,2,0,00,00);
tt2 = datetime(2019,2,15,0,00,00);
id = tt1 < TT_m_mean.Time & TT_m_mean.Time < tt2;

figure();
subplot(1,2,1);
scatter(TT_m_mean.Var1(id), TT_m_std.Var1(id));
corr(TT_m_mean.Var1(id), TT_m_std.Var1(id))

figure();
PP = polyfit(TT_m_mean.Var1(id), TT_m_std.Var1(id),1)
hold on
plot(TT_m_mean.Time(id), TT_m_std.Var1(id));
plot(TT_m_mean.Time(id), PP(1)*TT_m_mean.Var1(id)+PP(2));

