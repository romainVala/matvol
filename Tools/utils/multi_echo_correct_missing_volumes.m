function job = multi_echo_correct_missing_volumes(img,par)
% MULTI_ECHO_CORRECT_MISSING_VOLUMES will check the number of volumes in each eachos of the same run, and correct it eventually
%
% img : - cellstr of volumes paths
%       OR
%       - @volume object


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

if nargin < 1
    help(mfilename)
    error('[%s]: not enough input arguments - img is required',mfilename)
end

if isa(img,'volume')
    img_obj  = img;
    img = img_obj.getPath;
end


%% Main

nRun = numel(img);
job  = cell(0,1);

for iRun = 1 : nRun
    
    echos_path = img{iRun};
    if isempty(echos_path)
        continue
    end
    
    nVol     = size(echos_path,1);
    volCount = zeros(1,nVol);
    for iVol = 1 : nVol
        [~,w] = unix(sprintf('export AFNI_NIFTI_TYPE_WARN=NO; 3dinfo -nv %s', deblank( echos_path(iVol,:) )));
        volCount(iVol) = str2double(w);
    end
    
    if any(volCount(1) ~= volCount) % different number of volumes ?
        
        min_nrVol = min(volCount);
        
        % Echo
        fprintf('[%s]: %s %s \n',mfilename, num2str(volCount - min_nrVol), fileparts( deblank( echos_path(iVol,:) )) )
        
        % Prepare command
        for iVol = 1 : nVol
            job{end+1,1} = sprintf('export FSLOUTPUTTYPE=NIFTI; fslroi %s %s 0 %d', deblank( echos_path(iVol,:) ), deblank( echos_path(iVol,:) ), min_nrVol); %#ok<AGROW>
        end
        
    end
    
end

if numel(job) == 0
    fprintf('[%s]: ok ! \n', mfilename);
end


%% Prompt & run

disp(char(job))

fprintf('[%s]: Are you sure you want correct the volumes => only do this if there is only one volume difference\n',mfilename)
R = input(['[' mfilename ']: yes or no \n'],'s');

if any(strcmpi(R,{'yes','y'}))
    do_cmd_sge(job,par);
    fprintf('[%s]: done \n', mfilename);
else
    fprintf('[%s]: nothing done \n', mfilename);
end


end % function