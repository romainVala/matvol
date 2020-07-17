function  jobs = job_suit(img,par)
% JOB_SUIT - spm.tools.suit.isolate_seg
%
% INPUT : img can be 'char' of volume(file), multi-level 'cellstr' of volume(file), '@volume' array
%
% To build the image list easily, use get_subdir_regex & get_subdir_regex_files
%
% See also get_subdir_regex get_subdir_regex_files exam exam.AddSerie exam.addVolume


%% Check input arguments

if ~exist('par','var')
    par = ''; % for defpar
end

if nargin < 1
    help(mfilename)
    error('[%s]: not enough input arguments - img is required',mfilename)
end

obj = 0;
if isa(img,'volume')
    obj = 1;
    volumeArray  = img;
    img = volumeArray.toJob(0);
end


%% defpar

% cluster
defpar.sge      = 0;
defpar.jobname  = 'spm_suit';
defpar.walltime = '00:30:00';

% matvol classics
defpar.redo         = 0;
defpar.run          = 1;
defpar.display      = 0;


par = complet_struct(par,defpar);


%% SPM:Spatial:Suit

skip = [];

for subj = 1 : length(img)
    jobs{subj}.spm.tools.suit.isolate_seg.source = { cellstr(char(img(subj))) } ;
    jobs{subj}.spm.tools.suit.isolate_seg.bb =  [-76 76; -108 -6; -70 11]; 
    jobs{subj}.spm.tools.suit.isolate_seg.maskp = 0.2;
    jobs{subj}.spm.tools.suit.isolate_seg.keeptempfiles = 0;
end


%% Other routines

[ jobs ] = job_ending_rountines( jobs, skip, par );
