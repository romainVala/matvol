function job_spm_single_results_display (fsub, Coordlist, par)
%%  INPUTS
%   FSPM : cell variable defining the path to the SPM.mat file
%   CI : integer variable with the number of the contrast to display
%   T1 : character variable defining the path to the T1 MRI volume to
%   display
%   COORDLIST : structure variable defining ROI's names and coordinates to
%   display
%   OUTPUT_DIR : directory path where you want your figures to be saved
%   SPMFILE : structure variable defining SPM model
%   WD : working directory path where to find this script
%
%%
    % fsub = e.gpath;
% fspm = {'/network/lustre/iss01/cenir/analyse/irm/users/anna.skrzatek/nifti/2019_02_27_REMINARY_HM_005_V2/model_meica/'}
% fanat = {'/network/lustre/iss01/cenir/analyse/irm/users/anna.skrzatek/nifti/2019_02_27_REMINARY_HM_005_V2/S03_t1mpr_S256_0_8iso_p2/'}
% Coordlist.values = cat(2,[0.0; 0.0; 0.0], [34.0; -24.0; 68.0], [-34.0; -24.0; 68.0], [-4.0; -48.0; -24.0], [0.0; -24.0; 10.0]); 
% Coordlist.names = {'centre'; 'RIGHT SM'; 'LEFT SM'; 'CEREBELLUM'; 'MOTOR BI'}; 


% %% Init
    if ~exist('par','var')
        par = ''; % for defpar
    end
%% defpar

    defpar.sge = 0;
    defpar.run = 0;
    defpar.display = 0; %could be 1 in this case (to test)
    defpar.redo = 0;
    defpar.anat_dir_reg = 'S03_t1mpr_S256_0_8iso_p2';
    defpar.anat_file_reg = '^wms_S\d{2}.*p2.nii';
    defpar.subdir = 'model_meica';
    defpar.output_dir = 'figures_meica';
    defpar.conname = 'F-all'; % default corresponding to defpar.contrasts = 1
    
    defpar.titlestr = '';
    defpar.contrasts = 1; % default if conname not found in SPM.mat %coming soon research of name in the SPM file
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
    
    % assert length(fspm)==length(fanat)
    
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
        
% can I put a contrast loop here ? do a separate function looking for a
% contrast name in the SPM file
        for Ci = 1 : length(SPM.xCon)
            if strcmpi(SPM.xCon(1,Ci).name, par.conname)
                par.contrasts = Ci;
            end
        end
        %% SPM run
    
    spm('defaults','FMRI');
        jobs{subj}.spm.stats.results.spmmat = SPM_found;
        jobs{subj}.spm.stats.results.conspec.titlestr = par.titlestr;
        jobs{subj}.spm.stats.results.conspec.contrasts = par.contrasts; % do a Contrast loop
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

             hX    = findobj('Tag','hX'); % pick on, because we need the upper USerData
             hFxyz = get(hX,'UserData');
             UD    = get(hFxyz,'UserData');


             nxyz = Coordlist.values(:,iROI);

             spm_XYZreg('SetCoords',nxyz,UD.hReg,hFxyz);
             spm_results_ui('UpdateSPMval',UD)
                
            %% Save figure

             Fgraph = spm_figure('GetWin','Graphics');
                
             graphName = char(addsuffixtofilenames(addsuffixtofilenames(Coordlist.names(iROI),'_'),xSPM.title));
                
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
                fprintf('  %s\n',spm_file(graphName,'link','web(''%s'')'));
                %saveas(Fgraph, graphName, 'jpeg') % choose the name according to the Subject & the Contrast & the ROI
            end
        end
end
