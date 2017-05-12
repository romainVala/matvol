%this script does the time course extraction in a sphere

spm('defaults','FMRI')

%sujrootdir = '/servernas/home/traian/data/CERTRE_2models';
%s_dir = get_subdir_regex(sujrootdir,'CER');
%stat_dir = get_subdir_regex(s_dir,'stats','PPI_dir_preTMS')
%if you want to choose graphicaly
%s_dir = get_subdir_regex(sujrootdir,'graphically');

%logfile = 'Voi_PPI_dir_preTMS_CerebVI.log';

%VOI_coord = [24 -50 -24];
%VOI_coord = [24 -50 -24
%12 14 15
%15 15 15
%14 15 10];

%deuxieme alternative pour definir les coordonnees ecrire des fichiers texte (avec les coordonnees)
%dans un sous repertoir du sujet et donner comme argument ces fichiers
%par exemple
%VOI_coord = get_subdir_regex_files(stat_dir,'VOI_cerbeVI_coord.txt');

%Troisième alternative a partir d'un max
%VOI_mask = 'filepath_to_the_mask'

%VOI_coord_change = 'nearestmax'; %or other value will keep the position 

%SPHERE_spec = 4;    %sphere radius
%VOI_name = 'CerebVI';

%PPI_contrast = [1 -1 0];
%ppi_name = 'ppiCerebVI';

%NBsession = 1; %4
%ContrastNumSession = 1 ;%[47 48 49 50]; %number of Fcontrast for each session
%if PPI_contrast 3 colum First collome is the reg number second is the modulation number third is the wheight

if size(PPI_contrast,2)==3
  PPIMatrix = PPI_contrast;
else
  aa=1:length(PPI_contrast);
  bb=ones(1,length(PPI_contrast));
  PPIMatrix = [aa',bb',PPI_contrast'];
end

if ~strcmp(logfile(1),'/')
  logfile = fullfile(sujrootdir,logfile);
end


cwd=pwd;

for nbsuj = 1:length(stat_dir)
  
  cd(stat_dir{nbsuj})

  % DISPLAY THE MOTION CONTRAST RESULTS
  %---------------------------------------------------------------------
  clear jobs
  [pspm]=fileparts(which('spm')) ;

  jobs{1}.stats{1}.results.spmmat = cellstr(fullfile(stat_dir{nbsuj},'SPM.mat'));
  jobs{1}.stats{1}.results.conspec(1).titlestr = voicon.title;
  jobs{1}.stats{1}.results.conspec(1).contrasts = voicon.contrast;
  jobs{1}.stats{1}.results.conspec(1).threshdesc = voicon.thrdesc;
  jobs{1}.stats{1}.results.conspec(1).thresh = voicon.thresh;
  % jobs{1}.stats{1}.results.conspec(1).mask.contrasts = [];
  % jobs{1}.stats{1}.results.conspec(1).mask.thresh = [];
  % jobs{1}.stats{1}.results.conspec(1).mask.mtype = [];
  jobs{1}.stats{1}.results.conspec(1).extent = 0;
  jobs{1}.stats{1}.results.print = 0;
  
  spm_jobman('run',jobs);

  % overlay contrast on single-subj MNI template
  spm_sections(xSPM,findobj(spm_figure('FindWin','Interactive'),'Tag','hReg'),...
      fullfile(pspm,'canonical','single_subj_T1.nii')); 

  logstr = sprintf('Sujet %s \n',stat_dir{nbsuj});
  
  
  % % EXTRACT THE EIGENVARIATE
  %---------------------------------------------------------------------
  if exist('VOI_mask')
      xY.def = 'mask';
	if iscell(VOI_mask)
	xY.spec = spm_vol(VOI_mask{nbsuj})
else
      xY.spec = spm_vol(VOI_mask);
    end
  
      xY.name = VOI_name;
      xY.Ic   = 1;     % adjustment for effect of interest: enter the F contrast number from the GLM
      xY.Sess = 1;

  else
      
      if iscell(VOI_coord)
          voicoord = load(VOI_coord{nbsuj});
          logstr = sprintf('%s  Taking VOI coord file %s \n',logstr,VOI_coord{nbsuj});
      else
          if size(VOI_coord,1)>1
              voicoord = VOI_coord(nbsuj,:);
          else
              voicoord = VOI_coord;
          end
      end
      
      voipos = spm_mip_ui('SetCoords',voicoord);
      
      if strcmp(VOI_coord_change,'nearestmax')
          voipos = spm_mip_ui('Jump',spm_mip_ui('FindMIPax'),'nrmax') ;
          
          logstr = sprintf('%s  Jump %.2f mm from [%d %d %d]  to  [%d %d %d] \n',logstr,norm(voicoord-voipos'),voicoord,voipos);
      elseif strcmp(VOI_coord_change,'graphically')
          a = input('press enter when you have selected the voi center','s');
          voipos = spm_mip_ui('GetCoords');
          logstr = sprintf('%s  Graphically set voi coord [%d %d %d] \n',logstr,voipos);
          
      else
          logstr = sprintf('%s  Taking voi coord [%d %d %d] \n',logstr,voipos);
      end
      
      %start from the global poin and jump to the nearest global maxima
      clear xY;
      xY.xyz  = voipos;
      
      
      xY.name = VOI_name;
      xY.Ic   = 1;     % adjustment for effect of interest: enter the F contrast number from the GLM
      xY.Sess = 1;
      
      xY.def  = 'sphere';
      xY.spec = SPHERE_spec;
  end
  
  % GENERATE PPI STRUCTURE
  %=====================================================================
if length(NBsession)==1
  session_vector = 1:NBsession
else
  session_vector = NBsession
end

  for k = session_vector % 1:NBsession
    xY.Sess = k;  
    xY.Ic   = ContrastNumSession(k);
    
    [Y,xY]  = spm_regions(xSPM,SPM,hReg,xY);
    
    logstr = sprintf('%s  found %d point \n',logstr,size(xY.XYZmm,2));
    logmsg(logfile,logstr);
    
    if NBsession>1
      ppiname = [ppi_name ,'_Sess',num2str(k)];
    else
      ppiname = ppi_name;
    end
    
    PPI = spm_peb_ppi(SPM,'ppi',xY,PPIMatrix,ppiname,1);
    % FORMAT PPI = spm_peb_ppi(SPMname,ppiflag,VOI,Uu,ppiname,showGraphics);

    R=[PPI.ppi,PPI.Y,PPI.P];
    Rname = {sprintf('%s.ppi',ppiname),sprintf('%s.Y',ppiname),sprintf('%s.P',ppiname)};
    
    %ajouter les names dans le .mat
    save(['PPI_regressor_' ppiname],'R','Rname');

  end
end

%ajoute le model - tout - ou tout sauf le contrast -
%a chaque session ajoute la voi de la session correspond
