% thorax image with organs
img = mk_thorax_model_bp3d('','fine');
% high voxel resolution, but no partial volume calculation (slow)
V = calc_voxels(img, struct('imgsz',256)); 
%%
% set global values so that all calls to show_slices use the same scaling
calc_colours('ref_level',1);
calc_colours('clim',1)


M = mk_mosaic(V(:,:,[120:12:152]),0,[],1);
show_slices(M);
print_convert('view_3d_01a.png');

show_slices(flipud(squeeze(V(33,:,:))'))
print_convert('view_3d_01b.png');
show_slices(flipud(squeeze(V(:,70,:))'))
print_convert('view_3d_01c.png');
%% image processing toolbox
% Need zeros outside the volume
nanidx = isnan(V); V(nanidx) = 0; 

cmap = calc_colours('colourmap');
%%
vol = volshow(flip(V,1),'Colormap',cmap,RenderingStyle="MaximumIntensityProjection");
exportapp(vol.Parent.Parent,'view_3d_02a.png');
%%
% viewer with a slider
sv = sliceViewer(V);
exportgraphics(sv.getAxesHandle,'view_3d_02b.png'); % doesn't export UI components
%%
volumeViewer(flip(V,1));
% there seems to be no way to export the figure programmatically. 
% We captured a window snapshop (view_3d_02c.png).