function do_topup_unwarp_single_series(curent_ff,params)

topup_outdir = r_mkdir({params.subjectdir},params.topupdir);

if isfield(params,'display')
    par.fake = params.display;
end
par.sge=0;
par.fsl_output_format='NIFTI_PAIR';

for k=1:length(curent_ff)
    
    %if realig and reslice curent_ff is rf volume whereas the mean if meanf
    a = curent_ff{k}(1,:);
    [p fp ex] = fileparts(a);
    if strcmp(fp(1),'r')
        a = fullfile(p,[fp(2:end) ex]);
    end
    
    b=addprefixtofilenames({a},'mean');
    if ~exist(b{1})
        b{1} = do_fsl_mean(curent_ff(k),b{1},par);
    end
    curent_ff{k}=char([cellstr(char(curent_ff(k)));b]);
    fme(k) = b(1);
end

%ACQP=topup_param_from_nifti_cenir(curent_ff,topup_outdir)
try
    ACQP=topup_param_from_json_cenir(fme,topup_outdir);
catch
    ACQP=topup_param_from_nifti_cenir(fme,topup_outdir);
end


if size(unique(ACQP))<2
    error('all the serie have the same phase direction can not do topup')
end

cwd=pwd;

cd(topup_outdir{1})


fout = addsuffixtofilenames(topup_outdir,'/4D_orig_topup_movpar.txt');

if exist(fout{1})
    fprintf('skiping topup estimate because % exist',fout{1})
else
    
    fo = addsuffixtofilenames(topup_outdir,'/4D_orig');
    do_fsl_merge(fme,fo{1},par);
    do_fsl_topup(fo,par);
    
end

fo = addsuffixtofilenames(topup_outdir,'/4D_orig_topup');

for k=1:length(curent_ff)
    par.index=k;
    do_fsl_apply_topup(curent_ff(k),fo,par)
end

cd(cwd)

