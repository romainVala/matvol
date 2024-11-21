function job =  job_dwi2response(fdwi,par)
% JOB_DWI2RESPONSE :
%                   Estimate the response function using Mrtrix3
%
% Input :
%         fdwi : (cellstr) dwi images preprocessed
%
%
%
%         par.response_type : (char) Algorithms
%                      'tournier'  : estimate the response function for single-tissue
%                      'dhollander': estimate the response functions for multi-tissue ( default : 'dhollander')
%                      'msmt_5tt'  : estimate the response functions for multi-tissue based on 5 tissue-type-image
% 
% Output :
%       Create 3 txt files : 
%       response_gm.txt, response_wm.txt, response_csf.txt
%
%
%--------------------------------------------------------------------------


if ~exist('par'), par=''; end



defpar.bvec        = 'bvec';    % Regex or full name of b-vectors file ( default : 'bvec')
defpar.bval        = 'bval';    % Regex or full name of b-values file  ( default : 'bval')
defpar.grad_file   = 'grad.b';  % Diffusion gradient table name in mrtrix format


defpar.mask_name      = '';     % if define, copy it to mrtrix subdir, must be  in fdwi dir
defpar.compute_mask   = 'mask_mrtrix.nii';     % char to define the output name, not that if use_mask is defined, compute_mask


defpar.skip_gradfile        = 1;
defpar.redo                 = 0;
defpar.mrtrix_subdir        = 'mrtrix';

% defpar.jobdir  = pwd;


defpar.lmax          = '';            % Maximum harmonic degrees for response function
defpar.response_type = 'dhollander';  %  tournier, dhollander, msmt_5tt


% defpar.mrgrid

defpar.image5tt = {''};              % 5tt image 
defpar.jobname  = 'dwi2response';


defpar.nthreads       = 1;
defpar.sge            = 1;




par = complet_struct(par,defpar);



use_defined_mask= 1;
if isempty(par.mask_name), use_defined_mask = 0; end


% Check par.response_type value
algo = {'dhollander', 'msmt_5tt','tournier'};
assert(contains(par.response_type,algo),'par.response_type must contain one of these algorithms: dhollander, msmt_5tt, tournier');



% Check image5tt
if strcmp(par.response_type,'msmt_5tt')
    assert(length(par.image5tt) == length(fdwi),'The ''msms5TT'' algorithm requires a 5tt image');
end



job={};
for nbsuj = 1:length(fdwi)
    
    
    [dir4D the4D] = get_parent_path(fdwi{nbsuj},1);
    
    dti_dir = fullfile(dir4D,par.mrtrix_subdir);
    if ~exist(dti_dir,'dir'), mkdir(dti_dir);end
    
    
    
    
    %     cd (dti_dir);
    fgrad       = fullfile(dti_dir,par.grad_file);
    fRfunction  = fullfile(dti_dir, 'response_wm.txt');
    if exist(fgrad,'file') && par.skip_gradfile, skip=1; else skip = 0; end
    
    if exist(fRfunction,'file') && ~par.redo, do = 0; else do = 1; end
    
    if do
        
        if ~ skip
            
            % Convert the gradient file in mrtrix format
            bvecsf = get_file_from_same_dir(fdwi(nbsuj),par.bvec);
            bvalsf = get_file_from_same_dir(fdwi(nbsuj),par.bval);
            
            fdd = fullfile(dir4D,'m_dg_dn_4D_dwieddycor.nii');
            
            
            % Copy the 4D file in new mrtrix dir (dti_dir)
            
            bvec = load(bvecsf{1});
            bval = load(bvalsf{1});
            bval(bval<50) = 0;
            
            if size(bvec,1)>size(bvec,2), bvec=bvec';bval=bval';end
            
            vol = nifti_spm_vol(fdd);   % (fdwi{nbsuj});
            mat = vol(1).mat(1:3,1:3);
            vox = sqrt(diag(mat'*mat));  e=eye(3) ;e(1,1)=vox(1);e(2,2)=vox(2);e(3,3)=vox(3);
            rot = mat/e;
            fmrtrix = rot*bvec;
            
            fmr=[fmrtrix' bval'];
            
            fid = fopen(fgrad,'w');
            fprintf(fid,'%f\t%f\t%f\t%f\n',fmr');
            fclose(fid);
        end
        
 
    
            r_movefile(fdwi(nbsuj),{dti_dir},'link');

        
        cmd = sprintf('cd %s\n',dti_dir)
        
        % Mask
        if use_defined_mask
            fmask = get_subdir_regex_files(dir4D, par.mask_name);
            [~,aa] = get_parent_path(fmask,1);
            mask_name = char(aa);
            fo    = fullfile(dti_dir,mask_name);
            r_movefile(fmask,fo,'link');
            
        else
            
            cmd = sprintf('%s\n dwi2mask -grad %s %s %s -force', ...
                cmd, par.grad_file, the4D,par.compute_mask);
            mask_name = par.compute_mask;
        end
        
        
        %         % Tensor and fa
        %         cmd = sprintf('%s\n dwi2tensor %s dt.nii -mask %s -grad %s',cmd,the4D,par.mask,par.grad_file);
        %         cmd = sprintf('%s\n tensor2metric dt.nii -fa fa.nii.gz -vector facolor.nii.gz',cmd);
        %
        %  Algorithms
        
        switch par.response_type
            
            case 'tournier'
                % Response function estimation
                
                cmd = sprintf('%s\n dwi2response tournier %s response.txt -grad %s -mask %s -voxels sf.nii.gz', ...
                    cmd, the4D,  par.grad_file, mask_name);
                
                
                
            case 'dhollander'
                cmd = sprintf('%s\n dwi2response dhollander %s response_wm.txt response_gm.txt response_csf.txt -grad %s -mask %s -voxels sf.nii.gz',...
                    cmd, the4D,  par.grad_file, mask_name);
                
                
            case 'msmt_5tt'
                
                cmd = sprintf('%s\n dwi2response msmt_5tt %s response_wm.txt response_gm.txt response_csf.txt -grad %s -mask %s -voxels sf.nii.gz'...
                    , cmd, the4D, par.image5TT{nbsuj},par.grad_file, mask_name);
                
        end
        
        cmd = sprintf('%s -force ',cmd);
        if ~isempty(par.lmax)
            cmd = sprintf('%s -lmax %d',cmd,par.lmax);
        end

        
        if par.nthreads
            cmd = sprintf('%s -nthreads %d',cmd,par.nthreads);
        end
        
        if par.sge
            job{end+1} = cmd;
        else
            unix(cmd);
        end
        
    end %if do
end %for

job = do_cmd_sge(job,par);

end



