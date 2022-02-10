function job_rp_afni2spm(dfile, output_dir, par)

% Convert the data provided by AFNI (dfile.*1D files) to the same format as SPM data
% Converted data will be saved in a file called rp_spm.txt at the chosen
% location (output_dir)

% INPUTS :
% dfile      = inputs       file, must be cellstr or @rp objects
% output_dir = outputs directory, must be cellstr


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

if nargin < 1
    help(mfilename)
end

obj = 0;
if isa(dfile,'rp')
    obj = 1;
    rp_obj = dfile;
    dfile = rp_obj.to_job();
end


%% defpar

% local parameters
defpar.outname = 'rp_spm.txt';

% matvol classics
defpar.sge          = 0;
defpar.redo         = 0;
defpar.run          = 1;
defpar.auto_add_obj = 1;

par = complet_struct(par,defpar);


%% main loop

output_file = fullfile(output_dir, par.outname);

N = length(dfile);

for i = 1 : N
    
    if exist(output_file{i}, 'file') && ~par.redo
        fprintf('[%s] skipping %d/%d because exists : %s \n', mfilename, i, N, output_file{i})
        continue
    end
    
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
    save(output_file{i},'Datas','-ascii','-double','-tabs')
    fprintf('[%s]: saving file (%d,%d) : %s \n', mfilename, i, N, output_file{i})
    
end
