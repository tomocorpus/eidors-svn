% Clear all the figures that are open and the axes
close all
clear h

graphics_toolkit qt
pkg load statistics

% Run eidors from the folder it is in.... (can check if running later)
run ..\eidors-svn\eidors-svn\eidors\startup.m

% Load and modifiy the user settings file 
% 1 has the user settings file been run on this computer before?
% If not then ask for the file path
% If yes then display the data path
%data_path = 'C:\Users\symon\Dropbox\projects\2022\CornelPerfusion\data\symon';

% Set up the gui and the animal selection seciton of the GUI
figure(1, 'position',[61    783   1048    485]);
set (gcf, "color", get(0, "defaultuicontrolbackgroundcolor"))
% Set the data loc (TODO change for something more streamlined
h.data_dir = '.\mat_data'; 
h.toolTitle = uicontrol ("style", "text", ...
                         "units", "normalized", ...
                         "string", "3D Perfusion Tool", ...
                         "horizontalalignment", "center", ...
                         "position", [0.45 0.92 0.12 0.08]);
% TODO - add a reset button that just  runs the program again...
% The select and reconstruct buttons are locked until reset
% Reconstruct button changes - Reconstruct Data -> Reconstructig (red) -> Reconstructed
% After first one in black the button becomes locked until reset
h.selectSubject = uicontrol ("style", "text", ...
                             "units", "normalized", ...
                             "string", "Subject:", ...
                             "horizontalalignment", "left", ...
                             "position", [0.01 0.85 0.16 0.08]);
h.subjectList = uicontrol ("style", "popupmenu", ...
                          "units", "normalized", ...
                          "string", {"'AE' Astin Martin", ...
                              "'BE' Bugatti", ...
                              "'CE' Citroen", ...
                              "'DE' Dupont", ...
                              "'EE' Epsilon", ...
                              "'FE' Ferrari", ...
                              "'GE' Genesis", ...
                              "'HE' Hummer", ...
                              "'IE' Infinity", ...
                              "'JE' Jaguar"}, ...
                            "callback", @print_file_info, ...
                            "position", [0.06 0.85 0.12 0.08]);
h.selectManeuver = uicontrol ("style", "text", ...
                             "units", "normalized", ...
                             "string", "File:", ...
                             "horizontalalignment", "left", ...
                             "position", [0.24 0.85 0.04 0.08]);   
h.maneuverList = uicontrol ("style", "popupmenu", ...
                            "units", "normalized", ...
                            "string", {"'B1'", ...
                              "'D1'", ...
                              "'D1'", ...
                              "'D2'", ...
                              "'H1'", ...
                              "'H2'", ...
                              "'P1'", ...
                              "'P2'", ...
                              "'R1'", ...
                              "'R2'"}, ...  
                            "callback", @print_file_info, ...
                            "position", [0.28 0.85 0.06 0.08]);    
                   
h.reconst_button = uicontrol ("style", "pushbutton", ...
                                "units", "normalized", ...
                                "string", "Load Data", ...
                                "callback", @load_img_data, ...
                                "position", [0.45 0.85 0.12 0.08]);                         

% Disable this for now...                               
set(h.maneuverList,'enable','off');
% Load the data and reconstruct it...

guidata (gcf, h); % This is so so important  

function print_file_info(obj)
  h = guidata (obj);
  subject_list = {"Aston Martin","Bugatti pig","Citroen Pig", ...
                  "Dupont pig","Epsilon","Ferrari pig","Genesis Pig", ...
                  "Hummer pig","Infinity","Jaguar"};
  subject_code = {"AE","BE","CE","DE","EE","FE","GE","HE","IE","JE"};
  sel = get(h.subjectList,'Value');
  if sel == 0; sel = sel+1; end
  sub = subject_list{sel};
  code = subject_code{sel};
  file_list = {"B1","D1","D2","H1","H2","P1","P2","R1","R2"};
  sel = get(h.maneuverList,'Value');
  if sel == 0; sel = sel+1; end
  file = file_list{sel};
  h.selectManeuver = uicontrol ("style", "text", ...
                             "ForegroundColor",[0.4660 0.6740 0.1880], ...
                             "units", "normalized", ...
                             "string", ['File: ', h.data_dir,'\',code,'_','imgs.mat'], ...
                             "horizontalalignment", "left", ...
                             "position", [0.01 0.76 0.90 0.08]); 
  if code == "JE"
    file = "D1";
  end

  h.filename = [h.data_dir,'\',sub,'\',code,'-',file,'H.eit'];
  h.subject = code;
  guidata (obj, h);
end 

function init_pixel_selection(obj)
  % TODO First load the figure info and check to see if this data is already saved..
  % TODO check to see if it is saved in the file
  %  Set up the pixel selection section
  % heart pixel input
  h = guidata (obj);   
  h.heartSecionTitle = uicontrol ("style", "text", ...
                         "units", "normalized", ...
                         "ForegroundColor",[0.6350 0.0780 0.1840], ...
                         "string", "Select heart pixel", ... 
                         "horizontalalignment", "center", ... 
                         "position", [0.38 0.65 0.12 0.08]);
  h.heartXlabel = uicontrol ("style", "text", ...
                         "units", "normalized", ...
                         "ForegroundColor",[0.6350 0.0780 0.1840], ...
                         "string", "x:", ...
                         "horizontalalignment", "left", ...
                         "position", [0.40 0.58 0.1 0.08]);
  h.heartXpix = uicontrol ("style", "edit", ...
                           "units", "normalized", ...
                           "string", "enter val", ...
                           "callback", @save_pix_val, ...
                           "position", [0.41 0.58 0.07 0.06]);
  h.heartYlabel = uicontrol ("style", "text", ...
                             "units", "normalized", ...
                             "ForegroundColor",[0.6350 0.0780 0.1840], ...
                             "string", "y:", ...
                             "horizontalalignment", "left", ...
                             "position", [0.40 0.5 0.1 0.08]);
  h.heartYpix = uicontrol ("style", "edit", ...
                           "units", "normalized", ...
                           "string", "enter val", ...
                           "callback", @save_pix_val, ...
                           "position", [0.41 0.5 0.07 0.06]);
  % lung pixel input
  h.lungSecionTitle = uicontrol ("style", "text", ...
                         "units", "normalized", ...
                         "ForegroundColor",[0 0.4470 0.7410], ...
                         "string", "Select lung pixel", ...
                         "horizontalalignment", "center", ...
                         "position", [0.38 0.35 0.12 0.08]);
  h.lungXlabel = uicontrol ("style", "text", ...
                         "units", "normalized", ...
                         "ForegroundColor",[0 0.4470 0.7410], ...
                         "string", "x:", ...
                         "horizontalalignment", "left", ...
                         "position", [0.40 0.28 0.1 0.08]);
  h.lungXpix = uicontrol ("style", "edit", ...
                           "units", "normalized", ...
                           "string", "enter val", ...
                           "callback", @save_pix_val, ...
                           "position", [0.41 0.28 0.07 0.06]);
  h.lungYlabel = uicontrol ("style", "text", ...
                         "units", "normalized", ...
                         "ForegroundColor",[0 0.4470 0.7410], ...
                         "string", "y:", ...
                         "horizontalalignment", "left", ...
                         "position", [0.40 0.2 0.1 0.08]);
  h.lungYpix = uicontrol ("style", "edit", ...
                           "units", "normalized", ...
                           "string", "enter val", ...
                           "callback", @save_pix_val, ...
                           "position", [0.41 0.2 0.07 0.06]); 
  guidata (obj, h);
end

function save_pix_val(obj)
% Save the pixel value to the general gui variable
  h = guidata (gcf);
  switch (gcbo)
    case {h.heartXpix}
      val = str2num(get(h.heartXpix, "string"));
      if (val > 0) && (val < 33)
        h.heart_x = val;  
      else
        return
      end
    case {h.heartYpix}
      val = str2num(get(h.heartYpix, "string"));
      if (val > 0) && (val < 33)
        h.heart_y = val;
      else
        return
      end
    case {h.lungXpix}
      val = str2num(get(h.lungXpix, "string"));
      if (val > 0) && (val < 33)
        h.lung_x = val;  
      else
        return
      end
    case {h.lungYpix}
      val = str2num(get(h.lungYpix, "string"));
      if (val > 0) && (val < 33)
        h.lung_y = val;  
      else
        return
      end
  end
  % TODO if all values exist...
  if (isfield(h, 'heart_x') && isfield(h, 'heart_y') && ...
      isfield(h, 'lung_x' ) && isfield(h, 'lung_y' ))
    % Make the plot selected button appear!
    h.plot_button = uicontrol ("style", "pushbutton", ...
                               "units", "normalized", ...
                               "string", "Plot Selected", ...
                               "callback", @plot_selected, ...
                               "position", [0.40 0.08 0.09 0.06]); 
  end
  guidata (obj, h);
end

function gamma_fit(obj)
% Fit gamma functions to the selected pixels and plot the two gamma curves on the graph.

% CAN WE ADD A SLIDER TO ADJUST THE WINDOW TO FIT TO?!?!?!?!?!
  h.save_button = uicontrol ("style", "pushbutton", ...
                             "units", "normalized", ...
                             "string", "Save Data", ...
                             "callback", @save_data, ...
                             "position", [0.75 0.85 0.12 0.08]);
end

function plot_selected(obj)
% Plot the selected pixel over time (use the one generated for display - is this hard to save?) 
  h = guidata (obj);
  h_sig = h.imgs(h.heart_y,h.heart_x,:);
  l_sig = h.imgs(h.lung_y,h.lung_x,:);
  % Normalize the things
  h_sig = (h_sig - min(h_sig)) / ( max(h_sig) - min(h_sig) );
  l_sig = (l_sig - min(l_sig)) / ( max(l_sig) - min(l_sig) );
  
  plot(h.tt,h_sig,'Color',[0.6350 0.0780 0.1840],'LineWidth',2,'Parent', h.ax2)
  plot(h.tt,l_sig,'Color',[0 0.4470 0.7410],'LineWidth',2,'Parent', h.ax2)
  legend({'Glocal Signal','Heart Pixel','Lung Pixel'})
  
  % Can we add some highlighing to the pixels here?
  plot(h.heart_x,h.heart_y,'s','Color',[0.6350 0.0780 0.1840],'LineWidth',3,'Parent', h.ax1)
  plot(h.lung_x,h.lung_y,'s','Color',[0 0.4470 0.7410],'LineWidth',3,'Parent', h.ax1)
  
  % Initialize the gamma fit button
%  h.fit_button = uicontrol ("style", "pushbutton",
%                            "units", "normalized",
%                            "string", "Gamma Fit",
%                            "callback", @gamma_fit,
%                            "position", [0.70 0.75 0.09 0.06]); 


                            
  h.save_button = uicontrol ("style", "pushbutton", ...
                             "units", "normalized", ...
                             "string", "Save Data", ...
                             "callback", @save_data, ...
                             "position", [0.75 0.85 0.12 0.08]);
  guidata (obj, h); 
end

function save_data(obj)
% Save the selected pixels in a mat file with the animal and man 
% Save a screenshot of the pixels and plots
  h = guidata (obj);
  p = []; % Pixel object

  p.heart_x = h.heart_x; 
  p.heart_y = h.heart_y;
  p.lung_x = h.lung_x;
  p.lung_y = h.lung_y;
  
  save(['./mat_data/', h.subject, '_pixels.mat'],'p');
end

function load_img_data(obj)
  % Load the recondtructed images from the mat_data folder
  h = guidata (obj);
  % Disable the buttons while the reconstruction is going on

  set(h.reconst_button,'enable','off');
  set(h.reconst_button,'String','Loading...');
  set(h.reconst_button,"ForegroundColor",[0.6350 0.0780 0.1840]);
  set(h.maneuverList,'enable','off');
  set(h.subjectList,'enable','off');
  drawnow
  
  % What file are we using
  print_file_info(obj);
  
  % Load the images 
  dat = load(['./mat_data/', h.subject, '_imgs.mat']);
  imgs = dat.imgs;
  tt = dat.tt;
  [~, ix] = max(squeeze(nansum(nansum(imgs))));
  h.ax1 = axes ("position", [0.05 0.10 0.3 0.6]);
  axis off
  show_slices(imgs(:,:,ix));
  axis on
  xticks (2:2:32)
  yticks (2:2:32)
  ylabel('Y axis')
  xlabel('X axis')
  grid on
  set(h.reconst_button,'String','Load Data');
  set(h.reconst_button,"ForegroundColor",[0 0 0]);
  hold on
  
  % TODO 
  h.ax2 = axes ("position", [0.55 0.2 0.40 0.5]);
  title('Reconstructed Signal')
  sig = squeeze(nansum(nansum(imgs)));
  norm_sig = (sig - min(sig)) / ( max(sig) - min(sig) );
  plot(tt,norm_sig,'LineWidth',3,'Color',[50, 50, 50]/255)
  axis tight
  xlim([5 50])
  hold on 
  ylabel('Normalized Signal \Delta Z')
  xlabel('Time (s)') 
  grid on
  grid minor
  set(h.reconst_button,'enable','on');
  %set(h.maneuverList,'enable','on');
  set(h.subjectList,'enable','on');
  h.imgs = imgs;
  h.tt = tt;
  guidata (obj, h);
  init_pixel_selection(obj)
end

function reconstruct_rep_slice(obj)
  % Reconstruct the 2D representative slice
  h = guidata (obj);
  h = guidata (obj);
  % Disable the buttons while the reconstruction is going on
  set(h.reconst_button,'enable','off');
  set(h.maneuverList,'enable','off');
  set(h.subjectList,'enable','off');
  drawnow
  print_file_info(obj);
  [dd,tt,fs] = data_loader(h.filename);
  i_t = floor(10*fs);
  dd = detrend(dd')';
  dd = freq_filt(dd,@(f) (f<0.8),fs,2);
	imdl = mk_imdl();
  imgr = inv_solve(imdl,mean(dd(:,floor(5*fs):i_t),2),dd); % Use the mean of the pre-injection time as reference
  %yyaxis right

  [~, ix] = max(sum(imgr.elem_data));
  imgr.get_img_data.frame_select = ix;
  imgr_img = inv_solve(imdl,mean(dd(:,floor(5*fs):i_t),2),dd(:,ix));
  h.ax1 = axes ("position", [0.05 0.10 0.3 0.6]);
  axis off
  img = calc_slices(imgr,[nan,nan,0.8;nan,nan,1;nan,nan,1.2]);
  show_slices(mean(img,4));
  axis on
  xticks (2:2:32)
  yticks (2:2:32)
  ylabel('Y axis')
  xlabel('X axis')
  grid on
  
  % TODO 
  h.ax2 = axes ("position", [0.55 0.2 0.40 0.5]);
  title('Reconstructed Signal')
  plot(tt,sum(imgr.elem_data),'LineWidth',3,'Color',[50, 50, 50]/255)
  axis tight
  xlim([5 50])
  hold on 
  ylabel('Normalized Signal \Delta Z')
  xlabel('Time (s)') 
  grid on
  grid minor
  set(h.reconst_button,'enable','on');
  %set(h.maneuverList,'enable','on');
  set(h.subjectList,'enable','on');
  guidata (obj, h);
  init_pixel_selection(obj)
end