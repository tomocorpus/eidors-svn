function [thrad,thdeg] = space_electrodes(spacing_type, n_elecs, params);
% space_electrodes: equal spacing of electrodes around body
% [thrad,thdeg] = space_electrodes(spacing_type, n_elecs, params);
%
% OUTPUT: thrad,thdeg = spacing angle (rad,degrees) from centre
%
% INPUT: n_elecs = number of electrodes
%  spacing_type = 'ellipse':
%    params = eliptical radii [r_x r_y]
%  spacing_type = 'ellipse-space':  % space [first,last] around centre
%    params = eliptical radii [r_x r_y]
%
% Usage example:
% ellip= [1.1,0.9];
% [~,thdeg] = space_electrodes('ellipse', 32, ellip);
% fmdl = ng_mk_ellip_models([1,ellip],thdeg*[1,0] + [0,0.5],0.05);

% (C) 2024 Andy Adler . License: GPL v2 or v3.
% $Id$

if ischar(spacing_type) && strcmp(spacing_type,'UNIT_TEST'); do_unit_test; return; end

switch spacing_type
   case 'ellipse';
      thrad = ellip_space_elecs( n_elecs, params );
   case 'ellipse-space';
      thrad = ellip_space_elecs( 2*n_elecs, params );
      thrad(1:2:end) = []; % drop centre electrode
   otherwise
      error('spacing_type not recognized')
end

thdeg = 180/pi*thrad;

% equally space n_elecs around an ellipse of outer radius rad(1),rad(2)
function th = ellip_space_elecs( n_elecs, rad )
   % The radius is the integral of sqrt((r1*sin(th))^2 + (r2*cos(th))^2)
   %  This integral is the incomplete_elliptic_integral(th, 1-r2/r1)*sqrt(r1)
   %  Unfortunately, STUPID MATLAB, doesn't have incomplete elliptic integrals
   %  by default. So, rather than install a toolkit for it, we integrate numerically.
   if n_elecs==0; th=[]; return; end
   
   th = linspace(0,2*pi, 1000*(n_elecs)); th(1)=[]; % Accuracy to 100x spacing
   len = cumsum( sqrt( rad(1)*cos(th).^2 + rad(2)*sin(th).^2 ) );
   len = len/max(len);
   xi = linspace(0,1,n_elecs+1); xi(1)= []; xi(end)=[];
   yi = interp1(len,th,xi);

   th= [0;yi(:)];
   for exact = 0:3;
      eth = exact/2*pi;
      ff = abs(th-eth)<1e-3;
      th(ff) = eth;
   end


function do_unit_test
  th = space_electrodes('ellipse',16,[1,1]); 
  unit_test_cmp('circle', th(1), 0, 1e-14);
  unit_test_cmp('circle', diff(th), 2*pi/16, 1e-14);

  th = space_electrodes('ellipse',16,[1,2]); 
  unit_test_cmp('ellipse [1,2]', th(1), 0, 1e-14);
  unit_test_cmp('ellipse [1,2]', [th(1), min(diff(th)) max(diff(th))], ...
        [ 0   0.340861236200482   0.462219163446295 ], 1e-14);

  [~,th] = space_electrodes('ellipse-space',16,[1,2]); 
  unit_test_cmp('ellipse-space [1,2]', mean([th(1),th(end)-360])/360, 0, 1e-6);
  
  unit_test_cmp('ellipse-space [1,2]', th(1), 13.555876019146920, 1e-14);

  ellip= [2,1];
  [~,thdeg] = space_electrodes('ellipse', 32, ellip);
  fmdl = ng_mk_ellip_models([1,ellip],thdeg*[1,0] + [0,0.5],0.05);
  for i=1:num_elecs(fmdl);
    ctr(i,:) = mean(fmdl.nodes(fmdl.electrode(i).nodes,:));
  end
  dist = rssq(ctr,2);
dist
