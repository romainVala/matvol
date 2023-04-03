function  matlabbatch = job_do_two_sample_ttest(stat_dir,img1,img2,par)
% job_do_two_sample_ttest : SPM12:Stats:Factorial design specification
%                           and estimate parametes
%                           contrast manager for 'Groupe1 > Groupe2' and 'Groupe2 > Groupe1'
%
% Inputs :
%       stat_dir : cell array, path to directory where to save SPM.mat file
%       img1     : call array, group 1 images files
%       img2     : cell array, group 2 images files
%       par      : parameters for this analysis and matvol
%
%                par.type : which t-test to use Two-sample t-test or Paired t-test
%
%       To specify covariates and nuisance variables :
%                par.cov_name : Cell array contains the covariate name
%                                each name must be a 'par field' to
%                                sepecify covariates values
%                     ex :
%                              par.cov_name = {'age','tiv','gender'};
%                     then :
%                              par.age  = [26,32,44, ... 30,25,19]  same size with {img1;img2}
%                              par.tiv  = [1.24,1.23 ... 1.09,0.9]
%                              par.gender = [1,0,0,1 ... 1,0,1,0 ]
%
%                Importantly,  the  ordering  of  the files in {img1;img2}
%                          must be the same with the order of covariates values in the vector
%
%
%
%      To specify mask using the 3 methods supported by SPM12 :
%      Method 1 : threshold masking, using one of the options :(0:none, 1:absolute, 3:relative)
%               par.th_masking : one number must be selected 0, 1 or 2
%                               par.athresh : threshold value for absolute threshold masking [par.th_masking = 1]
%                               par.rthresh : threshold value for relative threshold masking [par.th_masking = 2]

%      Method 2 :  Implicit mask (no or yes)
%               par.use_imask : choose a number 0 or 1, by default SPM  uses an implicit mask
%
%      Method 3 : Explicit mask
%               par.emask     : select masks, using cell array
%
%
%
%      To estimate global effects select one of the options : (0:Omit, 1:user defined, 2:Mean)
%               par.gcalculation : one number must be selected 0, 1 or 2
%               par.gvalues : real numbers vector of global values if using user defined [par.gcalculation = 1]
%
%      Global normalisation :
%               par.use_gms : grand mean scaling, select one of the options : (0:no,1:yes)
%               par.gms_value : Grand mean scaled value must be entred if use_gms
%
%
%               par.normalisation : one of the options must be selected (1:none, 2:proportional, 3:ANCOVA)
%
%      par.rcontrast : estimate contrast (0: no, 1:yes), put 0 for VBM data
%      
%
%
% Output :
%       generates the finale SPM.mat file, beta files ... in stat_dir folder
% 
%
%
%



if ~exist('par','var')
    par='';
end


defpar.type  = 1;        % 1 : '2ttest' // 2 : pair_ttest
defpar.cov_name = {};

% masking
defpar.th_masking = 0;   % 0 : none // 1 : absolute // 2 : relative // otherwise par.masking = 0
defpar.athresh = 100;    % if using absolute, need absolute threshold, by default par.athresh = 100
defpar.rthresh = 0.8;    % if using relative, need relative threshold, by default par.rthresh = 0.8
defpar.use_imask   = 1;  % 0 : No // 1 : yes // by default, SPM use this methode
defpar.emask ={''};      % mask file
% global calculation
defpar.gcalculation = 0; % 0 : Omit // 1 : User // 2 : Mean
defpar.gvalues  = [];    % vector of global values same size with {img1;img2}
% global normalisation
defpar.use_gms  = 0;     % 0 : no  // 1 : yes  (Overall grand mean scaling)
defpar.gms_value = 50;   % use one or vector of real numbers

defpar.normalisation = 1;% 1 : none // 2 : proportional // 3 : ANCOVA
defpar.rcontrast     = 1;% 0 : no  // 1 : yes // result contrast


defpar.run = 1;
defpar.display=0;


par = complet_struct(par,defpar);

img1     = cellstr(char(img1));
img2     = cellstr(char(img2));
cov_name = cellstr(par.cov_name);
nsuj     = length(img1)+length(img2);

par.emask = cellstr(par.emask);




% pair_ttest
if par.type == 2
    assert(length(img1) == length(img2),'img1 and img2 must have the same size');
end





% Covariates
use_cov = 0;
ncov    = length(cov_name);

if ncov
    use_cov = 1;
    tmp     = isfield(par, cov_name);
    if sum(~tmp)
        
        error('Undefined field %s\n',cov_name{~tmp});
        
    end
    
    for ic = 1:ncov
        
        vec = par.(cov_name{ic});
        
        assert(isvector(vec),'par.%s must be a vector',cov_name{ic});
        assert(length(vec) == nsuj,'par.%s size must be the same as the number of images selected',cov_name{ic});
        
        covariates(:,ic) = vec;
        
    end
    
end

% global calculation
if par.gcalculation == 1
    
    assert(isvector(par.gvalues),'par.gvalues must be a vector');
    assert(length(par.gvalues) == nsuj,'The vector size of the global values must be the same as the number of images selected');
    gvalues(:,1) = par.gvalues;
    
end

% global normalisation
assert(any(par.normalisation == [1, 2, 3]),'Unexpected global normalization option');


if isempty(stat_dir)
    stat_dir = get_subdir_regex();
end

if ~iscell(stat_dir)
    stat_dir = cellstr(stat_dir);
end

if ~exist(stat_dir{1}); mkdir(stat_dir{1});end

spmmat_f = fullfile(stat_dir{1},'SPM.mat');



matlabbatch{1}.spm.stats.factorial_design.dir = stat_dir;

if par.type == 1      % 2ttest
    matlabbatch{1}.spm.stats.factorial_design.des.t2.scans1 = img1;% {char(img1)};
    matlabbatch{1}.spm.stats.factorial_design.des.t2.scans2 = img2;% {char(img2)};
    matlabbatch{1}.spm.stats.factorial_design.des.t2.dept = 0;
    matlabbatch{1}.spm.stats.factorial_design.des.t2.variance = 1;
    matlabbatch{1}.spm.stats.factorial_design.des.t2.gmsca = 0;
    matlabbatch{1}.spm.stats.factorial_design.des.t2.ancova = 0;
    
elseif par.type == 2 % pair_ttest
    for nbr = 1:length(img1)
        matlabbatch{1}.spm.stats.factorial_design.des.pt.pair(nbr).scans = {img1{nbr};img2{nbr}};
    end
    matlabbatch{1}.spm.stats.factorial_design.des.pt.gmsca = 0;
    matlabbatch{1}.spm.stats.factorial_design.des.pt.ancova = 0;
end

if use_cov
    
    for icov = 1: ncov
        matlabbatch{1}.spm.stats.factorial_design.cov(icov).c = covariates(:,icov);
        matlabbatch{1}.spm.stats.factorial_design.cov(icov).cname = cov_name{icov};
        matlabbatch{1}.spm.stats.factorial_design.cov(icov).iCFI = 1;
        matlabbatch{1}.spm.stats.factorial_design.cov(icov).iCC = 1;
    end
    
else
    matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
end

switch par.th_masking
    case 1
        
        matlabbatch{1}.spm.stats.factorial_design.masking.tm.tma.athresh = par.athresh;
    case 2
        matlabbatch{1}.spm.stats.factorial_design.masking.tm.tmr.rthresh = par.rthresh;
        
    otherwise
        
        matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
        
end


matlabbatch{1}.spm.stats.factorial_design.masking.im = par.use_imask;
matlabbatch{1}.spm.stats.factorial_design.masking.em = par.emask;



% clobal calculation
switch par.gcalculation
    case 1 % user
        
        matlabbatch{1}.spm.stats.factorial_design.globalc.g_user.global_uval = gvalues;
    case 2 % mean
        
        matlabbatch{1}.spm.stats.factorial_design.globalc.g_mean = 1;
    otherwise  % omit
        
        matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
end


% Global normalisation
if par.use_gms   % grand mean scaling
    matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_yes.gmscv = par.gms_value;
else
    matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
end


matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = par.normalisation; %1=none 2=propor 3=ANCOVA



% SPM: Stats: fMRI data specification
matlabbatch{2}.spm.stats.fmri_est.spmmat = {spmmat_f};
matlabbatch{2}.spm.stats.fmri_est.method.Classical = 1;


matlabbatch{3}.spm.stats.con.spmmat = {spmmat_f};
matlabbatch{3}.spm.stats.con.consess{1}.tcon.name = 'Groupe1 > Groupe2';
matlabbatch{3}.spm.stats.con.consess{1}.tcon.convec = [1 -1];
matlabbatch{3}.spm.stats.con.consess{1}.tcon.sessrep = 'none';

matlabbatch{3}.spm.stats.con.consess{2}.tcon.name = 'Groupe2 > Groupe1';
matlabbatch{3}.spm.stats.con.consess{2}.tcon.convec = [-1 1];
matlabbatch{3}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
matlabbatch{3}.spm.stats.con.delete = 0;

if par.rcontrast
    matlabbatch{4}.spm.stats.results.spmmat = {spmmat_f};
    matlabbatch{4}.spm.stats.results.conspec(1).titlestr = 'Groupe1 > Groupe2';
    matlabbatch{4}.spm.stats.results.conspec(1).contrasts = 1;
    matlabbatch{4}.spm.stats.results.conspec(1).threshdesc = 'FWE';
    matlabbatch{4}.spm.stats.results.conspec(1).thresh = 0.001;
    matlabbatch{4}.spm.stats.results.conspec(1).extent = 10;
    matlabbatch{4}.spm.stats.results.conspec(1).mask = struct('contrasts', {}, 'thresh', {}, 'mtype', {});
    
    matlabbatch{4}.spm.stats.results.conspec(2).titlestr = 'Groupe2 > Groupe1';
    matlabbatch{4}.spm.stats.results.conspec(2).contrasts = 1;
    matlabbatch{4}.spm.stats.results.conspec(2).threshdesc = 'FWE';
    matlabbatch{4}.spm.stats.results.conspec(2).thresh = 0.001;
    matlabbatch{4}.spm.stats.results.conspec(2).extent = 10;
    matlabbatch{4}.spm.stats.results.conspec(2).mask = struct('contrasts', {}, 'thresh', {}, 'mtype', {});
    matlabbatch{4}.spm.stats.results.print = true;

else
    matlabbatch{3}.spm.stats.results.print = true;
end


spm_jobman('run', matlabbatch');


end





