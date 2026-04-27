function imgs= EIT_intro(fig, prm)
% EIT_intro: Create a set of EIT images from the "Wikipedia EIT baby" contributed data set
% (c) 2020-2026 Andy Adler. Licenced under GPL v2 or v3
% $Id$
   if nargin==0; 
     mk_figure1;
     mk_figure2;
     mk_figure3;
     mk_figure4;
     mk_figure5;
     backprojection_show();
   end


   switch fig; 
      case 'baby_fem'; imgs = baby_fem();
         imgs.calc_colours.ref_level = 1;
      case 1;   mk_figure1
      case 2;   mk_figure2
      case 3;   mk_figure3
      case 4;   mk_figure4
      case 4.1; mk_figure4a
      case 4.2; mk_figure4b
      case 5;   mk_figure5
      case 6;
        fig_with_reconstruction_sensitivity(1.8, [0.15,0.45], [1,2,12,13],2.5);
        !mv contour.pdf contour1213.pdf
        fig_with_reconstruction_sensitivity(1.8, [0.15,0.45], [1,2,10,11],1);
        !mv contour.pdf contour1011.pdf
        print_convert equipotential.jpg
      case {7,'baby_backproj'}; 
         backprojection_show();
      case 'fig_with_equipotential'
         imgs= equipotential_slice(prm{1},prm{2},prm{3});
      case 'fig_sensitivity'
         imgs= sensitivty_slice(prm{1},prm{2},prm{3});
      case 'basic_fem'
         imgs= basic_fem(prm{1},prm{2});
      otherwise; error('huh?')
   end

function mk_figure1 % baby FEM image
    img = baby_fem(2.1);
    mi = img.fwd_model.mat_idx;
    img.elem_data(mi{2}) = 0.55;
    img.elem_data(mi{3}) = 1.5;
    opt.viewpoint = struct('az',1,'el',-35);
    opt.edge.width = 0;
    opt.edge.significant.color = [139,69,19]/256;
    img.calc_colours.ref_level= 0.95;
    img.calc_colours.clim= 1;
     show_fem_enhanced(img,opt);
    axis off
    print_convert baby_fem.jpg

function mk_figure2 % heart bigger and smaller
    for fn = 1:2; switch fn
        case 1; img = baby_fem([2.1,0.15,0.45],0.8);
        case 2; img = baby_fem([2.1,0.2 ,0.40],0.8);
        end    
        figure(fn)

        mi = img.fwd_model.mat_idx;
        img.elem_data(mi{2}) = 0.55;
        img.elem_data(mi{3}) = 1.5;
        opt.viewpoint = struct('az',1,'el',-35);
        opt.edge.width = 0;
        opt.edge.significant.color = [139,69,19]/256;
        img.calc_colours.ref_level= 0.95;
        img.calc_colours.clim= 1;
        show_fem_enhanced(img,opt);
        axis off
        print_convert(sprintf('baby_heart%d.jpg',fn))
    end

function mk_figure3 % Figure with Equipotentials
    fig_with_equipotential(1.8,[0.15,0.45],[1,6,1,6])
    print_convert equip1_diastole.jpg
    fig_with_equipotential(1.8,[0.2 ,0.40],[1,6,1,6])
    print_convert equip1_systole.jpg
    fig_with_equipotential(1.8,[0.15,0.45],[16,5,1,6])
    print_convert equip2_diastole.jpg
    fig_with_equipotential(1.8,[0.2 ,0.40],[16,5,1,6])
    print_convert equip2_systole.jpg

function [img,opt] = basic_fem(zlevel,heart);
    img = baby_fem([zlevel,heart]);
    img.fwd_model.nodes(:,3) = img.fwd_model.nodes(:,3) + zlevel;
    mi = img.fwd_model.mat_idx;
    img.elem_data(mi{2}) = 0.50;
    img.elem_data(mi{3}) = 1.5;
    opt.viewpoint = struct('az',1,'el',-75);
    opt.edge.width = 0;
    opt.edge.significant.color = [139,69,19]/256;

    img.calc_colours.ref_level= 0.95;
    img.calc_colours.clim= 2;
    img.opt = opt;
    if nargout > 0; return ; end
    show_fem_enhanced(img,opt);
    cmap = colormap;
    cmap = cmap(1:end-3,:);
    cmap(140:end,1) = cmap(140:end,1:2)*[1;1]/1.5;
    cmap(140:end,2) = cmap(140:end,2)/3;
    img.calc_colours.cmap_type= cmap;
    show_fem_enhanced(img,opt);

function fig_with_equipotential(zlevel, heart, ssmm)
    clf
    imgs = equipotential_slice(zlevel,heart, ssmm);
    show_slices(imgs);
    hh= get(gca,'Children');
    delete(hh(2))
    hold on
    basic_fem(zlevel,heart);
    hold off
    axis off

function [img, vv, S] = baby_model_sims(img,ssmm);
    mi = img.fwd_model.mat_idx;
    img.elem_data(mi{2}) = 0.3;
    img.elem_data(mi{3}) = 2.0;
    img.fwd_model.stimulation = stim_meas_list(ssmm, num_elecs(img));
    img.fwd_solve.get_all_nodes = true;
    vv= fwd_solve(img);
    J = calc_jacobian(img);
    S = J./get_elem_volume(img)';

function img = equipotential_slice(zlevel,heart,ssmm)
    img = baby_fem([zlevel+0.1,heart]);
    [img, vv] = baby_model_sims(img,ssmm);
    img = rmfield(img,'elem_data');
    img.node_data = vv.volt;
    img = img_slice(img, zlevel);

function img = img_slice(img, zlevel)
    msm = struct('level', [inf,inf,-zlevel], ...
           'x_pts', linspace(-1.2,1.2,101), ...
           'y_pts', linspace(-0.8,0.8,101));

    img.show_slices.axes_msm= true;
    img.fwd_model.mdl_slice_mapper = msm;
    img.show_slices.contour_levels = 20;
    img.show_slices.contour_properties = {'Color',[0,0,0],'LineWidth',2};
    img.calc_colours.backgnd= [1,1,1];

function fig_with_reconstruction_sensitivity(zlevel, heart_cut, ssmm, fac)
    img = baby_fem([zlevel+0.1,heart_cut]);
    img.elem_data(:) = 1.0;
    img.fwd_model.stimulation = stim_meas_list(ssmm, num_elecs(img));
    J= calc_jacobian(img);
    J = J'./get_elem_volume(img);
    img.elem_data = J;
    filt = ones(3); filt = conv2(filt,filt); filt = filt/sum(filt(:));
    img.calc_slices.filter = conv2(filt,filt);
    img = img_slice(img, zlevel);

% Don't need the imdl
%   imdl = GREIT_from_img(img, {[0,1],[0,1]}); 

    img.show_slices.contour_levels = max(J)*[5,10,15]/1000/fac;
    show_slices(img);
%   img.elem_data = imdl.solve_use_matrix.RM(:,5);

    hh= get(gca,'Children');
    delete(hh(2))
    zz = get(hh(1),'ZData'); 
    z0 = zz; z0(isnan(z0))= 0;
    set(hh(1),'ZData',z0);
    print -dpdf -vector contour.pdf
    set(hh(1),'ZData',zz);
    hold on
    basic_fem(zlevel,heart_cut);
    hold off
    axis off

function fig_with_sensitivity(zlevel, heart, ssmm)
    clf
    imgs = sensitivty_slice(zlevel,heart, ssmm);
    show_slices(imgs);
    hh= get(gca,'Children');
    delete(hh(2))
    hold on
    basic_fem(zlevel,heart);
    hold off
    axis off


function img = sensitivty_slice(zlevel,heart,ssmm)
    img = baby_fem([zlevel+0.1,heart]);
    mi = img.fwd_model.mat_idx;
    img.elem_data(mi{2}) = 0.3;
    img.elem_data(mi{3}) = 2.0;
    img.elem_data(:) = 1.0; %%% new
    img.fwd_model.stimulation = stim_meas_list(ssmm, num_elecs(img));
    J= calc_jacobian(img);
    J = J'./get_elem_volume(img);
    img.elem_data = J.*img.elem_data;
    img.elem_data = J;
    filt = ones(5); filt = filt/sum(filt(:));
    img.calc_slices.filter = conv2(filt,filt);
    img = img_slice(img, zlevel);

function fig_with_image(zlevel, heart)
    clf
    [img,opt] = basic_fem(zlevel,heart);
    opt.viewpoint.el = -70;
    th = 35*pi/180;
    rot = [cos(th), sin(th); -sin(th), cos(th)];
    img.fwd_model.nodes(:,[1,3]) = ...
    img.fwd_model.nodes(:,[1,3])*rot;
    colormap(gray(256));
    img.elem_data(img.fwd_model.mat_idx{3}) = 1;
    show_fem_enhanced(img,opt);
    cmap = colormap;
    axis off
    imgs = reconst_images;
    imgs.fwd_model.electrode(:) = [];
    imgs.fwd_model.nodes(:,1) = -imgs.fwd_model.nodes(:,1);
    imgs.fwd_model.nodes(:,[1,3]) = ...
    (imgs.fwd_model.nodes(:,1)*[1,0])*rot - [0,0.01];

    th = linspace(0,2*pi,51);
    imgc = imgs;
    hold on
    for i = 0:5;
        xofs = i*0.8;
        imgc.elem_data = imgs.elem_data(:,66+i);
        
        imgc.fwd_model.nodes(:,1) = ...
        imgs.fwd_model.nodes(:,1) + xofs;
        set(show_fem(imgc),'EdgeAlpha',0);
        K=1.02;
        plot3(K*1.2*rot(1,1)*cos(th) + xofs + .02, ...
              K*0.8*sin(th), ...
              K*1.2*rot(1,2)*cos(th),'k', 'LineWidth',2)
    end
    hold off
    colormap(cmap)
    print_convert image_sequence.jpg
%figure(2);show_slices(imgs);

function imdl = GREIT_from_img(img, pats); 
    fmdl = mdl_normalize(img.fwd_model,1);
    [fmdl.stimulation,fmdl.meas_select] = mk_stim_patterns(16,1,pats{:});

    opt.imgsz = [64 64]; opt.noise_figure = 0.4;
    imdl = mk_GREIT_model(fmdl, 0.25, [], opt);

function imgs = reconst_images
    unzip(get_contrib_data('if-neonate-spontaneous','if-neonate-spontaneous.zip'))
    img = baby_fem(3.0);
    imdl = GREIT_from_img(img, {'{ad}','{ad}'});

    vv= eidors_readdata('P04P-1016.get'); vi=vv; vh=vv(:,61);
    imgs = inv_solve(imdl,vh,vi);
    imgs.calc_colours.ref_level = 0;
    imgs.calc_colours.clim = 10;
    imgs.calc_colours.transparency_thresh =0;

function mk_figure4a
    fig_with_sensitivity(1.8,[0.15,0.45],[1,3,8,10])
    print_convert equipotentiala.png

function mk_figure4b
    fig_with_sensitivity(1.8,[0.15,0.45],[1,2,8,9])
    print_convert equipotentiala.png
    
function mk_figure4
    fig_with_sensitivity(1.8,[0.15,0.45],[1,6,8,10])
    print_convert equipotential.png

function mk_figure5
    fig_with_image(1.6,[0.15,0.45])
    print_convert equipotential.png
     
function img = baby_fem(hcut, topcut);
    if nargin==0; hcut = 2.0; end
    if length(hcut)==1; hcut(2:3) = [0.15,0.45]; end
    if nargin<=1; topcut = 0.0; end
    hcut0 = hcut(1);
    extra={'lungs', 'heart', 'arms', sprintf([ ...
       'solid mainobj_bot= plane(0,0,%f;0,0,-1) -maxh=0.02;' ...
       'solid top= plane(0,0,%f;0,0,-1) -maxh=0.02;' ...
       'solid llung = ellipsoid(-0.40,-0.05,1.5;0,0,1.2;0,0.6,0;0.55,0,0);' ...
       'solid rlung = ellipsoid( 0.40,-0.05,1.5;0,0,1.2;0,0.6,0;0.55,0,0);' ...
       'solid lbot = plane(0,0,%f;0,0,1) and top;'  ...
       'solid heart_= sphere(0.1, %f,1.8;%f) -maxh=0.05;' ...
       'solid heart= heart_ and lbot;' ...
       'solid lungs= (llung or rlung) and lbot and not heart_;' ...
       'solid lcut= plane(-1,0,2;-3,0, 1);' ...
       'solid larm= cylinder(0,0,-2;-1,0,0;0.4);' ...
       'solid larm_= larm and top and lcut;' ...
       'solid rcut= plane( 1,0,2; 3,0, 1);' ...
       'solid rarm= cylinder(0,0,-1; 1,0,0;0.4);' ...
       'solid rarm_= rarm and top and rcut;' ...
       'solid arms= larm_ or rarm_;' ...
           ], topcut*[1,1], hcut)};
    ng_write_opt('MSZZPLANE',[0,0,1.6,1.2,.01], ...
                 'MSZZPLANE',[0,0,1.4,1.2,.01], ...
                 'MSZZPLANE',[0,0,1.8,1.2,.01]);
    fmdl= ng_mk_ellip_models([hcut0,1.2,0.8], ...
              [16,1.5],[0.2,0.4,0.06],extra); 
    fmdl.nodes(:,3) = -fmdl.nodes(:,3);
    img= mk_image(fmdl, 1);
    img.elem_data(fmdl.mat_idx{2}) = 0.6;
    img.elem_data(fmdl.mat_idx{3}) = 1.5;


function backprojection_show();
    zmid = .05;
    ng_write_opt('MSZZPLANE',[0,0,zmid,1,0.1]);
    extra = {'ball',sprintf('solid ball = sphere(0.18,0.24,%f;0.04);',zmid)};
    Baby_Ellip = [1.15,0.85];
    fmdl = ng_mk_ellip_models([2*zmid,Baby_Ellip],[16,zmid],[.05, zmid*2, .01],extra);
    fmdl.nodes(:,1) = -fmdl.nodes(:,1);
    fmdl.mdl_slice_mapper.npoints = 100; %calc_colours('npoints');
    fmdl.mdl_slice_mapper.level = [inf,inf,zmid]; 
    fmdl.stimulation = mk_stim_patterns(16,1,[0,1],[0,1]);
    imdl = select_imdl(fmdl,{'Basic GN dif'}); imdl.hyperparameter.value = .0005;
%   imdl = select_imdl(fmdl,{'GREIT:NF=1 32x32'});

    ball = fmdl.mat_idx{2};
    show_backprojections(fmdl,imdl,ball)
    th=linspace(0,2*pi,101);
    MAG = 50.5;
    plot(sin(th)*MAG+MAG, ...
         cos(th)*MAG*Baby_Ellip(2)/Baby_Ellip(1)+MAG,'k','LineWidth',2);
    view(0,-70);
    print_convert backprojection_show.jpg

function show_backprojections(fmdl,imdl,ball);
  USE_REC_MODEL = 0;
  imgs = mk_image(fmdl,1);    vh = fwd_solve(imgs);
  imgs.elem_data(ball) = 1.1; vi = fwd_solve(imgs);
  vx = vh.meas + diag( vi.meas - vh.meas ); 
  if USE_REC_MODEL
  imdl.rec_model = mdl2d_from3d(fmdl);
  imdl.rec_model.mdl_slice_mapper = struct('level', [inf,inf,0], ...
           'x_pts', linspace(-1.2,1.2,101), ...
           'y_pts', linspace(-0.8,0.8,101));
  imdl.fwd_model.coarse2fine = mk_coarse_fine_mapping(fmdl,imdl.rec_model);
  end
  imdl.solve = @inv_solve_diff_GN_one_step;
  ied = getfield(inv_solve(imdl,vh,vx),'elem_data');
  ball = fmdl.mat_idx{2};
  xyz = interp_mesh(fmdl);
  xyz = mean(xyz(ball,:));
  if USE_REC_MODEL
  rmdl = imdl.rec_model;
  else
  rmdl = fmdl;
  end
  els = elem_select(rmdl,@(x,y,z) ...
     (x-xyz(1)).^2 + ...
     (y-xyz(2)).^2 < .01^2);
  fied = sum(ied(find(els),:));
  [~,most] = sort(abs(fied));
  idx = most(end-(0:2:20));

  cla; hold on;
  vh = ones(208,1);
  THR=0.45;
% for idxi = length(idx):-1:1;
  for idxi = 1:4
    vi_= vh; vi_(idx(idxi)) = vi.meas(idx(idxi));
    img = inv_solve(imdl,vh,vi_);
    lev = THR*max(img.elem_data);
    img.elem_data(img.elem_data< THR*lev)=0;
    img.calc_colours.ref_level = 0;
    img.calc_colours.backgnd = [1,1,1];
    img.calc_colours.greylev = -.1;
    img.calc_slices.filter = ones(5)/9;
    img.show_slices.contour_levels = [1,1]*0.5*lev;
    img.show_slices.contour_properties = {'LineWidth',2,'Color',[0,0,0]};
%   img.show_slices.axes_msm = true;
    rimg = calc_slices(img);
    rimg = calc_colours(rimg,img);
    rimg(rimg==128)=1;
    mask = (rimg>128) -  bwareaopen(rimg>128,150);
    rimg(~mask)=1;
    
    elem_ptr = mdl_slice_mapper( rmdl, 'elem');
    img.elem_data( elem_ptr(find(mask)) ) = 0;
    show_slices(img);
    set(gca,'YDir','reverse','XDir','reverse');
  end
  hh=get(gca,'Children');
  set(hh(2:2:end),'AlphaData',0.2);
