function job = job_fastSurfer(fanat,par)
% JOB_FASTSURFER : Creating Fastsurfer segmentation jobs  
%                 Fastsurfer is a pipline for segmentation and surface reconstruction
%                 based on deep learning. 
%              
%
% Input :
%        fanat : provide cellstr T1 image path
%        par   : matvol parameters structure
%
% Output :
%        generate jobs whose number is equal to the size of the fanat input variable
%        
%
% environment :
%   module load singularity/***
%   module load FreeSurfer/***
%
%--------------------------------------------------------------------------



if ~exist('par'), par = ''; end

%  flags   = 

defpar.output   = {};   % Path to save FastSurfer segmentation!
defpar.sujname  = {};   %
defpar.copylink = 0;    % Copy the linked T1 files

defpar.img        = {'/network/iss/cenir/software/irm/singularity/fastsurfer-gpu.sif'};
defpar.freesurfer = {'${FREESURFER_HOME}'} % path to freesurfer the folder where the licesnse.txt file, use any freesurfer loaded
defpar.asegdkt  = 1;  % default
defpar.cereb    = 1;  % default
defpar.hypothal = 1;



defpar.addPath  = '';    % subfolder name

defpar.walltime  = '24';

defpar.sge      = 1;
defpar.jobname  = 'RunFastSurfer';
defpar.mem      = '16G';
defpar.nbthread = 1 ;


par = complet_struct(par,defpar);


assert(length(par.sujname) == length(fanat),'Size of par.sujname and fanat muse be the same');
output = cellstr(char(par.output));
sub    = gdir(output,par.sujname);

assert(isempty(sub),'Output name already exists');



job={};

for nbr = 1:length(fanat)
    cmd = 'singularity exec --nv --no-home '
    ist1link = ~unix(sprintf('test -L %s\n',fanat{nbr}));
    
    ppath = split(fanat(nbr),par.sujname{nbr});       % !
    
    
    if ist1link
        [~, pathLink]  = unix(sprintf('readlink -f  %s',fanat{nbr}));
        
        if par.copylink
            %  [ft1, jcopyt1] = r_movefile(fft1, ft1','copy',par);   
        else   
            ppath = split(cellstr(char(pathLink)),par.sujname{nbr});
            
        end
        
    end
        
    
    cmd = sprintf('%s -B %s:/data -B %s:/output',cmd, ppath{1}, output{1});                      % path data
    cmd = sprintf('%s -B %s:/fs_license \\\\\n%s \\\\\n', cmd, par.freesurfer{1},par.img{1});    %
    
    cmd = sprintf('%s/fastsurfer/run_fastsurfer.sh --fs_license /fs_license/license.txt', cmd ); %
    cmd = sprintf('%s --t1 /data/%s/%s --sid %s --sd /output --parallel --3T', cmd, par.sujname{nbr}, ppath{2},par.sujname{nbr})
    
    
    job{end+1} = cmd;
    
end

job = do_cmd_sge(job,par);


border = repmat('-', 1, 100);
fprintf('%s\n\n      Don''t forget :\n      module load singularity/xxx\n      module load FreeSurfer/xxx\n\n%s\n', border, border);


end
