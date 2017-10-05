function transform_bvec_to_mrtrix(V4D,par)
% transform_bvec_to_mrtrix(V4D,par)
% given a nifti file this program will transforme bvecs and bvals from fsl to gradient matrix in mrtrix format
% V4D : input of nifti file : either a cell list of filepath or a matrix of filepath if no argument 
%       the spm graphical selector will call to select the volumes. 
% par : optional matlab structure to change defautl parameters :
%     par.bvals : default = 'bvals'  name of the bvals file (assumed to be in the same dir as the input nifti file)
%     par.bvecs : default = 'bvecs'  name of the bvecs file (assumed to be in the same dir as the input nifti file)
%     par.grad_file : default = 'grad.b'  name of the mrtrix direction files (output of the program)
%     par.mrtrix_outputdir : default = '' subdir (relativ to the dir of the nifti file) where the mrtrix gradient
%                                      file will be writen. if empty it will be in the same dir as the input file
%
%romain valabregue sep 2012

if ~exist('par')
    par='';
end

if ~isfield(par,'bvals')    par.bvals = 'bvals';  end
if ~isfield(par,'bvecs')    par.bvecs = 'bvecs';  end
if ~isfield(par,'grad_file')    par.grad_file = 'grad.b';  end
if ~isfield(par,'mrtrix_outputdir')    par.mrtrix_outputdir = '';  end

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
    bvecfile = fullfile(dir4D,par.bvecs);
    if ~exist(bvecfile)
	dd=dir(fullfile(dir4D,['*' par.bvecs '*']));
        if length(dd)==1
	   bvecfile = fullfile(dir4D,dd.name);
	else
	   fprintf('Can not find the bvecs file in dir %s \n define par.bvecs in the function call or choose it graphicaly\n',dir4D);
	   bvecfile = get_subdir_regex_files();
	   bvecfile = char(bvecfile);
    	end

    end

    bvalfile = fullfile(dir4D,par.bvals);
    if ~exist(bvalfile)
	dd=dir(fullfile(dir4D,['*' par.bvals '*']));
        if length(dd)==1
	   bvalfile = fullfile(dir4D,dd.name);
	else
	   fprintf('Can not find the bvals file in dir %s \n define par.bvals in the function call or choose it graphicaly\n',dir4D);
	   bvalfile = get_subdir_regex_files();
     	   bvalfile = char(bvalfile);
    	end

    end

    bvec = load(bvecfile);
    bval = load(bvalfile);
    
    %extract the rotation
    mat=vol(1).mat(1:3,1:3);
    vox = sqrt(diag(mat'*mat));  
    e=eye(3) ;e(1,1)=vox(1);e(2,2)=vox(2);e(3,3)=vox(3);
    rot=mat/e;

    %apply the nifti volume rotation to the bvec 
    fmrtrix=rot*bvec;
    fmr=[fmrtrix' bval'];

    if ~isempty (par.mrtrix_outputdir)
	dti_dir = fullfile(dir4D,par.mrtrix_outputdir)
    else
	dti_dir = dir4D;
    end

    fid = fopen(fullfile(dti_dir,par.grad_file),'w');
    fprintf(fid,'%f\t%f\t%f\t%f\n',fmr');
    fclose(fid);
    
    
end%for nbsuj = 1:length(V4D)




%%%%%%%%%%%%%%%%%%%%%%%%% function to select files
function o=get_subdir_regex_files(indir,reg_ex,p)
%cell vector of in directories
%reg_ex regular expression to select files
%p parameter, if  p.preproc_subdir is defined it will lock in this subdir
% and if not exist il will create it and copy the files in this subdir

if ~exist('p'), p=struct;end
if ~exist('indir'), indir={pwd};end
if ~exist('reg_ex'), reg_ex=('graphically');end


if ischar(reg_ex)
  if strcmp(reg_ex,'graphically')
    o={};
    for nb_dir=1:length(indir)
      dir_sel = spm_select(inf,'any','select files','',indir{nb_dir});
      dir_sel = cellstr(dir_sel);
      for kk=1:length(dir_sel)
	o{end+1} = dir_sel{kk};
      end
    end
    return
  end
end 


if isnumeric(p)
  aa=p;clear p
  p.wanted_number_of_file = aa;
  p.verbose=0;
end

if ~isfield(p,'verbose'), p.verbose=1;end

if ~iscell(reg_ex), reg_ex={reg_ex};end
if ~iscell(indir), indir={indir};end

o={};

for nb_dir=1:length(indir)
  
  cur_dir = indir{nb_dir};
  
  please_copy_file=0;

  if isfield(p,'preproc_subdir')
    if exist(fullfile(cur_dir,p.preproc_subdir),'dir')
      cur_dir = fullfile(cur_dir,p.preproc_subdir);
    else
      please_copy_file=1;
    end
    
  end

  od = dir(cur_dir);
  od = od(3:end);

  found=0;to={};
  
  for nb_reg=1:length(reg_ex)
    for k=1:length(od)
      if ~od(k).isdir && ~isempty(regexp(od(k).name,reg_ex{nb_reg}, 'once' ))
	to{end+1} = fullfile(cur_dir,od(k).name);
	found=found+1;
      end
    end
  end
  to = char(to);
  
  if p.verbose
    fprintf('found %d files in %s for ',found,cur_dir)
    for kr=1:length(reg_ex)
      fprintf('%s\t',reg_ex{kr});
    end
    fprintf('\n');
  end

  if ~isempty(to)
    if please_copy_file
      if p.verbose, fprintf('   copy them to %s ...',p.preproc_subdir);  end
      to = char(change_file_path_to_preproc_dir(to,p));
      if p.verbose, fprintf('   ... done\n');  end
	    
    end
    
    o{end+1} = to;
    
  end

  if isfield(p,'wanted_number_of_file')
    if size(to,1)~=p.wanted_number_of_file;
      error('found %d file first indir %s',size(to,1),indir{nb_dir})
    end
    
  end

end


%%%%%%%%%%%%%%%%%%%%%%%%% function to select directorie (with regular expression)
function [o no]=get_subdir_regex(indir,reg_ex,varargin)

if ~exist('indir'), indir=pwd;end
if ~exist('reg_ex'), reg_ex=('graphically');end

if length(varargin)>0
  o = get_subdir_regex(indir,reg_ex);
  for ka=1:length(varargin)
    o = get_subdir_regex(o,varargin{ka});
  end
  return
end

if ~iscell(indir), indir={indir};end

if ischar(reg_ex)
  if strcmp(reg_ex,'graphically')
    o={};
    for nb_dir=1:length(indir)
      dir_sel = spm_select(inf,'dir','select a directories','',indir{nb_dir});
      dir_sel = cellstr(dir_sel);
      for kk=1:length(dir_sel)
	o{end+1} = dir_sel{kk};
      end
    end
    return
  end
end 


if ~iscell(reg_ex), reg_ex={reg_ex};end

o={};
no={};

for nb_dir=1:length(indir)
  od = dir(indir{nb_dir});
  od = od(3:end);
  found_sub=0;
  
  for k=1:length(od)
    
    for nb_reg=1:length(reg_ex)      
      if strcmp(reg_ex{nb_reg}(1),'-')
%	reg_ex{nb_reg}(1)=''
	if od(k).isdir & ~isempty(regexp(od(k).name,reg_ex{nb_reg}(2:end)))
	  break
	end
      end
      
      if od(k).isdir & ~isempty(regexp(od(k).name,reg_ex{nb_reg}))
	o{end+1} = fullfile(indir{nb_dir},od(k).name,filesep);
	found_sub=1;
	break% (to avoid that 2 reg_ex adds the same dir
      end
      
    end
    
  end
  
  if ~found_sub
    no{end+1} = indir{nb_dir};
  end
end


function fo = gzip_volume(f)

f = cellstr(char(f));

for i=1:length(f)

  if ~strcmp(f{i}(end-1:end),'gz')
    cmd = sprintf('gzip -f %s',f{i});

    fo{i} = [f{i} '.gz'];
  
    unix(cmd);
  else
    fo{i} = f{i};
  end
  
end


function fo = unzip_volume(f)

f = cellstr(char(f));

for i=1:length(f)

  if strcmp(f{i}(end-1:end),'gz')
    cmd = sprintf('gunzip -f %s',f{i});

    fo{i} = f{i}(1:end-3);
  
    unix(cmd);
  else
    fo{i} = f{i};
  end
  
end

