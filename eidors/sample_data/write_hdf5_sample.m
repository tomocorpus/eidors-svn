% Write HDF5 Sample data
% Possner, Bulst, Adler "HDF5-based data format for EIT data", Conf. EIT2023
% $Id$
function write_hdf5_sample
   load 'montreal_data_1995.mat'
   txt = fileread('montreal_data_1995.readme');
   h5createwrite('/VERSION',2023.4,'double');
   h5createwrite('/patient/Readme',txt,'string');
   stim = mk_stim_patterns(16,1,[0,1],[0,1],{'meas_current'},1);
   freq=13000; oo=ones(1,16); FR = 1/7;
   stimprot= []; measprot= [];
   for i=1:length(stim);
      stimprot = [stimprot, stim(i).stim_pattern*oo];
      measprot = [measprot, stim(i).meas_pattern'];
   end
   h5createwrite('/data/datasetEIT/Meas.V.Abs',zc_breathhold,'int16');
   for i=1:16;
      field = sprintf('/data/datasetEIT/protocol/Stim.I.%02d(A)',i);
      h5createwrite(field,stimprot(i,:),'double');
      field = sprintf('/data/datasetEIT/protocol/Meas.V.%02d(V)',i);
      h5createwrite(field,measprot(i,:),'double');
   end
   h5createwrite('/data/datasetEIT/protocol/Stim.I.freq(Hz)',freq,'double');

   h5createwrite('/data/datasetECG/Meas.V.Abs',ecg_breathhold,'int16');
   h5createwrite('/data/datasetECG/protocol/Stim.I.01(A)',0,'double');
   h5createwrite('/data/datasetECG/protocol/Stim.I.02(A)',0,'double');
   h5createwrite('/data/datasetECG/protocol/Stim.I.freq(Hz)',0,'double');
   h5createwrite('/data/datasetECG/protocol/Meas.V.01(V)', 1,'double');
   h5createwrite('/data/datasetECG/protocol/Meas.V.02(V)',-1,'double');
   h5createwrite('/data/datasetECG/protocol/Meas.V.freq(Hz)',0,'double');
   h5createwrite('/data/datasetECG/protocol/Meas.Dtime(s)',FR/16,'double');

function h5createwrite(DS, data, datatype);
   fname = 'montreal_data_1995_breathold.h5';
   sz = size(data);
   if strcmp(datatype,'string');
      sz=1;
      data = convertCharsToStrings(data);
   end
   h5create(fname,DS,sz, 'Datatype', datatype);
   h5write(fname,DS, full(data));
