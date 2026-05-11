function [meshptr, xpts, ypts, zpts] = grid_imdl_mapper(imdl);
% grid_imdl_mapper: Maps an xyz grid-based imdl onto voxels
% 
% Inputs:
%   imdl: inv_model of a 3D (or 2D) reconstruction onto a grid-geometry
%
% Outputs:
%   x-, y-, zpts: vector of x,y,z centres of the grid elements
%   meshptr: 3D (or 2D) array of ptrs into the volume
%     meshptr == 0 => elements outside the model
%     meshptr >= 1 => Corresponding parameter element
%
% Usage
%   imgr = inv_solve( ... % inverse solve: parameters on mesh
%   parmap = [NaN;imgr.elem_data] % map Nan outside mesh
%   vol = parmap(meshptr+1); % vol is 3D voxel data

% (C) 2026 Andy Adler.  License: GPL version 2 or version 3
% $Id:
  if ischar(fmdl) && strcmp(fmdl,'UNIT_TEST'); do_unit_test; return; end
     
  rec_model = imdl.rec_model;
  c2f = rec_model.coarse2fine;
  fac = size(c2f,1)/size(c2f,2); % simlex per grid element 6 for 3D, 2 for 2D
  xyz = c2f'*interp_mesh(rec_model)/fac;
  if size(xyz,2)==2; xyz(:,3) = 0; end % set 2D as 3D at z=0
  tol = 1e-12; % just a guess but prevent unique from generating too many samples
  xpts = uniquetol(xyz(:,1),tol);
  ypts = uniquetol(xyz(:,2),tol);
  zpts = uniquetol(xyz(:,3),tol);
  [x,y,z] = ndgrid(xpts,ypts,zpts);
  xyzgrid = [x(:),y(:),z(:)];
  meshptr = zeros(size(x));
  for i=1:size(xyz,1);
    ff = all(xyz(i,:) == xyzgrid,2);
    ff = find(ff);
    assert( length(ff) == 1 );
    meshptr(ff) = i;
  end

function do_unit_test;
