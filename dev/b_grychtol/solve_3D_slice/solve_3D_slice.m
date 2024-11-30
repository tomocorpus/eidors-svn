function imdl = solve_3D_slice(imdl,varargin)
%SOLVE_3D_slice convert a 3D dual-model reconstruction matrix model to 2D
%
% imdl = SOLVE_3D_slice(imdl, level)
% imdl = SOLVE_3D_slice(imdl, level, opt) accepts the same parameters as
%  MK_PIXEL_SLICE.
%
% See also MK_PIXEL_SLICE

if ischar(imdl) && strcmp(imdl,'UNIT_TEST'); do_unit_test; return; end
[rec, fwd] = mk_pixel_slice(imdl.rec_model,varargin{:});

% f = fwd_model elems
% r = rec_model elems
% c = rec_model values
% s = slice values

c2f = imdl.fwd_model.coarse2fine; % fraction of fwd_model elem in coarse value
c2r = imdl.rec_model.coarse2fine; % fraction of rec_model elem in coarse value
s2r = fwd.coarse2fine;            % fraction of rec_model elem in slice value

rvol = get_elem_volume(imdl.rec_model,'no_c2f');
r2s = s2r' * spdiag(rvol); % volume of each slice elem built from rec elems

% we need to divide by the volume of each pixel, but we don't know
% the height, so we estimate from the area and the maximum volume
s_area = get_elem_volume(rec); 
s_hght = max(sum(r2s,2)) ./ s_area; 
svol = s_area .* s_hght;
r2s = r2s ./ svol;

if 0
   c = ones(size(c2f,2),1);
   r = c2r * c;
   s = r2s * r;
   unit_test_cmp('still 1', s(30),1,1e-13)
end

s2c = r2s * c2r;
RM = s2c * imdl.solve_use_matrix.RM;

% to map from the slice to the original fwd_model, we need r2c.
% Same approach:
r2c = c2r' * spdiag(rvol);
% again, in general, we don't know the volume of each element (because the
% coarse elements on the rec_model could theoreticall extend beyond the 
% elements of it, though we don't build such rec_models). We take the max
% of two estimates:
vol_fmdl = get_elem_volume(imdl.fwd_model);
vol_rmdl = get_elem_volume(imdl.rec_model);
rvol = max([vol_rmdl, vol_fmdl],[],2);
r2c = r2c ./ rvol;

c2f = imdl.fwd_model.coarse2fine * r2c * s2r;

if 0
   fmdl = imdl.fwd_model;
   fmdl.coarse2fine = c2f;
   img = mk_image(fmdl, ones(size(c2f,2),1));
   show_fem(img)
end

imdl.fwd_model.coarse2fine = c2f;
imdl.solve_use_matrix.RM = RM;
imdl.rec_model = rec;

function do_unit_test
   warning('off','EIDORS:FirstImageOnly');
   [vh,vi] = test_fwd_solutions;
   % inverse geometry
   fmdl= ng_mk_cyl_models([4,1,.5],[16,1.5,2.5],[0.05]);
   fmdl= mystim_square(fmdl);

   vopt.imgsz = [32 32];
   vopt.zvec = linspace( 0.75,3.25,6);
   vopt.save_memory = 1;
%  opt.noise_figure = 2;
   weight = 8.42412109211;
   [imdl,opt.distr] = GREIT3D_distribution(fmdl, vopt);
   imdl = mk_GREIT_model(imdl, 0.2, weight, opt);


   img = inv_solve(imdl, vh, vi);
   unit_test_cmp('img size', size(img.elem_data), [4280,5]);
   [mm,ll] =max(img.elem_data(:,1));
%    unit_test_cmp('img', [mm,ll], ...
%        [0.426631207850641, 1274], 1e-10);

   img.show_slices.img_cols = 1;
   slice1 = calc_slices(img,[inf inf 2]);
   subplot(231); show_fem(fmdl); title 'fmdl'
   img0 = img;
   img0.elem_data = img0.elem_data(:,3);
   subplot(234); show_fem(img0);  title '3D'
   subplot(232); show_slices(img,[inf,inf,2]); title '3D rec';
   eidors_colourbar(img);

   imd2 = solve_3D_slice(imdl,[Inf Inf 2.0],struct('z_depth',0.2));

   unit_test_cmp('RM size', size(imd2.solve_use_matrix.RM), [856,928]);
%    unit_test_cmp('RM', imd2.solve_use_matrix.RM(1,1:2), ...
%        [-13.546930204198315   9.664897892799864], 1e-8);

   img = inv_solve(imd2, vh, vi);
   unit_test_cmp('img size', size(img.elem_data), [856,5]);
   [mm,ll] =max(img.elem_data(:,1));
%    unit_test_cmp('img', [mm,ll], ...
%        [0.031608449353163, 453], 1e-10);
   img.show_slices.img_cols = 1;
   slice2 = calc_slices(img);
   subplot(235), show_slices(img); title('2D rec')
   eidors_colourbar(img);
   subplot(2,3,[3,6])

   level = struct( 'centre', [0 0 2],...
                   'normal_angle',[1 -1 1 0]/sqrt(3)');
   opt.z_depth = 0.5;
   opt.square_pixes = true;
   opt.imgsz = [64 64];
   imd2 = solve_3D_slice(imdl, level, opt);
   img = inv_solve(imd2, vh, vi);
   img.elem_data = img.elem_data(:,3);
   h1 = show_fem(img);
%    h1.EdgeColor = 0.8*ones(3,1);

   

   xlim([-1 1]); ylim([-1 1]); zlim([0 4]);
   hold on
   h2 = show_fem(imd2.fwd_model);
   h2.EdgeColor = 0.8*ones(3,1);
   show_fem(img0.fwd_model);
   hold off
   view(-20,40)



   unit_test_cmp('slice Nan', isnan(slice1), isnan(slice2))
   slice1(isnan(slice1))= 0;
   slice2(isnan(slice2))= 0;
   % this woudl be a special case, need a better test
%    unit_test_cmp('slice value', slice1, slice2, 1e-10)

  

   warning('on','EIDORS:FirstImageOnly');

function fmdl = mystim_square(fmdl);
   [~,fmdl] = elec_rearrange([16,2],'square', fmdl);
   [fmdl.stimulation, fmdl.meas_select] =  ...
       mk_stim_patterns(32,1,[0,5],[0,5],{},1);

function [vh,vi] = test_fwd_solutions;
   posns= linspace(1.0,3.0,5);
   str=''; for i=1:length(posns);
      extra{i} = sprintf('ball%03d',round(posns(i)*100));
      str = [str,sprintf('solid %s=sphere(0.5,0,%f;0.1); ', extra{i}, posns(i))];
   end
   extra{i+1} = str;
   fmdl= ng_mk_cyl_models([4,1,.2],[16,1.5,2.5],[0.05],extra); 
   fmdl = mystim_square(fmdl);
   
   img= mk_image(fmdl,1);
   vh = fwd_solve(img);
   %vh = add_noise(2000, vh);
   for i=1:length(posns);
      img= mk_image(fmdl,1);
      img.elem_data(fmdl.mat_idx{i+1}) = 2;
      vi{i} = fwd_solve(img);
   end;
   vi = [vi{:}];