function point2tet = point_in_tet(fmdl,points, epsilon, exclude_nodes)
%POINT_IN_TET test for points contained in elements
% point2tet = point_in_tet(fmdl,points, epsilon, exclude_nodes)
%
%   fmdl: tet mesh to test against
%   points: [x,y,z] of points to test
%   tolerance: typically eps
%   exclude_nodes: nodes to exclude
%
%   fmdl.point_in_tet.algorithm: specify approach
%     e.g. fmdl.point_in_tet.algorithm = 'do_point_in_tet_inequalities'
%   
% point2tet: sparse matrix Npoints x Ntets 
%
% (C) 2015 Bartlomiej Grychtol
% License: GPL version 2 or 3
% $Id$

if nargin>=1 && ischar(fmdl) && strcmp(fmdl,'UNIT_TEST'); do_unit_test(); return; end

if nargin < 4
    exclude_nodes = false;
end

copt.fstr = 'point_in_tet';
copt.cache_obj = {fmdl.nodes, fmdl.elems, points, epsilon, exclude_nodes};
ver = eidors_obj('interpreter_version');
try 
   calc_fn= str2func(fmdl.point_in_tet.algorithm);
catch % otherwise use triangulation unless octave
if ver.isoctave 
   calc_fn= @do_point_in_tet_inequalities;
else        
   calc_fn= @do_point_in_tet_triangulation;
end
end

point2tet = eidors_cache(calc_fn,{fmdl, points, epsilon, exclude_nodes}, copt);

end

function point2tet = do_point_in_tet_triangulation(fmdl, points, epsilon, exclude_nodes)
   s = warning('off','MATLAB:triangulation:PtsNotInTriWarnId');
   TR = triangulation(fmdl.elems, fmdl.nodes);
   warning(s.state,'MATLAB:triangulation:PtsNotInTriWarnId')
   ID = pointLocation(TR, points);
   idx = ~isnan(ID);
   point2tet = builtin('sparse',find(idx),ID(idx),1,size(points,1),size(fmdl.elems,1));
end

function point2tet = do_point_in_tet_inequalities(fmdl, points, epsilon, exclude_nodes)
   progress_msg('Tet inequalities');
   [A,b] = tet_to_inequal(fmdl.nodes,fmdl.elems);
   progress_msg(Inf);
   
   %split computation into managable chunks to fit in memory
   mem_req = size(points,1) * size(fmdl.elems,1) * 8; % in bytes
   mem_use = 2*(1024^3); % 2 GiB
   n_chunks = ceil(mem_req / mem_use);
   chunk_sz = ceil(size(points,1) / n_chunks);
   point2tet = logical(builtin('sparse',0, size(fmdl.elems,1)));
   chunk_end = 0;
   progress_msg('Point in tet',0,n_chunks);
   for c = 1:n_chunks
       progress_msg(c,n_chunks)
       chunk_start = chunk_end+1;
       chunk_end = min(chunk_start + chunk_sz, size(points,1));
       idx = chunk_start:chunk_end;
       if true
           A_= A(1:4:end,:)*points(idx,:)';
           b_= b(1:4:end);
           p2t = (bsxfun(@minus, A_,b_) <= epsilon)';
           %        progress_msg(.21);
           for i = 2:4
               % that was actually slower
               %good = find(any(p2t,2));
               %p2t(good,:) = p2t(good,:) & (bsxfun(@minus, A(i:4:end,:)*points(idx(good),:)',b(i:4:end)) <= epsilon)';
               A_= A(i:4:end,:)*points(idx,:)';
               b_= b(i:4:end);
               p2t = p2t & (bsxfun(@minus, A_, b_) <= epsilon)';
               %           progress_msg(.21 + (i-1)*.23);
           end
           point2tet = [point2tet; builtin('sparse',p2t)];
       else
           % slower...
           p2t = (bsxfun(@minus, A*points(idx,:)',b) <= epsilon)';
           point2tet = [point2tet; builtin('sparse',reshape(all(reshape(p2t',4,[])),[],length(idx))')];
       end
   end
   progress_msg(Inf);
   
   % exclude coinciding nodes
   %    ex= bsxfun(@eq,points(:,1),fmdl.nodes(:,1)') & ...
   %        bsxfun(@eq,points(:,2),fmdl.nodes(:,2)') & ...
   %        bsxfun(@eq,points(:,3),fmdl.nodes(:,3)');
   %    progress_msg(.94);
   %    point2tet(any(ex,2),:) = 0;
       
   if exclude_nodes    
       ex = ismember(points, fmdl.nodes, 'rows');
       point2tet(ex,:) = 0;
   end

end

function do_unit_test
   do_unit_test_3d
   do_unit_test_2d
end

function do_unit_test_2d
   fmdl = mk_common_model('a2c2',4);
   fmdl = fmdl.fwd_model;
   epsilon = 0.01;
   [x,y] = meshgrid(-2:0.5:2,-2:0.5:2);
   in=point_in_tet(fmdl,[x(:),y(:)],epsilon);
   vv=[41 42 50 51 49 40 33 32 31 43 59 39];
   hh=[ 4 26 29 30 31 32 34 35 36 51 55 59];
   in_=sparse(vv,hh,1,length(x(:)),num_elems(fmdl));
   unit_test_cmp('2D test',in,in_);
end

function do_unit_test_3d
   fmdl = mk_common_model('n3r2',[16,2]);
   fmdl = fmdl.fwd_model;
   epsilon = eps;
   [x,y,z] = ndgrid(-2:0.5:2,-2:0.5:2,1.1:2);
   for ca = 1:2; switch ca
      case 1; fmdl.point_in_tet.algorithm = 'do_point_in_tet_triangulation'; 
      case 2; fmdl.point_in_tet.algorithm = 'do_point_in_tet_inequalities'; 
      end
      str = ['3D test:', fmdl.point_in_tet.algorithm];
      in=point_in_tet(fmdl,[x(:),y(:),z(:)],epsilon);
      vv=[51 59 49 39 31 23];
      hh=[297 313 333 349 369 385];
      in_=sparse(vv,hh,1,length(x(:)),400);
      unit_test_cmp(str,all(sum(in,2)<=1), true);
      unit_test_cmp(str,in(:,1:400),in_);
   end
end
