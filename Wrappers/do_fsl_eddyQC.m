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

%find eddy name
ffeddy = gfile(dtidir,'eddy_parameters$',1);
[~, eddy_base_name] = get_parent_path(ffeddy);
for k=1:length(eddy_base_name)
    eddy_base_name{k} = eddy_base_name{k}(1:end-16);
end


par.index  = get_subdir_regex_files(dtidir,par.index,1);

if ~iscell(par.mask)
    par.mask  = get_subdir_regex_files(dtidir,par.mask,1);
end
par.bvecs = get_subdir_regex_files(dtidir,par.bvecs,1);
par.bvals = get_subdir_regex_files(dtidir,par.bvals,1);

for k=1:length(dtidir)
    dtopup = gdir(dtidir(k),par.topup_dir);
    if length(dtopup) == 0
        acqp(k) = gfile(dtidir(k),'^acqp',1);
    elseif length(dtopup) == 1
        acqp(k) = gfile(dtopup,'^acqp',1);
    else
        error('Suj %s too much topup dir change par.topup ', dtidir{k})
    end
end

% if isempty(par.topup)
%     acqp = get_subdir_regex_files(dtidir,'acqp',1);
%     
% else
%     if ischar(par.topup_dir) % then it is relative to DWI dir
%         par.topup_dir = addsuffixtofilenames(dtidir,['/' par.topup_dir]);
%     end
%     
%     par.topup_acqp = addsuffixtofilenames(par.topup_dir,['/' par.topup_acqp]);
%     if ~strcmp(par.topup(1),'/')
%         par.topup = addsuffixtofilenames(par.topup_dir,['/' par.topup]);
%     end
%     acqp = par.topup_acqp;
%     
% end

ffid = fopen(par.qc_dir_file,'w+')

job={}
for k=1:length(f4D)
    
    dd = gdir(dtidir(k),'qc$')
    if length(dd)>0
        fprintf('skiping %s because %s exist\n',dtidir{k},dd{1})
        continue
    end
    
    cmd = sprintf('cd %s\neddy_quad %s -idx %s -par %s -m %s -b %s -g %s -v \n',...
        dtidir{k}, eddy_base_name{k},par.index{k},acqp{k},par.mask{k},par.bvals{k},par.bvecs{k});
    
    job{end+1} = cmd;
    
    fprintf(ffid,'%s.qc\n',eddy_base_name{k});
    
end

fclose(ffid)

job2 = {sprintf('eddy_squad %s/%s',pwd,par.qc_dir_file)};


[job fqsub] = do_cmd_sge(job,par,jobappend);

    
par.jobname = [par.jobname '_last'];
do_cmd_sge(job2,par,fqsub);
    
