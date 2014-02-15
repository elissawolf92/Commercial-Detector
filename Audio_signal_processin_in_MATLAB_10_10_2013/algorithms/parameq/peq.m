function [y,z] = peq(u,z,G3dB,Gcf,Gpeak)

[Mu,Nu] = size(u);
w3dB = zeros(Mu,Nu,'like',u);

% Scale by overall 1/2 gain
s = .5*u;

for k = 1:Mu
    
    % 3 dB section
    o3dB = s(k,:) - z(1,:);
    p3dB = G3dB.*o3dB;
    s3dB = s(k,:) + p3dB;
    
    % Center freq. section
    ocf = s3dB - z(2,:);
    pcf = Gcf.*ocf;
    scf = s3dB + pcf;
    wcf = pcf + z(2,:);
    
    % Output
    w3dB(k,:) = p3dB + z(1,:);
    
    % Update States
    z(2,:) = scf;
    z(1,:) = wcf;
end

% Final Output
y = (s + w3dB) + Gpeak*(s - w3dB);
