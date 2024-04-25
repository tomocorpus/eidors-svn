function out = mk_thorax_model_bp3d(varargin)
%MK_THORAX_MODEL_BP3D
% mk_thorax_model_bp3d()
% mk_thorax_model_bp3d(elec_pos, elec_shape)
% mk_thorax_model_bp3d(elec_pos, elec_shape, maxh)
% mk_thorax_model_bp3d(stimpat)
% mk_thorax_model_bp3d(__, organspec)
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
% See also MK_THORAX_MODEL

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
      if ischar(varargin{1})
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
out = gmsh_stl2tet(torso);


function out = build_predef_elecs(elecstr)
if ~isempty(elecstr)
   eth16 = 360*cumsum([0.2 0.4*ones(1,7) 0.5 0.4*ones(1,7)])/6.5 - 90; eth16 = eth16';
   ep = eth16; ep(:,2) = 1150;
   out = mk_thorax_model('bp3d',ep,[10 0 2],20);
end

function out = add_organs(torso, organspec)
organs = get_organ_models;
tri.vertices = torso.nodes;
tri.faces = torso.boundary;
N = size(tri.vertices, 1);
tri.vertices = [tri.vertices; organs.nodes];
tri.faces = [tri.faces; N + organs.boundary(:,[1 3 2])];

shell = gmsh_stl2tet(tri);

if isfield(torso, 'electrode') && ~isempty(torso.electrode)
   for i = 1:numel(torso.electrode)
      electrode(i).nodes = torso.nodes(torso.electrode(i).nodes,:);
   end
   shell = restore_electrodes(shell, electrode, 0.01);
end

out = merge_meshes(shell, organs);
out.mat_names = ['body' organs.mat_names];
out.boundary = out.show_boundary;
out = rmfield(out, 'show_boundary');
   
idx = strcmp(out.mat_names,'Trachea');
out = remove_elems(out, out.mat_idx{idx});

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

function organ = get_organ_models
organ = struct();
cache_path = get_cache_path;
fname = 'bp3d_organs.mat';
fpath = [cache_path filesep fname];
if ~exist(fpath, 'file')
   eidors_msg('This takes a REALLY long time');
   organs = mk_organs;
   save(fpath, 'organs');
else
   load(fpath, 'organs');
end

function mdl = mk_organs

start_time = now(); 
organs = mk_individual_organs;
mdl = assemble_organs(organs);
mdl.show_boundary = mdl.boundary;
mdl = fix_boundary(mdl);

%  cashed results are not useful outside
eidors_cache('clear_old', start_time);

function mdl = assemble_organs(organs)
pcs = struct();

vessels = {'Aorta','IVC','SVC','PA', 'LSPV', 'LIPV','RSPV','RIPV'};
for i = 1:numel(vessels)
    v = vessels{i};
    disp(v)
    pcs.(v) = merge_meshes(organs.(v), organs.(['Blood' v]),1e-2);
    pcs.(v).mat_names = {v; ['Blood' v]};
end

left = merge_meshes(organs.LungLeft, ...            
                    pcs.LSPV, ...
                    pcs.LIPV, ...
                    1e-2);
left.mat_names = vertcat({'LungLeft'},pcs.LSPV.mat_names, pcs.LIPV.mat_names);

right = merge_meshes(organs.LungRight, ...            
                     pcs.RSPV, ...
                     pcs.RIPV, ...
                     1e-2);
right.mat_names = vertcat({'LungRight'},pcs.RSPV.mat_names, pcs.RIPV.mat_names);

heart = merge_meshes(organs.HeartWall, ...
                     organs.BloodLeftHeart, ...
                     organs.BloodRightHeart, ...
                     1e-2);
heart.mat_names = {'HeartWall';'HeartBloodLeft'; 'HeartBloodRight'};

mdl = merge_meshes(heart, left, right, 1e-2);
mdl.mat_names = vertcat(heart.mat_names, left.mat_names, right.mat_names);

mdl = merge_meshes(mdl, ...
                  pcs.PA, ...
                  pcs.Aorta, ...
                  pcs.SVC, ...
                  pcs.IVC, ...
                  1e-2);
mdl.mat_names = vertcat(mdl.mat_names, pcs.PA.mat_names,pcs.Aorta.mat_names, ...
                        pcs.SVC.mat_names, pcs.IVC.mat_names);

mdl = merge_meshes(mdl, organs.Trachea, 5e-2);
mdl.mat_names{end+1} = 'Trachea';

function organs = mk_individual_organs
org_path = get_contrib_data('bp3d-torso','bp3d_organs.mat');
srf = load(org_path);

vessels = {'Aorta','IVC','SVC','PA', 'LSPV', 'LIPV','RSPV','RIPV'};
for i = 1:numel(vessels)
    v = vessels{i};
    disp(v)
    [vessel, blood] = eidors_cache(@mk_vessel, srf.(v));
    organs.(v) = vessel;
    b = sprintf('Blood%s', v);
    organs.(b) = blood;
end

organs.Trachea = gmsh_stl2tet(srf.Trachea);
organs.LungLeft = gmsh_stl2tet(srf.LungLeft);
organs.LungRight = gmsh_stl2tet(srf.LungRight);

left = eidors_cache(@mk_blood_left_surf,srf);
organs.BloodLeftHeart = gmsh_stl2tet(left);

right = eidors_cache(@mk_blood_right_surf,srf);
organs.BloodRightHeart = gmsh_stl2tet(right);

heart = eidors_cache(@mk_heart_surf, srf);
organs.HeartWall = gmsh_stl2tet(heart);

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


function out = get_cache_path
global eidors_objects
out = [eidors_objects.model_cache filesep 'bp3d-torso'];
if ~exist(out, 'dir')
   mkdir(out);
end