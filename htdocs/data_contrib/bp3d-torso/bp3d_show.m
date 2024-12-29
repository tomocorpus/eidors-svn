torso = mk_thorax_model_bp3d('2x16_odd-even','fine');

%%
fmdl = torso.fwd_model;
clf
h = show_fem(fmdl);
ch = get(gca, 'Children');
for i = 1:numel(ch)
   set(ch(i),'EdgeColor','none');
end
set(h,'FaceColor',[.5 .5 .5]);
set(h,'FaceLighting','phong','AmbientStrength',0.7)
light('Position',[1 -.5 0.2],'Style','infinite');
set(h,'FaceAlpha',.3)

hold on

idx   = [   2,    3,    4];
alpha = [   .3,   .3,    1];
color = [  .3     0     0;
           .3     0     0;
           .75    0     0;];

for i = 1:numel(idx)
   obj = rmfield(fmdl,'boundary');
   obj.elems = obj.elems(fmdl.mat_idx{idx(i)},:);
   obj = fix_boundary(obj);
   oh(i) = show_fem(obj);
   set(oh(i),'EdgeColor','none')
   set(oh(i),'FaceColor',color(i,:),'FaceLighting','phong')
   set(oh(i),'FaceAlpha',alpha(i))
end

%oxygenated blood
idx = [5 9:12];
for i = 1:numel(idx)
   obj = rmfield(fmdl,'boundary');
   obj.elems = obj.elems(fmdl.mat_idx{idx(i)},:);
   obj = fix_boundary(obj);
   oh(i) = show_fem(obj);
   set(oh(i),'EdgeColor','none')
   set(oh(i),'FaceColor',[1 0 0],'FaceLighting','phong')
   
end

%de-oxygenated blood
idx = [6:8];
for i = 1:numel(idx)
   obj = rmfield(fmdl,'boundary');
   obj.elems = obj.elems(fmdl.mat_idx{idx(i)},:);
   obj = fix_boundary(obj);
   oh(i) = show_fem(obj);
   set(oh(i),'EdgeColor','none')
   set(oh(i),'FaceColor',[0 0 1],'FaceLighting','phong')
end
axis off
hold off
%%
view(3)
print_convert('torso_colors_01.jpg','-r600')
%%
view(0,0)
print_convert('torso_colors_02.jpg','-r600')
