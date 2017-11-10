function [o ] = get_subdir_regex_images(indir,reg_ex,p)

if ~exist('p'), p=struct;end

reg_ex_img = addsuffixtofilenames(reg_ex,'.*img');

if isnumeric(p)
    aa=p;clear p
    p.wanted_number_of_file = aa;
    p.verbose=0;    
end

pp.verbose=0;


o = get_subdir_regex_files(indir,reg_ex_img,pp);

if isempty(o)
    reg_ex_img = addsuffixtofilenames(reg_ex,'.*nii');
    
    o = get_subdir_regex_files(indir,reg_ex_img,pp);
    
end


%now we know the extention again to check for the number of file ask
if isfield(p,'wanted_number_of_file')
    o = get_subdir_regex_files(indir,reg_ex_img,p);
end

