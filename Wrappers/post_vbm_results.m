function couts = post_vbm_results(dir_vbm,par)
%function fo = do_fsl_bin(f,prefix,seuil)
%if seuil is a vector [min max] min<f<max
%if seuil is a number f>seuil


if ~exist('par'),par ='';end

defpar.redo = 1;
defpar.sge=0;
defpar.job_pack=10;
defpar.jobname = 'vbm_results';
defpar.walltime = '01:00:00';
defpar.resfilename = 'seg_results.csv'; %'seg_rrres.csv';
defpar.resfilenameAES = 'AES_results.csv'; %'seg_rrres.csv';
defpar.segreg='[cp]'; %p for vbm8
defpar.volreg='s'; %p for vbm8
defpar.brainmask = 'mask_brain_erode_dilate.nii.gz';
defpar.fms='';
defpar.niftireg_warp = '';
defpar.spm_warp = '';
defpar.spmTPM = '/network/lustre/iss01/cenir/analyse/irm/users/romain.valabregue/dicom/mni/TPM';
defpar.nrTPM = '/network/lustre/iss01/cenir/analyse/irm/users/romain.valabregue/dicom/mni/mean_nr1000/Mean_S50_all.nii';

par = complet_struct(par,defpar);

if ischar(dir_vbm)
    dir_vbm={dir_vbm};
end

if par.sge
    for k=1:length(dir_vbm)
        cmd{k} = sprintf('dir_vbm=''%s'';\npar.redo=%d; par.segreg=''%s'';par.volreg=''%s'';\npar.brainmask=''%s'';\n',...
            dir_vbm{k},par.redo,par.segreg,par.volreg,par.brainmask);
        if iscell(par.fms), cmd{k} = sprintf('%s par.fms={''%s''};\n', cmd{k},par.fms{k});end
        if iscell(par.niftireg_warp), cmd{k} = sprintf('%s par.niftireg_warp={''%s''};\n', cmd{k},par.niftireg_warp{k});end
        if iscell(par.spm_warp), cmd{k} = sprintf('%s par.spm_warp={''%s''};\n', cmd{k},par.spm_warp{k});end
        cmd{k} = sprintf('%s\npost_vbm_results(dir_vbm,par);\n',cmd{k});
            
    end
    
    do_cmd_matlab_sge(cmd,par)
    return
end


for k=1:length(dir_vbm)
    cur_dir = dir_vbm{k};
    
    fres = fullfile(cur_dir,par.resfilename);
    fresAES = fullfile(cur_dir,par.resfilenameAES);
    cout = struct;
    
    if exist(fres,'file')
        if par.redo > 0;
            doit=1;
            if par.redo>1
                do_delete(fres,0);
            else
                try
                    cout = read_res({fres}); cout=cout{1};
                catch                    
                    fprintf('ERROR BAD results csv  %s\n',fres);
                    do_delete(fres,0);
                end
            end
        else
            doit=0;
        end
        
    else
        doit=1;
    end
    cin=cout;
    
    if doit
        if iscell(par.fms)
            fms = par.fms(k);
        else
            fms = get_subdir_regex_files(cur_dir,['^m',par.volreg],1);
        end
        fp = get_subdir_regex_files(cur_dir,['^',par.segreg,'[123].*nii']);
        if isempty(fp)
            fp = get_subdir_regex_files(cur_dir,['^pve.*nii']);
            cmd = sprintf('cd %s\n mrcalc pve.nii.gz 2 -eq  p1s_S.nii.gz \n  mrcalc pve.nii.gz 3 -eq  p2s_S.nii.gz\n mrcalc pve.nii.gz 1 -eq  p3s_S.nii.gz',cur_dir);
            unix(cmd);
        end

        
        if ~isfield(cout,'mask_vol')
            fp = get_subdir_regex_files(cur_dir,['^',par.segreg,'[123].*nii']);
            if ~isempty(fp)
                if size(fp{1},1)==3
                    [v m std E ] = do_fsl_getvol(fp);            vv=(v(:,2).*m/1000);
                    
                    cout.gray_vol = vv(1);    cout.white_vol = vv(2);  cout.csf_vol = vv(3);
                    cout.gray_std = std(1);   cout.white_std = std(2); cout.csf_std = std(3);
                    cout.gray_E = E(1);       cout.white_E = E(2);     cout.csf_E = E(3);
                    
                    fo=fullfile(cur_dir,par.brainmask);
                    if ~exist(fo,'file')
                        %fms = get_subdir_regex_files(cur_dir,['^m',par.volreg],1);
                        do_fsl_mask_from_spm_segment(fms);
                    end
                    v=do_fsl_getvol(fo);            cout.mask_vol = v(2)/1000;
                    
                end
            end
        end
        
        if ~isfield(cout,'vbm_rp1_vol')            
            fp = get_subdir_regex_files(cur_dir,['^r',par.segreg,'[123].*nii']);
            if ~isempty(fp)
                if size(fp{1},1)==3
                    [v m ] = do_fsl_getvol(fp);         vv=(v(:,2).*m/1000);
                    cout.vbm_rp1_vol = vv(1);   cout.vbm_rp2_vol = vv(2);  cout.vbm_rp3_vol = vv(3);
                end
            end
        end
        
        if ~isfield(cout,'stpm_ncor_csf')
            fp = get_subdir_regex_files(cur_dir,'^w[pc][123].*nii');
            fpm = get_subdir_regex_files(cur_dir,['^w' par.brainmask]);

            if isempty(fp) || isempty(fpm)
                try
                fpr = get_subdir_regex_files(cur_dir,'^[pc][123].*nii',3);
                fprm =  get_subdir_regex_files(cur_dir,['^' par.brainmask]);
                if iscell(par.spm_warp), fy = par.spm_warp(k);
                else, fy = get_subdir_regex_files(cur_dir,['^y_',par.volreg,'.*nii'],1);end
                
                fy = unzip_volume(fy); 
                
                if isempty(fp) 
                    unzip_volume(fpr);fpr = get_subdir_regex_files(cur_dir,'^[pc][123].*nii',3);
                    job_apply_normalize(fy,fpr,struct('run',1)); 
                    fp = get_subdir_regex_files(cur_dir,'^w[pc][123].*nii');
                    gzip_volume(fp); gzip_volume(fpr); 
                    fp = get_subdir_regex_files(cur_dir,'^w[pc][123].*nii');
                end
                if isempty(fpm)
                    fprm = unzip_volume(fprm);
                    job_apply_normalize(fy,fprm,struct('run',1)); 
                    fpm = get_subdir_regex_files(cur_dir,['^w' change_file_extension(par.brainmask,'')]);
                    fprm=gzip_volume(fprm); fpm = gzip_volume(fpm);
                end                
                
                gzip_volume(fy); 
                catch
                    fprintf('ERROR apply normalize in  %s\n',cur_dir);
                end
            end
            
            if ~isempty(fp)
                if size(fp{1},1)==3
                    [v m ] = do_fsl_getvol(fp); vv=(v(:,2).*m/1000);
                    cout.wrp1_vol = vv(1);   cout.wrp2_vol = vv(2);     cout.wrp3_vol = vv(3);
                    if ~isempty(fpm), fp = concat_cell(fp,fpm); end
                    
                    voltpm={'_gray','_white','_csf','_mask'}; vol_meas = {'ncc','lncc'};
                    for kk=1: size(fp{1},1)       % 3 ir 4 if mask exist                
                        cmdi = sprintf('FREF=%s%s.nii.gz\n FIN=%s\n',par.spmTPM,voltpm{kk},fp{1}(kk,:));
                        
                        cmdc3 = sprintf('%s reg_measure -ref $FREF -flo $FIN -ncc -lncc  | awk ''{print $2}''  ',cmdi);
                        [a b] = unix(cmdc3); b=str2num(b);                        
                        for kkk=1:2
                            fname = sprintf('stpm_%s%s',vol_meas{kkk},voltpm{kk});
                            cout.(fname) = b(kkk);
                        end
                        cmdc3 = sprintf('%s c3d $FREF $FIN -ncor |awk ''{print $3}'' ',cmdi);
                        [a b] = unix(cmdc3); b=str2num(b);
                        fname = sprintf('stpm_ncor%s',voltpm{kk});cout.(fname) = b;
                    end                    
                end
            end
        end
        
        if ~isfield(cout,'ntpm_ncor_mask')
            if iscell(par.niftireg_warp)
                
            fp = get_subdir_regex_files(cur_dir,'^nw_[pc][123].*nii');
            if isempty(fp)
                fpr = get_subdir_regex_files(cur_dir,'^[pc][123].*nii',3);
                mypar.folder ='mov'; mypar.sge=0; 
                fref = {par.nrTPM};
                nifti_reg_applywarp(fpr,par.niftireg_warp(k),fref,mypar);
                fp = get_subdir_regex_files(cur_dir,'^nw_[pc][123].*nii');
                
                fpm = get_subdir_regex_files(cur_dir,['^nr_' par.brainmask]);
                if isempty(fpm)
                    fprm =  get_subdir_regex_files(cur_dir,['^' par.brainmask]); mypar.prefix='nr_';
                    nifti_reg_applywarp(fprm,par.niftireg_warp(k),fref,mypar);
                end
            end
            fpm = get_subdir_regex_files(cur_dir,['^nr_' par.brainmask]);

            if ~isempty(fp)
                if size(fp{1},1)==3
                    if ~isempty(fpm), fp = concat_cell(fp,fpm); end
                    voltpm={'_gray','_white','_csf','_mask'}; vol_meas = {'ncc','lncc'};
                    for kk=1:size(fp{1},1)       % 3 ir 4 if mask exist 
                        frefc = addprefixtofilenames({par.nrTPM},sprintf('c%d',kk));
                        if kk==4, frefc = {[ get_parent_path(par.nrTPM) ,'/Mean_brain_mask5k.nii']}; end
                        cmdi = sprintf('FREF=%s\n FIN=%s\n',frefc{1},fp{1}(kk,:));
                        cmdc3 = sprintf('%s reg_measure -ref $FREF -flo $FIN -ncc -lncc  | awk ''{print $2}''  ',cmdi);
                        [a b] = unix(cmdc3); b=str2num(b);                        
                        for kkk=1:2
                            fname = sprintf('ntpm_%s%s',vol_meas{kkk},voltpm{kk});
                            cout.(fname) = b(kkk);
                        end
                        cmdc3 = sprintf('%s c3d $FREF $FIN -ncor |awk ''{print $3}'' ',cmdi);
                        [a b] = unix(cmdc3); b=str2num(b);
                        fname = sprintf('ntpm_ncor%s',voltpm{kk});cout.(fname) = b;
                    end              
                    
                end
            end
            end
        end
        if ~isfield(cout,'lap_mean2')
            try
                %fms = get_subdir_regex_files(cur_dir,['^m',par.volreg],1);
                fo = addprefixtofilenames(fms,'lap_');
                if ~exist(fo{1},'file')
                    %cmd = sprintf('cd %s\n c3d %s mask_prob.nii.gz  -multiply -smooth 1.2vox -laplacian %s',cur_dir,fms{1},fo{1});
                    cmd = sprintf('cd %s\n c3d %s -laplacian -as L -push L -push L -multiply  %s  -multiply  %s',cur_dir,fms{1},par.brainmask,fo{1});
                    unix(cmd)
                end
                par.abs=1;
                [v m std E ] = do_fsl_getvol(fo,par);
                cout.lap_std = std;        cout.lap_E = E;     cout.lap_mean=0;    cout.lap_mean2 = m;
                
            catch
                fprintf('ERROR BAD ms nifti %s\n',cur_dir);
                %continue
            end
        end
        
        if ~isfield(cout,'bcsf_msT1_std')
            
            fp = get_subdir_regex_files(cur_dir,'^bin_[cgw].*nii');
            if isempty(fp)
%                 fp = get_subdir_regex_files(cur_dir,'^p0.*nii',1);
%                 cmd = sprintf('cd %s\nfslmaths %s -thr 0.99999 -uthr 1.00001 -bin bin_csf',cur_dir,fp{1});
%                 cmd = sprintf('%s\ncd %s\nfslmaths %s -thr 1.99999 -uthr 2.00001 -bin bin_gray',cmd,cur_dir,fp{1});
%                 cmd = sprintf('%s\ncd %s\nfslmaths %s -thr 2.99999 -uthr 3.00001 -bin bin_white',cmd,cur_dir,fp{1});
                 fp = get_subdir_regex_files(cur_dir,['^',par.segreg,'[123].*nii']);
                 fp=cellstr(char(fp));
                 cmd = sprintf('cd %s\nfslmaths %s -thr 0.9 -bin bin_csf',cur_dir,fp{3});
                 cmd = sprintf('%s\ncd %s\nfslmaths %s -thr 0.9 -bin bin_gray',cmd,cur_dir,fp{1});
                 cmd = sprintf('%s\ncd %s\nfslmaths %s -thr 0.0 -bin bin_white',cmd,cur_dir,fp{2});
                unix(cmd)
                try
                    fp = get_subdir_regex_files(cur_dir,'^bin_[cgw].*nii',3);
                catch
                    fprintf('ERROR no bin gray  %s\n',fres);
                    %continue
                end
            end
            
            [v] = do_fsl_getvol(fp);
            if ~isnan(v)
                
                cout.bingray_vol = v(2,2)/1000;cout.binwhite_vol = v(3,2)/1000;cout.bincsf_vol = v(1,2)/1000;
                
                ppp.mask = fullfile(cur_dir,'bin_gray.nii.gz');
                [v m std] = do_fsl_getvol(fms,ppp);
                cout.bgray_msT1_mean = m; cout.bgray_msT1_std = std;
                ppp.mask = fullfile(cur_dir,'bin_white.nii.gz');
                [v m std] = do_fsl_getvol(fms,ppp);
                cout.bwhite_msT1_mean = m; cout.bwhite_msT1_std = std;
                ppp.mask = fullfile(cur_dir,'bin_csf.nii.gz');
                [v m std] = do_fsl_getvol(fms,ppp);
                cout.bcsf_msT1_mean = m; cout.bcsf_msT1_std = std;
                
            end
        end
        if ~isfield(cout,'volume_contraction')
            
            try
                %fms=get_subdir_regex_files(cur_dir,['^m',par.volreg '.*nii'],1);
                v=nifti_spm_vol(fms{1});
                frm=get_subdir_regex_files(cur_dir,['^rm',par.volreg '.*nii']);
                if isempty(frm)
                    fms=unzip_volume(fms);
                    fmat = get_subdir_regex_files(cur_dir,['^' par.volreg '.*seg8.mat'],1);
                    %j=job_apply_affine(fm,fmat,{'/scratch/CENIR/users/romain.valabregue/dicom/mni/MNI152_T1_1mm.nii'});
                    j=job_apply_affine(fms,fmat);
                    spm_jobman('run',j);
                    frm=get_subdir_regex_files(cur_dir,['^rm',par.volreg '.*nii'])
                end
                
                %v=nifti_spm_vol(fm{1});
                v.vox = sqrt(sum(v.mat(1:3,1:3).^2));
                vr=nifti_spm_vol(frm{1});
                vr.vox = sqrt(sum(vr.mat(1:3,1:3).^2));
                cout.volume_contraction = prod(v.vox)./prod(vr.vox);
                
                fms = gzip_volume(fms);frm = gzip_volume(frm);
                
            catch
                fprintf('ERROR BAD volume_con nifti %s\n',fms{1});
                %continue
            end

        end
        if ~isfield(cout,'RicianNoise')
            addpath(genpath('/network/lustre/iss01/cenir/software/irm/matlab_toolbox/noise_estimation'));
            try
                fm=get_subdir_regex_files(cur_dir,['^m',par.volreg '.*nii'],1);
                [h A] = nifti_spm_vol(fm{1});
                cout.RicianNoise = RicianSTD(A); 
                
            catch
                fprintf('ERROR BAD Rician nifti %s\n',cur_dir);
                %continue
                
            end
        end
    end
    
    if length(fieldnames(cout)) > length(fieldnames(cin))
        ff=get_subdir_regex_files(cur_dir,'.*nii$');
        gzip_volume(ff);

        if exist(fres,'file')
            do_delete(fres,0);
        end
        if isfield(cout,'suj') % field automaticaly added by read_res
            cout=rmfield(cout,'suj');
        end
        write_result_to_csv(cout,fres);
    end
    
    couts(k)=cout;
    
        cout = struct;
    %% now AES part
    coutAES = struct;
    
    if exist(fresAES,'file')
        if par.redo > 0;
            doit=1;
            if par.redo>1
                do_delete(fresAES,0);
            else
                try
                    coutAES = read_res({fresAES}); coutAES=coutAES{1};
                catch                    
                    fprintf('ERROR BAD AES results csv  %s\n',fresAES);
                    do_delete(fresAES,0);
                end
            end
        else
            doit=0;
        end
        
    else
        doit=1;
    end
    cin=coutAES;
    
    coutAES = calc_AES(fms);
    
    fprm =  get_subdir_regex_files(cur_dir,['^' par.brainmask]);
    pp.mask = fprm;
    coutAES_mask = calc_AES(fms,pp);
    
    dd = fieldnames(coutAES_mask); ddout = addsuffixtofilenames(dd,'_mask');
    for rr=1:length(dd),        coutAES.(ddout{rr}) = coutAES_mask.(dd{rr}); end

    if exist(fresAES,'file')
        do_delete(fresAES,0);
    end

    write_result_to_csv(coutAES,fresAES)
    
end

