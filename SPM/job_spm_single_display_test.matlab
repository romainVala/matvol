function job_spm_single_results_display(dirStats, Conname, coordList, par)
%%  INPUTS
% 	DIRSTATS : paths to all subjects' sessions
%   FSPM : cell variable defining the path to the SPM.mat file --> replace by addsuffixtofilenames function
%   CI : integer variable with the number of the contrast to display --> search the contrast name in SPM.mat with the Conname and SPM file
%   T1 : character variable defining the path to the T1 MRI volume to
%   display --> replace by addsuffixtofilenames function
%   COORDLIST : structure variable defining ROI's names and coordinates to
%   display
%   OUTPUT_DIR : directory path where you want your figures to be saved --> find in par structure and use addsuffixtofilenames function to create directory in model_meica
%   SPMFILE : structure variable defining SPM model --> replace by addsuffixtofilenames function to fetch SPMfile for each subject as in job_first_level specify
%   WD : working directory path where to find this script --> use addsuffixtofilenames function to define model_meica directory
%
%%
% par structure like in all SPM functions

	if ~exist ('par', 'var')
		par = '';
	end

	defpar.sge = 0;
	defpar.run = 0;
	defpar.display = 0; % maybe 1 in this case : test
	defpar.redo = 0;
	defpar.anat_file_reg = '^wms_S\d{2}.*.nii';
	defpar.subdir = 'meica';

	defpar.titlestr = '';
	defpar.contrasts = 1; % par defaut afficher le contrast F-all
	defpar.threshdesc = 'none';
	defpar.thresh = 0.001; % par defaut
	defpar.extent = 5; % par defaut
	defpar.conjunction = 1;
	defpar.mask.none = 1;
	defpar.units = 1;
	defpar.print = false;
	defpar.write.none = 1;


	par.complet_struct(par, defpar);

	% parameters user can change but must be there

	if iscell(dirStats{1})
		nrSubject = length(dirStats);
	else
		nrSubject = 1;
	end

%	skip = []; % if [ jobs ] = job_ending_rountines(jobs,skip,par);

	%% Subject loop
	for subj = 1 : nrSubject

		fspm = char(addsuffixtofilenames(dirStats(subj),'meica/SPM.mat'));
		t1 = char(addsuffixtofilenames(addsuffixtofilenames(dirStats(subj),'meica/'), par.anat_file_reg));

		wd = char(addsuffixtofilenames(dirStats(subj),'meica'));


		for incon = 1 in Conname
			for ispm=1:length(fspm.xCon(1,:))

				if strcmpi(fspm.xCon(1,i))==1
					par.contrasts = i;
				end

				jobs{subj}.spm.stats.results.spmmat 			= fspm;
				jobs{subj}.spm.stats.results.conspec.titlestr 	= par.titlestr;
				jobs{subj}.spm.stats.results.conspec.contrasts 	= par.contrasts;
				jobs{subj}.spm.stats.results.conspec.threshdesc = par.threshdesc;
				jobs{subj}.spm.stats.results.conspec.thresh 	= par.thresh;
				jobs{subj}.spm.stats.results.conspec.extent 	= par.extent;
				jobs{subj}.spm.stats.results.conspec.conjunction= par.conjunction;
				jobs{subj}.spm.stats.results.conspec.mask.none 	= par.mask.none;
				jobs{subj}.spm.stats.results.units 				= par.units;
				jobs{subj}.spm.stats.results.print 				= par.print;
				jobs{subj}.spm.stats.results.write.none 		= par.write.none;
%% I think here we should execute one job at a time, rather than collecting them in a cellstr because of the visual output we use with each contrast
				% spm_jobman('run', jobs{subj});
				% ou
%% Run the jobs (found in job_sort_echos function)

% Fetch origial parameters, because all jobs are prepared
				% par.sge     = parsge;
				% par.verbose = parverbose;

				% jobs = do_cmd_sge(jobs, par);

				hReg = findobj('Tag','hReg');
				xSPM = evalin('base','xSPM');

				spm_sections(xSPM,hReg,t1);
%% ROI loop
				for iROI = 1 : length(coordList.values)

					hX 		= findobj('Tag','hX');
					hFxyz 	= get(hX,'UserData');
					UD 		= get(hFxyz,'UserData');

					nxyz 	= coordList.values(:,iROI);

					spm_XYZreg('SetCoords',nxyz, UD.hReg,hFxyz);
					spm_results_ui('UpdateSPMval', UD);

					%% Save figure %% adaptation from orthviews_save (hObj, event, hC, imgfile) function in spm_ov_save.m (Guillaume Flandin (C))

	                Fgraph = spm_figure('GetWin','Graphics');

	                graphName = char(addsuffixtofilenames(addsuffixtofilenames(Coordlist.names(iROI),'_'),fspm.xCon(Ci).name));
	                
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

				end % of ROI loop
			end % of contrast loop
	end % of subject loop

end