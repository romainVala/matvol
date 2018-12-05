function do_fsl_eddy(f4D,par,jobappend)

if ~exist('par'),par ='';end
if ~exist('jobappend','var'), jobappend ='';end

defpar.bvecs = '^bvecs$';
defpar.bvals = '^bvals$';
defpar.mask = 'nodif_brain_mask';
defpar.index = 'index.txt';

defpar.topup_dir = 'topup';
defpar.topup = '4D_B0_topup';
defpar.topup_acqp = 'acqp.txt';
defpar.outsuffix = 'eddycor';
defpar.resamp = 'jac'; %'jac' 'lsr'
defpar.eddy_add_cmd='';
defpar.sge=1;
defpar.jobname='eddy';
defpar.walltime='12:00:00';

par = complet_struct(par,defpar);

dtidir = get_parent_path(f4D);

par.index  = get_subdir_regex_files(dtidir,par.index,1);
if ~iscell(par.mask)
    par.mask  = get_subdir_regex_files(dtidir,par.mask,1);
end
par.bvecs = get_subdir_regex_files(dtidir,par.bvecs,1);
par.bvals = get_subdir_regex_files(dtidir,par.bvals,1);
outfile = addsuffixtofilenames(f4D,par.outsuffix);

if isempty(par.topup)
    for k=1:length(f4D)
        acqp = get_subdir_regex_files(dtidir(k),'acqp',1);
        
        cmd = sprintf('eddy %s --imain=%s  --mask=%s  --index=%s  --bvecs=%s  --bvals=%s  --acqp=%s   --out=%s --resamp=%s\n',...
            par.eddy_add_cmd,f4D{k},par.mask{k},par.index{k},par.bvecs{k},par.bvals{k},acqp{1},outfile{k},par.resamp);
        
        job{k} = cmd;
    end

else    
    if ischar(par.topup_dir) % then it is relative to DWI dir
        par.topup_dir = addsuffixtofilenames(dtidir,['/' par.topup_dir]);
    end
        
    par.topup_acqp = addsuffixtofilenames(par.topup_dir,['/' par.topup_acqp]);
    if ~strcmp(par.topup(1),'/')
        par.topup = addsuffixtofilenames(par.topup_dir,['/' par.topup]);
    end    
    
    for k=1:length(f4D)        
        cmd = sprintf('eddy %s --imain=%s  --mask=%s  --index=%s  --bvecs=%s  --bvals=%s  --acqp=%s  --topup=%s  --out=%s --resamp=%s\n',...
            par.eddy_add_cmd,f4D{k},par.mask{k},par.index{k},par.bvecs{k},par.bvals{k},par.topup_acqp{k},par.topup{k},outfile{k},par.resamp);
        
        job{k} = cmd;
    end
end

job = do_cmd_sge(job,par,jobappend);
