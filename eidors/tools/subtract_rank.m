function out = subtract_rank(in, ranklim)
% SUBTRACK_RANK: subtract a ranked level from data
%
%  imgout = subtract_rank(imgin, 0.3)
%    subtract the 30% percentile from imgr.elem_data
%  imgout = subtract_rank(imgin, [0.1,0.3])
%    subtract an average of 10-30% percentile from imgr.elem_data
%
% if input is a 'image' object, then operate on elem_data. Otherwise operate on value

% (C) 2024 Andy Adler. Licence GPL v2 or v3
% $Id$ 

if ischar(in) && strcmp(in,'UNIT_TEST'); do_unit_test; return; end

if isstruct(in) && strcmp(in.type, 'image') 
   use_elem_data = true;
elseif isnumeric(in)
   use_elem_data = false;
else
   error('Unknown type for subtract_rank');
end

function do_unit_test
  ed = [1:10] + [0;3];
