function write_ibex_mat(fname, fmdl, imgr)
% WRITE_IBEX_MAT:  write images to ibex mat file format
%  write_ibex_mat(fname, fmdl, imgr)
%    fname - file name to write to 
%    fmdl  - the fmdl to use, including lung regions
%    imgr  - the reconstructed image requence
%
% Limitations, imgr must be a 2D 32×32 image

% (C) 2024 Andy Adler. License: GPL version 2 or version 3
% $Id$

function [llung_ROI, rlung_ROI, thorax_ROI] = get_ROIs(fmdl);
    fmdl= mk_library_model('adult_male_16el_lungs');
    img = mk_image(fmdl, 1); % background conductivity
    img.elem_data(fmdl.mat_idx{2}) = 0.3001; % lungs
    img.elem_data(fmdl.mat_idx{3}) = 0.3002; % lungs
    ROI = calc_slices(img,[inf,inf,0.5]);
    llung_ROI = ~isnan(ROI) & (ROI==0.3001);
    rlung_ROI = ~isnan(ROI) & (ROI==0.3002);
    thorax_ROI= ~isnan(ROI); % include lungs, too
function [llung_ROI, rlung_ROI, thorax_ROI] = get_ROIs(fmdl);
data.imageRate = 13;

data.patient.ROI.Inside =thorax_ROI*100; % to scale it up to 100
data.patient.ROI.RightLung =rlung_ROI*100;
data.patient.ROI.LeftLung =llung_ROI*100;
data.patient.ROI.Heart =zeros(size(imgs,1),size(imgs,2));

% put to dummy because they are missing
data.patient.halfChest = 'NaN';
data.patient.height = 'NaN';
data.patient.weight = 'NaN';
data.patient.gender = 'NaN';

data.measurement.Position.transversal = zeros (1,size(imgs,3));
data.measurement.Position.longitudinal = zeros (1,size(imgs,3));
data.measurement.ImageQuality = 100*ones(1,size(imgs,3));
data.measurement.ElectrodeQuality = zeros(size(imgs,3),32);
data.measurement.ZeroRef = imgs;

data.injctionPattern= 'NaN';
data.SensorBelt.NumEl= 'NaN';

data.measurement.CompositValue=squeeze(sum(sum(imgs,2),1));

save('file-for-IBEX.mat','data');


