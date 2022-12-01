function xy = stream2(varargin)
% STREAM2: override to fix octave stream2
%  for the case where
%     xy = stream2 (x, y, u, v, sx, sy);
%  In octave, unlike matlab, it is assumed
%   that x,y are matrices rather than
%   vectors. So we need to build them
% Seealso: streamline

  switch (numel (varargin))
     case 6
        [x, y, u, v] = varargin{1:4};
  end
  % if octave were sane, builtin would work
  % xy = builtin('stream2',varargin{:});

  % Attempt to use cd(x). Doesn't work!!
  [d,~,~] = fileparts(file_in_path(pathdef(),'stream2.m'));
  startdir = pwd ();
  unwind_protect
     cd(d)
     xy = stream2(varargin{:});
  unwind_protect_cleanup
     cd(startdir);
  end_unwind_protect


