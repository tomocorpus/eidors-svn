function mdl = mk_organs

start_time = now(); 
organs = mk_individual_organs;
mdl = assemble_organs(organs);
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
% org_path = get_contrib_data('bp3d-torso','bp3d_organs.mat');
% srf = load(org_path);
srf = load('bp3d_organs.mat');

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

