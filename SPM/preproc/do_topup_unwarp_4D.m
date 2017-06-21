function do_topup_unwarp_4D(multi_dir,par)

if ~exist('par','var')
    par='';
end

defpar.todo  = 0;
defpar.subdir = 'topup';
defpar.file_reg = '^f.*nii';
defpar.fsl_output_format='NIFTI';
defpar.do_apply = [];

par = complet_struct(par,defpar);


if iscell(multi_dir{1})
    nsuj = length(multi_dir);
else
    nsuj=1;
end


for ns=1:nsuj
    
    curent_ff = get_subdir_regex_files(multi_dir{ns},par.file_reg);
    
    suj = get_parent_path(multi_dir{ns}(1));
    fprintf('\n[%s]: currently working on %s \n', mfilename, suj{1})
    
    topup_outdir = r_mkdir(suj,par.subdir);
    
    
    
    for k=1:length(curent_ff)
        
        %if realig and reslice curent_ff is rf volume whereas the mean if meanf
        a = curent_ff{k}(1,:);
        [p fp ex] = fileparts(a);
        if strcmp(fp(1),'r')
            a = fullfile(p,[fp(2:end) ex]);
        end
        
        b=addprefixtofilenames({a},'mean');
        if ~exist(b{1},'var')
            sgeset = par.sge;
            par.sge=0;
            b{1} = do_fsl_mean(curent_ff(k),b{1},par);
            par.sge=sgeset;
        end
        
        if k>1
            if compare_orientation(fme(1),b(1)) == 0
                fprintf('WARNING reslicing mean image \n');
                bb= do_fsl_reslice( b(1),fme(1));
                b(1) = bb;
            end
        end
        
        curent_ff{k}=char([cellstr(char(curent_ff(k)));b]);
        fme(k) = b(1); %#ok<AGROW>
    end
    
    fout = addsuffixtofilenames(topup_outdir,'/4D_orig_topup_movpar.txt');
    
    if exist(fout{1},'file')
        fprintf('[%s]: skiping topup estimate because %s exist \n',mfilename,fout{1})
    else
        
        fprintf('load json % \n\n',fout{1})
        
        %ACQP=topup_param_from_nifti_cenir(curent_ff,topup_outdir)
        try
            ACQP=topup_param_from_json_cenir(fme,topup_outdir);
        catch err
            warning(err.message)
            ACQP=topup_param_from_nifti_cenir(fme,topup_outdir);
        end
        if size(unique(ACQP),1)<2
            error('all the serie have the same phase direction can not do topup')
        end
        
        fprintf('topup estimate %s \n',fout{1})
        
        fo = addsuffixtofilenames(topup_outdir,'/4D_orig');
        par.checkorient=1; %give error if not same orient
        do_fsl_merge(fme,fo{1},par);
        do_fsl_topup(fo,par);
        
    end
    
    fo = addsuffixtofilenames(topup_outdir,'/4D_orig_topup');
    
    if isempty(par.do_apply)
        par.do_apply = ones(size(curent_ff));
    end
    
    for k=1:length(curent_ff)
        %no because length is the same  realind = ceil(k/2); % because curent_ff ad the mean
        %par.index=realind;
        
        par.index=k;
        if par.do_apply(k)
            do_fsl_apply_topup(curent_ff(k),fo,par)
        end
        
    end
    
end

end % function
