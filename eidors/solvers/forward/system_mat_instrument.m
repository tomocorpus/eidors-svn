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
% Instrument electrode can be added using
%  fmdl.electrode(end+1) = struct('nodes','instrument','z_contact',NaN);
%  Such electrodes must be last
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


   img.fwd_model = remove_instrument_electrodes(img.fwd_model);
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
   do_unit_test_x;
   do_unit_test_paper
%  do_unit_test_2d


function do_unit_test_x
   % Example from conference paper
   fmdl = mk_circ_tank(1,[],2);
   zC = 0.1;
   for i=1:num_elecs(fmdl);
      fmdl.electrode(i).nodes = num_nodes(fmdl) - 2*i + [1,2];
      fmdl.electrode(i).z_contact = zC;
   end

   fmdl.system_mat = @system_mat_instrument;
   fmdl.system_mat_instrument.connect_list = [];
   img= mk_image(fmdl,1);
   img.fwd_model.stimulation = ...
      stim_meas_list([1,2,1,2], ...
      num_elecs(img) ); 
   s_mat= calc_system_mat(img);
   vA = fwd_solve(img);
   unit_test_cmp('square:', vA.meas, 1+sqrt(2)*zC,1e-14);

   NewElectrode = num_elecs(fmdl)+1;
   fmdl.electrode(NewElectrode) = ... 
       struct('nodes','instrument','z_contact',NaN);
   zC = 1000;
   fmdl.system_mat_instrument.connect_list = ...
        [1,3,1/zC];
%       [2,3,.002;
%        1,3,.001];
   img = mk_image(fmdl,1);
   img.fwd_model.stimulation = ...
      stim_meas_list([1,3,1,3], ...
      num_elecs(img) ); 

%  show_fem(img)
   vB = fwd_solve(img);
   unit_test_cmp('square2:', vB.meas, zC,1e-12);

   img.fwd_model.system_mat_instrument.connect_list = ...
        [2,3,2/zC;
         1,3,1/zC];
   vC = fwd_solve(img);
   test = 1/(1/zC + 1/(zC/2 + 1 + 0.1*sqrt(2)));
   unit_test_cmp('square3:', vC.meas, test,1e-12);

function do_unit_test_2d
   img = mk_image(mk_common_model('a2C2',2));
   s_mat = calc_system_mat(img);
   test= zeros(1,num_nodes(img)+2);
   test(1,1:5)= [4,-1,-1,-1,-1];
   unit_test_cmp('basic',s_mat.E(1,:),test,10*eps);

   img.fwd_model.stimulation = stim_meas_list([1,2,1,2],2);
   v0 = fwd_solve(img);
   Y12 = 1/10; % Y=1/10Ohms between E#1 and new electrode
   c_list = [ 1,2,Y12];
   img.fwd_model.system_mat = @system_mat_instrument;
   img.fwd_model.system_mat_instrument.connect_list = c_list;
   vv = fwd_solve(img);
   test = 1/(1/v0.meas + Y12);
   unit_test_cmp('',vv.meas,test,1e3*eps);
  
   NewElectrode = num_elecs(img)+1; % add new electrode
   Y13 = 1/ 5; % Y=1/ 5Ohms between E#1 and new elec
%  c_list = [ 1,2,Y12;
%             2,NewElectrode,Y13];
   % Add instrument electrode
   img.fwd_model.electrode(NewElectrode) = ... 
       struct('nodes','instrument','z_contact',NaN);
   img.fwd_model.stimulation = stim_meas_list([1,2,1,3],NewElectrode);
   s_mat= calc_system_mat(img);
   vv = fwd_solve(img);

function do_unit_test_paper
   % Example from conference paper
   fmdl = eidors_obj('fwd_model','eg', ...
       'nodes',[0,0;0,1;2,0;2,1], ...
       'elems',[1,2,3;2,3,4], ...
       'gnd_node',1);
   fmdl = mdl_normalize(fmdl,1);
   fmdl.system_mat = @eidors_default;
   fmdl.solve      = @eidors_default;
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

   img.fwd_model.stimulation = ...
      stim_meas_list([1,2,1,2], ...
      num_elecs(img) ); 

   imgs = img; imgs.elem_data = [1;1];
   vv= fwd_solve(imgs);
   Ztest =  2+5/30+5/60;
   unit_test_cmp('CEM solve',vv.meas,Ztest,1e-13);

% NOTE: there is a bug in the paper,
% actually, the connection is to newEl
   NewElectrode = num_elecs(img)+1;
   Y12 = 1/10; % Y=1/10Ohms between E#1 and new electrode
   Y13 = 1/ 5; % Y=1/ 5Ohms between E#1 and new elec
   c_list = [ 1,3,Y12;
              2,NewElectrode,Y13];
   % Add instrument electrode
   img.fwd_model.electrode(NewElectrode) = ... 
       struct('nodes','instrument','z_contact',NaN);
   img.fwd_model.stimulation = ...
      stim_meas_list([1,3,1,3], ...
      num_elecs(img) ); 

   img.fwd_model.system_mat = @system_mat_instrument;
   img.fwd_model.system_mat_instrument.connect_list = c_list;
   s_mat= calc_system_mat(img); 
   save thisimg img

   Eok(:,7) = 0; Eok(7,:) = 0;
   Eok = Eok + [ 0 0 0 0 0 0 0;
0 0 0 0   0   0   0; 0 0 0 0   0   0   0; 
0 0 0 0   0   0   0; 0 0 0 0  .1   0 -.1;
0 0 0 0   0  .2 -.2; 0 0 0 0 -.1 -.2  .3];
   unit_test_cmp('instrument',s_mat.E,Eok,1e-13);

   imgs = img; imgs.elem_data = [1;1];
   vv= fwd_solve(imgs);
   Ztest = 1/( Y12 + 1/(Ztest + 1/Y13));
   
   unit_test_cmp('instrument solve1',vv.meas, Ztest,1e-13);

   % apply current to ground
   imgs.fwd_model.stimulation = struct( ...
      'stim_pattern',[1;0;NaN], ...
      'volt_pattern',[0;0;0], ...
      'meas_pattern',[1,0,-1;0,1,-1]);
   pp = fwd_model_parameters(img.fwd_model);
   vv= fwd_solve(imgs);
   Ztest2 = 10/(7.25+10)*5;
   unit_test_cmp('instrument solve2',vv.meas, [Ztest;Ztest2],1e-13);

   % apply voltage to ground
   imgs.fwd_model.stimulation = struct( ...
      'stim_pattern',[NaN;0;NaN], ...
      'volt_pattern',[10;0;0], ...
      'meas_pattern',[1,0,-1;0,1,-1]);
   vv= fwd_solve(imgs);
   Ztest = 10*[1;5/7.25];
   unit_test_cmp('instrument solve3',vv.meas, Ztest,1e-13);


%  disp(Eok)
%  disp(full(s_mat.E))
