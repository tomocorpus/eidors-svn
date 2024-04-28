function out = mk_thorax_model_bp3d(varargin)
%MK_THORAX_MODEL_BP3D Torso model based on BodyParts3D
%
% FMDL = MK_THORAX_MODEL_BP3D() 
% Returns a torso fwd_model with no electrodes or organs
%
% FMDL = MK_THORAX_MODEL_BP3D(elec_pos, elec_shape)
% FMDL = MK_THORAX_MODEL_BP3D(elec_pos, elec_shape, maxh)
% Allows specifying electrode configuration, see PLACE_ELEC_ON_SURF
%
% FMDL = MK_THORAX_MODEL_BP3D(stimpat)
% A predefined model with round electrodes (radius 1 cm). Accepts a string 
% parameter to define a stim pattern:
%    '2x16_planar'   - 2 rings of 16 electrodes, planar stimulation
%    '2x16_odd-even' - 2 rings, each stimulation is cross-plane 
%    '2x16_square'   - 2 rings, every second stimulation is cross-plane
%    '2x16_adjacent' - like square, but with adjacent stimulation
%    '1x32_ring'     - single ring of 32 electrodes
%
% IMG = MK_THORAX_MODEL_BP3D(... , organspec)
% Returns a torso model containing organ shapes as an image structure. Can
% be used with all the above electrode defintions. 
% ORGANSPEC must be one of:
%    'fine'          - a relatively dense model, ~7 million elems
%    'coarse'        - a coarser model, *NOT IMPLEMENTED YET*
%
% CITATION_REQUEST:
% AUTHOR: Mitsuhashi N, Fujieda K, Tamura T, Kawamoto S, Takagi T, Okubo K
% TITLE: BodyParts3D: 3D structure database for anatomical concepts
% JOURNAL: Nucleic Acids Res
% VOL: 37
% NUM: Database issue
% YEAR: 2013
% PAGE: D782--5
% LINK: https://academic.oup.com/nar/article/37/suppl_1/D782/1000752
% PDF: https://academic.oup.com/nar/article-pdf/37/suppl_1/D782/3210893/gkn613.pdf
% DOI: 10.1093/nar/gkn613
% PUBMED: 18835852
%
% LICENSE INFORMATION:
% This work is a derivative of the <a href="matlab: web 
% https://dbarchive.biosciencedbc.jp/en/bodyparts3d
% -browser">BodyParts3D</a> database by 
% <a href="matlab: web https://biosciencedbc.jp/ -browser"
% >The Database Center for Life Science</a>, used under the Creative Commons 
% Attribution-ShareAlike 2.1 Japan (<a href="matlab: web 
% http://creativecommons.org/licenses/by-sa/2.1/jp/deed.en_US 
% -browser">CC BY-SA 2.1 JP</a>) license.
% This work is licensed under CC BY-SA 2.1 JP by Bartek Grychtol.
%
% See also MK_THORAX_MODEL, PLACE_ELEC_ON_SURF

% (C) 2024 Bartek Grychtol. License: CC BY-SA 2.1 JP
% $Id$

citeme(mfilename)

if nargin == 0 % get a torso with no electrodes
   out = get_torso; 
   return; 
end
organspec = '';
if nargin > 1 && ischar(varargin{end})
   organspec = varargin{end};
   varargin(end) = [];
end

switch length(varargin)
   case 1
      if ischar(varargin{1}) && ~isempty(varargin{1})
         out = build_predef_elecs(varargin{1});
      else
         error('EIDORS:WrongInput','Electrode specification not understood');
      end
   case {2,3}
      out = mk_thorax_model('bp3d',varargin{:});
   otherwise
      error('EIDORS:WrongInput', 'Too many inputs');
end
   
if ~isempty(organspec)
   out = add_organs(out, organspec);
end


function out = get_torso()
contrib = 'bp3d-torso'; file =  'bp3d_torso.mat';
load(get_contrib_data(contrib,file),'torso');
eidors_msg('Budiling bp3d body surface', 2);
out = gmsh_stl2tet(torso);


function out = build_predef_elecs(stimpat)
eth16 = 360*cumsum([0.2 0.4*ones(1,7) 0.5 0.4*ones(1,7)])/6.5 - 90; eth16 = eth16';
eth32 = 360*cumsum([0.1 0.2*ones(1,15) 0.25 0.2*ones(1,15)])/6.45 - 90; eth32 = eth32';
ep = eth16; ep(:,2) = 1175;
ep(17:48,1) = eth32; ep(17:48,2) = 1212.5;
ep(49:64,1) = eth16; ep(49:64,2) = 1250;
out = mk_thorax_model('bp3d',ep,[10 0 1],20);

out = set_predef_stim(out, stimpat);


function out = add_organs(torso, organspec)
organs = get_organ_models(organspec);
tri.vertices = torso.nodes;
tri.faces = torso.boundary;
N = size(tri.vertices, 1);
tri.vertices = [tri.vertices; organs.nodes];
tri.faces = [tri.faces; N + organs.boundary(:,[1 3 2])];

eidors_msg('Re-meshing body volume', 2);
shell = gmsh_stl2tet(tri);
print_mdl_info(shell, 'Body');

eidors_msg('Restoring electrodes', 2);
if isfield(torso, 'electrode') && ~isempty(torso.electrode)
   for i = 1:numel(torso.electrode)
      electrode(i).nodes = torso.nodes(torso.electrode(i).nodes,:);
   end
   shell = restore_electrodes(shell, electrode, 0.01);
end
organs.boundary = organs.show_boundary;
organs = rmfield(organs, 'show_boundary');

eidors_msg('Merging body and organ volumes', 2);
out = merge_meshes(shell, organs);
out.mat_names = ['body'; organs.mat_names];
 
eidors_msg('Removing trachea', 2);
idx = strcmp(out.mat_names,'Trachea');
out = remove_elems(out, out.mat_idx{idx});

print_mdl_info(out, 'Final model');

function mm = restore_electrodes(mm, electrode, z_contact, thresh)
if nargin < 4
   thresh = eps;
end
surf_node_idx = unique(find_boundary(mm));
surf_nodes = mm.nodes(surf_node_idx,:);
idx = abs(surf_nodes(:,3)) < .98 * max(surf_nodes(:,3)); % ignore nodes close to caps
surf_node_idx = surf_node_idx(idx);
surf_nodes = surf_nodes(idx,:);
for e = 1:numel(electrode)
   for n = 1:size(electrode(e).nodes,1)
      dist = sqrt(sum((surf_nodes - electrode(e).nodes(n,:)).^2, 2));
      [val, pos] = min(dist);
      if val > thresh
         warning('Problem finding node %d of electrode %d. Closest distance: %f',n,e,val);
      end
      mm.electrode(e).nodes(n) = surf_node_idx(pos);
   end
   mm.electrode(e).z_contact = z_contact;
end

function organs = get_organ_models(organspec)
switch organspect
   case 'fine'
      fhandle = @mk_fine_organse;
   case 'coarse'
      error('EIDORS:NotImplemented', 'Coarse organ model is not '...
            'implemented yet.')
   otherwise
      error('EIDORS:WrongInput', 'Organ specification not understood.');
end
cache_path = get_cache_path;
fname = sprintf('bp3d_organs_%s.mat', organspec);
fpath = [cache_path filesep fname];
if ~exist(fpath, 'file')
   eidors_msg('This takes a REALLY long time');
   organs = eval(fhandle);
   save(fpath, 'organs');
else
   load(fpath, 'organs');
end

function mdl = mk_fine_organs

start_time = now(); 
organs = mk_individual_organs;
mdl = assemble_organs(organs);
mdl.show_boundary = mdl.boundary;
mdl = fix_boundary(mdl);

%  cashed results are not useful outside
eidors_cache('clear_old', start_time);

function mdl = assemble_organs(organs)
pcs = struct();

eidors_msg('Merging vessels', 2);
vessels = {'Aorta','IVC','SVC','PA', 'LSPV', 'LIPV','RSPV','RIPV'};
for i = 1:numel(vessels)
    v = vessels{i};
    disp(v)
    pcs.(v) = merge_meshes(organs.(v), organs.(['Blood' v]),1e-2);
    pcs.(v).mat_names = {v; ['Blood' v]};
end

eidors_msg('Merging left side', 2);
left = merge_meshes(organs.LungLeft, ...            
                    pcs.LSPV, ...
                    pcs.LIPV, ...
                    1e-2);
left.mat_names = vertcat({'LungLeft'},pcs.LSPV.mat_names, pcs.LIPV.mat_names);

eidors_msg('Merging right side', 2);
right = merge_meshes(organs.LungRight, ...            
                     pcs.RSPV, ...
                     pcs.RIPV, ...
                     1e-2);
right.mat_names = vertcat({'LungRight'},pcs.RSPV.mat_names, pcs.RIPV.mat_names);

eidors_msg('Merging heart', 2);
heart = merge_meshes(organs.HeartWall, ...
                     organs.BloodLeftHeart, ...
                     organs.BloodRightHeart, ...
                     1e-2);
heart.mat_names = {'HeartWall';'HeartBloodLeft'; 'HeartBloodRight'};

eidors_msg('Merging heart, left and right', 2);
mdl = merge_meshes(heart, left, right, 1e-2);
mdl.mat_names = vertcat(heart.mat_names, left.mat_names, right.mat_names);

eidors_msg('Merging remaining vessels', 2);
mdl = merge_meshes(mdl, ...
                  pcs.PA, ...
                  pcs.Aorta, ...
                  pcs.SVC, ...
                  pcs.IVC, ...
                  1e-2);
mdl.mat_names = vertcat(mdl.mat_names, pcs.PA.mat_names,pcs.Aorta.mat_names, ...
                        pcs.SVC.mat_names, pcs.IVC.mat_names);

eidors_msg('Merging trachea', 2);
mdl = merge_meshes(mdl, organs.Trachea, 5e-2);
mdl.mat_names{end+1} = 'Trachea';

function organs = mk_individual_organs
org_path = get_contrib_data('bp3d-torso','bp3d_organs.mat');
srf = load(org_path);

eidors_msg('Meshing vessels', 2);
vessels = {'Aorta','IVC','SVC','PA', 'LSPV', 'LIPV','RSPV','RIPV'};
for i = 1:numel(vessels)
    v = vessels{i};
    disp(v)
    [vessel, blood] = eidors_cache(@mk_vessel, srf.(v));
    organs.(v) = vessel;
    b = sprintf('Blood%s', v);
    organs.(b) = blood;
    print_mdl_info(vessel, v);
    print_mdl_info(blood, b);
end

eidors_msg('Meshing trachea and lungs', 2);
organs.Trachea = gmsh_stl2tet(srf.Trachea);
print_mdl_info(organs.Trachea, 'Trachea');
organs.LungLeft = gmsh_stl2tet(srf.LungLeft);
print_mdl_info(organs.LungLeft, 'LungLeft');
organs.LungRight = gmsh_stl2tet(srf.LungRight);
print_mdl_info(organs.LungRight, 'LungRight');

eidors_msg('Meshing left heart', 2);
left = eidors_cache(@mk_blood_left_surf,srf);
organs.BloodLeftHeart = gmsh_stl2tet(left, [3, 20]);
print_mdl_info(organs.BloodLeftHeart, 'BloodLeftHeart');

eidors_msg('Meshing right heart', 2);
right = eidors_cache(@mk_blood_right_surf,srf);
organs.BloodRightHeart = gmsh_stl2tet(right, [3, 20]);
print_mdl_info(organs.BloodRightHeart, 'BloodRighttHeart');

eidors_msg('Meshing heart wall', 2);
heart = eidors_cache(@mk_heart_surf, srf);
organs.HeartWall = gmsh_stl2tet(heart);
print_mdl_info(organs.HeartWall, 'HeartWall');

function right = mk_blood_right_surf(srf)
fn = @(x) flip_normals(x);
right = merge_meshes(srf.BloodRight, ...
                     fn(srf.SVC.cap), ...
                     fn(srf.IVC.cap), ...
                     fn(srf.PA.cap));

function left = mk_blood_left_surf(srf)
fn = @(x) flip_normals(x);
left = merge_meshes(srf.BloodLeft, ...
                    fn(srf.Aorta.cap), ...
                    fn(srf.LSPV.cap), ...
                    fn(srf.LIPV.cap), ...
                    fn(srf.RSPV.cap), ...
                    fn(srf.RIPV.cap), ...
                    1e-2);

function [heart, right, left] = mk_heart_surf(srf)
right = merge_meshes(srf.BloodRight, ...
                     srf.SVC.ring, ...
                     srf.IVC.ring, ...
                     srf.PA.ring, ...
                     1e-2);
right = flip_normals(right);

left = merge_meshes(srf.BloodLeft, ...
                    srf.Aorta.ring, ...
                    srf.LSPV.ring, ...
                    srf.LIPV.ring, ...
                    srf.RSPV.ring, ...
                    srf.RIPV.ring, ...
                    1e-2);
left = flip_normals(left);

heart = merge_meshes(bd(left), bd(right), bd(srf.HeartShell));

function [V, B] = mk_vessel(vstruct)
msh = merge_meshes(vstruct.outer, vstruct.ring, ...
                    flip_normals(vstruct.inner),1e-2);
V = gmsh_stl2tet(msh); 
msh = merge_meshes(vstruct.cap, vstruct.inner);
B = gmsh_stl2tet(msh);

function mdl = flip_normals(mdl)
mdl.elems = mdl.elems(:,[1 3 2]);

function mdl = bd(mdl)
mdl.boundary = mdl.elems;

function print_mdl_info(mdl, name)
fprintf('=> %20s: %6d nodes, %7d elems\n',name, num_nodes(mdl), num_elems(mdl));

function out = get_cache_path
global eidors_objects
out = [eidors_objects.model_cache filesep 'bp3d-torso'];
if ~exist(out, 'dir')
   mkdir(out);
end