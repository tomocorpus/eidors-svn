%% Reconstruct the B1 files for all animals to  save time
run ..\eidors-svn\eidors-svn\eidors\startup.m

%% Load the data on Symon's wondows machine
data_path = 'C:\Users\symon\Dropbox\projects\2022\CornelPerfusion\data\symon';
subject_list = ["Aston Martin","Bugatti pig","Citroen Pig", ...
                  "Dupont pig","Epsilon","Ferrari pig","Genesis Pig", ...
                  "Hummer pig","Infinity","Jaguar"];
subject_code = ["AE","BE","CE","DE","EE","FE","GE","HE","IE","JE"];                 

for i = 1:10 % loop through the 10 animals and load the 'BH1' file
  % Get the filename
  filename = [data_path,'\',subject_list{i},'\', subject_code{i},'-B1H.eit']
  if i==10
    filename = [data_path,'\',subject_list{i},'\', subject_code{i},'-D1H.eit']
  end
  % Load the data
  [dd,tt,fs] = data_loader(filename);
  
  % Set the reference time frame
  i_s = floor(5*fs);
  i_t = floor(10*fs);
  
  % Detrend and filter
  dd = detrend(dd')';
  dd = freq_filt(dd,@(f) (f<0.8),fs,2);
  
  % Get the inverse model
  imdl = mk_imdl();
  
  % Reconstruct 
  imgr = inv_solve(imdl,mean(dd(:,i_s:i_t),2),dd); % Use the mean of the pre-injection time as reference
  
  % Get the slices
  img = calc_slices(imgr,[nan,nan,0.8;nan,nan,1;nan,nan,1.2]);
  imgs = mean(img,4);
  % Save the data (in mat file)
  save([subject_code{i}, '_imgs.mat'],'imgs','tt');
end