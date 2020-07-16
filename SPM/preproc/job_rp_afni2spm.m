function job_rp_afni2spm(dfile, output_dir)

% Convert the data provided by AFNI (dfile.*1D files) to the same format as SPM data
% Converted data will be saved in a file called rp_spm.txt at the chosen
% location (output_dir)

% INPUTS :
% dfile      = inputs       file, must be cellstr
% output_dir = outputs directory, must be cellstr

N = length(dfile);

for i = 1:N
    
    % Load text file
    rp_afni = load(dfile{i});
    
    % Translation : keep mm
    Tx = rp_afni(:,4);
    Ty = rp_afni(:,5);
    Tz = rp_afni(:,6);
    
    % Rotation : deg -> rad
    Rx = rp_afni(:,1)*pi/180;
    Ry = rp_afni(:,2)*pi/180;
    Rz = rp_afni(:,3)*pi/180;
    
    Datas=[Tx, Ty, Tz, Rx, Ry, Rz]; %#ok<NASGU>
    
    % file .txt
    filename = fullfile(output_dir{i},'rp_spm.txt');
    save(filename,'Datas','-ascii','-double','-tabs')
    fprintf('saving file (%d,%d) : %s \n', i, N, filename)
    
end
