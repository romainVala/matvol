function job_spm_single_results_display (fsub, Coordlist, par)
%%  INPUTS
%
%   FSUB : cell structure containing paths to subjects' folders (one or multiple)
% fsub = e.gpath; % EXAMPLE for multiple subjects
% fsub = {'/network/lustre/iss01/cenir/analyse/irm/users/anna.skrzatek/nifti/2019_02_27_REMINARY_HM_005_V2/model_meica/'} % EXAMPLE for one subject
%
%   COORDLIST : structure variable defining ROI's names and coordinates to
%   display
% Coordlist.values = cat(2,[0.0; 0.0; 0.0], [34.0; -24.0; 68.0], [-34.0; -24.0; 68.0], [-4.0; -48.0; -24.0], [0.0; -24.0; 10.0]); % EXAMPLE
% Coordlist.names = {'centre'; 'RIGHT SM'; 'LEFT SM'; 'CEREBELLUM'; 'MOTOR BI'}; % EXAMPLE
%
%   PAR : strucutre containing all variable parameters
% .RUN = 0; % prepares
% .DISPLAY = 0; %could be 1 in this case (to test)
% .REDO = 0;
% .ANAT_DIR_REG : regular expression to fetch the folder containing t1 image file
% .ANAT_FILE_REG : regular expression to fetch the t1 image file
% .SUBDIR : name of the working directory (wd) containing the SPM.mat file
% .OUTPUT_DIR : name of the output directory where we will save created figures : must be or will be created INSIDE the wd
% .CONNAME = 'F-all'; % name of the contrast we want to create figures for (only 1 at a time) - case insensitive
%
% + CLASSIC MATLAB PARAMETERS FOR SPM RESULTS SECTION LIKE:
% .CONTRASTS : number of the contrast in case conname unknown or not found in SPM.mat
% .THRESH : threshold of significance to use in statistics
% .EXTENT : minimal cluster size

% %% Init
    if ~exist('par','var')
        par = ''; % for defpar
    end

%% defpar

    defpar.run = 0;
    defpar.display = 0; %could be 1 in this case (to test)
    defpar.redo = 0;
    defpar.anat_dir_reg = 'S03_t1mpr_S256_0_8iso_p2';
    defpar.anat_file_reg = '^wms_S\d{2}.*p2.nii';
    defpar.subdir = 'model_meica';
    defpar.output_dir = 'figures_meica';
    defpar.conname = 'F-all'; % default corresponding to defpar.contrasts = 1 if user doesn't give any name of the contrast
    
    defpar.titlestr = '';
    defpar.contrasts = 0; % default to know if conname not found in SPM.mat
    defpar.threshdesc = 'none';
    defpar.thresh = 0.001;
    defpar.extent = 5;
    defpar.conjunction = 1;
    defpar.mask.none = 1;
    defpar.units = 1;
    defpar.print = 0;
    defpar.write.none = 0;
    
    par = complet_struct(par, defpar);
    
%% SPM:Stats:Results
    
    % assert length(fspm)==length(fanat) % coming soon to check if we have the anat and stat files for every subject
    
    if iscell(fsub(1))
        nrSubject = length(fsub);
    else
        nrSubject = 1;
    end

    skip = []
    
%% subject loop

    for subj = 1 : nrSubject
%    subj = 1;
        fspm = char(get_subdir_regex(fsub(subj), par.subdir));
        fanat = char(get_subdir_regex(fsub(subj), par.anat_dir_reg));
        SPM_search = char(addsuffixtofilenames(fspm, '/SPM.mat'));
        
        if exist(SPM_search, 'file')
           SPM_found = get_subdir_regex_files (fspm, 'SPM.mat');
           t1 = char(get_subdir_regex_files (fanat, par.anat_file_reg));
        else
            skip = [skip subj];
        end
    
        load (char(SPM_found));
        
% maybe a contrast loop here in the fututre
        for Ci = 1 : length(SPM.xCon)
            if strcmpi(SPM.xCon(1,Ci).name, par.conname)
                par.contrasts = Ci;
            end
        end
% msg if contrast not found and default contrast display
        if par.contrasts == 0
            fprintf('Contrast %s not found, displaying the F-all contrast instead', par.conname);
            par.contrasts == 1;
        end

%% SPM run
    
    spm('defaults','FMRI');
        jobs{subj}.spm.stats.results.spmmat = SPM_found;
        jobs{subj}.spm.stats.results.conspec.titlestr = par.titlestr;
        jobs{subj}.spm.stats.results.conspec.contrasts = par.contrasts; % Contrast loop in the future ?
        jobs{subj}.spm.stats.results.conspec.threshdesc = par.threshdesc;
        jobs{subj}.spm.stats.results.conspec.thresh = par.thresh;
        jobs{subj}.spm.stats.results.conspec.extent = par.extent;
        jobs{subj}.spm.stats.results.conspec.conjunction = par.conjunction;
        jobs{subj}.spm.stats.results.conspec.mask.none = par.mask.none;
        jobs{subj}.spm.stats.results.units = par.units;
        jobs{subj}.spm.stats.results.print = par.print;
        jobs{subj}.spm.stats.results.write.none = par.write.none;
        spm_jobman('run',jobs);
        

        hReg = findobj('Tag','hReg');
        xSPM = evalin('base', 'xSPM');
        
              
        spm_sections(xSPM,hReg,t1);

            %% Go to the position : aka ROI choice
         for iROI = 1 : length(Coordlist.values)

             hX    = findobj('Tag','hX');
             hFxyz = get(hX,'UserData');
             UD    = get(hFxyz,'UserData');


             nxyz = Coordlist.values(:,iROI);

             spm_XYZreg('SetCoords',nxyz,UD.hReg,hFxyz);
             spm_results_ui('UpdateSPMval',UD)
                
            %% Save figure
            %%inspired from orthviews_save (hObj, event, hC, imgfile) function in spm_ov_save.m (Guillaume Flandin (C))

             Fgraph = spm_figure('GetWin','Graphics');
                
             graphName = char(addsuffixtofilenames(addsuffixtofilenames(Coordlist.names(iROI),'_'),xSPM.title)); % choose the name according to the Subject & the Contrast & the ROI
                
             global st
                X  = frame2im(getframe(st.fig));
                sz = size(X);
                sz = [sz(1) sz(1) sz(2) sz(2)];
                p1 = get(st.vols{1}.ax{1}.ax,'Position');
                p2 = get(st.vols{1}.ax{3}.ax,'Position');
                a  = [p1(1) p1(2)  p2(1)+p2(3)-p1(1) p2(2)+p2(4)-p1(2)] + 0.005*[-1 -1 2 2];
                a  = max(min(a,1),0);
                sz = ([1-a(2)-a(4),1-a(2),a(1),a(1)+a(3)] .* (sz-1)) + 1;
                sz = round(sz);
                X  = X(sz(1):sz(2),sz(3):sz(4),:);
                
                output_dir = char(get_subdir_regex(fspm, par.output_dir));
                 if ~exist(output_dir,'dir')
                     mkdir(output_dir);
                 end
                 cd (output_dir)
                
                imwrite(X,graphName,'png');
                fprintf('Saving image as:\n');
                fprintf('  %s\n',spm_file(graphName,'link','web(''%s'')')); % saving file in the output directory
            end
        end
end
