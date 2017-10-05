function transform_bvec_after_coregister(V4D,par)

if ~exist('par')
    par='';
end

if ~isfield(par,'bvals')    par.bvals = 'bval';  end
if ~isfield(par,'bvecs')    par.bvecs = 'bvec';  end
if ~isfield(par,'bvec_prefix')    par.bvec_prefix = 'coreg_rot_';  end

if nargin==0
    V4D = '';
end

if isempty(V4D)
   V4D = get_subdir_regex_files();
end

if ischar(V4D)
    V4D = cellstr(char(V4D));
end

for nbsuj = 1:length(V4D)
    
    [dir4D ff ex] = fileparts(V4D{nbsuj});
    
    %to read the nifti header spm_vol does not take zip nifti so unzip
    
    if strcmp(ex,'.gz'),    
        V4D(nbsuj) = unzip_volume(V4D{nbsuj});  
    end
    % read the nifti header
    vol = spm_vol(V4D{nbsuj});
    
    %zip again if needed
    if strcmp(ex,'.gz'),    
        gzip_volume(V4D{nbsuj});  
    end
    
    %Convert the gradient file in mrtrix format
    bvecfile = get_subdir_regex_files(dir4D,par.bvecs,1);
%    bvalfile = get_subdir_regex_files(dir4D,par.bvals,1);
    newbvecfile = addprefixtofilenames(bvecfile,par.bvec_prefix);
    
    bvec = load(bvecfile{1});
%    bval = load(bvalfile{1});
    
    if ~strcmp('Scanner',vol(1).private.mat0_intent)
        error('can not find original matrix')
    end
    mat0 = vol(1).private.mat0(1:3,1:3)
    mat=vol(1).mat(1:3,1:3);

    vox = sqrt(diag(mat'*mat));  
    e=eye(3) ;e(1,1)=vox(1);e(2,2)=vox(2);e(3,3)=vox(3);
    rot=mat/e;

    vox = sqrt(diag(mat0'*mat0));  
    e=eye(3) ;e(1,1)=vox(1);e(2,2)=vox(2);e(3,3)=vox(3);
    rot0=mat0/e;

    %apply the nifti volume rotation to the bvec 
    %newbvec = (rot/rot0)*bvec;
%     newbvec = (rot0/rot)*bvec;
%     newbvec = (inv(rot)*rot0)*bvec; %equivant a la transfo de 4D to B0
    newbvec =  inv(rot0)*rot*bvec;  %equivant a la transfo de B0 to rB0


    %Writing bvals and bvec
    fid = fopen(newbvecfile{1},'w');
    for kk=1:3
        fprintf(fid,'%f ',newbvec(kk,:));
        fprintf(fid,'\n');
    end
    fclose(fid);
    

    
end%for nbsuj = 1:length(V4D)


