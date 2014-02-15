function [y,a] = expander_algorithm(u,FIR,z)
% Copyright 2013 The MathWorks, Inc.
%persistent z % 
%
%
%
    %if isempty(z) % Set up resources for program
    %    z=z;
    %end

[Mu,~] = size(u);

p      = 2;
lambda = 0.9;
z0     = 0.15;

z(1,:) = lambda*z(end,:) + (1-lambda)*abs(u(1,:));
for k = 2:Mu
    
    % Envelope detector
    z(k,:) = lambda*z(k-1,:) + (1-lambda )*abs(u(k,:));
               
end

% Gain processor
f = z;
f(z >= z0) = cast(1,'like',u);
f(z < z0) = (z(z < z0)./z0).^(p-1);

% Smooth Gain
G = step(FIR,f);

% Compute output
y = G.*u;

a=z;