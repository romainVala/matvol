function  jobs = job_sandi_matlab(fdwi,par)
% JOB_SANDI_MATLAB : Fit SANDI diffusion model
%
% DESCRIPTION:
%     Performs the SANDI (Smallest-Anatomy-Nodes Diffusion Imaging) 
%     model fitting using the adapted code from the official SANDI MATLAB Toolbox.
%
%     Note on Acquisition Requirements:
%     Requires high gradient strength (high b-values and multiple b-shells).
%     
%     This function does NOT require the BIDS data structure or the specific 
%          naming for input files (as required by the original toolbox).
%          File paths are handled directly via the `fdwi` input.
%     See the 'par' section below for model-specific settings.
%
% -------------------------------------------------------------------------
% Inputs:
%
%     fdwi : cellstr, paths to the preprocessed Diffusion-Weighted Imaging (DWI) files.
%            
%     par  : matvol & sandi parameters.
% 
% -------------------------------------------------------------------------
% Output:
%
%     The function executes the fitting and saves the resulting SANDI metric files 
%
% REQUIREMENTS: 

%  Add the SANDI MATLAB Toolbox to your MATLAB path. Use the following  command :
%
%   addpath(genpath('/network/iss/cenir/software/irm/conda_env/tools/SANDI-Matlab-Toolbox-Latest-Release-main'))
%
% -------------------------------------------------------------------------



if ~exist('par'), par = ''; end

defpar.bvec     = 'bvec';
defpar.bval     = 'bval';
defpar.mask     = 'nodif_brain_mask';
defpar.noisemap = 'noisemap';
defpar.outname  = 'SANDI_Output'
defpar.StudyMainFolder = '' ;        % USER DEFINED: Path to the main folder where 


defpar.SNR      = []; % SNR;         if a noisemap from MPPCA denoising is provided, leave it empty. If no noisemap from MPPCA denoising is available, provide the SNR computed on an individual representative b=0 image
defpar.delta    = []; % Delta;       the diffusion gradient separation ( for PGSE sequence ) in ms. This is assumed the same for all the dataset within the same study.
defpar.smalldel = []; % smalldelta;  the diffusion gradient duration ( for PGSE sequence ) in ms. This is assumed the same for all the dataset within the same study.


% matvol

defpar.sge      = 1;
defpar.jobname  = 'SANDI_FIT';
defpar.mem           = '32G';
defpar.sge_nb_coeur  = 8;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

defpar.Dsoma =  3; % in micrometers^2/ms, if empty it is set to by default to 3
defpar.Din_UB =  3; % in micrometers^2/ms, if empty it is set to by default to 3
defpar.Rsoma_UB = []; % in micrometers, if empty it is set to by default to a max value given the diffusion time and the set Dsoma
defpar.De_UB = 3; % in micrometers^2/ms, if empty it is set to by default to 3

defpar.Nset = 1e5; % Size of the training set. Recommended values: 1e4 for testing the performance and between 1e5 and 1e6 for the analysis. Do not use values < 1e4. Values >1e6 might lead to 'out of memory'. 
defpar.MLmodel = 'RF'; % can be 'RF' for Random Forest; 'MLP' for multi-layer perceptron
defpar.FittingMethod = 0; % can be '0': minimizes MSE between ground truth model parameters and ML predictions. It has higher precision but lower accuracy; or '1': minimizes MSE between NLLS estimates of model parameters and ML predictions. It has higher accuracy but lower precision.
defpar.MLdebias = 0; % can be '0' or '1'. When '1', it will estimate slope and intercept from the prediciton vs ground truth relation (from training set) and correct the prediciton to follow the unit line. 

defpar.FWHM = 0.001; % size of the 3D Gaussian smoothing kernel. If needed, this smooths the input data before analysis.

defpar.UseDirectionAveraging = 1; % If set equal to 1, it calculates the powder-averaged signal as aritmetic mean over the directions instead of using the order zero SH.

defpar.DoTestPerformances = 0; % If '1' then it compares the performances of ML estimation with NLLS estimation on unseen simulated signals and write HTML report
defpar.diagnostics = 0; % can be '0' or '1'. When '1', figures will be plotted to help checking the results

defpar.WithDot = 0; % if 1 add 'dot' compartment in case needed, for example, in some cases to process ex vivo data





par = complet_struct(par,defpar);


if isempty(par.StudyMainFolder)
    par.StudyMainFolder  =  get_commonPath(fdwi)    % common Path
end

par.LogFileFilename = fullfile(par.StudyMainFolder,'SANDI_analysis_LogFile.txt');
par.LogFileID = fopen(par.LogFileFilename,'w');

bvec  = get_file_from_same_dir(fdwi,par.bvec,1);
bval  = get_file_from_same_dir(fdwi,par.bval,1);
mask  = get_file_from_same_dir(fdwi,par.mask,1);





if ~par.sge

disp('*****   SANDI analysis using Machine Learning based fitting method   ***** ')
dt = char(datetime("now"));
disp(['*****                          ' dt '                  ***** '])
fprintf(par.LogFileID,'*****   SANDI analysis using Machine Learning based fitting method   ***** \n');
fprintf(par.LogFileID,'*****                          %s                  ***** \n', dt);

end


% Check length 
par.DatasetList = get_parent_path(fdwi)


job = {};
for nbr = 1:numel(par.DatasetList)
    
    
    par.bvalues_filename = char(get_file_from_same_dir(fdwi(nbr),par.bval,1));
    par.bvecs_filename   = char(get_file_from_same_dir(fdwi(nbr),par.bvec,1));
    par.data_filename    = fdwi{nbr}
    
    par.mask_filename    = char(get_file_from_same_dir(fdwi(nbr),par.mask,1));
    
    try
        par.noisemap_mppca_filename = char(get_file_from_same_dir(fdwi(nbr), par.noisemap,1));
        
    catch MR
        fprintf(par.LogFileID,'*****   can''t load noisemap   ***** \n%s\n', MR.identifier);
        fprintf(par.LogFileID,'Putting par.noisemap_mppca_filename = []\n');
        par.noisemap_mppca_filename = [];
        if isempty(par.SNR)
            error('SNR or noisemap_mppca_filename must be defined');
        end 
    end
    
    if nbr==1 
        par.sigma_mppca = [];
        par.sigma_SHresiduals = [];
    end
    
    % Compute Direction-averaged signal
    par.output_folder = fullfile(par.DatasetList{nbr}, par.outname); % <---- Folder where the direction-averaged signal and SANDI fit results for each subject will be stored;
    %SANDIinput.report(subj_id, ses_id).r = report_generator([], fullfile(SANDIinput.output_folder,'SANDIreport'));
    par.subj_id = nbr;
       
    codejob =  gencode(par, 'par')';
    codejob{end+1}  = sprintf('\npar.LogFileID = fopen(par.LogFileFilename,''w'');\npar = make_direction_average(par);\n');
    codejob{end+1}  = sprintf('save(fullfile(''%s'',''par.mat''));\nfclose(par.LogFileID);\n', par.output_folder);
    job{end+1} = codejob;
    
end

    codecmd =  gencode(par, 'par')';
%    codecmd{end+1} = sprintf('par.sigma_mppca = [];\npar.sigma_SHresiduals = [];\n')
    codecmd{end+1} = sprintf('\n\npar.LogFileID = fopen(par.LogFileFilename,''w'');\nfor nbr =1:length(par.DatasetList)\n')
    codecmd{end+1} = sprintf('fmat   = gfile(fullfile(par.DatasetList{nbr}, par.outname),''^par.mat'');\nfpar = load(fmat{1});\n')
    codecmd{end+1} = sprintf('par.sigma_mppca = [par.sigma_mppca; fpar.par.sigma_mppca];\n par.sigma_SHresiduals = [par.sigma_SHresiduals; fpar.par.sigma_SHresiduals];\nend\n\n');
    codecmd{end+1} = sprintf('\npar = TrainMachineLearningModel(par); \n'); % trains the ML model on synthetic data
    codecmd{end+1} = sprintf('mkdir(fullfile(par.StudyMainFolder, ''Report_ML_Training_Performance''))');
    % Saving the Training Set

    codecmd{end+1} = sprintf('Signals_train = par.database_train_noisy;\nParams_train = par.params_train;\nPerformance_train = par.train_perf;\nBvals_train = par.model.bvals;\nSigma_mppca_train = par.model.sigma_mppca;\nSigma_SHresiduals_train = par.model.sigma_SHresiduals;\n');
    
    codecmd{end+1} = sprintf('save(fullfile(par.StudyMainFolder, ''Report_ML_Training_Performance'',''TrainingSet.mat''), ''Signals_train'',''Params_train'',''Performance_train'',''Bvals_train'', ''Sigma_mppca_train'', ''Sigma_SHresiduals_train'');\n\nfclose(par.LogFileID);\n');
    codecmd{end+1}  = sprintf('save(fullfile(''%s'',''par.mat''), ''par'',''-v7.3'');\n', par.StudyMainFolder);

    fclose(par.LogFileID);
    job{end+1} = codecmd;
    nbrJobs = length(job);

    
    
%  ------    

jobs = {};
for nbr = 1:numel(par.DatasetList)
    
    
    % Load the data
    par.output_folder = char(fullfile(par.DatasetList(nbr), par.outname));   % Ici check
    par.data_filename = fdwi{nbr};                                       % checked
    par.mask_filename = char(gfile(par.DatasetList(nbr), par.mask));
    
    % Fit the data
    %         par.subj_id = subj_id;
    %         par.ses_id = ses_id;
    
    
    codejobs =  gencode(par, 'param')';
    
    
    codejobs{end+1} = sprintf('fmat = gfile(param.StudyMainFolder,''^par.mat'');\nfpar = load(fmat{1});\n')
    codejobs{end+1} = sprintf('par = fpar.par;\npar.output_folder = param.output_folder;\npar.data_filename = param.data_filename;\npar.mask_filename=param.mask_filename;\n')
    
    codejobs{end+1}  = sprintf('\npar.LogFileID = fopen(par.LogFileFilename,''w'');\n');
    
    codejobs{end+1}  = sprintf('tic; if par.WithDot == 1, run_model_fitting_with_dot(par);else,run_model_fitting(par);end\ntt = toc;')
    codejobs{end+1}  = sprintf('disp([''DONE - Dataset analysed in in '' num2str(round(tt)) '' sec.''])\n')
    codejobs{end+1}  = sprintf('fprintf(par.LogFileID,[''DONE - Dataset analysed in in '' num2str(round(tt)) '' sec.''])\n');
    codejobs{end+1}  = sprintf('\nfclose(par.LogFileID);\n');
    job{end+1} = codejobs;
end

    
    do_cmd_matlab_sge(job, par);
    if isfield(par,'jobdir')
        fqsub = fullfile(par.jobdir, [par.jobname '/do_qsub.sh']);
    else
        fqsub = fullfile(pwd, [par.jobname '/do_qsub.sh']);
    end
    
    split_dependency_job(fqsub,(nbrJobs-1));
    split_dependency_job(fqsub,(nbrJobs));
    

end


function commonPath = get_commonPath(pathdir)

splitFolders = cellfun(@(p) strsplit(p, filesep), pathdir, 'UniformOutput', false);
commonPath   = '/';


for i = 1:min(cellfun(@numel, splitFolders))
    segment = splitFolders{1}{i};
    if all(cellfun(@(x) strcmp(x{i}, segment), splitFolders))
        commonPath = fullfile(commonPath, segment);
    else
        break
    end
end    
  
if isfile(commonPath)
  commonPath = get_parent_path(commonPath)
end

end


