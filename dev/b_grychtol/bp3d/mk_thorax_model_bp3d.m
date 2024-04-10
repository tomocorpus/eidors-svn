function out = mk_thorax_model_bp3d
%MK_THORAX_MODEL_BP3D
%
%
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
out = get_torso;

function out = get_torso()
contrib = 'bp3d-torso'; file =  'bp3d_torso.mat';
load(get_contrib_data(contrib,file),'torso');
out = gmsh_stl2tet(torso);

