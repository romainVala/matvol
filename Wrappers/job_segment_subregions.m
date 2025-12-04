function jobs = job_segment_subregions(sujname, par)
% FreeSurfer cross-sectional and longitudinal segmentation and command job generation
%
% This function segments three structures: thalamus, brainstem, hippo-amygdala.
% It must be run after recon-all.
%
% Inputs: 
%         sujname: cellstr of subject name used in the previous cross-sectional step, 
%                  or the base name for longitudinal analysis (use get_parent_path to get sujnames).
%         par: freesurfer and matvol parameters. 
%         par.subject_dir (alternatively, export SUBJECT_DIR) defines the subjects directory.
%         
% Output: segmentations and computed structure volumes. 
%
% Requires Freesurfer version 7.3 or higher. 
%  
% Usage example: module load FreeSurfer/7.4.1
%
%--------------------------------------------------------------------------



if ~exist('par','var'), par = ''; % for defpar
end


defpar.structure = 'all';      % 'thalamus', 'brainstem', 'hippo-amygdala'

defpar.segment_analysis = 0;   % 0 : cross-sectional analysis,  1 : longitudinal analysis

defpar.debug    = 0;           % Write intermediate debugging outputs for the 1st subject.
defpar.temp_dir = '';          % Path to write intermediate debugging outputs.
defpar.subject_dir = '';       % Subjects directory (override SUBJECTS_DIR env)

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

if ~isempty(par.temp_dir), temp_dir = ['--temp-dir ' par.temp_dir]; else, temp_dir = ''; end;

if ~isempty(par.subject_dir), subject_dir = ['--sd ' par.subject_dir]; else, subject_dir = ''; 
    warning('Parameter par.subject_dir is not set. Please ensure that the environment variable SUBJECT_DIR is correctly defined'); 
end;

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

