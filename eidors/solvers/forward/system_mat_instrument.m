function s_mat = system_mat_instrument( img);
% SYSTEM_MAT_INSTRUMENT: 
%  Calculate systems matrix inclusing modelling of instrument impedance
% img.fwd_model.system_mat = @system_mat_instrument
% img.fwd_model.system_mat_instrument.clist = [CONNECTION LIST]
% 
% where
%  connection list =
%     [node1a, node1b, admittance_1ab]
%     [node2a, node2b, admittance_2ab]
%
% CITATION_REQUEST:
% AUTHOR: A Adler
% TITLE: Modelling instrument admittances with EIDORS
% CONFERENCE: EIT 2021
% YEAR: 2021
% PAGE: 74
% LINK: https://zenodo.org/record/4940249

% (C) 2021 Andy Adler. License: GPL version 2 or version 3
% $Id$

   if ischar(img) && strcmp(img,'UNIT_TEST'); do_unit_test; return; end

   citeme(mfilename)

   new_c_list = img.fwd_model.system_mat_instrument.connect_list;

   s_mat= system_mat_1st_order(img);
   E = s_mat.E;

   n_nodes = num_nodes(img);
   if ~isempty(new_c_list);
      n_elecs = max([max(new_c_list(:,1:2)),num_elecs(img)]);
   else
      n_elecs = num_elecs(img);
   end
   n_max  = n_nodes + n_elecs; 
   Eo = sparse(n_max, n_max);
   Eo(1:size(E,1),1:size(E,2)) = E;
   for i=1:size(new_c_list,1);
     x = new_c_list(i,1) + n_nodes;
     y = new_c_list(i,2) + n_nodes;
     c = new_c_list(i,3);
     Eo(x,y) = Eo(x,y) - c;
     Eo(y,x) = Eo(y,x) - c;
     Eo(x,x) = Eo(x,x) + c;
     Eo(y,y) = Eo(y,y) + c;
   end
   
   s_mat.E = Eo;

function do_unit_test
   % Example from conference paper
   fmdl = eidors_obj('fwd_model','eg', ...
       'nodes',[0,0;0,1;2,0;2,1], ...
       'elems',[1,2,3;2,3,4]);
   fmdl = mdl_normalize(fmdl,1);
   fmdl.system_mat = @eidors_default;
   img = mk_image(fmdl,[1,2]);
   s_mat= calc_system_mat(img); 
   Eok= [ 5,-4,-1, 0;-4, 6, 0,-2;
         -1, 0, 9,-8; 0,-2,-8,10]/4;
   unit_test_cmp('basic',s_mat.E,Eok);

   img.fwd_model.electrode = [ ...
     struct('nodes',[1,2],'z_contact',5/30), ...
     struct('nodes',[3,4],'z_contact',5/60)];
   s_mat= calc_system_mat(img); 

   Eok(:,5:6) = 0; Eok(5:6,:) = 0;
   Eok = Eok + [ ...
     2 1 0 0 -3 0; 1 2 0 0 -3 0;
     0  0 4 2 0 -6; 0 0  2  4 0 -6
    -3 -3 0 0 6  0; 0 0 -6 -6 0 12];
   unit_test_cmp('with CEM',s_mat.E,Eok,1e-13);

% NOTE: there is a bug in the paper,
% actually, the connection is to newEl
   NewElectrode = 3; % add new electrode
   Y12 = 1/10; % Y=1/10Ohms between E#1 and new electrode
   Y13 = 1/ 5; % Y=1/ 5Ohms between E#1 and new elec
   c_list = [ 1,3,Y12;
              2,NewElectrode,Y13];
   img.fwd_model.system_mat = @system_mat_instrument;
   img.fwd_model.system_mat_instrument.connect_list = c_list;
   s_mat= calc_system_mat(img); 

   Eok(:,7) = 0; Eok(7,:) = 0;
   Eok = Eok + [ 0 0 0 0 0 0 0;
0 0 0 0   0   0   0; 0 0 0 0   0   0   0; 
0 0 0 0   0   0   0; 0 0 0 0  .1   0 -.1;
0 0 0 0   0  .2 -.2; 0 0 0 0 -.1 -.2  .3];
   unit_test_cmp('instrument',s_mat.E,Eok,1e-13);

   img.fwd_model.stimulation = ...
      stim_meas_list([1,NewElectrode,1,NewElectrode]); 
%  disp(Eok)
%  disp(full(s_mat.E))
