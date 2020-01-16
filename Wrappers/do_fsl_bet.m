function [ job, fmask ] = do_fsl_bet( fin, par, jobappend )
% DO_FSL_BET use fsl:bet for Brain Extraction Tool


%% Check input arguments

if ~exist('fin'      ,'var'), fin       = get_subdir_regex_files; end
if ~exist('par'      ,'var'), par       = ''                    ; end
if ~exist('jobappend','var'), jobappend = ''                    ; end

% I/O
defpar.output_name       = 'nodif_brain';
defpar.fsl_output_format = 'NIFTI_GZ'; % ANALYZE, NIFTI, NIFTI_PAIR, NIFTI_GZ


% bet options
defpar.robust           = 1;     % robust brain centre estimation (iterates BET several times)
defpar.mask             = 1;     % generate binary brain mask
defpar.frac             = 0.3 ;  % fractional intensity threshold (0->1); default=0.5; smaller values give larger brain outline estimates
defpar.radius           = [];    % head radius (mm not voxels); initial surface sphere is set to half of this
defpar.anat_brain       = 0;     % don't generate segmented brain image output

% fsl options
defpar.software         = 'fsl'; % to set the path
defpar.software_version = 5;     % 4 or 5 : fsl version

defpar.no4D             = 0;     % ?

defpar.jobname          = 'fslbet';
defpar.sge              = 0;
defpar.skip             = 1;
defpar.redo             = 0;

par = complet_struct(par,defpar);

% retrocompatibility
if par.redo
    par.skip = 0;
end


%% fsl : bet

fin   = cellstr(char(fin)); % make sure the input is a single-level cellstr
nFile = length (     fin );

job   = cell(nFile,1);
fmask = cell(nFile,1);
for iFile = 1 : nFile
    
    % in
    [pathstr, name, ~] = fileparts( fin{iFile} );
    ext_in             = file_ext ( fin{iFile} );
    
    % out
    ext_out = '';
    switch par.fsl_output_format
        case 'NIFTI_GZ'
            ext_out = '.nii.gz';
        case 'NIFTI'
            ext_out = '.nii';
        case ('NIFTI_PAIR')
            ext_out = '.img';
    end
    
    % Skip ?
    out_fullpath = fullfile(pathstr,[par.fsl_output_format ext_out]);
    if par.skip && exist(out_fullpath,'file')
        fprintf('skipping fslbet because %s exist\n',out_fullpath)
        continue
    end
    
    cmd = sprintf( 'export FSLOUTPUTTYPE=%s;\n cd %s;\n bet %s %s', par.fsl_output_format, pathstr, [name ext_in], [par.output_name ext_out] );
    
    if par.robust          , cmd = sprintf('%s -R'   ,cmd           ); end
    if par.mask            , cmd = sprintf('%s -m'   ,cmd           ); end
    if ~isempty(par.frac)  , cmd = sprintf('%s -f %g',cmd,par.frac  ); end
    if par.anat_brain==0   , cmd = sprintf('%s -n'   ,cmd           ); end
    if ~isempty(par.radius), cmd = sprintf('%s -r %d',cmd,par.radius); end
    
    job{iFile} = cmd;
    
    fmask{iFile} = fullfile( pathstr, [par.output_name '_mask' ext_out] );
    
    if par.no4D
        job{iFile} = sprintf( '%s\n #extra to remove 4th dimention\n fslroi %s_mask %s_mask 0 1\n', job{iFile}, par.output_name, par.output_name );
    end
    
end

job = do_cmd_sge(job,par,jobappend);


end % function


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function out = file_ext(in)

% File extension ?
if strcmp(in(end-6:end),'.nii.gz')
    out = '.nii.gz';
elseif strcmp(in(end-3:end),'.nii')
    out = '.nii';
else
    error('WTF ? supported files are .nii and .nii.gz')
end

end % function
