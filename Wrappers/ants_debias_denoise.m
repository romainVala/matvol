function [ job ] = ants_debias_denoise(fin, par)
%ANTS_DEBIAS_DENOISE
%
% ants_debias_denoise will use N4BiasFieldCorrection then DenoiseImage (from ANTs)
%
% SYNTAX :
%           ants_debias_denoise( fin );
%           ants_debias_denoise( fin, par );
% [ job ] = ants_debias_denoise( fin, par );
%
% EXAMPLE
% ants_debias_denoise('/path/to/volume.nii')
% ants_debias_denoise({'/path/to/volume1.nii','/path/to/volume2.nii'})
% ants_debias_denoise( examArray.getSerie('anat_T1').getVolume('^v'), par );
%
% INPUTS :
% - fin : single-level cellstr of file names
% OR
% - fin : @volume array
%
% See also get_subdir_regex_files exam exam.AddSerie serie.addVolume exam.getSerie serie.getVolume

if nargin==0, help(mfilename), return, end


%% Check input arguments

if ~exist('fin'      ,'var'), fin       = get_subdir_regex_files; end
if ~exist('par'      ,'var'), par       = ''; end
if ~exist('jobappend','var'), jobappend = ''; end

obj = 0;
if isa(fin,'volume')
    obj      = 1;
    img_obj  = fin.removeEmpty; % .removeEmpty strips dimensions and remove empty objects
    fin      = img_obj.toJob;   % .toJob converts to cellstr
end

% I/O
defpar.prefix_debias  = 'db_';
defpar.args_debias    = ''   ; % extra arguments, added to the command line
defpar.prefix_denoise = 'dn_';
defpar.denoise_args   = ''   ; % extra arguments, added to the command line

defpar.sge               = 0;
defpar.jobname           = 'ants_debias_denoise';
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

fin   = cellstr(char(fin)); % make sure the input is a single-level cellstr
nFile = length (     fin );

job         = cell(nFile,1);
out_debias  = cell(nFile,1);
out_denoise = cell(nFile,1);
skip        = [];
for iFile = 1 : nFile
    in = fin{iFile};
    out_debias{iFile}  = addprefixtofilenames(in               , par.prefix_debias );
    out_denoise{iFile} = addprefixtofilenames(out_debias{iFile}, par.prefix_denoise);
    cmd_debias  = sprintf('N4BiasFieldCorrection -i %s -o %s %s; \n', in               , out_debias {iFile}, par.args_debias);
    cmd_denoise = sprintf(         'DenoiseImage -i %s -o %s %s; \n', out_debias{iFile}, out_denoise{iFile}, par.args_debias);

    cmd = '';
    if exist(out_debias{iFile},'file') && ~par.redo
        fprintf('[%s]: skip %d/%d -> debiased file exist @ %s \n', mfilename, iFile, nFile, out_debias{iFile})
    else
        cmd = [cmd cmd_debias];
    end
    if exist(out_denoise{iFile},'file') && ~par.redo
        fprintf('[%s]: skip %d/%d -> denoised file exist @ %s \n', mfilename, iFile, nFile, out_denoise{iFile})
    else
        cmd = [cmd cmd_denoise];
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
            ser.addVolume( sub, ['^'                    par.prefix_debias tag ext] , [                   par.prefix_debias tag], 1 );
            ser.addVolume( sub, ['^' par.prefix_denoise par.prefix_debias tag ext] , [par.prefix_denoise par.prefix_debias tag], 1 );
        elseif par.sge % add the new volume in the object manually, because the file is not created yet
            ser.addVolume( 'root', fullfile(ser.path, [ out_debias{iVol} ext]) , [                   par.prefix_debias tag] );
            ser.addVolume( 'root', fullfile(ser.path, [out_denoise{iVol} ext]) , [par.prefix_denoise par.prefix_debias tag] );
        end
        
    end
    
end


end % function
