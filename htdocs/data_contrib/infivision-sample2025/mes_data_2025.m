pth = '~/data/2025/Infivision/Healthy_Lung_Breate_Hold.mes';
[vv, aux, stim] = eidors_readdata(pth);
FR = aux.frame_rate;
fmdl= mk_library_model('adult_male_32el');
fmdl.electrode = fmdl.electrode(32:-2:2);
fmdl.frame_rate = FR;
img = mk_image(fmdl, 1); % background conductivity

img.fwd_model.stimulation = stim;
opt.imgsz = [121 81];
opt.distr = 3; % non-random, uniform
opt.Nsim = 500; % 500 hundred targets to train on, seems enough
opt.target_size = 0.02; %small targets
opt.target_offset = 0.01;
opt.noise_figure = .28; % this is key!
opt.square_pixels = 1;
imdl=mk_GREIT_model(img, 0.2, [], opt);
imdl.fwd_model.meas_select = aux.msel;
%%
imgr= inv_solve(imdl, mean(vv,2), vv);
[imgr.ROIs,imgR] = define_ROIs(imdl,[-9,9],[-9,0,9],struct('normalize',1));
imgr = subtract_rank(imgr,0.96);
imgr.calc_colours.ref_level = 0;
imgr.calc_colours.greylev = .1;
imgr.calc_colours.backgnd = [1,1,1];
idx = 30;
subplot(211);
plot(imgr.time, -imgr.ROIs*imgr.elem_data,'LineWidth',1);
box off; legend('D','V')
fs = [107,111; 227,231]; vertlines(fs);
cols = 10;
for sp = 1:size(fs,1); subplot(4,1,sp+2);
  fs_ = fs(sp,:);
  imgr.get_img_data.frame_select = round(linspace(fs_(1),fs_(2),cols)*FR);
  imgr.show_slices.img_cols = cols;
  show_slices(imgr);
end

print_convert Healthy_Lung_Breate_Hold.jpg -p20x8
