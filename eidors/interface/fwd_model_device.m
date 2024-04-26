function fmdl = fmdl_model_device(fmdl,device, opt);
% FMDL_MODEL_DEVICE: set vendor/device specific parameters
% fmdl_model_device is a utility function to set vendor and device specific parameters.
% It sets the 'stimulation' and 'normalize_measurements' fields to the vendor-typical values
%
% Usage:
% fmdl = fmdl_model_device(fmdl,device, opt);
% 

% (C) 2024 Andy Adler License: GPL ver 2 or 3
% $Id$

if ischar(fmdl) && strcmp(fmdl,'UNIT_TEST'); do_unit_test(); return; end

switch lower(device)
  case {'draeger','dräger','pulmovista500'}
    fmdl=mdl_normalize(fmdl,true);
    mA = 0.01; % Estimate from docs
    fmdl.stimulation = mk_stim_patterns(16,1, ...
       [0,1],[0,1],{'no_meas_current','rotate_meas'},mA);

  otherwise error('No such device');
end

function do_unit_test
   fmdl = getfield(mk_common_model('a2c2',16), ...
                   'fwd_model');
   ssmm = stim_meas_list(fmdl.stimulation);
   unit_test_cmp('Init',ssmm([8,35],:), [
       1  2 11 10; 3  4 13 12]);

   fmdl = fwd_model_device(fmdl,'Draeger');
   ssmm = stim_meas_list(fmdl.stimulation);
   unit_test_cmp('Draeger',size(ssmm,1),208);
   unit_test_cmp('Draeger',ssmm([8,35],:), [
       1  2 11 10; 2  3 14 13]);
   unit_test_cmp('Draeger',fmdl.normalize_measurements, true);

 
