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
org = get_organ_models;
tri.vertices = torso.nodes;
tri.faces = torso.boundary;
for o = fields(org)
   N = size(tri.vertices, 1);
   tri.vertices = [tri.vertices; org.(o{1}).nodes];
   tri.faces = [tri.faces; N + org.(o{1}).boundary(:,[1 3 2])];
end

shell = gmsh_stl2tet(tri);
shell.mat_idx = {1:uint32(size(shell.elems,1))};

if isfield(torso, 'electrode') && ~isempty(torso.electrode)
   for i = 1:numel(torso.electrode)
      electrode(i).nodes = torso.nodes(torso.electrode(i).nodes,:);
   end
   shell = restore_electrodes(shell, electrode, 0.01);
end
cslist = @(CA) CA{:};
out = merge_meshes(shell, cslist(struct2cell(org)));
out.mat_names = {'shell'};
for o = fields(org)
   out.mat_names = [out.mat_names, org.(o{1}).mat_names];
end
   

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
   org_path = get_contrib_data('bp3d-torso','bp3d_organs.mat');
   srf = load(org_path, 'heart','blood_left','blood_right');
   wall = srf.heart;
   for org = {'blood_left','blood_right'}
      n_nodes = num_nodes(wall);
      wall.nodes = [wall.nodes ; srf.(org{1}).nodes];
      % re-order the triangles to flip the normals
      wall.elems = [wall.elems ; srf.(org{1}).elems(:,[1 3 2]) + n_nodes];
   end
   eidors_msg('This takes a REALLY long time');
   tet_wall = gmsh_stl2tet(wall);
   blood_left = gmsh_stl2tet(srf.blood_left);
   blood_right = gmsh_stl2tet(srf.blood_right);
   
   organ.heart_blood = merge_meshes(tet_wall,blood_left, blood_right);
   organ.heart_blood = fix_boundary(organ.heart_blood);
   organ.heart_blood.mat_names = {'wall', 'blood_left', 'blood_right'};
   
   save(fpath, 'organ');
else
   load(fpath, 'organ');
end

function out = get_cache_path
global eidors_objects
out = [eidors_objects.model_cache filesep 'bp3d-torso'];
if ~exist(out, 'dir')
   mkdir(out);
end