function job_spm_single_results_display(fspm, Ci, t1, Coordlist, output_dir, spmfile, wd)
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
    addpath(wd)
    addpath(output_dir)
    spm('defaults','FMRI');
        matlabbatch{1}.spm.stats.results.spmmat = fspm;
        matlabbatch{1}.spm.stats.results.conspec.titlestr = '';
        
        matlabbatch{1}.spm.stats.results.conspec.contrasts = Ci; % learn how to choose multiple contrasts or do a Contrast loop
        matlabbatch{1}.spm.stats.results.conspec.threshdesc = 'none';
        matlabbatch{1}.spm.stats.results.conspec.thresh = 0.001;
        matlabbatch{1}.spm.stats.results.conspec.extent = 5;
        matlabbatch{1}.spm.stats.results.conspec.conjunction = 1;
        matlabbatch{1}.spm.stats.results.conspec.mask.none = 1;
        matlabbatch{1}.spm.stats.results.units = 1;
        matlabbatch{1}.spm.stats.results.print = false;
        matlabbatch{1}.spm.stats.results.write.none = 1;
        spm_jobman('run',matlabbatch);
        
        
        hReg = findobj('Tag','hReg');
        xSPM = evalin('base', 'xSPM');
        
    %% Load section == 3DT1 normalized


 %       try
    %   hReg = findobj('Tag','hReg');
            
            spm_sections(xSPM,hReg,t1);

            %% Go to the position : aka ROI choice
            for iROI = 1 : length(Coordlist.values)

                hX    = findobj('Tag','hX'); % pick on, because we need the upper USerData
                hFxyz = get(hX,'UserData');
                UD    = get(hFxyz,'UserData');


                nxyz = Coordlist.values(:,iROI);
            %nxyz = rand(3,1)*30 -10;

                spm_XYZreg('SetCoords',nxyz,UD.hReg,hFxyz);
                spm_results_ui('UpdateSPMval',UD)
                
            %% Save figure

                Fgraph = spm_figure('GetWin','Graphics');
                
                %Fgraph.Children(2).Children(7).Children(2) - display
                %coordinates display next to images maybe
                % dCoord = findobj('Tag','OVmenu_Coordinates');

                graphName = char(addsuffixtofilenames(addsuffixtofilenames(Coordlist.names(iROI),'_'),spmfile.xCon(Ci).name));
                
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
                cd (output_dir);
                imwrite(X,graphName,'png');
                fprintf('Saving image as:\n');
                fprintf('  %s\n',spm_file(graphName,'link','web(''%s'')'));
                %saveas(Fgraph, graphName, 'jpeg') % choose the name according to the Subject & the Contrast & the ROI
            end
%        end
end