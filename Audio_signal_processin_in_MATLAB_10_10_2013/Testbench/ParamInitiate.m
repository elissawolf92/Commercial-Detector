
function param =ParamInitiate()
%initialize default paramters values to the equalizer. 
%Copyright 2013 The MathWorks, Inc.
param(1).Name = 'CenterFrequency';
param(1).InitialValue = 3000;
param(1).Limits = [0,22050];
param(2).Name = 'Bandwidth';
param(2).InitialValue = 2000;
param(2).Limits = [0,22050];
param(3).Name = 'Gain';
param(3).InitialValue = 6.020000e+00;
param(3).Limits = [-20,20];
param(4).Name = 'CenterFrequency2';
param(4).InitialValue = 1000;
param(4).Limits = [0,22050];
param(5).Name = 'Bandwidth2';
param(5).InitialValue = 2000;
param(5).Limits = [0,22050];
param(6).Name = 'Gain2';
param(6).InitialValue = -6.020000e+00;
param(6).Limits = [-20,20];
