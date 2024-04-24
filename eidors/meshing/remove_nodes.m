function [fmdl, c2f_idx] = remove_nodes(fmdl, idx, elec_opt)
%REMOVE_NODES   Remove nodes from a fwd_model.
%
%  fmdl = REMOVE_NODES(fmdl, idx) removes fmdl.nodes(idx,:)
%     fmdl : EIDORS fwd_model
%     idx  : indices (integer or logical) into fmdl.nodes
%
%  fmdl = REMOVE_NODES(... , elec_opt) specifies treatment of
%  electrodes:
%   'warn'      - (default) warns about empty electrodes, but keeps them
%   'keep'      - quietly keeps empty electrodes
%   'remove'    - quietly removes empty electrodes
%   'quiet'     - don't warn about changes to electrodes
%
%  [fmdl, c2f_idx] = REMOVE_NODES(...) also provides indices of elem_data 
%  to keep in an image.
%
%  REMOVE_NODES removes affected edges/faces from fmdl.boundary, but does
%  not recalculate it.
%
% See also: REMOVE_ELEMS, CROP_MODEL, REMOVE_UNUSED_NODES

% (C) 2024 Bartek Grychtol. License: GPL version 2 or version 3
% $Id$



if ischar(fmdl) && strcmp(fmdl, 'UNIT_TEST'), do_unit_test; return, end
if nargin < 3, elec_opt = ''; end

node_idx = false([num_nodes(fmdl), 1]);
node_idx(idx) = true;
elem_idx = any(node_idx(fmdl.elems),2);

[fmdl, c2f_idx] = remove_elems(fmdl, elem_idx, elec_opt);

function do_unit_test

fmdl = getfield(mk_common_model('a2c2',4),'fwd_model');
remove_nodes(fmdl, [10:14]);