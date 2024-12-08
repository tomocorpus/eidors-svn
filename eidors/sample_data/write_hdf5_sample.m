% Write HDF5 Sample data
% Possner, Bulst, Adler "HDF5-based data format for EIT data", Conf. EIT2023
% $Id$
function write_hdf5_sample
   load 'montreal_data_1995.mat'
   h5createwrite('/VERSION',2023.4,'double');
   h5createwrite('/patient/Readme','text','string');

function h5createwrite(DS, data, datatype);
   fname = 'montreal_data_1995_breathold.mat';
   sz = size(data);
   if strcmp(datatype,'string');
      sz=1;
      data = convertCharsToStrings(data);
   end
   h5create(fname,DS,sz, 'Datatype', datatype);
   h5write(fname,DS, data);
