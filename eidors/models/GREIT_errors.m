function imdl= GREIT_errors(imdli, options )
% GREIT_errors: Add Error Compensation to GREIT-type model
% imdl= imdl_errors(imdli, options )
%  imdl - inv_model structure
%
% OPTIONS => {'opt1','opt2'} options are processed in the order specified
% if OPTIONS is char, treated as first option
%
% Available options are:
%
% 'Channel=[list]';   
%
% See also: select_imdl
%
% Model must have a imdl.solve_use_matrix field with RM, M, PJt fields
%  these are created with keep_model_components option to mk_GREIT_model

% (C) 2024 Andy Adler. License: GPL version 2 or version 3
% $Id$

if ischar(imdli) && strcmp(imdli,'UNIT_TEST'); do_unit_test; return; end



function do_unit_test
   for sp=1:9; switch sp
      case 1; [vv,imdl] = test_data(1);
      case 2; [vv,imdl] = test_data(2);
      otherwise; break;
  
      end
      imgr = inv_solve(imdl,vv(:,1),vv(:,end));
      imgr.calc_colours.ref_level = 0;
      subplot(3,3,sp); hh=show_fem(imgr);
      set(hh,'EdgeColor','none');
   end

function [vv,imdl] = test_data(mode);
   fmdl = mk_library_model('adult_male_16el_lungs');
   fmdl.stimulation = mk_stim_patterns(16,1,[0,1],[0,1],{});
   img = mk_image(fmdl,1);
   k=0;for sig = linspace(0.2,0.1,50); k=k+1;
      img.elem_data(vertcat(fmdl.mat_idx{2:3}))=sig;
      vv(:,k) = getfield(fwd_solve(img),'meas');
   end
   imdl = select_imdl(fmdl,{'GREIT:NF=0.3 64x64 rad=0.25'});

   switch mode
      case 1;
      case 2; vv(3,:) = 0.1*randn(size( vv(3,:) ));
      otherwise; error 'huh?'
   end
