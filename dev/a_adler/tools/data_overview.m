function data_overview(fname,fmt,opts)
% data_overview: show an overview of an EIT data file
% License GPL v2 or v3. (C) 2024 Andy Adler 

  [dd,aux] = eidors_readdata(fname);
  switch aux.format(1:2)
    case 'lq'; data_overview_sentec(dd,aux,fname);
    otherwise
      error(['not sure what to do with format=',aux.format])
  end

function data_overview_sentec(dd,aux,fname);
  
  show_iq_and_ushapes(dd,aux)  

  subplot(223);
  tt=( 1:size(dd,2) )/aux.frame_rate;
  sig = real(sum(dd));
  plot(tt, sig ); box off; xlim tight

  subplot(224);
  fax = linspace(0,aux.frame_rate, size(dd,2) +1); fax(end) = [];
  plot(fax, abs(fft(sig))); box off; xlim([0,aux.frame_rate/2]);

  fname(1:max(find(fname=='/')))=[];
  sgtitle(fname,'interpreter','none');

function show_iq_and_ushapes(dd,aux)  
  dd(:,101:end) = [];
  msel = aux.meas_sel;

  subplot(221);
  plot(dd( msel,:),'k.'); hold on
  plot(dd(~msel,:),'b.'); hold off
  
  subplot(222); 
  dr = real(dd);
  plot(dr);
  xlim tight ; box off
