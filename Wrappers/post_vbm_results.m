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
defpar.segreg='[cp]'; %p for vbm8
defpar.volreg='s'; %p for vbm8
defpar.brainmask = 'mask_brain_erode_dilate.nii.gz';

par = complet_struct(par,defpar);

if ischar(dir_vbm)
    dir_vbm={dir_vbm};
end

if par.sge
    for k=1:length(dir_vbm)
        cmd{k} = sprintf('dir_vbm=''%s'';\npar.redo=%d; par.segreg=''%s'';par.volreg=''%s'';\npost_vbm_results(dir_vbm,par);\n',...
            dir_vbm{k},par.redo,par.segreg,par.volreg);
    end
    
    do_cmd_matlab_sge(cmd,par)
    return
end


for k=1:length(dir_vbm)
    cur_dir = dir_vbm{k};
    
    fres = fullfile(cur_dir,par.resfilename);
    cout = struct;
    
    if exist(fres,'file')
        if par.redo > 0;
            doit=1;
            if par.redo>1
                do_delete(fres,0);
            else
                try
                    cout = read_res(fres);
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
        
        if ~isfield(cout,'mask_vol')
            fp = get_subdir_regex_files(cur_dir,['^',par.segreg,'[123].*nii']);
            if isempty(fp)
                continue
            end
            
            if size(fp{1},1)==3
                [v m std E ] = do_fsl_getvol(fp);            vv=(v(:,2).*m/1000);
                
                cout.gray_vol = vv(1);    cout.white_vol = vv(2);  cout.csf_vol = vv(3);
                cout.gray_std = std(1);   cout.white_std = std(2); cout.csf_std = std(3);
                cout.gray_E = E(1);       cout.white_E = E(2);     cout.csf_E = E(3);
                
                fo=fullfile(cur_dir,par.brainmask);
                if ~exist(fo,'file')
                    do_fsl_add(fp,fo);
                end
                v=do_fsl_getvol(fo);            cout.mask_vol = v(2)/1000;
                
            end
        end
        
        if ~isfield(cout,'wmask_vol')
            
            fp = get_subdir_regex_files(cur_dir,['^r',par.segreg,'[123].*nii']);
            if isempty(fp)
                continue
            end

            if size(fp{1},1)==3
                [v m ] = do_fsl_getvol(fp);         vv=(v(:,2).*m/1000);
                cout.vbm_rp1_vol = vv(1);   cout.vbm_rp2_vol = vv(2);  cout.vbm_rp3_vol = vv(3);
            end
            
            %fp = get_subdir_regex_files(cur_dir,'^m0wrp[123].*nii');
            fp = get_subdir_regex_files(cur_dir,'^wc[123].*nii');
            if ~isempty(fp)
            if size(fp{1},1)==3
                [v m ] = do_fsl_getvol(fp); vv=(v(:,2).*m/1000);
                cout.m0wrp1_vol = vv(1);   cout.m0wrp2_vol = vv(2);     cout.m0wrp3_vol = vv(3);
                
                fo=fullfile(cur_dir,par.brainmask);
                if ~exist(fo,'file')
                    do_fsl_add(fp,fo);
                end
                v=do_fsl_getvol(fo);
                cout.wmask_vol = v(2)/1000;
            end
            end
        end
                
        if ~isfield(cout,'lap_mean2')
            try
                fms = get_subdir_regex_files(cur_dir,['^m',par.volreg],1);
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
                continue
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
                    continue
                end
            end
            
            [v] = do_fsl_getvol(fp);
            if isnan(v)
                continue
            end
            
            cout.bingray_vol = v(2,2)/1000;cout.binwhite_vol = v(3,2)/1000;cout.bincsf_vol = v(1,2)/1000;
            
            fm = get_subdir_regex_files(cur_dir,['^m',par.volreg '.*nii']);
            ppp.mask = fullfile(cur_dir,'bin_gray.nii.gz');
            [v m std] = do_fsl_getvol(fm,ppp);
            cout.bgray_msT1_mean = m; cout.bgray_msT1_std = std;
            ppp.mask = fullfile(cur_dir,'bin_white.nii.gz');
            [v m std] = do_fsl_getvol(fm,ppp);
            cout.bwhite_msT1_mean = m; cout.bwhite_msT1_std = std;
            ppp.mask = fullfile(cur_dir,'bin_csf.nii.gz');
            [v m std] = do_fsl_getvol(fm,ppp);
            cout.bcsf_msT1_mean = m; cout.bcsf_msT1_std = std;
        end
        if ~isfield(cout,'volume_contraction')
            
            try
                fm=get_subdir_regex_files(cur_dir,['^m',par.volreg '.*nii'],1);
                v=nifti_spm_vol(fm{1});
                frm=get_subdir_regex_files(cur_dir,['^rm',par.volreg '.*nii'])
                if isempty(frm)
                    fm=unzip_volume(fm);
                    fmat = get_subdir_regex_files(cur_dir,['^' par.volreg '.*seg8.mat'],1);
                    j=job_apply_affine(fm,fmat,{'/export/dataCENIR/dicom/nifti_proc/mni/MNI152_T1_1mm_brain.nii'});
                    spm_jobman('run',j);
                    frm=get_subdir_regex_files(cur_dir,['^rm',par.volreg '.*nii'])
                end
                
                %v=nifti_spm_vol(fm{1});
                v.vox = sqrt(sum(v.mat(1:3,1:3).^2));
                vr=nifti_spm_vol(frm{1});
                vr.vox = sqrt(sum(vr.mat(1:3,1:3).^2));
                cout.volume_contraction = prod(v.vox)./prod(vr.vox);
                
                fm = gzip_volume(fm);frm = gzip_volume(frm);
                
            catch
                fprintf('ERROR BAD ms nifti %s\n',fm{1});
                continue
            end

        end
        if ~isfield(cout,'RicianNoise')
            addpath(genpath('/network/lustre/iss01/cenir/software/irm/matlab_toolbox/noise_estimation'));
            try
                fm=get_subdir_regex_files(cur_dir,['^m',par.volreg '.*nii'],1);
                [h A] = nifti_spm_vol(fm{1});
                cout.RicianNoise = RicianSTD(A); 
                
            catch
                fprintf('ERROR BAD ms nifti %s\n',fm{1});
                keyboard
                continue
                
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
end

