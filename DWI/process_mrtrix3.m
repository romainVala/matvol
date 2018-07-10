function process_mrtrix3(V4D,par,jobappend)
%function process_mrtrix(V4D,par,jobappend)
%warning this is no more function process_mrtrix(V4D,dti_dir,par,jobappend)

if ~exist('par')
    par='';
end
if ~exist('jobappend','var'), jobappend =''; end

defpar.bvec = 'bvec';
defpar.bval = 'bval';
defpar.fsl_mask = '';  %if define, copy it to mrtrix subdir
defpar.sf_mask = '';
defpar.mask='mask_mrtrix.nii.gz';

defpar.grad_file = 'grad.b';
defpar.csd_name = 'CSD.nii';
defpar.skip_if_exist = 1;
defpar.skip_import_if_exist =1;
defpar.mrtrix_subdir = 'mrtrix';
defpar.jobdir = pwd;
defpar.jobname = 'mrtrix_process';
defpar.sge = 1;
defpar.nthreads = 1;
defpar.lmax = '';
defpar.response_type = 'dhollander'; % tournier
defpar.tempdir = '';

par = complet_struct(par,defpar);

par.sge_nb_coeur = par.nthreads;


if nargin==0
    V4D = get_subdir_regex_files();
    dti_dir = get_subdir_regex;
end

cwd=pwd; job={};

copy_sf_mask=1
if isempty(par.sf_mask), par.sf_mask = par.mask; copy_sf_mask=0; end

for nbsuj = 1:length(V4D)
    
    [dir4D ff ex] = fileparts(V4D{nbsuj});
    the4D = [ff ex];
    
    dti_dir = fullfile(dir4D,par.mrtrix_subdir);
    if ~exist(dti_dir,'dir'), mkdir(dti_dir);end
    
    cd (dti_dir);
    
    if exist(par.grad_file,'file') && par.skip_if_exist , skip=1;else skip=0;end
    
    if ~skip
        
        fprintf('\n****************\nInitial import of in %s\n',pwd);
        
        if exist('mask_mrtrix.nii.gz','file') && par.skip_import_if_exist , skip_import=1;else skip_import=0;end
        if ~skip_import
            
            % Convert the gradient file in mrtrix format
            bvecsf = get_file_from_same_dir(V4D(nbsuj),par.bvec);
            bvalsf = get_file_from_same_dir(V4D(nbsuj),par.bval);
            
            % Copy the 4D file in new mrtrix dir (dti_dir)
            
            aa = r_movefile(V4D(nbsuj),{dti_dir},'link');
            %if strcmp(ex,'.gz'),   aa = unzip_volume(aa);  end
            V4D(nbsuj) = aa;
            
            bvec = load(bvecsf{1});
            bval = load(bvalsf{1});
            bval(bval<50) = 0;
            
            if size(bvec,1)>size(bvec,2), bvec=bvec';bval=bval';end
            
            vol = nifti_spm_vol(V4D{nbsuj});
            mat=vol(1).mat(1:3,1:3);
            vox = sqrt(diag(mat'*mat));  e=eye(3) ;e(1,1)=vox(1);e(2,2)=vox(2);e(3,3)=vox(3);
            rot=mat/e;
            fmrtrix=rot*bvec;
            %fmrtrix=bvec; sur les donnes bruker coro, il ne faut pas faire
            %le rot je comprend plus rien ... arggg
            fmr=[fmrtrix' bval'];
            
            fid = fopen(par.grad_file,'w');
            fprintf(fid,'%f\t%f\t%f\t%f\n',fmr');
            fclose(fid);
            
            %aa = gzip_volume(aa);
            %V4D(nbsuj) = aa;
            
            
            %copy  fsl mask in dti_dir if define
            if ~isempty(par.fsl_mask)
                fmask = get_subdir_regex_files(dir4D,par.fsl_mask,1);
                fo = fullfile(dti_dir,par.mask);
                aa = r_movefile(fmask,fo,'link');
                %aa = unzip_volume(aa)
                %fmask = r_movefile(aa,fullfile(dti_dir,'mask.nii'),'move');
            end
            if copy_sf_mask
                fmask = get_subdir_regex_files(dir4D,par.sf_mask,1);
                fo = fullfile(dti_dir,par.sf_mask);
                aa = r_movefile(fmask,fo,'link');
            end
            
            
        else
            V4D(nbsuj) = get_subdir_regex_files(pwd,ff,1);
            %             fmask =  {fullfile(pwd,'mask_mrtrix.nii.gz')};
        end
        
        
        cmd = sprintf('cd %s\n',dti_dir)
        
        % Creation du masque if needed
        if isempty(par.fsl_mask)
            
            cmd = sprintf('%s\n dwi2mask -nthreads %d -grad %s %s %s', ...
                cmd,par.nthreads, par.grad_file, the4D,par.mask);
        end
        
        %tensor and fa
        cmd = sprintf('%s\n dwi2tensor %s dt.nii -mask %s -grad %s -nthreads %d ',cmd,the4D,par.mask,par.grad_file, par.nthreads);
        cmd = sprintf('%s\n tensor2metric dt.nii -fa fa.nii.gz -vector facolor.nii.gz -nthreads %d ',cmd, par.nthreads);
        
        switch par.response_type
            case 'tournier'
                % Response function estimation
                %cmd = sprintf('%s;\n dwi2response %s response.txt -grad %s -mask %s -sf sf.nii.gz -nthreads %d', cmd, the4D,  par.grad_file, par.sf_mask, par.nthreads);
                cmd = sprintf('%s\n dwi2response tournier %s response.txt -grad %s -mask %s -voxels sf.nii.gz -nthreads %d', ...
                    cmd, the4D,  par.grad_file, par.sf_mask, par.nthreads);
            case {'dhollander','dhollander_single'}
                cmd = sprintf('%s;\n dwi2response dhollander %s response_wm.txt response_gm.txt response_csf.txt -grad %s -mask %s -voxels sf.nii.gz -nthreads %d  ',...
                    cmd, the4D,  par.grad_file, par.sf_mask, par.nthreads);
                
        end
        
        if ~isempty(par.tempdir)
            cmd = sprintf('%s  -tempdir %s', cmd,par.tempdir);         
        end
        
        if ~isempty(par.lmax)
            cmd = sprintf('%s -lmax %d',cmd,par.lmax);
        end
        
        cmd = sprintf('%s \n',cmd);

        % Fibre Orientation Distribution estimation
        switch par.response_type
            case 'tournier'
                %cmd = sprintf('%s;\n dwi2fod %s response.txt CSD.nii.gz -mask %s -grad %s -nthreads %d \n', cmd, the4D, par.mask,  par.grad_file, par.nthreads);
                cmd = sprintf('%s;\n dwi2fod csd %s response.txt CSD.nii.gz -mask %s -grad %s -nthreads %d \n',...
                    cmd, the4D, par.mask,  par.grad_file, par.nthreads);
            case 'dhollander'
                cmd = sprintf('%s\n dwi2fod msmt_csd %s response_wm.txt CSD_wm.nii.gz response_gm.txt CSD_gm.nii.gz response_csf.txt CSD_csf.nii.gz -mask %s -grad %s -nthreads %d \n', ...
                    cmd, the4D, par.mask,  par.grad_file, par.nthreads);
                cmd = sprintf('%s\n mrconvert CSD_wm.nii.gz wm_density.nii.gz -coord 3 0 \n',cmd);
                cmd = sprintf('%s\n mrcat wm_density.nii.gz CSD_gm.nii.gz CSD_csf.nii.gz tissueRGB.nii.gz -axis 3\n',cmd);
            case 'dhollander_single'
                cmd = sprintf('%s\n dwi2fod msmt_csd %s response_wm.txt CSD_wm.nii.gz response_csf.txt CSD_csf.nii.gz -mask %s -grad %s -nthreads %d \n', ...
                    cmd, the4D, par.mask,  par.grad_file, par.nthreads);
                cmd = sprintf('%s\n mrconvert CSD_wm.nii.gz wm_density.nii.gz -coord 3 0 \n',cmd);
                cmd = sprintf('%s\n mrcat wm_density.nii.gz CSD_csf.nii.gz tissueRGB.nii.gz -axis 3\n',cmd);
        end
        
        if par.sge
            job{end+1} = cmd;
        else
            unix(cmd)
        end
        
    end %if ~skip
end %for nbsuj = 1:length(V4D)

cd(cwd);

job = do_cmd_sge(job,par,jobappend);
end
