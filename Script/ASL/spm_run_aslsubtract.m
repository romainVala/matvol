function out = spm_run_aslsubtract(job)
% SPM job execution function
% takes a harvested job data structure and call SPM functions to perform
% computations on the data.
% Input:
% job    - harvested job data structure (see matlabbatch help)
% Output:
% out    - computation results, usually a struct variable.
%__________________________________________________________________________
% Copyright (C) 2008 Wellcome Trust Centre for Neuroimaging

% John Ashburner
% $Id: spm_run_cat.m 3613 2009-12-04 18:47:59Z guillaume $

% Michèle Desjardins, January 2012


V               = strvcat(job.vols{:});
fileOrder       = job.order;

CBFmodel        = fieldnames(job.CBFmodel);
CBFmodelnm      = CBFmodel{1};
sequenceParams  = job.CBFmodel.(CBFmodelnm);
try
    M0file = job.CBFmodel.(CBFmodelnm).M0{1};
catch
    M0file = '';
end
doAddition      = job.doAddition;
datatype        = job.dtype;
[foo outname ext] = fileparts(job.name);
if isempty(ext); ext = '.nii'; end;
outputfilename  = [outname ext];
maskfile        = job.mask{1};
subtractionType = job.subMethod;
save3Dfiles     = job.save3D;
fROI            = job.fROI{1};
dont_recompute  = job.dont_recompute;
rmv_start_imgs  = job.rmv_start_imgs;
numSess         = job.numSess;


[V4 V4calib]    =  util_compute_asl_subtract(V,numSess,fileOrder,CBFmodelnm,...
    sequenceParams, M0file, doAddition,outputfilename,...
    maskfile,save3Dfiles,subtractionType,datatype,fROI,...
    dont_recompute,rmv_start_imgs);

% Output(dependencies)
flowfile = {};
calibflowfile = {};
for iSess = 1:size(V4,1)
    flowfile = [flowfile; V4{iSess}.fname];
    if ~isempty(V4calib)
        calibflowfile = [calibflowfile; V4calib{iSess}.fname];
    end
end
out.flowfile = flowfile;
out.calibflowfile = calibflowfile;


