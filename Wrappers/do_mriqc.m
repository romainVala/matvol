function  do_mriqc(bids_dir,par)

if ~exist('par'),par ='';end

defpar.jobname = 'mriqc';
defpar.outdir = '';
defpar.sge=1;
defpar.plabel='';
% a mettre dans le do qsubcmd_prepend = sprintf(' module load mriqc\n source /network/lustre/iss01/cenir/software/irm/bin/python_path3.6\n '
defpar.workdir='';
defpar.singularity=1;
defpar.singu_bind='';
defpar.singu_image = '/network/lustre/iss01/cenir/software/irm/singularity/mriqc_singu.simg';

par = complet_struct(par,defpar);


bids_dir=cellstr(char(bids_dir));

cmd={};

if isempty(par.outdir)
    [pp fff] = get_parent_path(bids_dir{1})
    par.outdir = r_mkdir(pp,'mriqc_out');
end


for nbbids=1:length(bids_dir) %wont work with multiple workdir or outdir
    
    bdir = bids_dir{nbbids};
    
    if isempty(par.plabel)
        suj = gdir(bdir,'^sub');
        [pp sujname] = get_parent_path(suj);
    else
        sujname = par.plabel;
    end        
    
    for kk=1:length(sujname)
        if length(par.outdir)>1, od = par.outdir{kk}; else od=par.outdir{1}; end
        
        if par.singularity
            if ~isempty(par.singu_bind), sb = par.singu_bind; else, sb=od;end
            cmdini = sprintf('singularity run --bind %s:%s %s',sb,sb,par.singu_image);
        else
            cmdini = 'mriqc';
        end        

        cmd{end+1} = sprintf('%s %s %s participant  --n_cpus 1  --ants-nthreads 1 ',cmdini,bdir,od);
        cmd{end} = sprintf('%s--ica --fft-spikes-detector --hmc-fsl --no-sub --verbose-reports --participant-label %s ',...
            cmd{end},sujname{kk}(5:end));
        if ~isempty(par.workdir)
             cmd{end} = sprintf('%s --work-dir %s \n',cmd{end},par.workdir{kk});
        end
    end
end

do_cmd_sge(cmd,par)

