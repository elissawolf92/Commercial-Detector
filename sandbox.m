%% Read in sound, create player:
wilfred = wavread('wilfred.wav');
%wilfred = sum(wilfred, 2);
wilfred = wilfred(:,1);
player = audioplayer(wilfred, 44100);
%% set up LPF:
lpf = fir1(20, 0.2);
w_lpf = filter(lpf, 1, wilfred);
%%
figure;
plot(wilfred(:,1), 'r');
hold on;
silence_idx = find(w_lpf==0);
plot(silence_idx, zeros(size(silence_idx)), 'g*');
cursor = line([0,0],[-0.5, 0.5]);
%%
play(player)
while true
    set(cursor, 'Xdata', [player.CurrentSample, player.CurrentSample])
    pause(0.1);
end