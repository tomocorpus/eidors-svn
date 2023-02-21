function [dd, tt, fs] = data_loader(fname)
    % Given a filename load the data
    % Also output a time array for nice easy plotting
    % I think all of this data is recorded on the 
    % Swisstom,Sentec device?
    [dd, aux] = eidors_readdata(fname,'LQ4');
    dd = real(dd); % No point keeping this around
    %warning('This requires an up to date version of EIDORS!!')
    fs = aux.frame_rate;
    tt = (0:size(dd,2)-1)/fs; % Don't bother with the time stamps for no