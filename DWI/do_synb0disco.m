function job = do_synb0disco(fileb0, filet1, par)
% DO_SYNB0DISCO : DIStortion COrrection of dMRI without reverse phase-encoding scans or field-maps
% 
% 
% Inputs :
%        fileb0 : (cell array), path to b0 images 
%        filet1 : (cell array), path to T1 images
%
%        par    : parameters structurs 
%
%
%
% Use Singularity po
% synb0-disco image container version : see defpar.img
%
% To build an other image container version :
%    singularity pull docker://leonyichencai/synb0-disco:"new version"
%    and change par.img path
%
% If running the in your computer use :
% export PATH="/network/lustre/iss01/apps/tools/singularity/3.8.3/bin:$PATH"
%
% If running the jobs in cluster use :
%  module load singularity/3.8.3
%  module load FreeSurfer/7.1.1
%
%
%--------------------------------------------------------------------------









if ~exist('par'), par = ''; end

defpar.img      = {'/network/lustre/iss02/cenir/software/irm/conda_env/singularity/synb0-disco_v3.1.sif'};   % path to singularity synb0-disco image container
defpar.notopup  = 0;        % 0 : run topup | 1 : do not run topup 
defpar.stripped = 0;        % 0 : used T1 not skull stripped | 1 : used T1 skull stripped
defpar.output   = 'b0corrected';  % topup output files prifex if run topup
defpar.workdir  = 'synb0';        % create folder in the same "fb0" folder
defpar.json_reg = '.*json'; % regex to get json file in the same fbO folder 
defpar.freesurfer = {'${FREESURFER_HOME}/license.txt'} % path to freesurfer licesnse.txt file, use any freesurfer loaded
defpar.acqp       = [0 1 0 0.05];
defpar.redo       = 0;


defpar.sge      = 1;
defpar.jobname  = 'synb0-dwi';
defpar.mem      = '16G';
defpar.waltime  = '48';
defpar.nbthread = 1 ;

par = complet_struct(par,defpar);

sge = par.sge; par.sge =-1;
assert(length(fileb0)==length(filet1),'Input cells must have the same size!');

pdirb0 = get_parent_path(fileb0,1);

% assert(length(fjson)==length(filet1),'json files size mismatch, check par.json_reg  !');

% Prepare the work file

workdir = fullfile(pdirb0, par.workdir);
output  = r_mkdir(pdirb0,par.output); 
if exist(workdir{1},'dir') && ~par.redo

    error('Workdir exist');
else
    dwork = r_mkdir(pdirb0, par.workdir);
    
    fb0 = fullfile(dwork,'b0.nii');
    ft1 = fullfile(dwork,'T1.nii');
%   ~~~
for nf =1:length(fileb0)
    isb0link = ~unix(sprintf('test -L %s\n',fileb0{nf}));
    ist1link = ~unix(sprintf('test -L %s\n',filet1{nf}));
    
    if isb0link
        [~,pathLink] = unix(sprintf('readlink -f  %s',fileb0{nf}));
        ffb0{nf}     = pathLink;
    else
        ffb0{nf} = fileb0{nf};
    end
    
    if ist1link
        [~,pathLink] = unix(sprintf('readlink -f  %s',filet1{nf}));
        fft1{nf} = pathLink;
    else
        fft1{nf} = filet1{nf};
    end
    
    
end

[fb0, jcopyb0] = r_movefile(ffb0, fb0','copy',par);
[ft1, jcopyt1] = r_movefile(fft1, ft1','copy',par);


% Combine files to use the function below


notopup  = '--notopup';
stripped = '';
if par.stripped, stripped = '--stripped'; end

job = {};
for nbr =1:length(dwork)
    cmd = sprintf('gzip -f %s\n',fb0{nbr});
    cmd = sprintf('%sgzip -f %s\n\n',cmd,ft1{nbr});

    cmd = sprintf('%ssingularity run --cleanenv -B %s:/INPUTS/ \\\\\n',cmd,dwork{nbr});
    cmd = sprintf('%s-B %s:/OUTPUTS \\\\\n',cmd, output{nbr});
    cmd = sprintf('%s-B %s:/extra/freesurfer/license.txt \\\\\n', cmd, par.freesurfer{1});
    
    
    %   A text file that describes the acqusition parameters
    if ~par.notopup
        notopup = '';
        
        
         fjson = gfile(pdirb0{nbr},par.json_reg,1); 
        try
                   
            acqp  = topup_param_from_json_cenir([fb0(nbr) ; fb0(nbr)],[], [fjson ; fjson]) % combine files to use the function
        catch
            acqp  = par.acqp;
        end
        
        fid  = fopen(fullfile(dwork{nbr},'acqparams.txt'),'wt');
        % Write the file acqparams.txt
        fprintf(fid,'%s',sprintf('%d %d %d %.4f',acqp(1,1),acqp(1,2),acqp(1,3),acqp(1,4)));
        fprintf(fid,'\n%s',sprintf('%d %d %d 0.00',acqp(1,1),acqp(1,2),acqp(1,3)));
        
    end
    
    cmd = sprintf('%s%s %s %s', cmd, par.img{1}, notopup,stripped);
    job{end+1} = cmd;
    
    

end

jobcopy = do_cmd_sge(jcopyt1,par,jcopyb0);

par.sge = sge;
job = do_cmd_sge(job,par,jobcopy);
      

border = repmat('-', 1, 100);
fprintf('%s\n\n      Don''t forget to run:\n      module load singularity/xxx\n      module load FreeSurfer/xxx\n\n%s\n', border, border);

end
