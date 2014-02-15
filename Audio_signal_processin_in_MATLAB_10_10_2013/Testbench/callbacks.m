function [pauseSim,stopSim,tunedparams] = callbacks(params)

% Obtain new values for parameters through UDP Receive
[paramNew, simControlFlags] = UnpackUDP();

pauseSim = simControlFlags.pauseSim;
stopSim = simControlFlags.stopSim;

if ~isempty(paramNew)
    for k = 1:length(params)
        tunedparams.(params(k).Name) = paramNew(k);
    end
else
    for k = 1:length(params)
        tunedparams.(params(k).Name) = NaN;
    end
end
