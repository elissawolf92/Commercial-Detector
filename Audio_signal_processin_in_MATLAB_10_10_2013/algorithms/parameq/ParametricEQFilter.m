classdef ParametricEQFilter < matlab.System
    %ParametricEQFilter Second-order parametric equalizer filter.
    %
    %   % EXAMPLE: Parametric EQ filter with center frequency of 5000,
    %   % bandwidth of 500, and peak gain of 6 dB
    %   h =  ParametricEQFilter('CenterFrequency',5000,'Bandwidth',500);
    %   htf = dsp.TransferFunctionEstimator('SampleRate',44100,...
    %       'FrequencyRange','onesided','SpectralAverages',50);
    %   hplot = dsp.ArrayPlot('PlotType','Line','YLimits',[-15 15],...
    %       'SampleIncrement',44100/1024);
    %   for i=1:1000
    %       x = randn(1024,1);
    %       y = step(h,x);
    %       H = step(htf,x,y);
    %       magdB = 20*log10(abs(H));
    %       step(hplot,magdB);
    %       if (i==500)
    %           % Tune center frequency to 10000
    %           h.CenterFrequency = 10000;
    %           % Tune bandwidth to 2000;
    %           h.Bandwidth = 2000;
    %           % Tune peak to -10 dB
    %           h.PeakGaindB = -10;
    %       end
    %   end
    %   release(h); release(htf); release(hplot)
    
    % Copyright 2013 The MathWorks, Inc.
    % $Date: 2013/08/08 21:01:14 $
    
    %#codegen
    
    properties (Nontunable)
        %SampleRate Sample rate of input
        %   Specify the sample rate of the input in Hertz as a finite
        %   numeric scalar. The default is 44100 Hz.
        SampleRate = 44100;
    end
    
    properties 
        Bandwidth = 2205;
        CenterFrequency = 11025;
        PeakGaindB = 6.0206;
    end
    
    properties (DiscreteState)
        % Define any discrete-time states
        States
    end
    
    properties (Access=private)
        ReferenceGain       =  1;
        ReferenceGaindB     =  0;          
        privReferenceGain
        privPeakGain
        privBandwidthCoefficient
        privCenterFrequencyCoefficient
    end
    
    properties (Access=protected, Nontunable)
        InputDataType;
    end
       
    methods
        function obj = ParametricEQFilter(varargin)
            
            % Support name-value pair arguments
            setProperties(obj,nargin,varargin{:});            
        end
                         
        function N = getOctaveBandwidth(obj) 
            Q = getQualityFactor(obj) ;           
            N = 2/log(2)*asinh(1/(2*Q));            
        end
        
        function Q = getQualityFactor(obj) 
            Q = obj.CenterFrequency/obj.Bandwidth;
        end                             
        
        function [b,a] = tf(obj)
            %[B,A] = tf(obj) Transfer function
            %   [B,A] = TF(obj) returns the vector of numerator
            %   coefficients B and the vector of denominator coefficients A
            %   for the equivalent transfer function corresponding to the
            %   parametric EQ filter.
            Fs = obj.SampleRate;
            bw = obj.Bandwidth;       dw = 2*pi*bw/Fs;
            f0 = obj.CenterFrequency; w0 = 2*pi*f0/Fs;
            s  = tan(dw/2); sp1 = 1+s;
            G  = 10^(obj.PeakGaindB/20);
            a  = [1, -2*cos(w0)/sp1, (1-s)/sp1];
            b  = [(1+G*s)/sp1, -2*cos(w0)/sp1, (1-G*s)/sp1];
        end
        
    end
    
    methods (Access=protected)
        function setupImpl(obj, u)
            obj.InputDataType = class(u);
            obj.States = zeros(2,size(u,2),'like',u);
                        
            processTunedPropertiesImpl(obj);
        end
        
        function resetImpl(obj)
            % Specify initial values for DiscreteState properties
            obj.States = zeros(size(obj.States),'like',obj.States);  
        end
        
        function y = stepImpl(obj, u)
     
            [y,obj.States] = peq(u,obj.States,...
                obj.privBandwidthCoefficient,...
                obj.privCenterFrequencyCoefficient,...
                obj.privPeakGain);
        end
        
        function validateInputsImpl(obj,u)

             validateattributes(u, {'single', 'double'}, {'2d'},'','')%#ok<EMCA>
            
        end 
                
        
        function processTunedPropertiesImpl(obj)
            inputDataTypeLocal = obj.InputDataType;
                        
            Fs = cast(obj.SampleRate,inputDataTypeLocal);
            BW = cast(obj.Bandwidth,inputDataTypeLocal);
            CF = cast(obj.CenterFrequency,inputDataTypeLocal);
            t  = tan(BW*pi/Fs);
            obj.privBandwidthCoefficient = 2/(1+t)-1;
            obj.privCenterFrequencyCoefficient = -cos(2*CF/Fs*pi);
            G0dB = cast(obj.ReferenceGaindB,inputDataTypeLocal);
            obj.privReferenceGain = 10^(G0dB/20);
            GdB  = cast(obj.PeakGaindB,inputDataTypeLocal);
            obj.privPeakGain = 10^(GdB/20);
            
        end               
        
        function N = getNumInputsImpl(obj)
            % Specify number of System inputs
            N = 1; % Because stepImpl has one argument beyond obj
        end
        
        function N = getNumOutputsImpl(obj)
            % Specify number of System outputs
            N = 1; % Because stepImpl has one output
        end
    end
end

