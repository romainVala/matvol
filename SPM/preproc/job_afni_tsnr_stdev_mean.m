function [job] = job_afni_tsnr_stdev_mean(input4D, par)
%JOB_AFNI_TSNR_STDEV_MEAN
%
% job_afni_tsnr_stdev_mean will use 3dTstat from AFNI with options -mean, -stdev, -tsnr
%
% SYNTAX :
%           job_afni_tsnr_stdev_mean( input4D );
%           job_afni_tsnr_stdev_mean( input4D, par );
% [ job ] = job_afni_tsnr_stdev_mean( input4D, par );
%
% EXAMPLE
% job_afni_tsnr_stdev_mean('/path/to/volume.nii')
% job_afni_tsnr_stdev_mean({'/path/to/volume1.nii','/path/to/volume2.nii'})
% job_afni_tsnr_stdev_mean( examArray.getSerie('run').getVolume('^v'), par );
%
% INPUTS :
% - input4D : single-level cellstr of file names
% OR
% - input4D : @volume array
%
% See also get_subdir_regex_files exam exam.AddSerie serie.addVolume exam.getSerie serie.getVolume

if nargin==0, help(mfilename), return, end


%% Check input arguments

if ~exist('input4D'  ,'var'), input4D       = get_subdir_regex_files; end
if ~exist('par'      ,'var'), par       = ''; end
if ~exist('jobappend','var'), jobappend = ''; end

obj = 0;
if isa(input4D,'volume')
    obj      = 1;
    img_obj  = input4D.removeEmpty; % .removeEmpty strips dimensions and remove empty objects
    input4D  = img_obj.toJob;   % .toJob converts to cellstr
end

% I/O
defpar.prefix_tsnr  =  'tsnr_';
defpar.prefix_stdev = 'stdev_';
defpar.prefix_mean  =  'mean_';

defpar.sge               = 0;
defpar.jobname           = 'job_afni_tsnr_stdev_mean';
defpar.mem               = '4G';

defpar.run               = 1;
defpar.redo              = 0;
defpar.verbose           = 1;
defpar.auto_add_obj      = 1;

par = complet_struct(par,defpar);

% retrocompatibility
if par.redo
    par.skip = 0;
end


%% main

input4D = cellstr(char(input4D)); % make sure the input is a single-level cellstr
nFile   = length (     input4D );

job         = cell(nFile,1);
out_tsnr  = cell(nFile,1);
out_stdev = cell(nFile,1);
out_mean  = cell(nFile,1);
skip        = [];
for iFile = 1 : nFile
    in = input4D{iFile};
    
    out_tsnr {iFile} = addprefixtofilenames(in, par.prefix_tsnr );
    out_stdev{iFile} = addprefixtofilenames(in, par.prefix_stdev);
    out_mean {iFile} = addprefixtofilenames(in, par.prefix_mean );
    
    cmd_tsnr  = sprintf('3dTstat -prefix %s -tsnr %s; \n' , out_tsnr {iFile}, in);
    cmd_stdev = sprintf('3dTstat -prefix %s -stdev %s; \n', out_stdev{iFile}, in);
    cmd_mean  = sprintf('3dTstat -prefix %s -mean %s; \n' , out_mean {iFile}, in);

    cmd = '';
    
    if exist(out_tsnr{iFile},'file') && ~par.redo
        fprintf('[%s]: skip %d/%d -> tsnr file exist @ %s \n', mfilename, iFile, nFile, out_tsnr{iFile})
    else
        cmd = [cmd cmd_tsnr];
    end
    
    if exist(out_stdev{iFile},'file') && ~par.redo
        fprintf('[%s]: skip %d/%d -> stdev file exist @ %s \n', mfilename, iFile, nFile, out_stdev{iFile})
    else
        cmd = [cmd cmd_stdev];
    end
    
    if exist(out_mean{iFile},'file') && ~par.redo
        fprintf('[%s]: skip %d/%d -> mean file exist @ %s \n', mfilename, iFile, nFile, out_mean{iFile})
    else
        cmd = [cmd cmd_mean];
    end
    
    if ~isempty(cmd)
        job{iFile} = cmd;
    else
        skip = [skip iFile];
    end

end

job(skip) = []; % eject empty jobs


%% Run the jobs

% Run CPU, run !
job = do_cmd_sge(job, par, jobappend);


%% Add outputs objects

if obj && par.auto_add_obj && (par.run || par.sge)
    
    for iVol = 1 : length(img_obj)
        
        % Shortcut
        vol = img_obj(iVol);
        ser = vol.serie;
        tag = vol.tag;
        sub = vol.subdir;
        
        ext  = '.*.nii';
        
        if par.run     % use the normal method
            ser.addVolume( sub, ['^' par.prefix_tsnr  tag ext] , [par.prefix_tsnr  tag], 1 );
            ser.addVolume( sub, ['^' par.prefix_stdev tag ext] , [par.prefix_stdev tag], 1 );
            ser.addVolume( sub, ['^' par.prefix_mean  tag ext] , [par.prefix_mean  tag], 1 );
        elseif par.sge % add the new volume in the object manually, because the file is not created yet
            ser.addVolume( 'root', fullfile(ser.path, [ out_tsnr {iVol} ext]) , [par.prefix_tsnr  tag] );
            ser.addVolume( 'root', fullfile(ser.path, [ out_stdev{iVol} ext]) , [par.prefix_stdev tag] );
            ser.addVolume( 'root', fullfile(ser.path, [ out_mean {iVol} ext]) , [par.prefix_mean  tag] );
        end
        
    end
    
end

end % function
