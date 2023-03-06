function [ROIs, imgR, imdl] = define_ROIs(imdl, varargin)
% DEFINE_ROIS: define ROI regions in image
%
% [ROIs, imgR, imdl] = define_ROIs(imdl, xcuts, ycuts, ...)
%   imdl: inv_ or fwd_model structure
%   xcuts, ycuts: x and y cuts of ROI grid
% 
% ROIs: matrix [n_ROIs x n_elems]
% imgR: image of ROIs (mostly for debugging)
% imdl: inv_model which reconstructs onto ROIs (if possible)
%

% TODO: 
%   - add 3D
%   - create rec_model if not there
%   - can it work for non-solve_use_matrix?
%

if ischar(imdl) && strcmp(imdl,'UNIT_TEST'); do_unit_test; return; end

recc2f = 1;
switch imdl.type
   case 'fwd_model';
      fmdl = imdl;
   case 'inv_model';
      if isfield(imdl,'rec_model');
         fmdl = imdl.rec_model;
         recc2f = fmdl.coarse2fine;
      else
         fmdl = imdl.fwd_model;
      end

   otherwise;
      error('define_ROIs: require fwd_ or inv_model');
end

% TODO: Get an opt structure from varargin


rmdl = mk_grid_model([],varargin{:});

ROIa = mk_approx_c2f(fmdl,rmdl);
ROIs = ROIa.' * recc2f;
imgR= mk_image(fmdl,ROIs.');

function do_unit_test
   do_GREIT_test
%  do_simple_test
%  do_3D_test

function do_GREIT_test
   fmdl = mk_library_model('neonate_32el_lungs');
   [stim,msel] = mk_stim_patterns(32,1,[0,5],[0,5],{'no_meas_current_next2'},1);
   fmdl.stimulation = stim;
   fmdl.meas_select = msel;
   imdl= select_imdl(fmdl,'GREIT:NF=0.500 32x32');
   [ROIs,imgR] = define_ROIs(imdl,-1:0.5:1,-1:0.5:1);
   subplot(121); show_slices(imgR)
   imdl= select_imdl(fmdl,'GREIT:NF=0.500 16x16');
   [ROIs,imgR] = define_ROIs(imdl,-1:0.5:1,-1:0.5:1);
   subplot(122); show_slices(imgR)
