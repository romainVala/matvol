function job = do_fsl_eddyQC(f4D,par,jobappend)

if ~exist('par','var'),par ='';end
if ~exist('jobappend','var'), jobappend ='';end

defpar.bvecs = '^bvecs$';
defpar.bvals = '^bvals$';
defpar.mask = 'nodif_brain_mask';
defpar.index = 'index.txt';

defpar.topup_dir = 'topup';
defpar.topup = '4D_B0_topup';
defpar.topup_acqp = 'acqp.txt';
defpar.qc_dir_file='file_qcdir.txt';
defpar.eddy_add_cmd='';
defpar.sge=1;
defpar.jobname='QCeddy';
defpar.walltime='00:30:00';
defpar.mem = '600';

par = complet_struct(par,defpar);

[ dtidir ] = get_parent_path(f4D);

eddy_base_name = f4D;
%test which basename has been used for eddy 
ff= addsuffixtofilenames(eddy_base_name,'eddy_parameters');
if ~exist(ff{1},'file')
    eddy_base_name = change_file_extension(f4D,'');    
    ff= addsuffixtofilenames(eddy_base_name,'eddy_parameters');
end


par.index  = get_subdir_regex_files(dtidir,par.index,1);

if ~iscell(par.mask)
    par.mask  = get_subdir_regex_files(dtidir,par.mask,1);
end
par.bvecs = get_subdir_regex_files(dtidir,par.bvecs,1);
par.bvals = get_subdir_regex_files(dtidir,par.bvals,1);

if isempty(par.topup)
    acqp = get_subdir_regex_files(dtidir,'acqp',1);
    
else
    if ischar(par.topup_dir) % then it is relative to DWI dir
        par.topup_dir = addsuffixtofilenames(dtidir,['/' par.topup_dir]);
    end
    
    par.topup_acqp = addsuffixtofilenames(par.topup_dir,['/' par.topup_acqp]);
    if ~strcmp(par.topup(1),'/')
        par.topup = addsuffixtofilenames(par.topup_dir,['/' par.topup]);
    end
    acqp = par.topup_acqp;
    
end

ffid = fopen(par.qc_dir_file,'w+')

for k=1:length(f4D)
    
    cmd = sprintf('eddy_quad %s -idx %s -par %s -m %s -b %s -g %s -v \n',...
        eddy_base_name{k},par.index{k},acqp{k},par.mask{k},par.bvals{k},par.bvecs{k});
    
    job{k} = cmd;
    
    fprintf(ffid,'%s.qc\n',eddy_base_name{k});
    
end

fclose(ffid)

job2 = {sprintf('eddy_squad %s/%s',pwd,par.qc_dir_file)};


[job fqsub] = do_cmd_sge(job,par,jobappend);

    
par.jobname = [par.jobname '_last'];
do_cmd_sge(job2,par,'',fqsub);
    
