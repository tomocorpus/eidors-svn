function data_to_hdf5(example_no)
% data_to_hdf5: convert data to eidors hdf5 file format

switch example_no;
  case 'montreal_data_1995';
    montreal_data_1995();
  otherwise;
    error('no such example');
end
    


function montreal_data_1995()
  fn = 'montreal_data_1995';
  h5f = [fn,'.h5'];
  delete(h5f)

  % These data were recorded on the ??? system
  % with 16 electrodes and adjacent stim/meas pattern
  % using 3 mA at 13kHz
  % Frame rate was 
  Nel = 16;
  [stim,msel] = mk_stim_patterns(Nel,1,[0,1],[0,1],{'no_meas_current'},.003);
  load([fn,'.mat'],'zc_resp');
  data = zc_resp(msel,:);
  Dtime = linspace(0,1/7,256+1); Dtime(end) = [];
  ds = '/data/DS1';
  h5createwrite(h5f,[ds,'/EIT.abs'],data,'int16')
  time = (0:size(data,2))'/7; % 7 FPS
  h5createwrite(h5f,[ds,'/FRAMETIME'],time,'double')
  prot=[ds,'/protocol'];
  k=0;for i=1:length(stim);
    si=stim(i).stim_pattern;
    mi=stim(i).meas_pattern;
    for j=1:size(mi,1); k=k+1;
       I(k,:) = si.';
       M(k,:) = mi(j,:).';
       Ifreq(k) = 13000;
       Mfreq(k) = 13000;
    end
  end
  h5createwrite(h5f,[prot,'/Ifreq(Hz)'],Ifreq);
  for i=1:Nel;
      dset = sprintf([prot,'/I%02d(A)'],i);
      h5createwrite(h5f,dset,I(:,i));
  end
  h5createwrite(h5f,[prot,'/Mfreq(Hz)'],Mfreq);
  for i=1:Nel;
      dset = sprintf([prot,'/MI%02d(V)'],i);
      h5createwrite(h5f,dset,M(:,i));
  end
  h5createwrite(h5f,[prot,'/Dtime(s)'],Dtime);
     
  h5disp(h5f)
