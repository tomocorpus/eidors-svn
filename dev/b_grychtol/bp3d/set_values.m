img = mk_image(torso, 1);
for i = 2:numel(torso.mat_idx)
    if strcmp(torso.mat_names{i},'HeartWall')
        img.elem_data(torso.mat_idx{i}) = 1.5;
    elseif strcmp(torso.mat_names{i},'Trachea')
        img.elem_data(torso.mat_idx{i}) = NaN;
    elseif ~isempty(strfind(torso.mat_names{i}, 'Blood'))
        img.elem_data(torso.mat_idx{i}) = 2;
    elseif ~isempty(strfind(torso.mat_names{i}, 'Lung'))
        img.elem_data(torso.mat_idx{i}) = .5;
    else % vessel
        img.elem_data(torso.mat_idx{i}) = .8;
    end
end


%%
show_fem_enhanced(img);
axis off
%%
img.fwd_model.show_fem.alpha_inhomogeneities = 0.1;
ing.calc_colours.transparency_thresh = 0.2;
img.calc_colours.ref_level = 1;
hh = show_fem(img);
set(hh,'edgecolor','none','facecolor','k','facealpha',.2);
set(gcf,'color','w')
axis off
view(3)
print_convert('torso_show_fem_transparent.jpg','-r300');

%%
angle = linspace(0,360,121); angle(end) = [];
fname = 'torso.gif';
for i = 1:numel(angle)
    view([angle(i), 30]);
%     show_fem_enhanced('refresh')
%     zlim([min(zpts)-10, max(zpts)+10]);
    drawnow
    F(i) = getframe(gcf);
    im = frame2im(F(i));
    [imind,cm] = rgb2ind(im,256);
          % Write to the GIF File 
      if i == 1 
          imwrite(imind,cm,fname,'gif', 'Loopcount',inf,'DelayTime',0.1); 
      else 
          imwrite(imind,cm,fname,'gif','WriteMode','append','DelayTime',0.1); 
      end 
end

%%
img = set_slice(img, [inf inf 1200], [128 0]);
ing.calc_colours.transparency_thresh = 0.2;
show_slices(img, [inf inf 1200])
set(gca,'ydir','reverse')
print_convert('torso_calc_slices.png')

%%
show_3d_slices(img, [1150,1200,1250],[20, 60],[-90]);
axis off
print_convert('torso_show_3d_slices.png','-r300')