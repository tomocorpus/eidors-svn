mdlh = mk_thorax_model('bp3d',[-135 1280; -50 1100],[110 80 2],25);
mdl = mk_thorax_model('bp3d-organs',[-135 1280; -50 1100],[110 80 2],25);
%%
mdl.fwd_model.stimulation = stim_meas_list([1 2 1 2]);
mdl.fwd_solve.get_all_nodes = true;
vh = fwd_solve(mdl);
current = calc_elem_current(mdl, vh.volt);
%%
[~,~,~,opt] = define_voxels(mdl,'zlim',[1000, 1380],'imgsz',128);
img = mk_image(mdl.fwd_model, current);
[val, point2tet] = calc_grid_points(img, opt.x_pts, opt.y_pts, opt.z_pts);
%%
vabs = vecnorm(val,2, 4);

histogram(log10(vabs(:)))
[x,y,z] = meshgrid(opt.y_pts, opt.x_pts, opt.z_pts);
vabs(isnan(vabs)) = 0;
isosurface(x,y,z,vabs,0.2e-4)
axis equal
%%
lv = log10(1e6*vabs);
lv(lv<0) = 0;
volumeViewer(lv/max(lv(:)));
%%
hidx = mdl.fwd_model.mat_idx{4};
heart = img;
heart.fwd_model.elems = img.fwd_model.elems(hidx,:);
abs_current = vecnorm(current,2,2);
% make better units (defibrillation current = 30 A)
abs_current = abs_current * 30 * 1e6; % micro amps now
heart.elem_data = abs_current(hidx);
heart.fwd_model = fix_boundary(heart.fwd_model);

%% Make surface model
fmdl = fix_model(heart.fwd_model, struct('face2elem',1,'boundary_face',1));
srf.type = 'fwd_model';
srf.nodes = fmdl.nodes;
srf.elems = fmdl.boundary;
el_idx = fmdl.face2elem(fmdl.boundary_face,1);
himg = mk_image(srf, heart.elem_data(el_idx));

%%
try, img = rmfield(himg, 'calc_colours'); end
himg.calc_colours.transparency_thresh = -1;
himg.calc_colours.cmap_type = turbo(254);
clf
h = show_fem(himg);
light('Position',[1 -.5 0.2],'Style','infinite')
ch = get(gca,'Children');
set(ch(3),'FaceLighting','phong','AmbientStrength',0.7);
axis off
axis tight
eidors_colourbar(himg,[],[1 .5 .1])

print_convert('cardioversion_heart.jpg','-r300')
