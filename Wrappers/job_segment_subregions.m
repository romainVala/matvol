function jobs = job_segment_subregions(sujname, par)

% FreeSurfer cross-sectional and longitudinal segmentation
% Generate commands jobs == > cluster 
% Segment three structures : thalamus, brainstem, hippo-amygdala
% This func in used after ran recon-all 
%
% Inputs: cellstr, sujname (or suj ID) for cross-sectional analysis or base name for
% longitudinal analysis
%
%  
% Output segmentations and computed structure volumes will be saved to the
% Need Freesurfer 7.3 or more 
%  
% Use ex. module load FreeSurfer/7.4.1
% and export SUBJECT_DIR=path2freesurfer recon-all or par.subject_dir
% 



if ~exist('par','var'), par = ''; % for defpar
end


defpar.structure = 'all';      % thalamus, brainstem, hippo-amygdala

defpar.segment_analysis = 0;   % 0 : cross-sectional analysis,  1 : longitudinal analysis

defpar.debug    = 0;           % Write intermediate debugging outputs for the 1st subject.
defpar.temp_dir = {''};        % Path to write intermediate debugging outputs.
defpar.subject_dir = {''};     % Subjects directory (override SUBJECTS_DIR env)

% Matvol opt

defpar.walltime = '48:00:00';
defpar.jobname  = 'segment_subregions';

par = complet_struct(par,defpar);


switch par.segment_analysis
    case 0
        segment_analysis = '--cross';
    case 1
        segment_analysis = '--long-base';
    otherwise
        error('Unknown segmentation mode, please check ''par.segment_analysis''');
        
end

if par.debug, debug =  '--debug'; else, debug = ''; end;

if ~isempty(par.temp_dir{1}), temp_dir = ['--temp-dir ' par.temp_dir{1}]; else, temp_dir = ''; end;

if ~isempty(par.subject_dir{1}), subject_dir = ['--sd ' par.subject_dir{1}]; else, subject_dir = ''; end;

jobs = {};
for nbr = 1 : length(sujname)
    
    cmd = sprintf('%s %s %s', segment_analysis, sujname{nbr}, subject_dir);
    
    switch par.structure
        
        case 'all' %  Can't do it in one command 
            cmd_structure = sprintf('segment_subregions thalamus %s %s %s\n', cmd,  debug, temp_dir);
            cmd_structure = sprintf('%ssegment_subregions brainstem %s\n',cmd_structure,cmd);          
            cmd_structure = sprintf('%ssegment_subregions hippo-amygdala %s\n',cmd_structure,cmd);            
        case 'thalamus'
            cmd_structure = sprintf('segment_subregions thalamus %s %s %s\n', cmd,  debug, temp_dir);
        case 'brainstem'
            cmd_structure = sprintf('segment_subregions brainstem %s %s %s\n', cmd,  debug, temp_dir);
        case 'hippo-amygdala'
            cmd_structure = sprintf('segment_subregions hippo-amygdala %s %s %s\n', cmd,  debug, temp_dir);
            
        otherwise
                error('Unknown structure to segment. Selection one option :  all, thalamus, brainstem, hippo-amygdala');
    end 
    
    
    if nbr > 1, debug = '';temp_dir='';end
   jobs{end+1} = cmd_structure; 
    
end


 do_cmd_sge(jobs,par);



end

