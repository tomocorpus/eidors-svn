function out = mk_thorax_model_bp3d(varargin)
%MK_THORAX_MODEL_BP3D
% mk_thorax_model_bp3d()
% mk_thorax_model_bp3d(elec_pos, elec_shape)
% mk_thorax_model_bp3d(elec_pos, elec_shape, maxh)
% mk_thorax_model_bp3d(stimpat)
% mk_thorax_model_bp3d(__, organspec)
%
% CITATION_REQUEST:
% AUTHOR: Mitsuhashi N, Fujieda K, Tamura T, Kawamoto S, Takagi T, Okubo K
% TITLE: BodyParts3D: 3D structure database for anatomical concepts
% JOURNAL: Nucleic Acids Res
% VOL: 37
% NUM: Database issue
% YEAR: 2013
% PAGE: D782--5
% LINK: https://academic.oup.com/nar/article/37/suppl_1/D782/1000752
% PDF: https://academic.oup.com/nar/article-pdf/37/suppl_1/D782/3210893/gkn613.pdf
% DOI: 10.1093/nar/gkn613
% PUBMED: 18835852
%
% LICENSE INFORMATION:
% This work is a derivative of the <a href="matlab: web 
% https://dbarchive.biosciencedbc.jp/en/bodyparts3d
% -browser">BodyParts3D</a> database by 
% <a href="matlab: web https://biosciencedbc.jp/ -browser"
% >The Database Center for Life Science</a>, used under the Creative Commons 
% Attribution-ShareAlike 2.1 Japan (<a href="matlab: web 
% http://creativecommons.org/licenses/by-sa/2.1/jp/deed.en_US 
% -browser">CC BY-SA 2.1 JP</a>) license.
% This work is licensed under CC BY-SA 2.1 JP by Bartek Grychtol.
%
% See also MK_THORAX_MODEL

% (C) 2024 Bartek Grychtol. License: CC BY-SA 2.1 JP
% $Id$

citeme(mfilename)

if nargin == 0 % get a torso with no electrodes
   out = get_torso; 
   return; 
end
organspec = '';
if nargin > 1 && ischar(varargin{end})
   organspec = varargin{end};
   varargin(end) = [];
end

switch length(varargin)
   case 1
      if ischar(varargin{1})
         out = build_predef_elecs(varargin{1});
      else
         error('EIDORS:WrongInput','Electrode specification not understood');
      end
   case {2,3}
      out = mk_thorax_model('bp3d',varargin{:});
   otherwise
      error('EIDORS:WrongInput', 'Too many inputs');
end
   
if ~isempty(organspec)
   out = add_organs(out, organspec);
end


function out = get_torso()
contrib = 'bp3d-torso'; file =  'bp3d_torso.mat';
load(get_contrib_data(contrib,file),'torso');
out = gmsh_stl2tet(torso);


function out = build_predef_elecs(elecstr)
if ~isempty(elecstr)
   eth16 = 360*cumsum([0.2 0.4*ones(1,7) 0.5 0.4*ones(1,7)])/6.5 - 90; eth16 = eth16';
   ep = eth16; ep(:,2) = 1150;
   out = mk_thorax_model('bp3d',ep,[10 0 2],20);
end

function out = add_organs(out, organspec)
return